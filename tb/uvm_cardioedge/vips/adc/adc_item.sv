// ============================================================================
// File: adc_item.sv
// Directory: tb/uvm_cardioedge/vips/adc/
// Description: UVM Sequence Item for ADC VIP transactions
// ============================================================================

`ifndef ADC_ITEM_SV
`define ADC_ITEM_SV

class adc_item extends uvm_sequence_item;

    rand bit [11:0]      sample_in;
    rand bit             sample_valid;
    rand int unsigned    delay_cycles;
    int unsigned         sample_id;
    time                 timestamp;

    constraint c_valid_dist {
        sample_valid dist { 1 := 95, 0 := 5 };
    }

    constraint c_sample_range {
        sample_in inside {[12'h000 : 12'hFFF]};
    }

    constraint c_delay_cycles {
        delay_cycles inside {[1 : 10]};
    }

    `uvm_object_utils_begin(adc_item)
        `uvm_field_int(sample_in,     UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(sample_valid,  UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(delay_cycles,  UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(sample_id,     UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(timestamp,     UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "adc_item");
        super.new(name);
        sample_valid = 1'b1;
        delay_cycles = 1;
        sample_in    = 12'h000;
        sample_id    = 0;
        timestamp    = 0;
    endfunction

    virtual function string convert2string();
        return $sformatf("ADC Item [id=%0d]: sample_in=0x%03h (%0d), sample_valid=%0b, delay=%0d, time=%0t",
                         sample_id, sample_in, sample_in, sample_valid, delay_cycles, timestamp);
    endfunction

endclass : adc_item

`endif // ADC_ITEM_SV
