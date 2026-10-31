// ============================================================================
// File: adc_scoreboard.sv
// Directory: tb/uvm_cardioedge/scoreboards/
// Description: UVM Scoreboard for ADC VIP functional validation
// ============================================================================

`ifndef ADC_SCOREBOARD_SV
`define ADC_SCOREBOARD_SV

`uvm_analysis_imp_decl(_adc)

class adc_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_adc #(adc_item, adc_scoreboard) item_collected_export;

    int unsigned total_trans  = 0;
    int unsigned pass_count   = 0;
    int unsigned fail_count   = 0;

    `uvm_component_utils(adc_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write_adc(adc_item item);
        bit is_valid = 1'b1;
        total_trans++;

        // Check 1: No unknown or high-impedance values in sample data
        if ($isunknown(item.sample_in)) begin
            `uvm_error("ADC_SB_FAIL", $sformatf("Sample #%0d contains unknown (X/Z) bits: sample_in=0x%03h",
                       total_trans, item.sample_in))
            is_valid = 1'b0;
        end

        // Check 2: Resolution check (must be within 12-bit range 0x000 to 0xFFF)
        if (item.sample_in > 12'hFFF) begin
            `uvm_error("ADC_SB_FAIL", $sformatf("Sample #%0d exceeds 12-bit resolution: sample_in=0x%03h",
                       total_trans, item.sample_in))
            is_valid = 1'b0;
        end

        // Check 3: Sample valid assertion verified
        if (item.sample_valid !== 1'b1) begin
            `uvm_error("ADC_SB_FAIL", $sformatf("Sample #%0d has sample_valid != 1: valid=%0b",
                       total_trans, item.sample_valid))
            is_valid = 1'b0;
        end

        if (is_valid) begin
            pass_count++;
            `uvm_info("ADC_SB_PASS", $sformatf("Sample #%0d Verified PASS: 0x%03h (%0d) at %0t",
                      total_trans, item.sample_in, item.sample_in, item.timestamp), UVM_HIGH)
        end else begin
            fail_count++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("------------------------------------------------------------");
        $display("                ADC SCOREBOARD SUMMARY                      ");
        $display("------------------------------------------------------------");
        $display("  Total Samples Checked : %0d", total_trans);
        $display("  Passed Transactions   : %0d", pass_count);
        $display("  Failed Transactions   : %0d", fail_count);
        if (fail_count == 0 && total_trans > 0) begin
            $display("  ADC VIP STATUS        : ALL CHECKS PASSED");
        end else if (total_trans == 0) begin
            $display("  ADC VIP STATUS        : WARNING (No transactions checked)");
        end else begin
            $display("  ADC VIP STATUS        : FAILED (%0d errors detected)", fail_count);
        end
        $display("------------------------------------------------------------");
    endfunction

endclass : adc_scoreboard

`endif // ADC_SCOREBOARD_SV
