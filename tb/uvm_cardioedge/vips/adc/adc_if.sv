// ============================================================================
// File: adc_if.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: SystemVerilog interface for ADC VIP connecting to CardioEdge SoC
// ============================================================================

`timescale 1ns/1ps

interface adc_if (
    input logic clk,
    input logic rst_n
);
    // Primary ADC sample acquisition ports (driven by VIP to DUT)
    logic [11:0] sample_in;
    logic        sample_valid;

    // Interrupt signals monitored from DUT
    logic        irq_sample;
    logic        irq_overrun;

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1step;
        output sample_in;
        output sample_valid;
        input  rst_n;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input sample_in;
        input sample_valid;
        input irq_sample;
        input irq_overrun;
        input rst_n;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input rst_n);
    modport mon_mp (clocking mon_cb, input clk, input rst_n);

endinterface : adc_if
