// ============================================================================
// File: spi_sequence.sv
// Directory: tb/uvm_cardioedge/sequences/
// Description: UVM Sequences for SPI VIP stimulus generation
// ============================================================================

`ifndef SPI_SEQUENCE_SV
`define SPI_SEQUENCE_SV

// ----------------------------------------------------------------------------
// Base SPI Slave Response Sequence
// ----------------------------------------------------------------------------
class spi_base_sequence extends uvm_sequence #(spi_item);

    `uvm_object_utils(spi_base_sequence)

    function new(string name = "spi_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        spi_item item = spi_item::type_id::create("item");
        start_item(item);
        item.miso_data    = 8'hA5;
        item.delay_cycles = 0;
        finish_item(item);
    endtask

endclass : spi_base_sequence

// ----------------------------------------------------------------------------
// Multiple SPI Transactions Sequence
// ----------------------------------------------------------------------------
class spi_multi_trans_sequence extends uvm_sequence #(spi_item);

    logic [7:0] resp_bytes[] = '{8'hA5, 8'h5A, 8'hFF, 8'h00, 8'h33, 8'hCC};

    `uvm_object_utils(spi_multi_trans_sequence)

    function new(string name = "spi_multi_trans_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("SPI_SEQ", $sformatf("Starting SPI Multi-Transaction Sequence (%0d bytes)", resp_bytes.size()), UVM_MEDIUM)
        for (int i = 0; i < resp_bytes.size(); i++) begin
            spi_item item = spi_item::type_id::create($sformatf("spi_item_%0d", i));
            start_item(item);
            item.miso_data    = resp_bytes[i];
            item.delay_cycles = 0;
            item.trans_id     = i + 1;
            finish_item(item);
        end
        `uvm_info("SPI_SEQ", "Completed SPI Multi-Transaction Sequence", UVM_MEDIUM)
    endtask

endclass : spi_multi_trans_sequence

`endif // SPI_SEQUENCE_SV
