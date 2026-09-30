`default_nettype none
module adc_basic_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    logic [31:0] rd;
    logic [31:0] sample;
    $display("[BASIC] Start");

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_CTRL), rd);
    if (rd == 32'h0) pass_count++; else begin fail_count++; $display("[FAIL] CTRL reset"); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_BUSY_BIT] == 0 && rd[STAT_FEMPTY_BIT] == 1) pass_count++;
    else begin fail_count++; $display("[FAIL] STATUS reset=%08h",rd); end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h1);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h0);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);

    wait (adc_tb.u_dut.acq_busy === 1'b1);
    adc_tb.u_adc_model.drive_sample(12'hABC);

    adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS),
                           32'h0000_0002, 32'h0000_0002, 1000);

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_SAMPLE_DATA), rd);
    if (rd[11:0] == 12'hABC) pass_count++;
    else begin fail_count++; $display("[FAIL] SAMPLE_DATA=%08h",rd); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_FIFO_DATA), sample);
    if (sample[11:0] == 12'hABC) pass_count++;
    else begin fail_count++; $display("[FAIL] FIFO_DATA=%08h",sample); end

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_FEMPTY_BIT] == 1'b1) pass_count++;
    else begin fail_count++; $display("[FAIL] FIFO not empty=%08h",rd); end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h0000_0002);
    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_DONE_BIT] == 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] DONE W1C failed"); end

    $display("[BASIC] End");
  endtask
endmodule
`default_nettype wire
