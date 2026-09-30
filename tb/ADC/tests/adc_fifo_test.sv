`default_nettype none
module adc_fifo_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    logic [31:0] rd, data;
    logic [11:0] expected;
    int i;
    $display("[FIFO] Start");

    // Fill exactly FIFO_DEPTH entries using software acquisitions.
    for (i=0; i<32; i=i+1) begin
      adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
      wait (adc_tb.u_dut.acq_busy === 1'b1);
      adc_tb.u_adc_model.drive_sample(12'(i));
      adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS),
                             32'h2, 32'h2, 1000);
      adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h2);
    end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_FFULL_BIT] == 1'b1) pass_count++;
    else begin fail_count++; $display("[FAIL] FIFO did not become full: %08h",rd); end

    // 33rd sample must be dropped and set OVERRUN.
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
    wait (adc_tb.u_dut.acq_busy === 1'b1);
    adc_tb.u_adc_model.drive_sample(12'hEEE);
    adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS), 32'h30, 32'h30, 1000);

    // Drain and verify FIFO ordering.
    for (i=0; i<32; i=i+1) begin
      adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_FIFO_DATA), data);
      expected = 12'(i);
      if (data[11:0] != expected) begin
        fail_count++;
        $display("[FAIL] FIFO[%0d] got=%03h expected=%03h",i,data[11:0],expected);
      end else pass_count++;
    end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_FEMPTY_BIT] == 1'b1) pass_count++;
    else begin fail_count++; $display("[FAIL] FIFO not empty"); end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h10);
    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_OVERRUN_BIT] == 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] OVERRUN W1C failed"); end

    $display("[FIFO] End");
  endtask
endmodule
`default_nettype wire
