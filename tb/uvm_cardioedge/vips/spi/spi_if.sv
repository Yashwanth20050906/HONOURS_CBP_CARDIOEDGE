// ============================================================================
// File: spi_if.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: SystemVerilog interface for SPI VIP connecting to CardioEdge SoC
// ============================================================================

`timescale 1ns/1ps

interface spi_if (
    input logic clk,
    input logic rst_n
);
    // SPI Serial bus signals
    logic spi_clk_o;   // Driven by SoC SPI master
    logic spi_cs_n_o;  // Driven by SoC SPI master (active low)
    logic spi_mosi_o;  // Driven by SoC SPI master
    logic spi_miso_i;  // Driven by VIP (SPI slave) to SoC master

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1step;
        output spi_miso_i;
        input  spi_clk_o;
        input  spi_cs_n_o;
        input  spi_mosi_o;
        input  rst_n;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input spi_clk_o;
        input spi_cs_n_o;
        input spi_mosi_o;
        input spi_miso_i;
        input rst_n;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input rst_n);
    modport mon_mp (clocking mon_cb, input clk, input rst_n);

endinterface : spi_if
