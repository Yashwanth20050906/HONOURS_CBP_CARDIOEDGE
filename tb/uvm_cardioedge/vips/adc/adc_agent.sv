// ============================================================================
// File: adc_agent.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Agent for ADC VIP
// ============================================================================

`ifndef ADC_AGENT_SV
`define ADC_AGENT_SV

class adc_agent extends uvm_agent;

    adc_driver    drv;
    adc_monitor   mon;
    adc_sequencer seqr;

    uvm_analysis_port #(adc_item) ap;

    `uvm_component_utils(adc_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = adc_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = adc_driver::type_id::create("drv", this);
            seqr = adc_sequencer::type_id::create("seqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass : adc_agent

`endif // ADC_AGENT_SV
