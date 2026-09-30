`default_nettype none
module adc_axi_protocol_test;
  import adc_pkg::*;
  task automatic run(ref int pass_count, ref int fail_count);
    logic [31:0] rd;
    logic [1:0] resp;
    $display("[AXI] Start");

    // CTRL byte strobes: only enable byte is writable.
    adc_tb.u_bfm.axil_write(adc_tb.reg_addr(OFFSET_CTRL), 32'h0000_0001, 4'h1, resp);
    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_CTRL), rd);
    if (resp==AXI_RESP_OKAY && rd==32'h1) pass_count++;
    else begin fail_count++; $display("[FAIL] CTRL byte write"); end

    // Independent AW/W ordering.
    adc_tb.u_bfm.axil_write_aw_first(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h1, 4'h1, resp);
    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), rd);
    if (resp==AXI_RESP_OKAY && rd[0]==1'b1) pass_count++;
    else begin fail_count++; $display("[FAIL] AW-first write"); end

    adc_tb.u_bfm.axil_write_w_first(adc_tb.reg_addr(OFFSET_IRQ_EN), 32'h2, 4'h1, resp);
    adc_tb.u_bfm.axil_read_simple(adc_tb.reg_addr(OFFSET_IRQ_EN), rd);
    if (resp==AXI_RESP_OKAY && rd[1:0]==2'b10) pass_count++;
    else begin fail_count++; $display("[FAIL] W-first write"); end

    // Valid reads must return OKAY.
    adc_tb.u_bfm.axil_read(adc_tb.reg_addr(OFFSET_STATUS), rd, resp);
    if (resp==AXI_RESP_OKAY) pass_count++;
    else begin fail_count++; $display("[FAIL] valid RRESP=%b",resp); end

    // Writes to read-only registers must return SLVERR.
    adc_tb.u_bfm.axil_write(adc_tb.reg_addr(OFFSET_SAMPLE_DATA), 32'h1, 4'hF, resp);
    if (resp==AXI_RESP_SLVERR) pass_count++;
    else begin fail_count++; $display("[FAIL] SAMPLE_DATA write BRESP=%b",resp); end

    adc_tb.u_bfm.axil_write(adc_tb.reg_addr(OFFSET_FIFO_DATA), 32'h1, 4'hF, resp);
    if (resp==AXI_RESP_SLVERR) pass_count++;
    else begin fail_count++; $display("[FAIL] FIFO_DATA write BRESP=%b",resp); end

    // Invalid and misaligned addresses must return SLVERR.
    adc_tb.u_bfm.axil_write(adc_tb.reg_addr(32'h20), 32'h0, 4'hF, resp);
    if (resp==AXI_RESP_SLVERR) pass_count++;
    else begin fail_count++; $display("[FAIL] invalid write BRESP=%b",resp); end

    adc_tb.u_bfm.axil_read(adc_tb.reg_addr(32'h20), rd, resp);
    if (resp==AXI_RESP_SLVERR && rd==0) pass_count++;
    else begin fail_count++; $display("[FAIL] invalid read RRESP=%b DATA=%08h",resp,rd); end

    adc_tb.u_bfm.axil_read(adc_tb.reg_addr(32'h01), rd, resp);
    if (resp==AXI_RESP_SLVERR) pass_count++;
    else begin fail_count++; $display("[FAIL] misaligned read RRESP=%b",resp); end

    // FIFO_DATA empty read: OKAY, zero, no pop.
    adc_tb.u_bfm.axil_read(adc_tb.reg_addr(OFFSET_FIFO_DATA), rd, resp);
    if (resp==AXI_RESP_OKAY && rd==0) pass_count++;
    else begin fail_count++; $display("[FAIL] empty FIFO read"); end

    $display("[AXI] End");
  endtask
endmodule
`default_nettype wire
