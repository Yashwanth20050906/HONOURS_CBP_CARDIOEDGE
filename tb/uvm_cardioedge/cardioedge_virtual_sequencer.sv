// ============================================================================
// File: cardioedge_virtual_sequencer.sv
// Directory: tb/uvm_cardioedge/
// Description: Virtual Sequencer coordinating ADC, GPIO, SPI, and UART VIPs
// ============================================================================

`ifndef CARDIOEDGE_VIRTUAL_SEQUENCER_SV
`define CARDIOEDGE_VIRTUAL_SEQUENCER_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class cardioedge_virtual_sequencer extends uvm_sequencer;

    // Sub-sequencer handles
    adc_pkguvm::adc_sequencer   adc_seqr;
    gpio_pkg::gpio_sequencer    gpio_seqr;
    spi_pkg::spi_sequencer      spi_seqr;
    uart_pkg::uart_sequencer    uart_seqr;

    `uvm_component_utils(cardioedge_virtual_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : cardioedge_virtual_sequencer

`endif // CARDIOEDGE_VIRTUAL_SEQUENCER_SV
