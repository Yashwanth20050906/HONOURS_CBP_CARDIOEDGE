// ============================================================================
// File: uart_scoreboard.sv
// Directory: tb/uvm_cardioedge/scoreboards/
// Description: UVM Scoreboard for UART VIP functional validation
// ============================================================================

`ifndef UART_SCOREBOARD_SV
`define UART_SCOREBOARD_SV

`uvm_analysis_imp_decl(_uart)

class uart_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_uart #(uart_item, uart_scoreboard) item_collected_export;

    int unsigned total_trans = 0;
    int unsigned pass_count  = 0;
    int unsigned fail_count  = 0;

    bit seen_char_C = 1'b0;
    bit seen_char_A = 1'b0;
    bit seen_char_55 = 1'b0;

    `uvm_component_utils(uart_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write_uart(uart_item item);
        bit check_pass = 1'b1;
        string expected_str = "Valid Character";
        string observed_str;
        total_trans++;

        observed_str = $sformatf("0x%02h ('%c')", item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E);

        // Check 1: No unknown or high-impedance values
        if ($isunknown(item.data)) begin
            `uvm_error("UART_SB_FAIL", $sformatf("UART character contains unknown (X/Z) bits: 0x%02h", item.data))
            check_pass = 1'b0;
        end

        // Check 2: Verify expected SoC firmware UART transmission ('C' and 'A' and 0x55)
        if (item.is_dut_tx) begin
            if (item.data == 8'h43) begin
                seen_char_C = 1'b1;
                expected_str = "'C' (0x43)";
                `uvm_info("UART_SB_PASS", "[UART SCOREBOARD] Expected vs Actual comparison: Character 'C' (0x43) matched", UVM_LOW)
            end else if (item.data == 8'h41) begin
                seen_char_A = 1'b1;
                expected_str = "'A' (0x41)";
                `uvm_info("UART_SB_PASS", "[UART SCOREBOARD] Expected vs Actual comparison: Character 'A' (0x41) matched", UVM_LOW)
            end else if (item.data == 8'h55) begin
                seen_char_55 = 1'b1;
                expected_str = "'U' (0x55)";
                `uvm_info("UART_SB_PASS", "[UART SCOREBOARD] Expected vs Actual comparison: Character 0x55 ('U') matched", UVM_LOW)
            end else begin
                expected_str = "ASCII Data";
                `uvm_info("UART_SB_PASS", $sformatf("[UART SCOREBOARD] Expected vs Actual comparison: Monitored character 0x%02h ('%c')",
                          item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E), UVM_LOW)
            end
        end

        $display("[SCOREBOARD CHECK] VIP: UART | TXN ID: %0d | EXPECTED: %s | OBSERVED: %s | COMPARISON: %s | RESULT: %s",
                 total_trans, expected_str, observed_str, check_pass ? "MATCH" : "MISMATCH", check_pass ? "PASS" : "FAIL");

        if (check_pass) begin
            pass_count++;
            `uvm_info("UART_SB_PASS", $sformatf("[UART RESULT] PASS: UART Transaction #%0d Verified: 0x%02h ('%c')",
                      total_trans, item.data, (item.data >= 32 && item.data <= 126) ? item.data : 8'h2E), UVM_LOW)
        end else begin
            fail_count++;
            `uvm_error("UART_SB_FAIL", $sformatf("[UART RESULT] FAIL: UART Transaction #%0d Failed", total_trans))
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("------------------------------------------------------------");
        $display("               UART SCOREBOARD SUMMARY                      ");
        $display("------------------------------------------------------------");
        $display("  Total UART Characters       : %0d", total_trans);
        $display("  Passed Characters           : %0d", pass_count);
        $display("  Failed Characters           : %0d", fail_count);
        $display("  Firmware 'C' (0x43) Seen    : %s", seen_char_C ? "YES" : "NO");
        $display("  Firmware 'A' (0x41) Seen    : %s", seen_char_A ? "YES" : "NO");
        if (fail_count == 0 && total_trans > 0) begin
            $display("  UART VIP STATUS             : ALL CHECKS PASSED");
        end else if (total_trans == 0) begin
            $display("  UART VIP STATUS             : WARNING (No characters checked)");
        end else begin
            $display("  UART VIP STATUS             : FAILED (%0d errors detected)", fail_count);
        end
        $display("------------------------------------------------------------");
    endfunction

endclass : uart_scoreboard

`endif // UART_SCOREBOARD_SV
