// ============================================================================
// File: uart_if.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: SystemVerilog interface for UART VIP connecting to CardioEdge SoC
// ============================================================================

`timescale 1ns/1ps

interface uart_if (
    input logic clk,
    input logic rst_n
);
    // Serial lines
    logic uart_rx_i; // Driven by VIP Tx into SoC UART RX
    logic uart_tx_o; // Driven by SoC UART TX into VIP Monitor
    logic uart_irq;  // Interrupt from SoC UART

    // Clocking block for driver
    clocking drv_cb @(posedge clk);
        default input #1step output #1step;
        output uart_rx_i;
        input  uart_tx_o;
        input  uart_irq;
        input  rst_n;
    endclocking

    // Clocking block for monitor
    clocking mon_cb @(posedge clk);
        default input #1step output #1step;
        input uart_rx_i;
        input uart_tx_o;
        input uart_irq;
        input rst_n;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input rst_n);
    modport mon_mp (clocking mon_cb, input clk, input rst_n);

endinterface : uart_if
