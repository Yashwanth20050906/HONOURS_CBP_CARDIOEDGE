// ============================================================================
// File: gpio_scoreboard.sv
// Directory: tb/uvm_cardioedge/scoreboards/
// Description: UVM Scoreboard for GPIO VIP functional validation
// ============================================================================

`ifndef GPIO_SCOREBOARD_SV
`define GPIO_SCOREBOARD_SV

`uvm_analysis_imp_decl(_gpio)

class gpio_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_gpio #(gpio_item, gpio_scoreboard) item_collected_export;

    int unsigned total_trans = 0;
    int unsigned pass_count  = 0;
    int unsigned fail_count  = 0;

    // Track recognized CPU output states
    bit seen_dir_ff  = 1'b0;
    bit seen_out_a5  = 1'b0;
    bit seen_out_a7  = 1'b0;
    bit seen_out_a6  = 1'b0;
    bit seen_in_stim = 1'b0;

    `uvm_component_utils(gpio_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write_gpio(gpio_item item);
        bit check_pass = 1'b1;
        total_trans++;

        // Check 1: No unknown or high-impedance values in output/oe
        if ($isunknown(item.gpio_out[7:0])) begin
            `uvm_error("GPIO_SB_FAIL", $sformatf("GPIO OUT contains unknown (X/Z) bits: 0x%02h", item.gpio_out[7:0]))
            check_pass = 1'b0;
        end
        if ($isunknown(item.gpio_oe[7:0])) begin
            `uvm_error("GPIO_SB_FAIL", $sformatf("GPIO OE contains unknown (X/Z) bits: 0x%02h", item.gpio_oe[7:0]))
            check_pass = 1'b0;
        end

        // Check 2: Functional pattern verification from SoC firmware
        if (item.gpio_oe[7:0] == 8'hFF) begin
            seen_dir_ff = 1'b1;
            `uvm_info("GPIO_SB_PASS", "Verified GPIO Direction DIR = 0xFF (All outputs enabled)", UVM_HIGH)
        end

        if (item.gpio_out[7:0] == 8'hA5) begin
            seen_out_a5 = 1'b1;
            `uvm_info("GPIO_SB_PASS", "Verified Initial GPIO Write: DATA_O = 0xA5", UVM_MEDIUM)
        end

        if (item.gpio_out[7:0] == 8'hA7) begin
            seen_out_a7 = 1'b1;
            `uvm_info("GPIO_SB_PASS", "Verified Atomic SET_O: DATA_O = 0xA7 (Bit 1 set)", UVM_MEDIUM)
        end

        if (item.gpio_out[7:0] == 8'hA6) begin
            seen_out_a6 = 1'b1;
            `uvm_info("GPIO_SB_PASS", "Verified Atomic CLR_O: DATA_O = 0xA6 (Bit 0 cleared)", UVM_MEDIUM)
        end

        if (item.gpio_drv_en != 8'h0) begin
            seen_in_stim = 1'b1;
            `uvm_info("GPIO_SB_PASS", $sformatf("Verified External GPIO Input Drive: 0x%02h (drv_en=0x%02h)",
                      item.gpio_in[7:0], item.gpio_drv_en), UVM_HIGH)
        end

        if (check_pass) begin
            pass_count++;
        end else begin
            fail_count++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("------------------------------------------------------------");
        $display("               GPIO SCOREBOARD SUMMARY                      ");
        $display("------------------------------------------------------------");
        $display("  Total Transitions Monitored : %0d", total_trans);
        $display("  Passed Checks               : %0d", pass_count);
        $display("  Failed Checks               : %0d", fail_count);
        $display("  Firmware DIR=0xFF Observed  : %s", seen_dir_ff  ? "YES" : "NO");
        $display("  Firmware DATA=0xA5 Observed : %s", seen_out_a5  ? "YES" : "NO");
        $display("  Firmware SET=0xA7 Observed  : %s", seen_out_a7  ? "YES" : "NO");
        $display("  Firmware CLR=0xA6 Observed  : %s", seen_out_a6  ? "YES" : "NO");
        $display("  External Input Observed     : %s", seen_in_stim ? "YES" : "NO");
        if (fail_count == 0 && total_trans > 0) begin
            $display("  GPIO VIP STATUS             : ALL CHECKS PASSED");
        end else if (total_trans == 0) begin
            $display("  GPIO VIP STATUS             : WARNING (No transitions checked)");
        end else begin
            $display("  GPIO VIP STATUS             : FAILED (%0d errors detected)", fail_count);
        end
        $display("------------------------------------------------------------");
    endfunction

endclass : gpio_scoreboard

`endif // GPIO_SCOREBOARD_SV
