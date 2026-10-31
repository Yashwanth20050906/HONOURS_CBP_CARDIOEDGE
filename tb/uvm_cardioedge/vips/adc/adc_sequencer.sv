// ============================================================================
// File: adc_sequencer.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Sequencer for ADC VIP
// ============================================================================

`ifndef ADC_SEQUENCER_SV
`define ADC_SEQUENCER_SV

class adc_sequencer extends uvm_sequencer #(adc_item);

    `uvm_component_utils(adc_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : adc_sequencer

`endif // ADC_SEQUENCER_SV
