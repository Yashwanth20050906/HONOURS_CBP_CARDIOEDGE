`default_nettype none
module adc_periodic_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    bit timeout;
    logic [31:0] rd;
    $display("[PERIODIC] Start");

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h1);
    timeout = 1'b0;
    fork
      begin
        wait (adc_tb.u_dut.acq_busy === 1'b1);
        timeout = 1'b0;
      end
      begin
        repeat (200_500) @(posedge adc_tb.clk);
        timeout = 1'b1;
      end
    join_any
    disable fork;

    if (timeout) begin
      fail_count++;
      $display("[FAIL] periodic request did not start near 250 Hz interval");
    end else begin
      pass_count++;
      adc_tb.u_adc_model.drive_sample(12'h5A5);
      adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS), 32'h2, 32'h2, 1000);
      adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_SAMPLE_DATA), rd);
      if (rd[11:0] == 12'h5A5) pass_count++;
      else begin fail_count++; $display("[FAIL] periodic sample=%03h",rd[11:0]); end
    end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h0);
    $display("[PERIODIC] End");
  endtask
endmodule
`default_nettype wire
