// ============================================================================
// File: adc_pkguvm.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Package for ADC VIP
// ============================================================================

package adc_pkguvm;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "adc_item.sv"
    `include "adc_sequencer.sv"
    `include "adc_driver.sv"
    `include "adc_monitor.sv"
    `include "adc_agent.sv"
    `include "adc_scoreboard.sv"
    `include "adc_sequence.sv"

endpackage : adc_pkguvm
