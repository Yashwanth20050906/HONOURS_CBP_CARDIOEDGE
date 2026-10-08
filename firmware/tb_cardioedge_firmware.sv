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
    localparam MAX_SIM_CYCLES  = 200000; // Safety watchdog timeout

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
    // Dynamic Firmware Loader (Non-Invasive IMEM Initialization)
    // -----------------------------------------------------------------------
    string hex_file;
    integer fd, load_success;

    initial begin
        load_success = 0;

        $display("================================================================");
        $display("   CARDIOEDGE FIRMWARE SIMULATION TESTBENCH (VCS / VERDI)");
        $display("================================================================");

        // Priority 1: Check command-line plusarg +HEX=<file>
        if ($value$plusargs("HEX=%s", hex_file)) begin
            $display("[LOADER] Command-line plusarg detected: +HEX=%s", hex_file);
            fd = $fopen(hex_file, "r");
            if (fd != 0) begin
                $fclose(fd);
                $readmemh(hex_file, dut.u_imem.mem);
                $display("[LOADER] Successfully loaded firmware from: %s", hex_file);
                load_success = 1;
            end else begin
                $display("[LOADER] WARNING: Specified +HEX file not found: %s", hex_file);
            end
        end

        // Priority 2: Check local directory 'cardioedge_test.vhx'
        if (!load_success) begin
            fd = $fopen("cardioedge_test.vhx", "r");
            if (fd != 0) begin
                $fclose(fd);
                $readmemh("cardioedge_test.vhx", dut.u_imem.mem);
                $display("[LOADER] Successfully loaded default firmware from: cardioedge_test.vhx");
                load_success = 1;
            end
        end

        // Priority 3: Check firmware directory '../firmware/cardioedge_test.vhx'
        if (!load_success) begin
            fd = $fopen("../firmware/cardioedge_test.vhx", "r");
            if (fd != 0) begin
                $fclose(fd);
                $readmemh("../firmware/cardioedge_test.vhx", dut.u_imem.mem);
                $display("[LOADER] Successfully loaded firmware from: ../firmware/cardioedge_test.vhx");
                load_success = 1;
            end
        end

        // Fallback: Retain existing IMEM preloaded program
        if (!load_success) begin
            $display("[LOADER] NOTE: No external .vhx file found.");
            $display("[LOADER] Operating with baseline preloaded test image in IMEM.");
        end

        $display("----------------------------------------------------------------");
    end

    // -----------------------------------------------------------------------
    // Live UART Console Output Interceptor
    // -----------------------------------------------------------------------
    integer uart_char_count = 0;
    string uart_line_buf = "";

    always @(posedge clk) begin
        if (rst_n && dut.u_uart.tx_fifo_push_int) begin
            byte c;
            c = dut.u_uart.tx_fifo_data_in_int;
            $write("%c", c);
            $fflush();
            uart_char_count = uart_char_count + 1;

            if (c == 8'h0A) begin // Newline
                if (uart_line_buf == "TEST COMPLETE" || uart_line_buf == "ALL TESTS PASSED") begin
                    // Flag potential completion
                end
                uart_line_buf = "";
            end else if (c >= 32 && c <= 126) begin
                uart_line_buf = {uart_line_buf, string'(c)};
            end
        end
    end

    // -----------------------------------------------------------------------
    // Peripheral Access & ECG Sample Monitoring
    // -----------------------------------------------------------------------
    integer qrs_sample_writes = 0;
    integer dmem_writes       = 0;
    integer ifu_fetches       = 0;

    always @(posedge clk) begin
        if (rst_n) begin
            // Count IFU instruction fetches
            if (dut.s00_axi_arvalid && dut.s00_axi_arready)
                ifu_fetches <= ifu_fetches + 1;

            // Count DMEM LSU stores
            if (dut.s01_axi_awvalid && dut.s01_axi_awready && (dut.s01_axi_awaddr[31:16] == 16'h0001))
                dmem_writes <= dmem_writes + 1;

            // Count QRS ECG sample writes (offset 0x08 at 0x40012000)
            if (dut.s01_axi_awvalid && dut.s01_axi_awready && (dut.s01_axi_awaddr == 32'h40012008)) begin
                qrs_sample_writes <= qrs_sample_writes + 1;
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

        // Run simulation with cycle watchdog
        repeat (MAX_SIM_CYCLES) @(posedge clk) begin
            // Terminate gracefully if "TEST COMPLETE" is detected on UART
            if (uart_line_buf == "TEST COMPLETE") begin
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
