`timescale 1ns/1ps
`default_nettype none
module adc_tb;
  import adc_pkg::*;

  localparam integer ADC_RES  = 12;
  localparam integer FIFO_D   = 32;
  localparam integer CLK_HZ   = 50_000_000;
  localparam integer SRATE_HZ = 250;
  localparam logic [31:0] BASE = 32'h1000_0300;
  localparam real CLK_PERIOD_NS = 1_000_000_000.0 / CLK_HZ;

  logic clk, rst_n;
  logic [ADC_RES-1:0] sample_in;
  logic sample_valid;
  logic irq_sample, irq_overrun;

  logic [31:0] s_axi_awaddr, s_axi_wdata, s_axi_araddr;
  logic [3:0]  s_axi_wstrb;
  logic s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready;
  logic [1:0] s_axi_bresp;
  logic s_axi_bvalid, s_axi_bready;
  logic s_axi_arvalid, s_axi_arready;
  logic [31:0] s_axi_rdata;
  logic [1:0] s_axi_rresp;
  logic s_axi_rvalid, s_axi_rready;

  int pass_count, fail_count;
  string test_name;

  always #(CLK_PERIOD_NS/2.0) clk = ~clk;

  function automatic [31:0] reg_addr(input [31:0] offset);
    reg_addr = BASE + offset;
  endfunction

  adc_controller #(
    .ADC_RESOLUTION(ADC_RES),
    .NUM_CHANNELS(1),
    .FIFO_DEPTH(FIFO_D),
    .CLK_FREQ_HZ(CLK_HZ),
    .SAMPLE_RATE_HZ(SRATE_HZ),
    .BASE_ADDR(BASE),
    .ENABLE_FIFO(1),
    .ENABLE_INTERRUPTS(1)
  ) u_dut (
    .aclk(clk), .aresetn(rst_n),
    .sample_in(sample_in), .sample_valid(sample_valid),
    .irq_sample(irq_sample), .irq_overrun(irq_overrun),
    .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
    .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
    .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
    .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp), .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready)
  );

  axi_lite_master_bfm u_bfm (
    .clk(clk), .rst_n(rst_n),
    .awaddr(s_axi_awaddr), .awvalid(s_axi_awvalid), .awready(s_axi_awready),
    .wdata(s_axi_wdata), .wstrb(s_axi_wstrb), .wvalid(s_axi_wvalid), .wready(s_axi_wready),
    .bresp(s_axi_bresp), .bvalid(s_axi_bvalid), .bready(s_axi_bready),
    .araddr(s_axi_araddr), .arvalid(s_axi_arvalid), .arready(s_axi_arready),
    .rdata(s_axi_rdata), .rresp(s_axi_rresp), .rvalid(s_axi_rvalid), .rready(s_axi_rready)
  );

  adc_sample_source #(.ADC_RESOLUTION(ADC_RES)) u_adc_model (
    .clk(clk), .rst_n(rst_n), .sample_out(sample_in), .sample_valid(sample_valid)
  );

  // Test modules contain callable tasks. They are instantiated here so
  // the tasks can legally use hierarchical references into adc_tb.
  adc_basic_test        u_basic_test();
  adc_fifo_test         u_fifo_test();
  adc_interrupt_test   u_interrupt_test();
  adc_reset_test       u_reset_test();
  adc_axi_protocol_test u_axi_protocol_test();
  adc_periodic_test    u_periodic_test();

  // Verbose ADC debug monitor: prints only when key state changes.
  // Uses actual signal names present in adc_controller / adc_registers.
  logic dbg_last_busy, dbg_last_done, dbg_last_empty, dbg_last_full, dbg_last_overrun;
  logic [ADC_RES-1:0] dbg_last_sample;

  initial begin
    dbg_last_busy    = 1'bx;
    dbg_last_done    = 1'bx;
    dbg_last_empty   = 1'bx;
    dbg_last_full    = 1'bx;
    dbg_last_overrun = 1'bx;
    dbg_last_sample  = 'hx;
  end

  always @(posedge clk) begin
    if ((u_dut.acq_busy           !== dbg_last_busy)    ||
        (u_dut.u_regs.r_done      !== dbg_last_done)    ||
        (u_dut.fifo_empty         !== dbg_last_empty)   ||
        (u_dut.fifo_full          !== dbg_last_full)    ||
        (u_dut.u_regs.r_overrun   !== dbg_last_overrun) ||
        (u_dut.sample_data_reg    !== dbg_last_sample)) begin
      $display("[%0t][DUT] busy=%b done=%b fifo_empty=%b fifo_full=%b overrun=%b sample=%h",
               $time,
               u_dut.acq_busy,
               u_dut.u_regs.r_done,
               u_dut.fifo_empty,
               u_dut.fifo_full,
               u_dut.u_regs.r_overrun,
               u_dut.sample_data_reg);
      dbg_last_busy    = u_dut.acq_busy;
      dbg_last_done    = u_dut.u_regs.r_done;
      dbg_last_empty   = u_dut.fifo_empty;
      dbg_last_full    = u_dut.fifo_full;
      dbg_last_overrun = u_dut.u_regs.r_overrun;
      dbg_last_sample  = u_dut.sample_data_reg;
    end
  end

  initial clk = 1'b0;

  task automatic apply_reset(input integer cycles = 5);
    rst_n = 1'b0;
    repeat (cycles) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk);
  endtask

  task automatic report;
    $display("==================================================");
    $display("ADC TB: %0s", test_name);
    $display("PASS=%0d FAIL=%0d", pass_count, fail_count);
    if (fail_count == 0) $display("*** ALL CHECKS PASSED ***");
    else                 $display("*** TEST FAILED ***");
    $display("==================================================");
  endtask

  initial begin
    if (!$value$plusargs("TEST_NAME=%s", test_name))
      test_name = "all";

    pass_count = 0;
    fail_count = 0;
    rst_n = 1'b0;
    apply_reset(10);

    case (test_name)
      "adc_basic_test":        u_basic_test.run(pass_count, fail_count);
      "adc_fifo_test":         u_fifo_test.run(pass_count, fail_count);
      "adc_interrupt_test":    u_interrupt_test.run(pass_count, fail_count);
      "adc_reset_test":        u_reset_test.run(pass_count, fail_count);
      "adc_axi_protocol_test": u_axi_protocol_test.run(pass_count, fail_count);
      "adc_periodic_test":     u_periodic_test.run(pass_count, fail_count);

      "all": begin
        u_basic_test.run(pass_count, fail_count);
        apply_reset(5);
        u_fifo_test.run(pass_count, fail_count);
        apply_reset(5);
        u_interrupt_test.run(pass_count, fail_count);
        apply_reset(5);
        u_reset_test.run(pass_count, fail_count);
        apply_reset(5);
        u_axi_protocol_test.run(pass_count, fail_count);
        apply_reset(5);
        u_periodic_test.run(pass_count, fail_count);
      end

      default: $fatal(1, "Unknown TEST_NAME=%s", test_name);
    endcase

    report();
    if (fail_count != 0) $fatal(1, "ADC verification failed");
    $finish;
  end

  initial begin
    #500_000_000;
    $fatal(1, "ADC TB watchdog timeout");
  end

`ifdef DUMP_FSDB
  initial begin
    $fsdbDumpfile("adc_waveform.fsdb");
    $fsdbDumpvars(0, adc_tb);
  end
`endif
endmodule
`default_nettype wire
