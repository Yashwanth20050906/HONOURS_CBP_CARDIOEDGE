// ============================================================================
// File: spi_sequencer.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Sequencer for SPI VIP
// ============================================================================

`ifndef SPI_SEQUENCER_SV
`define SPI_SEQUENCER_SV

class spi_sequencer extends uvm_sequencer #(spi_item);

    `uvm_component_utils(spi_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : spi_sequencer

`endif // SPI_SEQUENCER_SV
