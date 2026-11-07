// ============================================================================
// File: spi_driver.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Driver for SPI VIP acting as SPI Slave Responder
// ============================================================================

`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_item);

    virtual spi_if vif;
    int unsigned num_driven = 0;

    `uvm_component_utils(spi_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("SPI_DRV_NOVIF", {"Virtual interface vif must be set for ", get_full_name(), ".vif"});
        end
        `uvm_info("SPI_DRV", "[SPI VIF] Virtual interface connected: vif != null", UVM_LOW)
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [7:0] resp_byte;
        bit has_item;

        vif.spi_miso_i <= 1'b0;

        `uvm_info("SPI_DRV", "Waiting for reset release (rst_n == 1)...", UVM_MEDIUM)
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
        `uvm_info("SPI_DRV", "Reset released. SPI Slave responder active.", UVM_MEDIUM)

        forever begin
            // Wait for Chip Select assertion from SoC Master (active low)
            wait (vif.spi_cs_n_o === 1'b0);

            // Attempt to retrieve sequence item, or fall back to default slave response
            seq_item_port.try_next_item(req);
            has_item  = (req != null);
            resp_byte = has_item ? req.miso_data : 8'hA5;
            num_driven++;

            if (has_item) begin
                `uvm_info("SPI_DRV", $sformatf("[SPI DRIVER] Transaction received: ID=%0d, miso_data=0x%02h", req.trans_id, req.miso_data), UVM_LOW)
            end else begin
                `uvm_info("SPI_DRV", $sformatf("[SPI DRIVER] Transaction received: (default responder) miso_data=0x%02h", resp_byte), UVM_LOW)
            end

            `uvm_info("SPI_DRV", $sformatf("[SPI DRIVER] SPI signals driven: responder active, MISO=0x%02h", resp_byte), UVM_LOW)

            // Mode 0: bit 7 must be driven and stable before the first rising clock edge
            vif.spi_miso_i <= resp_byte[7];

            // For subsequent bits 6 down to 0, drive on falling edges (negedge spi_clk_o)
            for (int b = 6; b >= 0; b--) begin
                @(negedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
                if (vif.spi_cs_n_o === 1'b1) break;
                vif.spi_miso_i <= resp_byte[b];
            end

            // Wait for the final rising edge of the 8th bit
            @(posedge vif.spi_clk_o or posedge vif.spi_cs_n_o);

            if (has_item) begin
                req.end_time = $time;
                seq_item_port.item_done();
            end

            // When CS_N is deasserted, release MISO
            if (vif.spi_cs_n_o === 1'b1) begin
                vif.spi_miso_i <= 1'b0;
            end else begin
                // Wait until CS_N goes high or next transaction edge
                fork
                    wait (vif.spi_cs_n_o === 1'b1);
                    @(negedge vif.spi_clk_o);
                join_any
                if (vif.spi_cs_n_o === 1'b1) begin
                    vif.spi_miso_i <= 1'b0;
                end
            end
        end
    endtask

endclass : spi_driver

`endif // SPI_DRIVER_SV
