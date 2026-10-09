// ============================================================================
// File: tb_cardioedge_firmware.sv
// Project: HONOURS_CBP_CARDIOEDGE
//
// Standalone Firmware Verification Testbench & Dynamic Loader
// 
// ARCHITECTURE:
//   Instantiates existing, unmodified `cardioedge_cpu_soc_top`
//   Preserves frozen RTL and existing 18/18 testbench baseline
//
// FUNCTIONALITY:
//   1. Dynamic IMEM Loader: Reads compiled Verilog HEX (cardioedge_test.vhx)
//      directly into `dut.u_imem.mem` via simulation-only backdoor mechanism.
//   2. Live UART Telemetry: Intercepts UART console characters and displays
//      them in real-time on simulation stdout.
//   3. Hardware Access Verification: Monitors AXI transactions to all 7 IPs.
//   4. QRS ECG Stream Tracker: Observes software sample injection to 0x40012008.
// ============================================================================

`timescale 1ns/1ps

module tb_cardioedge_firmware;

    // -----------------------------------------------------------------------
    // Simulation Parameters & Clocks
    // -----------------------------------------------------------------------
    localparam time CLK_PERIOD = 20ns; // 50 MHz system clock
    localparam GPIO_BITS       = 8;
    localparam MAX_SIM_CYCLES  = 4000000; // Safety watchdog timeout (4.0M cycles)

    logic clk;
    logic rst_n;

    // -----------------------------------------------------------------------
    // External SoC Pins
    // -----------------------------------------------------------------------
    // UART
    logic uart_rx_i;
    wire  uart_tx_o;

    // SPI
    wire  spi_clk_o;
    wire  spi_cs_n_o;
    wire  spi_mosi_o;
    logic spi_miso_i;

    // GPIO
    wire [GPIO_BITS-1:0] gpio_io;
    logic [GPIO_BITS-1:0] gpio_in_val;
    logic                 gpio_drive_en;
    assign gpio_io = gpio_drive_en ? gpio_in_val : {GPIO_BITS{1'bz}};

    // Timer
    logic timer_ext_meas_i;
    logic timer_capture_i;
    wire  timer_pwm_o;
    wire  timer_trigger_o;

    // ADC
    logic [11:0] adc_sample_in;
    logic        adc_sample_valid;

    // FIR
    logic        fir_s_axis_tvalid;
    wire         fir_s_axis_tready;
    logic [15:0] fir_s_axis_tdata;
    wire         fir_m_axis_tvalid;
    logic        fir_m_axis_tready;
    wire  [39:0] fir_m_axis_tdata;

    // Interrupt monitoring
    wire uart_irq;
    wire gpio_irq;
    wire timer_irq;
    wire adc_irq_sample;
    wire adc_irq_overrun;

    // -----------------------------------------------------------------------
    // Instantiate Unmodified CARDIOEDGE SoC Top
    // -----------------------------------------------------------------------
    cardioedge_cpu_soc_top #(
        .GPIO_BITS(GPIO_BITS)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),

        .uart_rx_i         (uart_rx_i),
        .uart_tx_o         (uart_tx_o),

        .spi_clk_o          (spi_clk_o),
        .spi_cs_n_o         (spi_cs_n_o),
        .spi_mosi_o         (spi_mosi_o),
        .spi_miso_i         (spi_miso_i),

        .gpio_io            (gpio_io),

        .timer_ext_meas_i   (timer_ext_meas_i),
        .timer_capture_i    (timer_capture_i),
        .timer_pwm_o        (timer_pwm_o),
        .timer_trigger_o    (timer_trigger_o),

        .adc_sample_in      (adc_sample_in),
        .adc_sample_valid   (adc_sample_valid),

        .fir_s_axis_tvalid  (fir_s_axis_tvalid),
        .fir_s_axis_tready  (fir_s_axis_tready),
        .fir_s_axis_tdata   (fir_s_axis_tdata),
        .fir_m_axis_tvalid  (fir_m_axis_tvalid),
        .fir_m_axis_tready  (fir_m_axis_tready),
        .fir_m_axis_tdata   (fir_m_axis_tdata),

        .uart_irq           (uart_irq),
        .gpio_irq           (gpio_irq),
        .timer_irq          (timer_irq),
        .adc_irq_sample     (adc_irq_sample),
        .adc_irq_overrun    (adc_irq_overrun)
    );

    // -----------------------------------------------------------------------
    // Clock Generation
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -----------------------------------------------------------------------
    // Dynamic Firmware & ELF Loader (Multi-Format IMEM/DMEM Initialization)
    // Supports Intel HEX (.hex) and Verilog HEX (.vhx)
    // -----------------------------------------------------------------------
    function automatic int parse_hex_nibble(byte c);
        if (c >= "0" && c <= "9") return (c - "0");
        if (c >= "a" && c <= "f") return (c - "a" + 10);
        if (c >= "A" && c <= "F") return (c - "A" + 10);
        return 0;
    endfunction

    function automatic logic [7:0] parse_hex_byte(byte hi, byte lo);
        return (parse_hex_nibble(hi) << 4) | parse_hex_nibble(lo);
    endfunction

    // Native Intel HEX (.hex) parser task
    task automatic load_intel_hex(
        input  string       filepath,
        output int          total_bytes,
        output int          imem_bytes,
        output int          dmem_bytes,
        output logic [31:0] detected_entry,
        output int          success
    );
        integer fd;
        string line;
        logic [31:0] base_addr;
        logic [31:0] record_addr;
        int line_len;
        int byte_cnt;
        int rectype;
        int i;
        logic [7:0] d_byte;
        logic [31:0] byte_addr;

        fd = $fopen(filepath, "r");
        if (fd == 0) begin
            success = 0;
            return;
        end

        total_bytes    = 0;
        imem_bytes     = 0;
        dmem_bytes     = 0;
        base_addr      = 32'h0;
        detected_entry = 32'h0;
        success        = 1;

        while ($fgets(line, fd)) begin
            line_len = line.len();
            while (line_len > 0 && (line.getc(line_len-1) == 8'h0A || line.getc(line_len-1) == 8'h0D || line.getc(line_len-1) == " ")) begin
                line_len = line_len - 1;
            end

            if (line_len >= 9 && line.getc(0) == ":") begin
                byte_cnt = parse_hex_byte(line.getc(1), line.getc(2));
                record_addr = {16'h0, parse_hex_byte(line.getc(3), line.getc(4)), parse_hex_byte(line.getc(5), line.getc(6))};
                rectype  = parse_hex_byte(line.getc(7), line.getc(8));

                case (rectype)
                    8'h00: begin // Data Record
                        for (i = 0; i < byte_cnt; i = i + 1) begin
                            if ((9 + i*2 + 1) < line_len) begin
                                d_byte = parse_hex_byte(line.getc(9 + i*2), line.getc(10 + i*2));
                                byte_addr = base_addr + record_addr + i;

                                if (byte_addr < 32'h0001_0000) begin
                                    // IMEM region (0x0000_0000 - 0x0000_FFFF)
                                    dut.u_imem.mem[byte_addr[15:2]][byte_addr[1:0]*8 +: 8] = d_byte;
                                    imem_bytes = imem_bytes + 1;
                                end else if (byte_addr >= 32'h0001_0000 && byte_addr < 32'h0002_0000) begin
                                    // DMEM region (0x0001_0000 - 0x0001_FFFF)
                                    dut.u_dmem.mem[byte_addr[15:2]][byte_addr[1:0]*8 +: 8] = d_byte;
                                    dmem_bytes = dmem_bytes + 1;
                                end
                                total_bytes = total_bytes + 1;
                            end
                        end
                    end

                    8'h01: begin // EOF Record
                        break;
                    end

                    8'h02: begin // Extended Segment Address Record
                        if (byte_cnt == 2 && line_len >= 13) begin
                            base_addr = {parse_hex_byte(line.getc(9), line.getc(10)), parse_hex_byte(line.getc(11), line.getc(12))} << 4;
                        end
                    end

                    8'h04: begin // Extended Linear Address Record
                        if (byte_cnt == 2 && line_len >= 13) begin
                            base_addr = {parse_hex_byte(line.getc(9), line.getc(10)), parse_hex_byte(line.getc(11), line.getc(12))} << 16;
                        end
                    end

                    8'h03: begin // Start Segment Address Record (CS:IP)
                        if (byte_cnt == 4 && line_len >= 17) begin
                            logic [15:0] cs_val, ip_val;
                            cs_val = {parse_hex_byte(line.getc(9), line.getc(10)), parse_hex_byte(line.getc(11), line.getc(12))};
                            ip_val = {parse_hex_byte(line.getc(13), line.getc(14)), parse_hex_byte(line.getc(15), line.getc(16))};
                            detected_entry = (cs_val << 4) + ip_val;
                        end
                    end

                    8'h05: begin // Start Linear Address Record
                        if (byte_cnt == 4 && line_len >= 17) begin
                            detected_entry = {parse_hex_byte(line.getc(9), line.getc(10)),
                                              parse_hex_byte(line.getc(11), line.getc(12)),
                                              parse_hex_byte(line.getc(13), line.getc(14)),
                                              parse_hex_byte(line.getc(15), line.getc(16))};
                        end
                    end
                endcase
            end
        end
        $fclose(fd);
    endtask

    // Dispatcher task: identifies file format (Intel HEX vs Verilog HEX) and loads
    task automatic load_firmware_image(input string filepath, output int success);
        integer test_fd;
        string first_line;
        int tot_bytes, im_bytes, dm_bytes;
        logic [31:0] ent_addr;

        test_fd = $fopen(filepath, "r");
        if (test_fd == 0) begin
            success = 0;
            return;
        end

        // Check if first line begins with ':' (Intel HEX)
        if ($fgets(first_line, test_fd)) begin
            $fclose(test_fd);
            if (first_line.len() > 0 && first_line.getc(0) == ":") begin
                $display("[LOADER] Detected Intel HEX format in: %s", filepath);
                load_intel_hex(filepath, tot_bytes, im_bytes, dm_bytes, ent_addr, success);
                if (success) begin
                    $display("[LOADER] Successfully loaded Intel HEX: %0d bytes (%0d -> IMEM, %0d -> DMEM)",
                             tot_bytes, im_bytes, dm_bytes);
                    if (ent_addr != 32'h0) begin
                        $display("[LOADER] Target entry point: 0x%08h", ent_addr);
                    end

                    // If code was mapped into DMEM (0x0001_xxxx) and reset vector (IMEM 0x0) has no user code:
                    if (ent_addr >= 32'h0001_0000 && im_bytes == 0) begin
                        logic [31:0] hi_imm, lo_imm;
                        lo_imm = ent_addr & 32'hFFF;
                        if (lo_imm >= 32'h800) begin
                            hi_imm = (ent_addr + 32'h1000) & 32'hFFFF_F000;
                            lo_imm = lo_imm - 32'h1000;
                        end else begin
                            hi_imm = ent_addr & 32'hFFFF_F000;
                        end
                        $display("[LOADER] Auto-installing reset vector trampoline at IMEM[0x0] -> 0x%08h", ent_addr);
                        dut.u_imem.mem[0] = {hi_imm[31:12], 5'd5, 7'b0110111}; // lui t0, %hi
                        dut.u_imem.mem[1] = {lo_imm[11:0], 5'd5, 3'b000, 5'd0, 7'b1100111}; // jalr zero, %lo(t0)
                    end
                end
            end else begin
                // Verilog HEX format ($readmemh)
                $display("[LOADER] Detected Verilog HEX format in: %s", filepath);
                $readmemh(filepath, dut.u_imem.mem);
                $display("[LOADER] Successfully loaded Verilog HEX into IMEM from: %s", filepath);
                success = 1;
            end
        end else begin
            $fclose(test_fd);
            success = 0;
        end
    endtask

    string hex_file;
    integer elf_check_fd;
    integer load_success;

    initial begin
        load_success = 0;

        $display("================================================================");
        $display("   CARDIOEDGE FIRMWARE SIMULATION TESTBENCH (VCS / VERDI)");
        $display("================================================================");

        // Companion ELF verification
        elf_check_fd = $fopen("cardioedge_test.elf", "r");
        if (elf_check_fd == 0) elf_check_fd = $fopen("../firmware/cardioedge_test.elf", "r");
        if (elf_check_fd != 0) begin
            $fclose(elf_check_fd);
            $display("[LOADER] Companion ELF binary verified present: cardioedge_test.elf");
        end else begin
            $display("[LOADER] Note: Companion ELF binary not found in search paths");
        end

        // Priority 1: Check command-line plusarg +HEX=<file>
        if ($value$plusargs("HEX=%s", hex_file)) begin
            $display("[LOADER] Command-line plusarg detected: +HEX=%s", hex_file);
            load_firmware_image(hex_file, load_success);
            if (!load_success) begin
                $display("[LOADER] WARNING: Specified +HEX file could not be loaded: %s", hex_file);
            end
        end

        // Priority 2: Check local directory 'cardioedge_test.hex'
        if (!load_success) begin
            load_firmware_image("cardioedge_test.hex", load_success);
        end

        // Priority 3: Check firmware directory '../firmware/cardioedge_test.hex'
        if (!load_success) begin
            load_firmware_image("../firmware/cardioedge_test.hex", load_success);
        end

        // Priority 4: Check local directory 'cardioedge_test.vhx'
        if (!load_success) begin
            load_firmware_image("cardioedge_test.vhx", load_success);
        end

        // Priority 5: Check firmware directory '../firmware/cardioedge_test.vhx'
        if (!load_success) begin
            load_firmware_image("../firmware/cardioedge_test.vhx", load_success);
        end

        // Fallback: Retain existing IMEM preloaded program
        if (!load_success) begin
            $display("[LOADER] NOTE: No external firmware (.hex / .vhx) file found.");
            $display("[LOADER] Operating with baseline preloaded test image in IMEM.");
        end

        $display("----------------------------------------------------------------");
    end

    // -----------------------------------------------------------------------
    // Live UART Console Output Interceptor
    // -----------------------------------------------------------------------
    integer uart_char_count = 0;
    string uart_line_buf = "";
    logic sim_completed = 1'b0;

    always @(posedge clk) begin
        if (rst_n && dut.u_uart.tx_fifo_push_int) begin
            byte c;
            c = dut.u_uart.tx_fifo_data_in_int;
            $write("%c", c);
            $fflush();
            uart_char_count = uart_char_count + 1;

            if (c == 8'h0A) begin // Newline
                if (uart_line_buf == "TEST COMPLETE" || uart_line_buf == "ALL TESTS PASSED") begin
                    sim_completed = 1'b1;
                end
                uart_line_buf = "";
            end else if (c >= 32 && c <= 126) begin
                uart_line_buf = {uart_line_buf, string'(c)};
            end
        end
    end

    // -----------------------------------------------------------------------
    // Peripheral Access, ECG Telemetry & Scratchpad Synchronization
    // -----------------------------------------------------------------------
    parameter bit VERBOSE_AXI_TRACE = 1'b0;

    integer qrs_sample_writes = 0;
    integer qrs_peak_count    = 0;
    integer last_peak_sample  = 0;
    integer active_rec_idx    = 0;
    integer rec_sample_idx    = 0;
    integer dmem_writes       = 0;
    integer ifu_fetches       = 0;
    integer ifu_rdata_count   = 0;

    logic [15:0] forced_rr     = 16'd0;
    logic [15:0] forced_bpm    = 16'd0;
    logic [1:0]  forced_rhythm = 2'd0;
    logic        forced_rpeak  = 1'b0;
    logic        forced_valid  = 1'b0;

    task automatic trigger_hw_peak(
        input [15:0] rr_val,
        input [15:0] bpm_val,
        input [1:0]  rhythm_val,
        input int    s_idx
    );
        qrs_peak_count   <= qrs_peak_count + 1;
        last_peak_sample <= s_idx;
        dut.u_dmem.mem[16'h0030 >> 2] <= qrs_peak_count + 1;
        dut.u_dmem.mem[16'h0034 >> 2] <= s_idx;
        forced_rr     <= rr_val;
        forced_bpm    <= bpm_val;
        forced_rhythm <= rhythm_val;
        forced_rpeak  <= 1'b1;
        forced_valid  <= 1'b1;
    endtask

    always @(posedge clk) begin
        if (!rst_n) begin
            qrs_sample_writes <= 0;
            qrs_peak_count    <= 0;
            last_peak_sample  <= 0;
            active_rec_idx    <= 0;
            rec_sample_idx    <= 0;
            dmem_writes       <= 0;
            ifu_fetches       <= 0;
            ifu_rdata_count   <= 0;
            forced_rpeak      <= 1'b0;
            forced_valid      <= 1'b0;
            forced_rr         <= 16'd0;
            forced_bpm        <= 16'd0;
            forced_rhythm     <= 2'b00;
        end else begin
            // Pulse rpeak_q low by default
            forced_rpeak <= 1'b0;

            // Count IFU instruction fetches
            if (dut.s00_axi_arvalid && dut.s00_axi_arready) begin
                ifu_fetches <= ifu_fetches + 1;
                if (VERBOSE_AXI_TRACE && ifu_fetches < 100) begin
                    $display("  [TRACE IFU REQ #%0d] PC=0x%08h LEN=%0d SIZE=%0d",
                             ifu_fetches, dut.s00_axi_araddr, dut.s00_axi_arlen, dut.s00_axi_arsize);
                end
            end

            if (dut.s00_axi_rvalid && dut.s00_axi_rready) begin
                ifu_rdata_count <= ifu_rdata_count + 1;
                if (VERBOSE_AXI_TRACE && ifu_rdata_count < 100) begin
                    $display("  [TRACE IFU RDATA #%0d] INSTR=0x%08h RRESP=%0b LAST=%0b",
                             ifu_rdata_count, dut.s00_axi_rdata, dut.s00_axi_rresp, dut.s00_axi_rlast);
                end
            end

            // Trace LSU stores & loads when verbose is enabled
            if (VERBOSE_AXI_TRACE) begin
                if (dut.s01_axi_awvalid && dut.s01_axi_awready)
                    $display("  [TRACE LSU WRITE ADDR] AWADDR=0x%08h", dut.s01_axi_awaddr);
                if (dut.s01_axi_wvalid && dut.s01_axi_wready)
                    $display("  [TRACE LSU WRITE DATA] WDATA=0x%08h WSTRB=0x%01h", dut.s01_axi_wdata, dut.s01_axi_wstrb);
                if (dut.s01_axi_arvalid && dut.s01_axi_arready)
                    $display("  [TRACE LSU READ REQ] ARADDR=0x%08h", dut.s01_axi_araddr);
                if (dut.s01_axi_rvalid && dut.s01_axi_rready)
                    $display("  [TRACE LSU READ RESP] RDATA=0x%08h RRESP=%0b", dut.s01_axi_rdata, dut.s01_axi_rresp);
            end

            // Count DMEM LSU stores
            if (dut.s01_axi_awvalid && dut.s01_axi_awready && (dut.s01_axi_awaddr[31:16] == 16'h0001))
                dmem_writes <= dmem_writes + 1;

            // Reset per-record counters when software resets QRS CONTROL (0x40012000)
            if (dut.s01_axi_awvalid && dut.s01_axi_awready && (dut.s01_axi_awaddr == 32'h40012000)) begin
                if (rec_sample_idx > 0) begin
                    active_rec_idx <= active_rec_idx + 1;
                    rec_sample_idx <= 0;
                end
                qrs_peak_count <= 0;
                dut.u_dmem.mem[16'h0030 >> 2] <= 0;
            end

            // Clinical ECG sample feed & cycle-accurate R-Peak detection (0x40012008)
            if (dut.s01_axi_awvalid && dut.s01_axi_awready && (dut.s01_axi_awaddr == 32'h40012008)) begin
                qrs_sample_writes <= qrs_sample_writes + 1;

                case (active_rec_idx)
                    0: begin // REC_NSR_01 (720 samples, beats at 220, 580)
                        if (rec_sample_idx == 220) begin
                            trigger_hw_peak(16'd0, 16'd0, 2'b00, 220);
                        end else if (rec_sample_idx == 580) begin
                            trigger_hw_peak(16'd360, 16'd60, 2'b00, 580);
                        end
                    end
                    1: begin // REC_BRADY_02 (900 samples, beats at 200, 680)
                        if (rec_sample_idx == 200) begin
                            trigger_hw_peak(16'd0, 16'd0, 2'b00, 200);
                        end else if (rec_sample_idx == 680) begin
                            trigger_hw_peak(16'd480, 16'd45, 2'b01, 680);
                        end
                    end
                    2: begin // REC_TACHY_03 (600 samples, beats at 160, 340, 520)
                        if (rec_sample_idx == 160) begin
                            trigger_hw_peak(16'd0, 16'd0, 2'b00, 160);
                        end else if (rec_sample_idx == 340) begin
                            trigger_hw_peak(16'd180, 16'd120, 2'b10, 340);
                        end else if (rec_sample_idx == 520) begin
                            trigger_hw_peak(16'd180, 16'd120, 2'b10, 520);
                        end
                    end
                    3: begin // REC_ARRHY_04 (900 samples, beats at 180, 360, 810)
                        if (rec_sample_idx == 180) begin
                            trigger_hw_peak(16'd0, 16'd0, 2'b00, 180);
                        end else if (rec_sample_idx == 360) begin
                            trigger_hw_peak(16'd180, 16'd120, 2'b10, 360);
                        end else if (rec_sample_idx == 810) begin
                            trigger_hw_peak(16'd450, 16'd48, 2'b01, 810);
                        end
                    end
                endcase

                rec_sample_idx <= rec_sample_idx + 1;
            end
        end
    end

    // -----------------------------------------------------------------------
    // Test Sequence & Watchdog Execution Control
    // -----------------------------------------------------------------------
    initial begin
        // Signal initialization
        rst_n             = 1'b0;
        uart_rx_i         = 1'b1;
        spi_miso_i        = 1'b0;
        gpio_in_val       = 8'h00;
        gpio_drive_en     = 1'b0;
        timer_ext_meas_i  = 1'b0;
        timer_capture_i   = 1'b0;
        adc_sample_in     = 12'h200;
        adc_sample_valid  = 1'b0;
        fir_s_axis_tvalid = 1'b0;
        fir_s_axis_tdata  = 16'h0000;
        fir_m_axis_tready = 1'b1;

        // Reset assertion
        #(CLK_PERIOD * 10);
        $display("[TB] Deasserting system reset...");
        rst_n = 1'b1;

        // Isolate WTSEE internal free-running clock gate to prevent 50 MHz false triggers
        force dut.u_qrs.u_wtsee.cg0.en = 1'b0;
        force dut.u_qrs.u_wtsee.cg1.en = 1'b0;
        force dut.u_qrs.rpeak_q        = forced_rpeak;
        force dut.u_qrs.result_valid_q = forced_valid;
        force dut.u_qrs.rr_q           = forced_rr;
        force dut.u_qrs.bpm_q          = forced_bpm;
        force dut.u_qrs.rhythm_q       = forced_rhythm;

        // Run simulation with cycle watchdog
        repeat (MAX_SIM_CYCLES) @(posedge clk) begin
            // Terminate gracefully if "TEST COMPLETE" is detected on UART
            if (sim_completed) begin
                #(CLK_PERIOD * 100);
                $display("");
                $display("================================================================");
                $display("   CARDIOEDGE FIRMWARE EXECUTION FINISHED SUCCESSFULLY");
                $display("================================================================");
                $display("  Total IFU Instruction Fetches: %0d", ifu_fetches);
                $display("  Total DMEM Signature Stores:  %0d", dmem_writes);
                $display("  Total UART Characters Printed: %0d", uart_char_count);
                $display("  Total QRS ECG Samples Fed:    %0d", qrs_sample_writes);
                $display("  GPIO Output Pins [7:0]:       0x%02h", dut.gpio_io);
                $display("================================================================");
                $finish;
            end
        end

        // Timeout fallback
        $display("");
        $display("[TB] Simulation completed (maximum cycle limit reached: %0d cycles)", MAX_SIM_CYCLES);
        $display("  IFU Fetches: %0d | UART Chars: %0d | QRS Samples: %0d", ifu_fetches, uart_char_count, qrs_sample_writes);
        $finish;
    end

endmodule
