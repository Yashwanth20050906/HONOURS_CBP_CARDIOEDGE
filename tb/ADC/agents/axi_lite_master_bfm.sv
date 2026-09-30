`default_nettype none
module axi_lite_master_bfm (
  input  logic clk,
  input  logic rst_n,

  output logic [31:0] awaddr,
  output logic        awvalid,
  input  logic        awready,
  output logic [31:0] wdata,
  output logic [3:0]  wstrb,
  output logic        wvalid,
  input  logic        wready,
  input  logic [1:0]  bresp,
  input  logic        bvalid,
  output logic        bready,

  output logic [31:0] araddr,
  output logic        arvalid,
  input  logic        arready,
  input  logic [31:0] rdata,
  input  logic [1:0]  rresp,
  input  logic        rvalid,
  output logic        rready
);
  import adc_pkg::*;

  initial begin
    awaddr  = '0; awvalid = 1'b0;
    wdata   = '0; wstrb   = 4'hF; wvalid = 1'b0;
    bready  = 1'b1;
    araddr  = '0; arvalid = 1'b0; rready = 1'b1;
  end

  // Full write: drives AW and W channels (potentially simultaneously),
  // waits for handshakes, then waits for B channel response.
  task automatic axil_write(
    input  logic [31:0] addr,
    input  logic [31:0] data,
    input  logic [3:0]  strb,
    output logic [1:0]  resp
  );
    bit aw_done, w_done;
    @(negedge clk);
    awaddr  <= addr;
    awvalid <= 1'b1;
    wdata   <= data;
    wstrb   <= strb;
    wvalid  <= 1'b1;
    aw_done = 0;
    w_done  = 0;

    while (!(aw_done && w_done)) begin
      @(posedge clk);
      if (!aw_done && awvalid && awready) begin
        aw_done = 1;
        awvalid <= 1'b0;
      end
      if (!w_done && wvalid && wready) begin
        w_done = 1;
        wvalid <= 1'b0;
      end
    end

    while (!(bvalid && bready))
      @(posedge clk);
    resp = bresp;
    $display("[%0t][BFM][WRITE] DONE  addr=%08h data=%08h strb=%b resp=%b",
             $time, addr, data, strb, resp);
    @(negedge clk);
  endtask

  // Convenience write (full-strobe, discards response).
  task automatic axil_write_simple(
    input logic [31:0] addr,
    input logic [31:0] data
  );
    logic [1:0] resp;
    $display("[%0t][BFM][WRITE] START addr=%08h data=%08h", $time, addr, data);
    axil_write(addr, data, 4'hF, resp);
    $display("[%0t][BFM][WRITE] END   addr=%08h data=%08h resp=%b", $time, addr, data, resp);
  endtask

  // Full read: drives AR channel, waits for R channel response.
  task automatic axil_read(
    input  logic [31:0] addr,
    output logic [31:0] data,
    output logic [1:0]  resp
  );
    bit ar_done;
    @(negedge clk);
    araddr  <= addr;
    arvalid <= 1'b1;
    ar_done = 0;

    while (!ar_done) begin
      @(posedge clk);
      if (arvalid && arready) begin
        ar_done = 1;
        arvalid <= 1'b0;
      end
    end

    while (!(rvalid && rready))
      @(posedge clk);
    data = rdata;
    resp = rresp;
    $display("[%0t][BFM][READ]  DONE  addr=%08h data=%08h resp=%b",
             $time, addr, data, resp);
    @(negedge clk);
  endtask

  // Convenience read (discards response).
  task automatic axil_read_simple(
    input  logic [31:0] addr,
    output logic [31:0] data
  );
    logic [1:0] resp;
    $display("[%0t][BFM][READ]  START addr=%08h", $time, addr);
    axil_read(addr, data, resp);
  endtask

  // Poll until (read_data & mask) == (expected & mask), or timeout.
  task automatic axil_poll(
    input logic [31:0]  addr,
    input logic [31:0]  mask,
    input logic [31:0]  expected,
    input integer       timeout_cycles = 100000
  );
    logic [31:0] rd;
    integer      i;
    $display("[%0t][BFM][POLL]  START addr=%08h mask=%08h expected=%08h",
             $time, addr, mask, expected);
    rd = 32'hDEAD_BEEF;
    for (i = 0; i < timeout_cycles; i = i + 1) begin
      axil_read_simple(addr, rd);
      if ((rd & mask) == (expected & mask)) begin
        $display("[%0t][BFM][POLL]  PASS  addr=%08h mask=%08h expected=%08h actual=%08h",
                 $time, addr, mask, expected, rd);
        return;
      end
    end
    $display("[%0t][BFM][POLL]  TIMEOUT addr=%08h mask=%08h expected=%08h last=%08h",
             $time, addr, mask, expected, rd);
    $fatal(1, "AXI poll timeout addr=%08h mask=%08h expected=%08h last=%08h",
           addr, mask, expected, rd);
  endtask

  // AW-first write: AW handshake completes, then W is sent.
  task automatic axil_write_aw_first(
    input  logic [31:0] addr,
    input  logic [31:0] data,
    input  logic [3:0]  strb,
    output logic [1:0]  resp
  );
    bit aw_done, w_done;
    @(negedge clk);
    awaddr  <= addr;
    awvalid <= 1'b1;
    wdata   <= data;
    wstrb   <= strb;
    wvalid  <= 1'b0;
    aw_done = 0;
    w_done  = 0;

    while (!aw_done) begin
      @(posedge clk);
      if (awvalid && awready) begin
        aw_done  = 1;
        awvalid <= 1'b0;
      end
    end

    @(negedge clk);
    wvalid <= 1'b1;

    while (!w_done) begin
      @(posedge clk);
      if (wvalid && wready) begin
        w_done  = 1;
        wvalid <= 1'b0;
      end
    end

    while (!(bvalid && bready)) @(posedge clk);
    resp = bresp;
    $display("[%0t][BFM][WRITE][AW-FIRST] addr=%08h data=%08h resp=%b",
             $time, addr, data, resp);
    @(negedge clk);
  endtask

  // W-first write: W handshake completes, then AW is sent.
  task automatic axil_write_w_first(
    input  logic [31:0] addr,
    input  logic [31:0] data,
    input  logic [3:0]  strb,
    output logic [1:0]  resp
  );
    bit aw_done, w_done;
    @(negedge clk);
    awaddr  <= addr;
    awvalid <= 1'b0;
    wdata   <= data;
    wstrb   <= strb;
    wvalid  <= 1'b1;
    aw_done = 0;
    w_done  = 0;

    while (!w_done) begin
      @(posedge clk);
      if (wvalid && wready) begin
        w_done  = 1;
        wvalid <= 1'b0;
      end
    end

    @(negedge clk);
    awvalid <= 1'b1;

    while (!aw_done) begin
      @(posedge clk);
      if (awvalid && awready) begin
        aw_done  = 1;
        awvalid <= 1'b0;
      end
    end

    while (!(bvalid && bready)) @(posedge clk);
    resp = bresp;
    $display("[%0t][BFM][WRITE][W-FIRST] addr=%08h data=%08h resp=%b",
             $time, addr, data, resp);
    @(negedge clk);
  endtask

endmodule
`default_nettype wire
