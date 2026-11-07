class spi_monitor extends uvm_monitor;

    virtual spi_if vif;

    uvm_analysis_port #(spi_item) ap;

    `uvm_component_utils(spi_monitor)

    function new(string n, uvm_component p);
        super.new(n, p); 
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual spi_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("SPI_MON",
                       "Failed to retrieve SPI virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        spi_item item;
        forever begin
            @(posedge vif.spi_clk_o);
            item = spi_item::type_id::create("item");
            item.spi_mosi_o = vif.spi_mosi_o;
            item.spi_miso_i = vif.spi_miso_i;
            item.spi_cs_n_o = vif.spi_cs_n_o;
            `uvm_info("SPI_MON", $sformatf("Observed SPI transfer = MOSI: 0x%02h, MISO: 0x%02h", item.spi_mosi_o, item.spi_miso_i), UVM_MEDIUM)
            ap.write(item);
        end
    endtask

endclass
