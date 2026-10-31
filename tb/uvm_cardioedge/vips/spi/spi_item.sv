// ============================================================================
// File: spi_item.sv
// Directory: tb/uvm_cardioedge/vips/spi/
// Description: UVM Sequence Item for SPI VIP transactions
// ============================================================================

`ifndef SPI_ITEM_SV
`define SPI_ITEM_SV

class spi_item extends uvm_sequence_item;

    // Stimulus (Slave to Master response data)
    rand bit [7:0]       miso_data;
    rand int unsigned    delay_cycles;

    // Monitored responses from Master
    bit [7:0]            mosi_data;
    bit                  cs_n_asserted;
    time                 start_time;
    time                 end_time;
    int unsigned         trans_id;

    constraint c_delay {
        delay_cycles inside {[0 : 5]};
    }

    `uvm_object_utils_begin(spi_item)
        `uvm_field_int(miso_data,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(mosi_data,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(delay_cycles,  UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(trans_id,      UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(start_time,    UVM_ALL_ON | UVM_TIME)
        `uvm_field_int(end_time,      UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "spi_item");
        super.new(name);
        miso_data     = 8'hA5;
        mosi_data     = 8'h00;
        delay_cycles  = 0;
        cs_n_asserted = 1'b0;
        start_time    = 0;
        end_time      = 0;
        trans_id      = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("SPI Item [id=%0d]: MOSI(DUT)=0x%02h, MISO(VIP)=0x%02h [start=%0t, end=%0t]",
                         trans_id, mosi_data, miso_data, start_time, end_time);
    endfunction

endclass : spi_item

`endif // SPI_ITEM_SV
