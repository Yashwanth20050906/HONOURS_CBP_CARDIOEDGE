// ============================================================================
// File: gpio_if.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: SystemVerilog interface for GPIO VIP connecting to CardioEdge SoC
// ============================================================================

`timescale 1ns/1ps

interface gpio_if (
    input logic clk,
    input logic rst_n
);
    // VIP driving stimulus into DUT
    logic [31:0] gpio_in;
    logic [7:0]  gpio_drv_en; // Per-bit drive enable onto bidirectional gpio_io

    // Signals observed from DUT
    logic [31:0] gpio_out;
    logic [31:0] gpio_oe;
    logic        gpio_irq;

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1step;
        output gpio_in;
        output gpio_drv_en;
        input  gpio_out;
        input  gpio_oe;
        input  gpio_irq;
        input  rst_n;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input gpio_in;
        input gpio_drv_en;
        input gpio_out;
        input gpio_oe;
        input gpio_irq;
        input rst_n;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input rst_n);
    modport mon_mp (clocking mon_cb, input clk, input rst_n);

endinterface : gpio_if
