// ============================================================================
// File: uart_sequencer.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: UVM Sequencer for UART VIP
// ============================================================================

`ifndef UART_SEQUENCER_SV
`define UART_SEQUENCER_SV

class uart_sequencer extends uvm_sequencer #(uart_item);

    `uvm_component_utils(uart_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : uart_sequencer

`endif // UART_SEQUENCER_SV
