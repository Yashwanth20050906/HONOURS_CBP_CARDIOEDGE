// ============================================================================
// File: gpio_pkg.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: UVM Package for GPIO VIP
// ============================================================================

package gpio_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "gpio_item.sv"
    `include "gpio_sequencer.sv"
    `include "gpio_driver.sv"
    `include "gpio_monitor.sv"
    `include "gpio_agent.sv"
    `include "gpio_scoreboard.sv"
    `include "gpio_sequence.sv"

endpackage : gpio_pkg
