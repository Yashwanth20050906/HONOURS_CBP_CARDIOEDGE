// ============================================================================
// File: gpio_sequence.sv
// Directory: tb/uvm_cardioedge/sequences/
// Description: UVM Sequences for GPIO VIP stimulus generation
// ============================================================================

`ifndef GPIO_SEQUENCE_SV
`define GPIO_SEQUENCE_SV

// ----------------------------------------------------------------------------
// Base GPIO Sequence
// ----------------------------------------------------------------------------
class gpio_base_sequence extends uvm_sequence #(gpio_item);

    `uvm_object_utils(gpio_base_sequence)

    function new(string name = "gpio_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        gpio_item item = gpio_item::type_id::create("item");
        start_item(item);
        item.gpio_in      = 32'h0000_003C;
        item.gpio_drv_en  = 8'hFF;
        item.delay_cycles = 2;
        item.hold_cycles  = 5;
        finish_item(item);
    endtask

endclass : gpio_base_sequence

// ----------------------------------------------------------------------------
// Multiple GPIO Patterns Sequence (Logic 0, Logic 1, Walking Ones, Walking Zeros)
// ----------------------------------------------------------------------------
class gpio_pattern_sequence extends uvm_sequence #(gpio_item);

    logic [7:0] patterns[] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'h3C, 8'hC3, 8'h0F, 8'hF0};

    `uvm_object_utils(gpio_pattern_sequence)

    function new(string name = "gpio_pattern_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("GPIO_SEQ", $sformatf("Starting GPIO Multi-Pattern Sequence (%0d patterns)", patterns.size()), UVM_MEDIUM)
        for (int p = 0; p < patterns.size(); p++) begin
            gpio_item item = gpio_item::type_id::create($sformatf("gpio_pat_%0d", p));
            start_item(item);
            item.gpio_in      = {24'h0, patterns[p]};
            item.gpio_drv_en  = 8'hFF;
            item.delay_cycles = 3;
            item.hold_cycles  = 4;
            item.trans_id     = p + 1;
            finish_item(item);
        end
        `uvm_info("GPIO_SEQ", "Completed GPIO Multi-Pattern Sequence", UVM_MEDIUM)
    endtask

endclass : gpio_pattern_sequence

// ----------------------------------------------------------------------------
// GPIO Input/Output Direction Stress Sequence
// ----------------------------------------------------------------------------
class gpio_direction_test_sequence extends uvm_sequence #(gpio_item);

    `uvm_object_utils(gpio_direction_test_sequence)

    function new(string name = "gpio_direction_test_sequence");
        super.new(name);
    endfunction

    virtual task body();
        gpio_item item;

        // Drive lower nibble input, float upper nibble
        item = gpio_item::type_id::create("nibble_item");
        start_item(item);
        item.gpio_in      = 32'h0000_0005;
        item.gpio_drv_en  = 8'h0F; // only drive lower 4 bits
        item.delay_cycles = 2;
        item.hold_cycles  = 6;
        finish_item(item);

        // Drive all zeros (Logic 0 check)
        item = gpio_item::type_id::create("zero_item");
        start_item(item);
        item.gpio_in      = 32'h0000_0000;
        item.gpio_drv_en  = 8'hFF;
        item.delay_cycles = 2;
        item.hold_cycles  = 4;
        finish_item(item);

        // Drive all ones (Logic 1 check)
        item = gpio_item::type_id::create("ones_item");
        start_item(item);
        item.gpio_in      = 32'h0000_00FF;
        item.gpio_drv_en  = 8'hFF;
        item.delay_cycles = 2;
        item.hold_cycles  = 4;
        finish_item(item);
    endtask

endclass : gpio_direction_test_sequence

`endif // GPIO_SEQUENCE_SV
