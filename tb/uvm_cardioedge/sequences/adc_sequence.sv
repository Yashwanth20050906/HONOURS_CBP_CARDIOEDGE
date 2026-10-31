// ============================================================================
// File: adc_sequence.sv
// Directory: tb/uvm_cardioedge/sequences/
// Description: UVM Sequences for ADC VIP stimulus generation
// ============================================================================

`ifndef ADC_SEQUENCE_SV
`define ADC_SEQUENCE_SV

// ----------------------------------------------------------------------------
// Base ADC Sequence
// ----------------------------------------------------------------------------
class adc_base_sequence extends uvm_sequence #(adc_item);

    `uvm_object_utils(adc_base_sequence)

    function new(string name = "adc_base_sequence");
        super.new(name);
    endfunction

    virtual task body();
        adc_item item = adc_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with { sample_valid == 1'b1; delay_cycles == 2; }) begin
            `uvm_error("ADC_SEQ", "Randomization failed for adc_item")
        end
        finish_item(item);
    endtask

endclass : adc_base_sequence

// ----------------------------------------------------------------------------
// Multiple ADC Samples Sequence
// ----------------------------------------------------------------------------
class adc_multi_sample_sequence extends uvm_sequence #(adc_item);

    int unsigned num_samples = 16;
    logic [11:0] sample_array[] = '{12'h7A5, 12'h8B2, 12'h100, 12'h555, 12'hAAA, 12'hFFF,
                                     12'h000, 12'h200, 12'h400, 12'h600, 12'h800, 12'hA00,
                                     12'hC00, 12'hE00, 12'h333, 12'hCCC};

    `uvm_object_utils(adc_multi_sample_sequence)

    function new(string name = "adc_multi_sample_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("ADC_SEQ", $sformatf("Starting ADC Multi-Sample Sequence (%0d samples)", num_samples), UVM_MEDIUM)
        for (int i = 0; i < num_samples; i++) begin
            adc_item item = adc_item::type_id::create($sformatf("adc_item_%0d", i));
            start_item(item);
            item.sample_in    = (i < sample_array.size()) ? sample_array[i] : (12'h100 + (i * 12'h20));
            item.sample_valid = 1'b1;
            item.delay_cycles = 4;
            item.sample_id    = i + 1;
            finish_item(item);
        end
        `uvm_info("ADC_SEQ", "Completed ADC Multi-Sample Sequence", UVM_MEDIUM)
    endtask

endclass : adc_multi_sample_sequence

// ----------------------------------------------------------------------------
// Continuous Acquisition Sequence
// ----------------------------------------------------------------------------
class adc_continuous_sequence extends uvm_sequence #(adc_item);

    int unsigned burst_count = 8;

    `uvm_object_utils(adc_continuous_sequence)

    function new(string name = "adc_continuous_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("ADC_SEQ", $sformatf("Starting ADC Continuous Acquisition (%0d burst samples)", burst_count), UVM_MEDIUM)
        for (int k = 0; k < burst_count; k++) begin
            adc_item item = adc_item::type_id::create($sformatf("burst_item_%0d", k));
            start_item(item);
            item.sample_in    = 12'h200 + (k * 12'h50);
            item.sample_valid = 1'b1;
            item.delay_cycles = 1; // back-to-back fast acquisition
            item.sample_id    = k + 100;
            finish_item(item);
        end
        `uvm_info("ADC_SEQ", "Completed ADC Continuous Acquisition", UVM_MEDIUM)
    endtask

endclass : adc_continuous_sequence

// ----------------------------------------------------------------------------
// Invalid Sample Condition Sequence (Negative Testing)
// ----------------------------------------------------------------------------
class adc_invalid_sample_sequence extends uvm_sequence #(adc_item);

    `uvm_object_utils(adc_invalid_sample_sequence)

    function new(string name = "adc_invalid_sample_sequence");
        super.new(name);
    endfunction

    virtual task body();
        adc_item item = adc_item::type_id::create("invalid_item");
        `uvm_info("ADC_SEQ", "Testing invalid sample condition (sample_valid = 0)", UVM_MEDIUM)
        start_item(item);
        item.sample_in    = 12'hEAD;  // nominal sample with valid=0
        item.sample_valid = 1'b0;     // Not valid
        item.delay_cycles = 2;
        finish_item(item);
    endtask

endclass : adc_invalid_sample_sequence

`endif // ADC_SEQUENCE_SV
