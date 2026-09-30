`default_nettype none
module adc_reset_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    logic [31:0] rd;
    $display("[RESET] Start");

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_CTRL), rd);
    if (rd == 0) pass_count++; else begin fail_count++; $display("[FAIL] CTRL reset=%08h",rd); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if ((rd & 32'h3F) == 32'h4) pass_count++;
    else begin fail_count++; $display("[FAIL] STATUS reset=%08h",rd); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_SAMPLE_DATA), rd);
    if (rd == 0) pass_count++; else begin fail_count++; $display("[FAIL] SAMPLE_DATA reset"); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), rd);
    if (rd == 0) pass_count++; else begin fail_count++; $display("[FAIL] IRQ_EN reset"); end

    // Start an acquisition and then assert hardware reset.
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
    wait (adc_tb.u_dut.acq_busy === 1'b1);

    adc_tb.rst_n = 1'b0;
    repeat (4) @(posedge adc_tb.clk);
    adc_tb.rst_n = 1'b1;
    @(posedge adc_tb.clk);

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_CTRL), rd);
    if (rd == 0) pass_count++; else begin fail_count++; $display("[FAIL] CTRL after reset"); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if ((rd & 32'h3F) == 32'h4) pass_count++;
    else begin fail_count++; $display("[FAIL] STATUS after reset=%08h",rd); end

    $display("[RESET] End");
  endtask
endmodule
`default_nettype wire
