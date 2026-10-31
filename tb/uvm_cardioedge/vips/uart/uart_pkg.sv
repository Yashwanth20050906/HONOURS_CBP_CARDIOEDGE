// ============================================================================
// File: uart_pkg.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: UVM Package for UART VIP
// ============================================================================

package uart_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_item.sv"
    `include "uart_sequencer.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"
    `include "uart_scoreboard.sv"
    `include "uart_sequence.sv"

endpackage : uart_pkg
