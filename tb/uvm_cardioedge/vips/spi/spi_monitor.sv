// ============================================================================
// File: spi_monitor.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Monitor for SPI VIP monitoring SPI bus transactions
// ============================================================================

`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;

    virtual spi_if vif;
    uvm_analysis_port #(spi_item) ap;
    int unsigned num_monitored = 0;

    `uvm_component_utils(spi_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SPI_MON_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_item item;
        logic [7:0] mosi_shreg;
        logic [7:0] miso_shreg;
        time t_start;

        // Wait for reset release
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            // Wait for Chip Select assertion (negedge)
            wait (vif.spi_cs_n_o === 1'b0);
            t_start = $time;
            mosi_shreg = 8'h00;
            miso_shreg = 8'h00;

            // Sample up to 8 bits on SPI clock edges
            for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin
                @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
                if (vif.spi_cs_n_o === 1'b1) break;
                mosi_shreg = {mosi_shreg[6:0], vif.spi_mosi_o};
                miso_shreg = {miso_shreg[6:0], vif.spi_miso_i};
            end

            // Wait for CS_N deassertion
            if (vif.spi_cs_n_o === 1'b0) begin
                wait (vif.spi_cs_n_o === 1'b1);
            end

            num_monitored++;
            item = spi_item::type_id::create("spi_mon_item");
            item.mosi_data     = mosi_shreg;
            item.miso_data     = miso_shreg;
            item.cs_n_asserted = 1'b1;
            item.start_time    = t_start;
            item.end_time      = $time;
            item.trans_id      = num_monitored;

            `uvm_info("SPI_MON", $sformatf("Monitored SPI Frame #%0d: MOSI(DUT)=0x%02h, MISO(VIP)=0x%02h [%0t - %0t]",
                      num_monitored, item.mosi_data, item.miso_data, item.start_time, item.end_time), UVM_MEDIUM)

            ap.write(item);
        end
    endtask

endclass : spi_monitor

`endif // SPI_MONITOR_SV
