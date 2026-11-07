class spi_driver extends uvm_driver #(spi_item);

    virtual spi_if vif;

    `uvm_component_utils(spi_driver)

    function new(string n, uvm_component p);
        super.new(n, p);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("SPI_DRV",
                       "Failed to retrieve SPI virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin 
            seq_item_port.get_next_item(req);
            @(posedge vif.spi_clk_o);
            seq_item_port.item_done();
        end
    endtask

endclass
