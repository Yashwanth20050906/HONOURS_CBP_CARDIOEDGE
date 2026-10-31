// ============================================================================
// File: gpio_item.sv
// Directory: tb/uvm_cardioedge/vips/gpio/
// Description: UVM Sequence Item for GPIO VIP transactions
// ============================================================================

`ifndef GPIO_ITEM_SV
`define GPIO_ITEM_SV

class gpio_item extends uvm_sequence_item;

    // Stimulus (driven to DUT)
    rand bit [31:0]      gpio_in;
    rand bit [7:0]       gpio_drv_en;
    rand int unsigned    delay_cycles;
    rand int unsigned    hold_cycles;

    // Monitored responses from DUT
    bit [31:0]           gpio_out;
    bit [31:0]           gpio_oe;
    bit                  gpio_irq;
    time                 timestamp;
    int unsigned         trans_id;

    constraint c_delay {
        delay_cycles inside {[1 : 10]};
        hold_cycles  inside {[1 : 10]};
    }

    `uvm_object_utils_begin(gpio_item)
        `uvm_field_int(gpio_in,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_drv_en,  UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(delay_cycles, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(hold_cycles,  UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(gpio_out,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_oe,      UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_irq,     UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(timestamp,    UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "gpio_item");
        super.new(name);
        gpio_in      = 32'h0;
        gpio_drv_en  = 8'h0;
        delay_cycles = 1;
        hold_cycles  = 2;
        gpio_out     = 32'h0;
        gpio_oe      = 32'h0;
        gpio_irq     = 1'b0;
        timestamp    = 0;
        trans_id     = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("GPIO Item [id=%0d]: IN=0x%08h (drv_en=0x%02h), OUT=0x%08h, OE=0x%08h, IRQ=%0b at %0t",
                         trans_id, gpio_in, gpio_drv_en, gpio_out, gpio_oe, gpio_irq, timestamp);
    endfunction

endclass : gpio_item

`endif // GPIO_ITEM_SV
