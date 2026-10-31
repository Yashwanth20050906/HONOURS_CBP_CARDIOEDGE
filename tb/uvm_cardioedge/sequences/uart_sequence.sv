// ============================================================================
// File: uart_sequence.sv
// Directory: tb/uvm_cardioedge/sequences/
// Description: UVM Sequences for UART VIP stimulus generation
// ============================================================================

`ifndef UART_SEQUENCE_SV
`define UART_SEQUENCE_SV

// ----------------------------------------------------------------------------
// Base UART Byte Sequence
// ----------------------------------------------------------------------------
class uart_base_sequence extends uvm_sequence #(uart_item);

    `uvm_object_utils(uart_base_sequence)

    function new(string name = "uart_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uart_item item = uart_item::type_id::create("item");
        start_item(item);
        item.data        = 8'h55; // Alternating 01010101
        item.delay_bauds = 1;
        finish_item(item);
    endtask

endclass : uart_base_sequence

// ----------------------------------------------------------------------------
// Multiple Characters Sequence
// ----------------------------------------------------------------------------
class uart_string_sequence extends uvm_sequence #(uart_item);

    string msg = "CARDIOEDGE";

    `uvm_object_utils(uart_string_sequence)

    function new(string name = "uart_string_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("UART_SEQ", $sformatf("Starting UART String Transmission: \"%s\"", msg), UVM_MEDIUM)
        for (int i = 0; i < msg.len(); i++) begin
            uart_item item = uart_item::type_id::create($sformatf("char_%0d", i));
            start_item(item);
            item.data        = msg[i];
            item.delay_bauds = 1;
            item.trans_id    = i + 1;
            finish_item(item);
        end
        `uvm_info("UART_SEQ", "Completed UART String Transmission", UVM_MEDIUM)
    endtask

endclass : uart_string_sequence

// ----------------------------------------------------------------------------
// Back-to-Back Fast Serial Characters Sequence
// ----------------------------------------------------------------------------
class uart_back_to_back_sequence extends uvm_sequence #(uart_item);

    logic [7:0] bytes[] = '{8'h55, 8'hAA, 8'h33, 8'hCC, 8'h0F, 8'hF0};

    `uvm_object_utils(uart_back_to_back_sequence)

    function new(string name = "uart_back_to_back_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("UART_SEQ", $sformatf("Starting UART Back-to-Back Sequence (%0d bytes)", bytes.size()), UVM_MEDIUM)
        for (int k = 0; k < bytes.size(); k++) begin
            uart_item item = uart_item::type_id::create($sformatf("b2b_%0d", k));
            start_item(item);
            item.data        = bytes[k];
            item.delay_bauds = 0; // immediate back-to-back
            item.trans_id    = k + 10;
            finish_item(item);
        end
        `uvm_info("UART_SEQ", "Completed UART Back-to-Back Sequence", UVM_MEDIUM)
    endtask

endclass : uart_back_to_back_sequence

`endif // UART_SEQUENCE_SV
