//
// Native Testbench for Timer AXI Wrapper
//

module tb_timer_axi;

    logic        aclk;
    logic        aresetn;
    logic [31:0] s_axi_awaddr;
    logic [2:0]  s_axi_awprot;
    logic        s_axi_awvalid;
    logic        s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;
    logic [31:0] s_axi_araddr;
    logic [2:0]  s_axi_arprot;
    logic        s_axi_arvalid;
    logic        s_axi_arready;
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;
    logic        irq;

    logic        ext_meas_i;
    logic        capture_i;
    logic        pwm_o;
    logic        trigger_o;

    // Clock
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // DUT
    timer_axi dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .awaddr(s_axi_awaddr),
        .awprot(s_axi_awprot),
        .awvalid(s_axi_awvalid),
        .awready(s_axi_awready),
        .wdata(s_axi_wdata),
        .wstrb(s_axi_wstrb),
        .wvalid(s_axi_wvalid),
        .wready(s_axi_wready),
        .bresp(s_axi_bresp),
        .bvalid(s_axi_bvalid),
        .bready(s_axi_bready),
        .araddr(s_axi_araddr),
        .arprot(s_axi_arprot),
        .arvalid(s_axi_arvalid),
        .arready(s_axi_arready),
        .rdata(s_axi_rdata),
        .rresp(s_axi_rresp),
        .rvalid(s_axi_rvalid),
        .rready(s_axi_rready),
        .ext_meas_i(ext_meas_i),
        .capture_i(capture_i),
        .pwm_o(pwm_o),
        .trigger_o(trigger_o),
        .irq(irq)
    );

    // Shared BFM Tasks
    `include "axi_bfm_tasks.sv"

    // Offsets
    localparam ADDR_CTRL    = 32'h00;
    localparam ADDR_LOAD    = 32'h04;
    localparam ADDR_INT_EN  = 32'h10;
    localparam ADDR_CMP     = 32'h18;
    
    logic [31:0] read_val;

    initial begin
        $dumpfile("dump_axi.vcd");
        $dumpvars(0, tb_timer_axi);

        aresetn = 0;
        s_axi_awvalid = 0;
        s_axi_awaddr  = 0;
        s_axi_awprot  = 0;
        s_axi_wvalid  = 0;
        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_bready  = 0;
        s_axi_arvalid = 0;
        s_axi_araddr  = 0;
        s_axi_arprot  = 0;
        s_axi_rready  = 0;
        ext_meas_i = 0;
        capture_i = 0;
        
        repeat(10) @(posedge aclk);
        aresetn = 1;
        repeat(10) @(posedge aclk);

        $display("TEST 1: AXI Register R/W");
        axi_write(ADDR_LOAD, 32'hCAFEBABE);
        axi_read(ADDR_LOAD, read_val);
        
        if (read_val !== 32'hCAFEBABE) $error("AXI Read Mismatch: Got %h", read_val);
        else $display("AXI Read LOAD: PASS");

        // Test CMP R/W
        axi_write(ADDR_CMP, 32'h12345678);
        axi_read(ADDR_CMP, read_val);
        if (read_val !== 32'h12345678) $error("AXI Read CMP Mismatch: Got %h", read_val);
        else $display("AXI Read CMP: PASS");

        $display("TEST 2: Timer via AXI");
        axi_write(ADDR_LOAD, 32'd15);
        axi_write(ADDR_INT_EN, 32'd1);
        axi_write(ADDR_CTRL, 32'd1);

        wait(irq == 1);
        $display("AXI Interrupt Received");

        $display("AXI TESTS PASSED");
        $finish;
    end

endmodule
