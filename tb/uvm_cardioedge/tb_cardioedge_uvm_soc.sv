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

        // FIR Streaming Interface (Safely tied off)
        .fir_s_axis_tvalid  (1'b0),
        .fir_s_axis_tready  (fir_s_axis_tready),
        .fir_s_axis_tdata   (16'h0000),
        .fir_m_axis_tvalid  (fir_m_axis_tvalid),
        .fir_m_axis_tready  (1'b1),
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

    // GPIO VIP Monitor Connections
    assign gpio_vif.gpio_out[GPIO_BITS-1:0] = dut.u_gpio.reg_data_o[GPIO_BITS-1:0];
    assign gpio_vif.gpio_out[31:GPIO_BITS]  = '0;
    assign gpio_vif.gpio_oe[GPIO_BITS-1:0]  = dut.u_gpio.reg_dir[GPIO_BITS-1:0];
    assign gpio_vif.gpio_oe[31:GPIO_BITS]   = '0;
    assign gpio_vif.gpio_irq                = gpio_irq;

    // ADC VIP Monitor Connections
    assign adc_vif.irq_sample  = adc_irq_sample;
    assign adc_vif.irq_overrun = adc_irq_overrun;

    // -----------------------------------------------------------------------
    // Comprehensive Firmware Preloader for VeeR CPU Boot
    // -----------------------------------------------------------------------
    task automatic preload_comprehensive_program();
        integer w;
        for (w = 0; w < 16384; w = w + 1)
            dut.u_imem.mem[w] = 32'h0000006F; // jal zero, 0 (infinite loop)

        // 1. Basic DMEM write & read
        dut.u_imem.mem[ 0] = 32'h00010537; // lui a0, 0x10000 (DMEM base = 0x0001_0000)
        dut.u_imem.mem[ 1] = 32'h05A00293; // addi t0, zero, 0x5A
        dut.u_imem.mem[ 2] = 32'h00552023; // sw t0, 0(a0) (store 0x5A to DMEM[0])
        dut.u_imem.mem[ 3] = 32'h00052303; // lw t1, 0(a0) (load from DMEM[0])

        // 2. CPU Instruction Execution
        dut.u_imem.mem[ 4] = 32'h00A00093; // addi ra, zero, 10
        dut.u_imem.mem[ 5] = 32'h01400113; // addi sp, zero, 20
        dut.u_imem.mem[ 6] = 32'h002081B3; // add gp, ra, sp (gp = 30)
        dut.u_imem.mem[ 7] = 32'h40118233; // sub tp, gp, ra (tp = 20)
        dut.u_imem.mem[ 8] = 32'h00209293; // slli t0, ra, 2 (t0 = 40)
        dut.u_imem.mem[ 9] = 32'h00220463; // beq tp, sp, +8
        dut.u_imem.mem[10] = 32'h00000193; // addi gp, zero, 0
        dut.u_imem.mem[11] = 32'h00352223; // sw gp, 4(a0)
        dut.u_imem.mem[12] = 32'h00552423; // sw t0, 8(a0)
        dut.u_imem.mem[13] = 32'h00500313; // addi t1, zero, 5
        dut.u_imem.mem[14] = 32'hFFF30313; // addi t1, t1, -1
        dut.u_imem.mem[15] = 32'hFE031EE3; // bne t1, zero, -4
        dut.u_imem.mem[16] = 32'h00652623; // sw t1, 12(a0)

        // 3. UART Peripheral Access & Real Character Transmission ('C', 'A')
        dut.u_imem.mem[17] = 32'h400005B7; // lui a1, 0x40000 (UART base)
        dut.u_imem.mem[18] = 32'h08300393; // addi t2, zero, 0x83 (DLAB=1, 8N1)
        dut.u_imem.mem[19] = 32'h0075A623; // sw t2, 12(a1) (write UART LCR with DLAB=1)
        dut.u_imem.mem[20] = 32'h04000393; // addi t2, zero, 64 (BAUD_DIV = 64 -> 1280 ns)
        dut.u_imem.mem[21] = 32'h0075A423; // sw t2, 8(a1) (write BAUD_DIV)
        dut.u_imem.mem[22] = 32'h00300393; // addi t2, zero, 3 (DLAB=0, 8N1)
        dut.u_imem.mem[23] = 32'h0075A623; // sw t2, 12(a1) (write UART LCR with DLAB=0)
        dut.u_imem.mem[24] = 32'h00C5AE03; // lw t3, 12(a1) (read UART LCR)
        dut.u_imem.mem[25] = 32'h01C52823; // sw t3, 16(a0) (save UART LCR to DMEM[4])
        dut.u_imem.mem[26] = 32'h04300393; // addi t2, zero, 0x43 ('C')
        dut.u_imem.mem[27] = 32'h0075A023; // sw t2, 0(a1) (transmit 'C' via UART_THR)
        dut.u_imem.mem[28] = 32'h04100393; // addi t2, zero, 0x41 ('A')
        dut.u_imem.mem[29] = 32'h0075A023; // sw t2, 0(a1) (transmit 'A' via UART_THR)
        dut.u_imem.mem[30] = 32'h0145AE03; // lw t3, 20(a1) (read UART LSR)
        dut.u_imem.mem[31] = 32'h01C52A23; // sw t3, 20(a0) (save UART LSR to DMEM[5])

        // 4. GPIO Peripheral Access (Direction 0xFF, Output 0xA5, SET_O -> 0xA7, CLR_O -> 0xA6)
        dut.u_imem.mem[32] = 32'h40002637; // lui a2, 0x40002 (GPIO base)
        dut.u_imem.mem[33] = 32'h0FF00E93; // addi t4, zero, 0xFF
        dut.u_imem.mem[34] = 32'h01D62423; // sw t4, 8(a2) (GPIO DIR = 0xFF)
        dut.u_imem.mem[35] = 32'h0A500E93; // addi t4, zero, 0xA5
        dut.u_imem.mem[36] = 32'h01D62223; // sw t4, 4(a2) (GPIO DATA_O = 0xA5)
        dut.u_imem.mem[37] = 32'h00462F03; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[38] = 32'h01E52C23; // sw t5, 24(a0) (save GPIO DATA_O to DMEM[6])
        dut.u_imem.mem[39] = 32'h00200E93; // addi t4, zero, 0x02
        dut.u_imem.mem[40] = 32'h03D62023; // sw t4, 32(a2) (GPIO SET_O = 0x02 -> DATA_O = 0xA7)
        dut.u_imem.mem[41] = 32'h00462F03; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[42] = 32'h01E52E23; // sw t5, 28(a0) (save GPIO DATA_O to DMEM[7])
        dut.u_imem.mem[43] = 32'h00100E93; // addi t4, zero, 0x01
        dut.u_imem.mem[44] = 32'h03D62423; // sw t4, 36(a2) (GPIO CLR_O = 0x01 -> DATA_O = 0xA6)
        dut.u_imem.mem[45] = 32'h00462F03; // lw t5, 4(a2) (read GPIO DATA_O)
        dut.u_imem.mem[46] = 32'h03E52023; // sw t5, 32(a0) (save GPIO DATA_O to DMEM[8])

        // 5. TIMER Peripheral Access
        dut.u_imem.mem[47] = 32'h400046B7; // lui a3, 0x40004 (TIMER base)
        dut.u_imem.mem[48] = 32'h01400F93; // addi t6, zero, 20
        dut.u_imem.mem[49] = 32'h01F6A223; // sw t6, 4(a3) (TIMER LOAD = 20)
        dut.u_imem.mem[50] = 32'h0046A403; // lw s0, 4(a3)
        dut.u_imem.mem[51] = 32'h02852223; // sw s0, 36(a0)
        dut.u_imem.mem[52] = 32'h00100493; // addi s1, zero, 1
        dut.u_imem.mem[53] = 32'h0096A823; // sw s1, 16(a3) (TIMER INT_EN = 1)
        dut.u_imem.mem[54] = 32'h0096A023; // sw s1, 0(a3) (enable TIMER)
        dut.u_imem.mem[55] = 32'h0086A403; // lw s0, 8(a3)
        dut.u_imem.mem[56] = 32'h02852423; // sw s0, 40(a0)

        // 6. FIR Filter Engine Access
        dut.u_imem.mem[57] = 32'h4000C737; // lui a4, 0x4000C (FIR base)
        dut.u_imem.mem[58] = 32'h00100493; // addi s1, zero, 1
        dut.u_imem.mem[59] = 32'h00972023; // sw s1, 0(a4) (enable FIR)
        dut.u_imem.mem[60] = 32'h10000493; // addi s1, zero, 256 (0x0100)
        dut.u_imem.mem[61] = 32'h00972823; // sw s1, 16(a4)
        dut.u_imem.mem[62] = 32'h08000493; // addi s1, zero, 128 (0x0080)
        dut.u_imem.mem[63] = 32'h00972A23; // sw s1, 20(a4)
        dut.u_imem.mem[64] = 32'h00100493; // addi s1, zero, 1
        dut.u_imem.mem[65] = 32'h00972223; // sw s1, 4(a4) (strobe FIR LOAD)
        dut.u_imem.mem[66] = 32'h00072B03; // lw s6, 0(a4)
        dut.u_imem.mem[67] = 32'h01072B83; // lw s7, 16(a4)
        dut.u_imem.mem[68] = 32'h03652623; // sw s6, 44(a0)
        dut.u_imem.mem[69] = 32'h03752823; // sw s7, 48(a0)

        // 7. ADC Controller Access & Acquisition Verification
        dut.u_imem.mem[70] = 32'h4000E7B7; // lui a5, 0x4000E (ADC base)
        dut.u_imem.mem[71] = 32'h00100493; // addi s1, zero, 1
        dut.u_imem.mem[72] = 32'h0097A023; // sw s1, 0(a5) (enable ADC)
        dut.u_imem.mem[73] = 32'h00300493; // addi s1, zero, 3
        dut.u_imem.mem[74] = 32'h0097A823; // sw s1, 16(a5) (enable ADC interrupts)
        dut.u_imem.mem[75] = 32'h0047A903; // lw s2, 4(a5) (read ADC STATUS)
        dut.u_imem.mem[76] = 32'h0087A983; // lw s3, 8(a5) (read ADC SAMPLE_DATA)
        dut.u_imem.mem[77] = 32'h03252A23; // sw s2, 52(a0) (save ADC STATUS to DMEM[13])
        dut.u_imem.mem[78] = 32'h03352C23; // sw s3, 56(a0) (save ADC SAMPLE_DATA to DMEM[14])

        // 8. SPI Controller Real Register Access & Transmission (DTR = 0x5A)
        dut.u_imem.mem[79] = 32'h40010837; // lui a6, 0x40010 (SPI base)
        dut.u_imem.mem[80] = 32'h00A00993; // addi s3, zero, 10
        dut.u_imem.mem[81] = 32'h05382023; // sw s3, 64(a6) (soft reset)
        dut.u_imem.mem[82] = 32'h18600993; // addi s3, zero, 0x186
        dut.u_imem.mem[83] = 32'h07382023; // sw s3, 96(a6) (SPI CR = 0x186)
        dut.u_imem.mem[84] = 32'h00000993; // addi s3, zero, 0
        dut.u_imem.mem[85] = 32'h07382823; // sw s3, 112(a6) (SPI SSR = 0x00 -> assert CS_N=0)
        dut.u_imem.mem[86] = 32'h05A00993; // addi s3, zero, 0x5A
        dut.u_imem.mem[87] = 32'h07382423; // sw s3, 104(a6) (write SPI DTR = 0x5A)
        dut.u_imem.mem[88] = 32'h06482B83; // lw s7, 100(a6) (read SPI SR)
        dut.u_imem.mem[89] = 32'h03752E23; // sw s7, 60(a0) (save SPI SR to DMEM[15])

        // 9. QRS Peak Detector Access
        dut.u_imem.mem[90] = 32'h400128B7; // lui a7, 0x40012 (QRS base)
        dut.u_imem.mem[91] = 32'h00100A13; // addi s4, zero, 1
        dut.u_imem.mem[92] = 32'h0148A023; // sw s4, 0(a7)
        dut.u_imem.mem[93] = 32'h0048AC03; // lw s8, 4(a7)
        dut.u_imem.mem[94] = 32'h03852023; // sw s8, 64(a0)

        // 10. Infinite loop
        dut.u_imem.mem[95] = 32'h0000006F; // jal zero, 0

        $display("[UVM TB BOOT] Comprehensive 94-instruction verification program preloaded into IMEM.");
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
    // Reset Sequence & Virtual Interface Registration
    // -----------------------------------------------------------------------
    initial begin
        rst_n = 1'b0;

        // Register Virtual Interfaces with UVM Configuration Database
        uvm_config_db#(virtual adc_if)::set(null, "*", "vif", adc_vif);
        uvm_config_db#(virtual gpio_if)::set(null, "*", "vif", gpio_vif);
        uvm_config_db#(virtual spi_if)::set(null, "*", "vif", spi_vif);
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_vif);

        // Preload CPU IMEM while held in reset
        load_firmware_or_preload();

        // Hold reset for 10 clock cycles then release cleanly
        #(CLK_PERIOD * 10);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[UVM TB] Reset released (rst_n = 1). CPU starting execution.");
    end

    // -----------------------------------------------------------------------
    // Start UVM Test
    // -----------------------------------------------------------------------
    initial begin
        $timeformat(-9, 2, " ns", 20);
        $display("============================================================");
        $display("   STARTING CARDIOEDGE SOC UVM VERIFICATION TESTBENCH       ");
        $display("============================================================");
        run_test("cardioedge_uvm_test");
    end

endmodule : tb_cardioedge_uvm_soc
