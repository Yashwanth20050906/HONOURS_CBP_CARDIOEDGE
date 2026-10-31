// ============================================================================
// File: adc_monitor.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Monitor for ADC VIP monitoring samples sent to CardioEdge SoC
// ============================================================================

`ifndef ADC_MONITOR_SV
`define ADC_MONITOR_SV

class adc_monitor extends uvm_monitor;

    virtual adc_if vif;
    uvm_analysis_port #(adc_item) ap;
    int unsigned num_monitored = 0;

    `uvm_component_utils(adc_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adc_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("ADC_MON_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        adc_item item;

        // Wait for system reset release
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.sample_valid === 1'b1) begin
                item = adc_item::type_id::create("adc_mon_item");
                item.sample_in    = vif.sample_in;
                item.sample_valid = vif.sample_valid;
                item.timestamp    = $time;
                num_monitored++;
                item.sample_id    = num_monitored;

                `uvm_info("ADC_MON", $sformatf("Monitored ADC Sample #%0d: data=0x%03h (%0d) at %0t",
                          num_monitored, item.sample_in, item.sample_in, item.timestamp), UVM_MEDIUM)

                ap.write(item);
            end
        end
    endtask

endclass : adc_monitor

`endif // ADC_MONITOR_SV
