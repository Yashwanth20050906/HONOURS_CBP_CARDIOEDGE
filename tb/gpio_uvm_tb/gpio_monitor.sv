class gpio_monitor extends uvm_monitor;

    virtual gpio_if vif;

    uvm_analysis_port #(gpio_item) ap;

    `uvm_component_utils(gpio_monitor)

    function new(string n, uvm_component p); 
        super.new(n, p);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual gpio_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("GPIO_MON",
                       "Failed to retrieve GPIO virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        gpio_item item;
        forever begin
            @(vif.gpio_in or vif.gpio_out or vif.gpio_oe);
            item = gpio_item::type_id::create("item");
            item.gpio_in  = vif.gpio_in;
            item.gpio_out = vif.gpio_out;
            item.gpio_oe  = vif.gpio_oe;
            `uvm_info("GPIO_MON", $sformatf("Observed GPIO pattern = OUT: 0x%08h, OE: 0x%08h, IN: 0x%08h", item.gpio_out, item.gpio_oe, item.gpio_in), UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass
