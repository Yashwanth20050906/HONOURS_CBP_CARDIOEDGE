// ============================================================================
// File: spi_scoreboard.sv
// Directory: tb/uvm_cardioedge/scoreboards/
// Description: UVM Scoreboard for SPI VIP functional validation
// ============================================================================

`ifndef SPI_SCOREBOARD_SV
`define SPI_SCOREBOARD_SV

`uvm_analysis_imp_decl(_spi)

class spi_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp_spi #(spi_item, spi_scoreboard) item_collected_export;

    int unsigned total_trans  = 0;
    int unsigned pass_count   = 0;
    int unsigned fail_count   = 0;

    bit seen_dtr_5a = 1'b0;

    `uvm_component_utils(spi_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_export = new("item_collected_export", this);
    endfunction

    virtual function void write_spi(spi_item item);
        bit check_pass = 1'b1;
        total_trans++;

        // Check 1: No unknown or high-impedance values on serial lines
        if ($isunknown(item.mosi_data)) begin
            `uvm_error("SPI_SB_FAIL", $sformatf("SPI MOSI byte contains unknown bits: 0x%02h", item.mosi_data))
            check_pass = 1'b0;
        end
        if ($isunknown(item.miso_data)) begin
            `uvm_error("SPI_SB_FAIL", $sformatf("SPI MISO byte contains unknown bits: 0x%02h", item.miso_data))
            check_pass = 1'b0;
        end

        // Check 2: Chip select must have been asserted
        if (!item.cs_n_asserted) begin
            `uvm_error("SPI_SB_FAIL", "SPI transaction completed without verified CS_N assertion")
            check_pass = 1'b0;
        end

        // Check 3: Check for expected SoC firmware byte transmission (DTR = 0x5A)
        if (item.mosi_data == 8'h5A) begin
            seen_dtr_5a = 1'b1;
            `uvm_info("SPI_SB_PASS", "Verified SoC Firmware SPI Transmission: MOSI = 0x5A", UVM_MEDIUM)
        end

        if (check_pass) begin
            pass_count++;
            `uvm_info("SPI_SB_PASS", $sformatf("SPI Transaction #%0d Verified PASS: MOSI=0x%02h, MISO=0x%02h",
                      total_trans, item.mosi_data, item.miso_data), UVM_HIGH)
        end else begin
            fail_count++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("------------------------------------------------------------");
        $display("                SPI SCOREBOARD SUMMARY                      ");
        $display("------------------------------------------------------------");
        $display("  Total SPI Transactions      : %0d", total_trans);
        $display("  Passed Transactions         : %0d", pass_count);
        $display("  Failed Transactions         : %0d", fail_count);
        $display("  Firmware DTR=0x5A Observed  : %s", seen_dtr_5a ? "YES" : "NO");
        if (fail_count == 0 && total_trans > 0) begin
            $display("  SPI VIP STATUS              : ALL CHECKS PASSED");
        end else if (total_trans == 0) begin
            $display("  SPI VIP STATUS              : WARNING (No transactions checked)");
        end else begin
            $display("  SPI VIP STATUS              : FAILED (%0d errors detected)", fail_count);
        end
        $display("------------------------------------------------------------");
    endfunction

endclass : spi_scoreboard

`endif // SPI_SCOREBOARD_SV
