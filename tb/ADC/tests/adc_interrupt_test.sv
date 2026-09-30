`default_nettype none
module adc_interrupt_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    logic [31:0] rd;
    int i;
    $display("[IRQ] Start");

    // SAMPLE interrupt
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h1);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h1);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
    wait (adc_tb.u_dut.acq_busy === 1'b1);
    adc_tb.u_adc_model.drive_sample(12'h555);
    wait (adc_tb.irq_sample === 1'b1);

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_DONE_BIT]) pass_count++;
    else begin fail_count++; $display("[FAIL] sample pending not set"); end
    if (adc_tb.irq_overrun === 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] overrun IRQ unexpectedly active"); end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h2);
    #1;
    if (adc_tb.irq_sample === 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] sample IRQ did not clear"); end

    // Masking: conversion still completes, but IRQ remains low.
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h0);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h2);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
    wait (adc_tb.u_dut.acq_busy === 1'b1);
    adc_tb.u_adc_model.drive_sample(12'h123);
    adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS), 32'h2, 32'h2, 1000);
    if (adc_tb.irq_sample === 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] masked sample IRQ asserted"); end
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h2);

    // Fill FIFO, then one more sample to generate overrun.
    for (i=0; i<32; i=i+1) begin
      adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
      wait (adc_tb.u_dut.acq_busy === 1'b1);
      adc_tb.u_adc_model.drive_sample(12'(i));
      adc_tb.u_bfm.axil_poll(adc_tb.reg_addr(OFFSET_STATUS), 32'h2, 32'h2, 1000);
      adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h2);
    end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h2);
    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_CTRL), 32'h3);
    wait (adc_tb.u_dut.acq_busy === 1'b1);
    adc_tb.u_adc_model.drive_sample(12'hFFF);
    wait (adc_tb.irq_overrun === 1'b1);

    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_STATUS), rd);
    if (rd[STAT_OVERRUN_BIT]) pass_count++;
    else begin fail_count++; $display("[FAIL] overrun pending not set"); end

    adc_tb.u_bfm.axil_write_simple(adc_tb.reg_addr(OFFSET_STATUS), 32'h10);
    #1;
    if (adc_tb.irq_overrun === 1'b0) pass_count++;
    else begin fail_count++; $display("[FAIL] overrun IRQ did not clear"); end

    $display("[IRQ] End");
  endtask
endmodule
`default_nettype wire
