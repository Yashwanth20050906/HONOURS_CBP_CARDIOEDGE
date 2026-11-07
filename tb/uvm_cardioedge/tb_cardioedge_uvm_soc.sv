// ============================================================================
// File: tb_cardioedge_uvm_soc.sv
// Directory: tb/uvm_cardioedge/
// Description: Completely New Top-Level UVM Testbench for CardioEdge SoC
//              integrating ADC, GPIO, SPI, and UART UVM VIPs.
// ============================================================================

`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"

import adc_pkguvm::*;
import gpio_pkg::*;
import spi_pkg::*;
import uart_pkg::*;

module tb_cardioedge_uvm_soc;

    // -----------------------------------------------------------------------
    // Simulation Parameters & Timing
    // -----------------------------------------------------------------------
    localparam time CLK_PERIOD = 20ns; // 50 MHz system clock
    localparam GPIO_BITS       = 8;

    // -----------------------------------------------------------------------
    // Clock and Reset Generation
    // -----------------------------------------------------------------------
    logic clk;
    logic rst_n;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // -----------------------------------------------------------------------
    // Synopsys Verdi FSDB Waveform Dumping
    // -----------------------------------------------------------------------
    string fsdb_file = "cardioedge_uvm_18_regression.fsdb";
    initial begin
        if ($value$plusargs("FSDB_FILE=%s", fsdb_file)) begin
            $display("[FSDB CONFIG] Custom FSDB target path: %s", fsdb_file);
        end else begin
            fsdb_file = "cardioedge_uvm_18_regression.fsdb";
        end
        $display("[FSDB CONFIG] Initializing Verdi FSDB dump to '%s'...", fsdb_file);
        $fsdbDumpfile(fsdb_file);
        $fsdbDumpvars(0, tb_cardioedge_uvm_soc, "+all");
        $fsdbDumpMDA;
    end

    // -----------------------------------------------------------------------
    // VIP Interfaces
    // -----------------------------------------------------------------------
    adc_if  adc_vif  (.clk(clk), .rst_n(rst_n));
    gpio_if gpio_vif (.clk(clk), .rst_n(rst_n));
    spi_if  spi_vif  (.clk(clk), .rst_n(rst_n));
    uart_if uart_vif (.clk(clk), .rst_n(rst_n));

    // -----------------------------------------------------------------------
    // GPIO Bidirectional Bus Wiring
    // -----------------------------------------------------------------------
    wire [GPIO_BITS-1:0] gpio_io;

    genvar gi;
    generate
        for (gi = 0; gi < GPIO_BITS; gi++) begin : gen_gpio_bidir
            assign gpio_io[gi] = gpio_vif.gpio_drv_en[gi] ? gpio_vif.gpio_in[gi] : 1'bz;
        end
    endgenerate

    // -----------------------------------------------------------------------
    // DUT Interconnect & Port Signals
    // -----------------------------------------------------------------------
    wire uart_tx_o;
    wire spi_clk_o;
    wire spi_cs_n_o;
    wire spi_mosi_o;
    wire uart_irq;
    wire gpio_irq;
    wire timer_irq;
    wire adc_irq_sample;
    wire adc_irq_overrun;
    wire timer_pwm_o;
    wire timer_trigger_o;
    logic fir_s_axis_tvalid = 1'b0;
    logic [15:0] fir_s_axis_tdata = 16'h0000;
    logic fir_m_axis_tready = 1'b1;
    wire fir_s_axis_tready;
    wire fir_m_axis_tvalid;
    wire [39:0] fir_m_axis_tdata;

    // -----------------------------------------------------------------------
    // Device Under Test (DUT): Full CardioEdge SoC Top Module
    // -----------------------------------------------------------------------
    cardioedge_cpu_soc_top #(
        .GPIO_BITS(GPIO_BITS)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),

        // UART External Pins -> UART VIP Interface
        .uart_rx_i         (uart_vif.uart_rx_i),
        .uart_tx_o         (uart_tx_o),

        // SPI External Pins -> SPI VIP Interface
        .spi_clk_o          (spi_clk_o),
        .spi_cs_n_o         (spi_cs_n_o),
        .spi_mosi_o         (spi_mosi_o),
        .spi_miso_i         (spi_vif.spi_miso_i),

        // GPIO Bidirectional Pins -> GPIO VIP Interface
        .gpio_io            (gpio_io),

        // ADC External Interface -> ADC VIP Interface
        .adc_sample_in      (adc_vif.sample_in),
        .adc_sample_valid   (adc_vif.sample_valid),

        // Timer External Pins (Safely tied off)
        .timer_ext_meas_i   (1'b0),
        .timer_capture_i    (1'b0),
        .timer_pwm_o        (timer_pwm_o),
        .timer_trigger_o    (timer_trigger_o),

        // FIR Streaming Interface
        .fir_s_axis_tvalid  (fir_s_axis_tvalid),
        .fir_s_axis_tready  (fir_s_axis_tready),
        .fir_s_axis_tdata   (fir_s_axis_tdata),
        .fir_m_axis_tvalid  (fir_m_axis_tvalid),
        .fir_m_axis_tready  (fir_m_axis_tready),
        .fir_m_axis_tdata   (fir_m_axis_tdata),

        // Interrupts
        .uart_irq           (uart_irq),
        .gpio_irq           (gpio_irq),
        .timer_irq          (timer_irq),
        .adc_irq_sample     (adc_irq_sample),
        .adc_irq_overrun    (adc_irq_overrun)
    );

    // -----------------------------------------------------------------------
    // Connect Monitored DUT Signals back to VIP Interfaces
    // -----------------------------------------------------------------------
    // UART VIP Monitor Connections
    assign uart_vif.uart_tx_o = uart_tx_o;
    assign uart_vif.uart_irq  = uart_irq;

    // SPI VIP Monitor Connections
    assign spi_vif.spi_clk_o  = spi_clk_o;
    assign spi_vif.spi_cs_n_o = spi_cs_n_o;
    assign spi_vif.spi_mosi_o = spi_mosi_o;

    // ADC VIP Monitor Connections
    assign adc_vif.irq_sample  = adc_irq_sample;
    assign adc_vif.irq_overrun = adc_irq_overrun;

    // GPIO VIP Monitor Connections
    assign gpio_vif.gpio_out = {24'h0, dut.u_gpio.reg_data_o[GPIO_BITS-1:0]};
    assign gpio_vif.gpio_oe  = {24'h0, dut.u_gpio.reg_dir[GPIO_BITS-1:0]};
    assign gpio_vif.gpio_irq = gpio_irq;

    // -----------------------------------------------------------------------
    // Clinical ECG Dataset Loading
    // -----------------------------------------------------------------------
    integer ecg_file, ecg_scan, ecg_val;
    reg signed [15:0] ecg_mem [0:3000];
    integer ecg_count = 0;

    initial begin
        ecg_file = $fopen("../tb/ecg_input.txt", "r");
        if (ecg_file == 0)
            ecg_file = $fopen("ecg_input.txt", "r");
        if (ecg_file != 0) begin
            while (!$feof(ecg_file) && ecg_count < 3000) begin
                ecg_scan = $fscanf(ecg_file, "%d\n", ecg_val);
                if (ecg_scan == 1) begin
                    ecg_mem[ecg_count] = ecg_val[15:0];
                    ecg_count = ecg_count + 1;
                end
            end
            $fclose(ecg_file);
            $display("[UVM TB INIT] Successfully loaded %0d clinical ECG samples from ecg_input.txt", ecg_count);
        end else begin
            $display("[UVM TB INIT] Notice: ecg_input.txt not found. Generating synthetic clinical ECG waveform.");
            for (integer k = 0; k < 1500; k = k + 1) begin
                if ((k % 200) == 70)
                    ecg_mem[k] = 16'sd12000;
                else if ((k % 200) == 65)
                    ecg_mem[k] = -16'sd1500;
                else if ((k % 200) == 75)
                    ecg_mem[k] = -16'sd2000;
                else if ((k % 200) >= 100 && (k % 200) <= 130)
                    ecg_mem[k] = 16'sd800;
                else
                    ecg_mem[k] = 16'sd20;
            end
            ecg_count = 1500;
        end
    end

    // -----------------------------------------------------------------------
    // Real-Time Bus & Signal Monitors
    // -----------------------------------------------------------------------
    integer ifu_fetch_count   = 0;
    integer imem_access_count = 0;
    integer dmem_write_count  = 0;
    integer dmem_read_count   = 0;
    integer uart_access_count = 0;
    integer gpio_access_count = 0;
    integer timer_access_count= 0;
    integer fir_access_count  = 0;
    integer adc_access_count  = 0;
    integer spi_access_count  = 0;
    integer qrs_access_count  = 0;
    integer dummy_access_count= 0;

    logic [31:0] first_ifu_addr      = 32'hFFFF_FFFF;
    logic [31:0] captured_dmem_awaddr= 32'h0;
    logic [31:0] captured_dmem_araddr= 32'h0;
    logic [31:0] last_dmem_wdata     = 32'h0;
    logic [31:0] last_dmem_rdata     = 32'h0;
    logic [1:0]  last_dmem_rresp     = 2'b00;
    logic        concurrent_traffic_detected = 1'b0;

    integer qrs_peak_count         = 0;
    integer fir_output_count       = 0;
    integer fir_in_accepted_count  = 0;
    integer adc_accepted_count     = 0;

    // IFU Bus Handshake Monitor (S00)
    always @(posedge clk) begin
        if (rst_n && dut.s00_axi_arvalid && dut.s00_axi_arready) begin
            if (ifu_fetch_count == 0) first_ifu_addr = dut.s00_axi_araddr;
            ifu_fetch_count = ifu_fetch_count + 1;
            if (ifu_fetch_count <= 6) begin
                $display("  [VeeR IFU FETCH #%0d] ARADDR=0x%08h ARLEN=%0d ARSIZE=%0d",
                         ifu_fetch_count, dut.s00_axi_araddr, dut.s00_axi_arlen, dut.s00_axi_arsize);
            end
        end
    end

    // -----------------------------------------------------------------------
    // AXI Address Map Target Decoder
    // -----------------------------------------------------------------------
    function automatic string get_target_name(input logic [31:0] addr);
        if (addr < 32'h0001_0000) return "IMEM (M07)";
        if (addr >= 32'h0001_0000 && addr < 32'h0002_0000) return "DMEM (M08)";
        if (addr >= 32'h4000_0000 && addr < 32'h4000_1000) return "UART (M00)";
        if (addr >= 32'h4000_2000 && addr < 32'h4000_3000) return "GPIO (M01)";
        if (addr >= 32'h4000_4000 && addr < 32'h4000_5000) return "TIMER (M02)";
        if (addr >= 32'h4000_6000 && addr < 32'h4000_7000) return "DUMMY_M09";
        if (addr >= 32'h4000_8000 && addr < 32'h4000_9000) return "DUMMY_M10";
        if (addr >= 32'h4000_A000 && addr < 32'h4000_B000) return "DUMMY_M11";
        if (addr >= 32'h4000_C000 && addr < 32'h4000_D000) return "FIR (M03)";
        if (addr >= 32'h4000_E000 && addr < 32'h4000_F000) return "ADC (M04)";
        if (addr >= 32'h4001_0000 && addr < 32'h4001_1000) return "SPI (M05)";
        if (addr >= 32'h4001_2000 && addr < 32'h4001_3000) return "QRS (M06)";
        if (addr >= 32'h4001_4000 && addr < 32'h4001_5000) return "DUMMY_M12";
        if (addr >= 32'h4001_E000 && addr < 32'h4001_F000) return "DUMMY_M17";
        return "UNKNOWN";
    endfunction

    // Interconnect M07 (IMEM) Monitor
    always @(posedge clk) begin
        if (rst_n && dut.m07_axi_arvalid && dut.m07_axi_arready) begin
            imem_access_count = imem_access_count + 1;
        end
    end

    // -----------------------------------------------------------------------
    // AXI Bus Handshake & Transaction Data-Flow Logger
    // -----------------------------------------------------------------------
    logic [31:0] lsu_awaddr_q = 32'h0;
    logic [31:0] lsu_wdata_q  = 32'h0;
    logic [31:0] lsu_araddr_q = 32'h0;

    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.s01_axi_awvalid && dut.s01_axi_awready)
                lsu_awaddr_q <= dut.s01_axi_awaddr;
            if (dut.s01_axi_wvalid && dut.s01_axi_wready)
                lsu_wdata_q  <= dut.s01_axi_wdata;

            if (dut.s01_axi_bvalid && dut.s01_axi_bready) begin
                $display("  [%0t ps][VeeR-LSU][AXI-WRITE] Address=0x%08h Target=%-11s Data=0x%08h Response=2'b%02b",
                         $time, lsu_awaddr_q, get_target_name(lsu_awaddr_q), lsu_wdata_q, dut.s01_axi_bresp);
            end

            if (dut.s01_axi_arvalid && dut.s01_axi_arready)
                lsu_araddr_q <= dut.s01_axi_araddr;

            if (dut.s01_axi_rvalid && dut.s01_axi_rready) begin
                $display("  [%0t ps][VeeR-LSU][AXI-READ]  Address=0x%08h Target=%-11s Data=0x%08h Response=2'b%02b",
                         $time, lsu_araddr_q, get_target_name(lsu_araddr_q), dut.s01_axi_rdata, dut.s01_axi_rresp);
            end
        end
    end

    // LSU / Peripheral Monitors
    always @(posedge clk) begin
        if (rst_n) begin
            if (dut.s00_axi_arvalid && (dut.s01_axi_awvalid || dut.s01_axi_arvalid)) begin
                concurrent_traffic_detected <= 1'b1;
            end

            if (dut.m08_axi_awvalid && dut.m08_axi_awready)
                captured_dmem_awaddr <= dut.m08_axi_awaddr;
            if (dut.m08_axi_arvalid && dut.m08_axi_arready)
                captured_dmem_araddr <= dut.m08_axi_araddr;

            if (dut.m08_axi_wvalid && dut.m08_axi_wready) begin
                dmem_write_count = dmem_write_count + 1;
                last_dmem_wdata  = dut.m08_axi_wdata;
            end
            if (dut.m08_axi_rvalid && dut.m08_axi_rready) begin
                dmem_read_count = dmem_read_count + 1;
                last_dmem_rdata = dut.m08_axi_rdata;
                last_dmem_rresp = dut.m08_axi_rresp;
            end

            if ((dut.m00_axi_awvalid && dut.m00_axi_awready) || (dut.m00_axi_arvalid && dut.m00_axi_arready))
                uart_access_count = uart_access_count + 1;
            if ((dut.m01_axi_awvalid && dut.m01_axi_awready) || (dut.m01_axi_arvalid && dut.m01_axi_arready))
                gpio_access_count = gpio_access_count + 1;
            if ((dut.m02_axi_awvalid && dut.m02_axi_awready) || (dut.m02_axi_arvalid && dut.m02_axi_arready))
                timer_access_count = timer_access_count + 1;
            if ((dut.m03_axi_awvalid && dut.m03_axi_awready) || (dut.m03_axi_arvalid && dut.m03_axi_arready))
                fir_access_count = fir_access_count + 1;
            if ((dut.m04_axi_awvalid && dut.m04_axi_awready) || (dut.m04_axi_arvalid && dut.m04_axi_arready))
                adc_access_count = adc_access_count + 1;
            if ((dut.m05_axi_awvalid && dut.m05_axi_awready) || (dut.m05_axi_arvalid && dut.m05_axi_arready))
                spi_access_count = spi_access_count + 1;
            if ((dut.m06_axi_awvalid && dut.m06_axi_awready) || (dut.m06_axi_arvalid && dut.m06_axi_arready))
                qrs_access_count = qrs_access_count + 1;

            if ((dut.m09_axi_awvalid && dut.m09_axi_awready) || (dut.m09_axi_arvalid && dut.m09_axi_arready) ||
                (dut.m10_axi_awvalid && dut.m10_axi_awready) || (dut.m10_axi_arvalid && dut.m10_axi_arready) ||
                (dut.m11_axi_awvalid && dut.m11_axi_awready) || (dut.m11_axi_arvalid && dut.m11_axi_arready) ||
                (dut.m12_axi_awvalid && dut.m12_axi_awready) || (dut.m12_axi_arvalid && dut.m12_axi_arready) ||
                (dut.m17_axi_awvalid && dut.m17_axi_awready) || (dut.m17_axi_arvalid && dut.m17_axi_arready))
                dummy_access_count = dummy_access_count + 1;

            if (dut.u_qrs.rpeak)
                qrs_peak_count <= qrs_peak_count + 1;

            if (fir_s_axis_tvalid && fir_s_axis_tready)
                fir_in_accepted_count <= fir_in_accepted_count + 1;
            if (fir_m_axis_tvalid && fir_m_axis_tready)
                fir_output_count <= fir_output_count + 1;

            if (adc_vif.sample_valid)
                adc_accepted_count <= adc_accepted_count + 1;
        end
    end

    // -----------------------------------------------------------------------
    // Golden 32-tap FIR Reference Model
    // -----------------------------------------------------------------------
    reg signed [15:0] fir_ref_shift_reg [0:31];
    reg signed [15:0] fir_ref_coeff [0:31];

    function automatic logic signed [39:0] fir_calc_ref(input logic signed [15:0] sample);
        logic signed [39:0] acc;
        integer t;
        for (t = 31; t > 0; t = t - 1)
            fir_ref_shift_reg[t] = fir_ref_shift_reg[t-1];
        fir_ref_shift_reg[0] = sample;

        acc = 40'sd0;
        for (t = 0; t < 32; t = t + 1)
            acc = acc + (fir_ref_shift_reg[t] * fir_ref_coeff[t]);
        return acc;
    endfunction

    // -----------------------------------------------------------------------
    // Comprehensive Machine Code Preload Task
    // -----------------------------------------------------------------------
    // Preloads dut.u_imem.mem with a complete verification routine
    // exercising every MMIO peripheral, registers, ISA instructions, and all 4 VIPs.
    // -----------------------------------------------------------------------
    task automatic preload_comprehensive_program();
        integer w;
        integer idx;
        for (w = 0; w < 16384; w = w + 1)
            dut.u_imem.mem[w] = 32'h0000006F; // Default: jal zero, 0 (infinite loop)

        idx = 0;

        // 1. Basic DMEM write & read
        dut.u_imem.mem[idx] = 32'h00010537; idx++; // lui a0, 0x10000 (DMEM base = 0x0001_0000)
        dut.u_imem.mem[idx] = 32'h05A00293; idx++; // addi t0, zero, 0x5A
        dut.u_imem.mem[idx] = 32'h00552023; idx++; // sw t0, 0(a0) (store 0x5A to DMEM[0])
        dut.u_imem.mem[idx] = 32'h00052303; idx++; // lw t1, 0(a0) (load from DMEM[0])

        // 2. CPU Instruction Execution: ALU, Branches, Loop
        dut.u_imem.mem[idx] = 32'h00A00093; idx++; // addi ra, zero, 10
        dut.u_imem.mem[idx] = 32'h01400113; idx++; // addi sp, zero, 20
        dut.u_imem.mem[idx] = 32'h002081B3; idx++; // add gp, ra, sp (gp = 30)
        dut.u_imem.mem[idx] = 32'h40118233; idx++; // sub tp, gp, ra (tp = 20)
        dut.u_imem.mem[idx] = 32'h00209293; idx++; // slli t0, ra, 2 (t0 = 40)
        dut.u_imem.mem[idx] = 32'h00220463; idx++; // beq tp, sp, +8
        dut.u_imem.mem[idx] = 32'h00000193; idx++; // addi gp, zero, 0
        dut.u_imem.mem[idx] = 32'h00352223; idx++; // sw gp, 4(a0)
        dut.u_imem.mem[idx] = 32'h00552423; idx++; // sw t0, 8(a0)
        dut.u_imem.mem[idx] = 32'h00500313; idx++; // addi t1, zero, 5
        dut.u_imem.mem[idx] = 32'hFFF30313; idx++; // addi t1, t1, -1
        dut.u_imem.mem[idx] = 32'hFE031EE3; idx++; // bne t1, zero, -4
        dut.u_imem.mem[idx] = 32'h00652623; idx++; // sw t1, 12(a0)

        // 3. UART Peripheral Access & Real Character Transmission ('C', 'A', 0x55)
        dut.u_imem.mem[idx] = 32'h400005B7; idx++; // lui a1, 0x40000 (UART base)
        dut.u_imem.mem[idx] = 32'h08300393; idx++; // addi t2, zero, 0x83 (DLAB=1, 8N1)
        dut.u_imem.mem[idx] = 32'h0075A623; idx++; // sw t2, 12(a1) (write UART LCR with DLAB=1)
        dut.u_imem.mem[idx] = 32'h00400393; idx++; // addi t2, zero, 4 (BAUD_DIV = 4 -> 1280 ns)
        dut.u_imem.mem[idx] = 32'h0075A423; idx++; // sw t2, 8(a1) (write BAUD_DIV)
        dut.u_imem.mem[idx] = 32'h00300393; idx++; // addi t2, zero, 3 (DLAB=0, 8N1)
        dut.u_imem.mem[idx] = 32'h0075A623; idx++; // sw t2, 12(a1) (write UART LCR with DLAB=0)
        dut.u_imem.mem[idx] = 32'h00C5AE03; idx++; // lw t3, 12(a1) (read UART LCR)
        dut.u_imem.mem[idx] = 32'h01C52823; idx++; // sw t3, 16(a0) (save UART LCR to DMEM[4])
        dut.u_imem.mem[idx] = 32'h04300393; idx++; // addi t2, zero, 0x43 ('C')
        dut.u_imem.mem[idx] = 32'h0075A023; idx++; // sw t2, 0(a1) (transmit 'C' via UART_THR)
        dut.u_imem.mem[idx] = 32'h04100393; idx++; // addi t2, zero, 0x41 ('A')
        dut.u_imem.mem[idx] = 32'h0075A023; idx++; // sw t2, 0(a1) (transmit 'A' via UART_THR)
        dut.u_imem.mem[idx] = 32'h05500393; idx++; // addi t2, zero, 0x55 ('U' / 8'h55)
        dut.u_imem.mem[idx] = 32'h0075A023; idx++; // sw t2, 0(a1) (transmit 0x55 via UART_THR)
        dut.u_imem.mem[idx] = 32'h0145AE03; idx++; // lw t3, 20(a1) (read UART LSR)
        dut.u_imem.mem[idx] = 32'h01C52A23; idx++; // sw t3, 20(a0) (save UART LSR to DMEM[5])

        // 4. GPIO Peripheral Access (Direction 0xFF, Output 0x00, 0xFF, 0xA5, SET_O -> 0xA7, CLR_O -> 0xA6)
        dut.u_imem.mem[idx] = 32'h40002637; idx++; // lui a2, 0x40002 (GPIO base)
        dut.u_imem.mem[idx] = 32'h0FF00E93; idx++; // addi t4, zero, 0xFF
        dut.u_imem.mem[idx] = 32'h01D62423; idx++; // sw t4, 8(a2) (GPIO DIR = 0xFF)
        dut.u_imem.mem[idx] = 32'h00000E93; idx++; // addi t4, zero, 0x00
        dut.u_imem.mem[idx] = 32'h01D62223; idx++; // sw t4, 4(a2) (GPIO DATA_O = 0x00)
        dut.u_imem.mem[idx] = 32'h0FF00E93; idx++; // addi t4, zero, 0xFF
        dut.u_imem.mem[idx] = 32'h01D62223; idx++; // sw t4, 4(a2) (GPIO DATA_O = 0xFF)
        dut.u_imem.mem[idx] = 32'h0A500E93; idx++; // addi t4, zero, 0xA5
        dut.u_imem.mem[idx] = 32'h01D62223; idx++; // sw t4, 4(a2) (GPIO DATA_O = 0xA5)
        dut.u_imem.mem[idx] = 32'h00462F03; idx++; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[idx] = 32'h01E52C23; idx++; // sw t5, 24(a0) (save GPIO DATA_O to DMEM[6])
        dut.u_imem.mem[idx] = 32'h00200E93; idx++; // addi t4, zero, 0x02
        dut.u_imem.mem[idx] = 32'h03D62023; idx++; // sw t4, 32(a2) (GPIO SET_O = 0x02 -> DATA_O = 0xA7)
        dut.u_imem.mem[idx] = 32'h00462F03; idx++; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[idx] = 32'h01E52E23; idx++; // sw t5, 28(a0) (save GPIO DATA_O to DMEM[7])
        dut.u_imem.mem[idx] = 32'h00100E93; idx++; // addi t4, zero, 0x01
        dut.u_imem.mem[idx] = 32'h03D62423; idx++; // sw t4, 36(a2) (GPIO CLR_O = 0x01 -> DATA_O = 0xA6)
        dut.u_imem.mem[idx] = 32'h00462F03; idx++; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[idx] = 32'h03E52023; idx++; // sw t5, 32(a0) (save GPIO DATA_O to DMEM[8])

        // 5. TIMER Peripheral Access
        dut.u_imem.mem[idx] = 32'h400046B7; idx++; // lui a3, 0x40004 (TIMER base)
        dut.u_imem.mem[idx] = 32'h01400F93; idx++; // addi t6, zero, 20
        dut.u_imem.mem[idx] = 32'h01F6A223; idx++; // sw t6, 4(a3) (TIMER LOAD = 20)
        dut.u_imem.mem[idx] = 32'h0046A403; idx++; // lw s0, 4(a3)
        dut.u_imem.mem[idx] = 32'h02852223; idx++; // sw s0, 36(a0)
        dut.u_imem.mem[idx] = 32'h00100493; idx++; // addi s1, zero, 1
        dut.u_imem.mem[idx] = 32'h0096A823; idx++; // sw s1, 16(a3) (TIMER INT_EN = 1)
        dut.u_imem.mem[idx] = 32'h0096A023; idx++; // sw s1, 0(a3) (enable TIMER)
        dut.u_imem.mem[idx] = 32'h0086A403; idx++; // lw s0, 8(a3)
        dut.u_imem.mem[idx] = 32'h02852423; idx++; // sw s0, 40(a0)

        // 6. FIR Filter Engine Access
        dut.u_imem.mem[idx] = 32'h4000C737; idx++; // lui a4, 0x4000C (FIR base)
        dut.u_imem.mem[idx] = 32'h00100493; idx++; // addi s1, zero, 1
        dut.u_imem.mem[idx] = 32'h00972023; idx++; // sw s1, 0(a4) (enable FIR)
        dut.u_imem.mem[idx] = 32'h10000493; idx++; // addi s1, zero, 256 (0x0100)
        dut.u_imem.mem[idx] = 32'h00972823; idx++; // sw s1, 16(a4)
        dut.u_imem.mem[idx] = 32'h08000493; idx++; // addi s1, zero, 128 (0x0080)
        dut.u_imem.mem[idx] = 32'h00972A23; idx++; // sw s1, 20(a4)
        dut.u_imem.mem[idx] = 32'h00100493; idx++; // addi s1, zero, 1
        dut.u_imem.mem[idx] = 32'h00972223; idx++; // sw s1, 4(a4) (strobe FIR LOAD)
        dut.u_imem.mem[idx] = 32'h00072B03; idx++; // lw s6, 0(a4)
        dut.u_imem.mem[idx] = 32'h01072B83; idx++; // lw s7, 16(a4)
        dut.u_imem.mem[idx] = 32'h03652623; idx++; // sw s6, 44(a0)
        dut.u_imem.mem[idx] = 32'h03752823; idx++; // sw s7, 48(a0)

        // 7. ADC Controller Access & Acquisition Verification
        dut.u_imem.mem[idx] = 32'h4000E7B7; idx++; // lui a5, 0x4000E (ADC base)
        dut.u_imem.mem[idx] = 32'h00100493; idx++; // addi s1, zero, 1
        dut.u_imem.mem[idx] = 32'h0097A023; idx++; // sw s1, 0(a5) (enable ADC)
        dut.u_imem.mem[idx] = 32'h00300493; idx++; // addi s1, zero, 3
        dut.u_imem.mem[idx] = 32'h0097A823; idx++; // sw s1, 16(a5) (enable ADC interrupts)
        dut.u_imem.mem[idx] = 32'h0047A903; idx++; // lw s2, 4(a5) (read ADC STATUS)
        dut.u_imem.mem[idx] = 32'h0087A983; idx++; // lw s3, 8(a5) (read ADC SAMPLE_DATA)
        dut.u_imem.mem[idx] = 32'h03252A23; idx++; // sw s2, 52(a0) (save ADC STATUS to DMEM[13])
        dut.u_imem.mem[idx] = 32'h03352C23; idx++; // sw s3, 56(a0) (save ADC SAMPLE_DATA to DMEM[14])

        // 8. SPI Controller Real Register Access & Transmission
        dut.u_imem.mem[idx] = 32'h40010837; idx++; // lui a6, 0x40010 (SPI base)
        dut.u_imem.mem[idx] = 32'h00A00993; idx++; // addi s3, zero, 10 (0x0A)
        dut.u_imem.mem[idx] = 32'h05382023; idx++; // sw s3, 64(a6) (SPI SRR soft reset = 0x0A)
        dut.u_imem.mem[idx] = 32'h18600993; idx++; // addi s3, zero, 0x186
        dut.u_imem.mem[idx] = 32'h07382023; idx++; // sw s3, 96(a6) (SPI CR = 0x186)
        dut.u_imem.mem[idx] = 32'h00000993; idx++; // addi s3, zero, 0
        dut.u_imem.mem[idx] = 32'h07382823; idx++; // sw s3, 112(a6) (SPI SSR = 0x00 -> assert CS_N=0)
        dut.u_imem.mem[idx] = 32'h05A00993; idx++; // addi s3, zero, 0x5A
        dut.u_imem.mem[idx] = 32'h07382423; idx++; // sw s3, 104(a6) (write SPI DTR = 0x5A)
        dut.u_imem.mem[idx] = 32'h06482B83; idx++; // lw s7, 100(a6) (read SPI SR)
        dut.u_imem.mem[idx] = 32'h03752E23; idx++; // sw s7, 60(a0) (save SPI SR to DMEM[15])

        // 9. QRS Peak Detector Real MMIO Operations (NO FORCES!)
        dut.u_imem.mem[idx] = 32'h400128B7; idx++; // lui a7, 0x40012 (QRS base)
        dut.u_imem.mem[idx] = 32'h00100A13; idx++; // addi s4, zero, 1
        dut.u_imem.mem[idx] = 32'h0148A023; idx++; // sw s4, 0(a7) (write QRS CONTROL = 1)
        dut.u_imem.mem[idx] = 32'h0048AC03; idx++; // lw s8, 4(a7) (read QRS STATUS)
        dut.u_imem.mem[idx] = 32'h03852023; idx++; // sw s8, 64(a0) (save QRS STATUS to DMEM[16])
        dut.u_imem.mem[idx] = 32'h01000A13; idx++; // addi s4, zero, 16
        dut.u_imem.mem[idx] = 32'h0148A423; idx++; // sw s4, 8(a7) (write ECG_INPUT = 16)
        dut.u_imem.mem[idx] = 32'h20000A13; idx++; // addi s4, zero, 512
        dut.u_imem.mem[idx] = 32'h0148A423; idx++; // sw s4, 8(a7) (write ECG_INPUT = 512)
        dut.u_imem.mem[idx] = 32'h00C8AC83; idx++; // lw s9, 12(a7) (read RPEAK)
        dut.u_imem.mem[idx] = 32'h0108AD03; idx++; // lw s10, 16(a7) (read RR_INTERVAL)
        dut.u_imem.mem[idx] = 32'h0148AD83; idx++; // lw s11, 20(a7) (read BPM)
        dut.u_imem.mem[idx] = 32'h03952223; idx++; // sw s9, 68(a0) (save RPEAK to DMEM[17])
        dut.u_imem.mem[idx] = 32'h03A52423; idx++; // sw s10, 72(a0) (save RR_INTERVAL to DMEM[18])
        dut.u_imem.mem[idx] = 32'h03B52623; idx++; // sw s11, 76(a0) (save BPM to DMEM[19])
        dut.u_imem.mem[idx] = 32'h0188AD83; idx++; // lw s11, 24(a7) (read RHYTHM_CLASS from 0x4001_2018)
        dut.u_imem.mem[idx] = 32'h05B52A23; idx++; // sw s11, 84(a0) (save RHYTHM_CLASS to DMEM[21])

        // 10. Completion Token
        dut.u_imem.mem[idx] = 32'h55AA3AB7; idx++; // lui s5, 0x55AA3
        dut.u_imem.mem[idx] = 32'h3CCA8A93; idx++; // addi s5, s5, 0x3CC -> s5 = 0x55AA33CC
        dut.u_imem.mem[idx] = 32'h03552823; idx++; // sw s5, 80(a0) (save 0x55AA33CC to DMEM[20])

        // 11. Dummy Slaves DECERR Verification (0x4000_6000)
        dut.u_imem.mem[idx] = 32'h40006AB7; idx++; // lui s5, 0x40006 (M09 Dummy region)
        dut.u_imem.mem[idx] = 32'h000AA023; idx++; // sw zero, 0(s5) (dummy write M09 -> DECERR)
        dut.u_imem.mem[idx] = 32'h0000006F; idx++; // jal zero, 0 (infinite loop end)

        $display("[UVM TB BOOT] Comprehensive verification program preloaded into IMEM (%0d instructions).", idx);
    endtask

    task automatic load_firmware_or_preload();
        string fw_path;
        integer f_test;
        bit fw_loaded = 1'b0;

        if ($value$plusargs("FIRMWARE=%s", fw_path)) begin
            f_test = $fopen(fw_path, "r");
            if (f_test != 0) begin
                $fclose(f_test);
                $display("[UVM TB BOOT] Loading specified firmware '%s' into IMEM via $readmemh...", fw_path);
                $readmemh(fw_path, dut.u_imem.mem);
                fw_loaded = 1'b1;
            end
        end

        if (!fw_loaded && $test$plusargs("LOAD_VHX")) begin
            f_test = $fopen("../firmware/cardioedge_test.vhx", "r");
            if (f_test != 0) begin
                $fclose(f_test);
                fw_path = "../firmware/cardioedge_test.vhx";
                $display("[UVM TB BOOT] +LOAD_VHX enabled: Loading %s via $readmemh...", fw_path);
                $readmemh(fw_path, dut.u_imem.mem);
                fw_loaded = 1'b1;
            end
        end

        if (!fw_loaded) begin
            preload_comprehensive_program();
        end
    endtask

    // -----------------------------------------------------------------------
    // Reset Sequence & CPU Boot Configuration
    // -----------------------------------------------------------------------
    initial begin
        rst_n = 1'b0;

        // Preload CPU IMEM while held in reset
        load_firmware_or_preload();

        // Hold reset for 10 clock cycles then release cleanly
        #(CLK_PERIOD * 10);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[UVM TB] Reset released (rst_n = 1). CPU starting execution.");
    end

    // -----------------------------------------------------------------------
    // Start UVM Test & Virtual Interface Registration
    // -----------------------------------------------------------------------
    initial begin
        // Register Virtual Interfaces into UVM Configuration Database
        // Registered before run_test() to guarantee availability during build_phase()
        // Specific monitor paths
        uvm_config_db#(virtual adc_if)::set(null, "uvm_test_top.env.adc_agent_h.mon", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top.env.gpio_agent_h.mon", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.env.spi_agent_h.mon", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.uart_agent_h.mon", "vif", uart_vif);

        // Specific driver paths
        uvm_config_db#(virtual adc_if)::set(null, "uvm_test_top.env.adc_agent_h.drv", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top.env.gpio_agent_h.drv", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.env.spi_agent_h.drv", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.uart_agent_h.drv", "vif", uart_vif);

        // Also register explicit component hierarchy paths
        uvm_config_db#(virtual adc_if)::set(null, "uvm_test_top.env.adc_agent_h.*", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top.env.gpio_agent_h.*", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.env.spi_agent_h.*", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.uart_agent_h.*", "vif", uart_vif);

        // Alias paths without _h (e.g. uvm_test_top.env.adc_agent.mon)
        uvm_config_db#(virtual adc_if)::set(null, "uvm_test_top.env.adc_agent.mon", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "uvm_test_top.env.gpio_agent.mon", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "uvm_test_top.env.spi_agent.mon", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "uvm_test_top.env.uart_agent.mon", "vif", uart_vif);

        // Global wildcard paths
        uvm_config_db#(virtual adc_if)::set(null, "*", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_vif);

        $timeformat(-9, 2, " ns", 20);
        $display("============================================================");
        $display("   STARTING CARDIOEDGE SOC UVM VERIFICATION TESTBENCH       ");
        $display("============================================================");
        run_test("cardioedge_uvm_test");
    end

    // -----------------------------------------------------------------------
    // Global Watchdog Timer (50 ms @ 50 MHz = 2,500,000 cycles)
    // -----------------------------------------------------------------------
    initial begin
        #(20ns * 2500000);
        $display("");
        $display("[WATCHDOG TIMEOUT] Simulation exceeded 2,500,000 cycles (50 ms).");
        $finish;
    end

endmodule : tb_cardioedge_uvm_soc
