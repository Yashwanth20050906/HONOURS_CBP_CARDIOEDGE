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

            `uvm_info("SPI_DRV", $sformatf("SPI Master activated CS_N=0. Responder driving MISO=0x%02h", resp_byte), UVM_HIGH)

            // Shift 8 bits onto MISO
            for (int b = 7; b >= 0; b--) begin
                vif.spi_miso_i <= resp_byte[b];
                // Wait for master clock edge or CS deassertion
                @(posedge vif.spi_clk_o or negedge vif.spi_clk_o or posedge vif.spi_cs_n_o);
                if (vif.spi_cs_n_o === 1'b1) break;
            end

            // Wait for chip select release
            if (vif.spi_cs_n_o === 1'b0) begin
                wait (vif.spi_cs_n_o === 1'b1);
            end
            vif.spi_miso_i <= 1'b0;

            if (has_item) begin
                req.end_time = $time;
                seq_item_port.item_done();
            end
        end
    endtask

endclass : spi_driver

`endif // SPI_DRIVER_SV
