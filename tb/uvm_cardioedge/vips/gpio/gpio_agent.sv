// ============================================================================
// File: gpio_agent.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: UVM Agent for GPIO VIP
// ============================================================================

`ifndef GPIO_AGENT_SV
`define GPIO_AGENT_SV

class gpio_agent extends uvm_agent;

    gpio_driver    drv;
    gpio_monitor   mon;
    gpio_sequencer seqr;

    uvm_analysis_port #(gpio_item) ap;

    `uvm_component_utils(gpio_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = gpio_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = gpio_driver::type_id::create("drv", this);
            seqr = gpio_sequencer::type_id::create("seqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass : gpio_agent

`endif // GPIO_AGENT_SV
