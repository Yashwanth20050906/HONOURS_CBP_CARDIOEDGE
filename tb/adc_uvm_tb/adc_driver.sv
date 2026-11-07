class adc_driver extends uvm_driver #(adc_item);

    virtual adc_if vif;

    `uvm_component_utils(adc_driver)

    function new(string n, uvm_component p);
        super.new(n, p);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adc_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("ADC_DRV",
                       "Failed to retrieve ADC virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase); 
        forever begin 
            seq_item_port.get_next_item(req);
            @(posedge vif.sample_valid); 
            seq_item_port.item_done();
        end 
    endtask

endclass
