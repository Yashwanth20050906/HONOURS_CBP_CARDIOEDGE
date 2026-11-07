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

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual spi_if)::get(
                this, "", "vif", vif)) begin
            `uvm_fatal("SPI_MON",
                       "Failed to retrieve SPI virtual interface")
        end
        `uvm_info("SPI_MON", "[SPI VIF] Virtual interface connected: vif != null", UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        spi_item item;
        logic [7:0] mosi_shreg;
        logic [7:0] miso_shreg;
        time t_start;
        int bit_cnt;

        // Wait for reset release
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            // Wait for Chip Select assertion (active low: CS_N == 0)
            wait (vif.spi_cs_n_o === 1'b0);
            `uvm_info("SPI_MON", "[SPI DUT] Response observed: SoC Master asserted CS_N=0, initiating transfer", UVM_LOW)
            t_start = $time;
            mosi_shreg = 8'h00;
            miso_shreg = 8'h00;
            bit_cnt = 0;

            // Sample 8 bits on SPI clock rising edges while CS_N is asserted
            while (bit_cnt < 8) begin
                @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
                if (vif.spi_cs_n_o === 1'b1) break;
                mosi_shreg = {mosi_shreg[6:0], vif.spi_mosi_o};
                miso_shreg = {miso_shreg[6:0], vif.spi_miso_i};
                bit_cnt++;
            end

            // When a full byte has been sampled, broadcast transaction
            if (bit_cnt == 8) begin
                num_monitored++;
                item = spi_item::type_id::create("spi_mon_item");
                item.mosi_data     = mosi_shreg;
                item.miso_data     = miso_shreg;
                item.cs_n_asserted = 1'b1;
                item.start_time    = t_start;
                item.end_time      = $time;
                item.trans_id      = num_monitored;

                `uvm_info("SPI_MON", $sformatf("[SPI MONITOR] Transaction captured: ID=%0d, MOSI(DUT)=0x%02h, MISO(VIP)=0x%02h [%0t - %0t]",
                          num_monitored, item.mosi_data, item.miso_data, item.start_time, item.end_time), UVM_LOW)
                `uvm_info("SPI_MON", $sformatf("Observed SPI transfer = MOSI: 0x%02h, MISO: 0x%02h",
                          item.mosi_data, item.miso_data), UVM_MEDIUM)

                $display("[LIVE MONITOR] SPI  | TIME: %0t | TXN ID: %0d | CS: 0 | MOSI: 0x%02h | MISO: 0x%02h | STATUS: 8-BIT MODE 0 FRAME [%0t - %0t]",
                         item.end_time, num_monitored, item.mosi_data, item.miso_data, item.start_time, item.end_time);

                ap.write(item);
            end

            // Frame boundary handling: if CS_N remains low, wait until either CS_N goes high or next clock edge
            if (vif.spi_cs_n_o === 1'b0) begin
                fork
                    wait (vif.spi_cs_n_o === 1'b1);
                    @(posedge vif.spi_clk_o);
                join_any
            end
        end
    endtask

endclass : spi_monitor

`endif // SPI_MONITOR_SV
