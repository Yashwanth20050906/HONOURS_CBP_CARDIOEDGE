class adc_monitor extends uvm_monitor;

    virtual adc_if vif;

    uvm_analysis_port #(adc_item) ap;

    `uvm_component_utils(adc_monitor)

    function new(string n, uvm_component p); 
        super.new(n, p); 
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual adc_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("ADC_MON",
                       "Failed to retrieve ADC virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        adc_item item;
        forever begin
            @(posedge vif.sample_valid);
            item = adc_item::type_id::create("item");
            item.sample_in = vif.sample_in;
            item.sample_valid = vif.sample_valid;
            `uvm_info("ADC_MON", $sformatf("Observed ADC sample = 0x%03h", item.sample_in), UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass
