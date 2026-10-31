// ============================================================================
// File: uart_item.sv
// Directory: tb/uvm_cardioedge/vips/uart/
// Description: UVM Sequence Item for UART VIP transactions
// ============================================================================

`ifndef UART_ITEM_SV
`define UART_ITEM_SV

class uart_item extends uvm_sequence_item;

    rand bit [7:0]       data;
    rand int unsigned    delay_bauds;
    bit                  is_dut_tx; // 1 = transmitted by DUT (uart_tx_o), 0 = driven to DUT (uart_rx_i)
    time                 timestamp;
    int unsigned         trans_id;

    constraint c_delay {
        delay_bauds inside {[0 : 4]};
    }

    `uvm_object_utils_begin(uart_item)
        `uvm_field_int(data,        UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(delay_bauds, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(is_dut_tx,   UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(trans_id,    UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(timestamp,   UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "uart_item");
        super.new(name);
        data        = 8'h00;
        delay_bauds = 1;
        is_dut_tx   = 1'b0;
        timestamp   = 0;
        trans_id    = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("UART Item [id=%0d]: Data=0x%02h ('%c'), Source=%s at %0t",
                         trans_id, data, (data >= 32 && data <= 126) ? data : 8'h2E,
                         is_dut_tx ? "DUT_TX" : "VIP_TX", timestamp);
    endfunction

endclass : uart_item

`endif // UART_ITEM_SV
