// ============================================================================
// File: spi_agent.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Agent for SPI VIP
// ============================================================================

`ifndef SPI_AGENT_SV
`define SPI_AGENT_SV

class spi_agent extends uvm_agent;

    spi_driver    drv;
    spi_monitor   mon;
    spi_sequencer seqr;

    uvm_analysis_port #(spi_item) ap;

    `uvm_component_utils(spi_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = spi_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = spi_driver::type_id::create("drv", this);
            seqr = spi_sequencer::type_id::create("seqr", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass : spi_agent

`endif // SPI_AGENT_SV
