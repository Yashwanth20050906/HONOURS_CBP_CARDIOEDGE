class uart_monitor extends uvm_monitor;

    virtual uart_if vif;

    uvm_analysis_port #(uart_item) ap;

    `uvm_component_utils(uart_monitor)

    function new(string n, uvm_component p); 
        super.new(n, p); 
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("UART_MON",
                       "Failed to retrieve UART virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        uart_item item;
        forever begin
            @(vif.uart_tx_o or vif.uart_rx_i);
            item = uart_item::type_id::create("item");
            item.uart_tx_o = vif.uart_tx_o;
            item.uart_rx_i = vif.uart_rx_i;
            `uvm_info("UART_MON", $sformatf("Observed UART signal change = TX: %0b, RX: %0b", item.uart_tx_o, item.uart_rx_i), UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass
