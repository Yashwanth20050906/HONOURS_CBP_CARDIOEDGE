// ============================================================================
// File: spi_pkg.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Package for SPI VIP
// ============================================================================

package spi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "spi_item.sv"
    `include "spi_sequencer.sv"
    `include "spi_driver.sv"
    `include "spi_monitor.sv"
    `include "spi_agent.sv"
    `include "spi_scoreboard.sv"
    `include "spi_sequence.sv"

endpackage : spi_pkg
