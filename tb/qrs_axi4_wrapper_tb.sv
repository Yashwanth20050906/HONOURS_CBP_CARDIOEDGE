

// ============================================================
// QRS AXI4 Wrapper Standalone Verification Testbench
//
// Purpose:
//   1. Verify AXI4 single-beat write transactions
//   2. Verify AXI4 single-beat read transactions
//   3. Verify QRS control/input registers
//   4. Feed ECG samples into the QRS core
//   5. Read QRS result/status registers
//
// This is a functional smoke test.
// It does NOT check medical/algorithmic accuracy of QRS detection.
// No Verdi/FSDB is required.
// ============================================================

module qrs_axi4_wrapper_tb;

    // ========================================================
    // Parameters
    // ========================================================

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam ID_WIDTH   = 8;

    localparam [31:0] QRS_BASE        = 32'h4000_1000;

    localparam [31:0] REG_CONTROL     = QRS_BASE + 32'h00;
    localparam [31:0] REG_STATUS      = QRS_BASE + 32'h04;
    localparam [31:0] REG_ECG_INPUT   = QRS_BASE + 32'h08;
    localparam [31:0] REG_RPEAK       = QRS_BASE + 32'h0C;
    localparam [31:0] REG_RR_INTERVAL = QRS_BASE + 32'h10;
    localparam [31:0] REG_BPM         = QRS_BASE + 32'h14;
    localparam [31:0] REG_RHYTHM      = QRS_BASE + 32'h18;

    // ========================================================
    // Clock / Reset
    // ========================================================

    reg clk = 1'b0;
    reg rst = 1'b1;

    always #5 clk = ~clk;

    // ========================================================
    // AXI4 Write Address Channel
    // ========================================================

    reg  [ID_WIDTH-1:0]   s_axi_awid;
    reg  [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg  [7:0]            s_axi_awlen;
    reg  [2:0]            s_axi_awsize;
    reg  [1:0]            s_axi_awburst;
    reg                   s_axi_awlock;
    reg  [3:0]            s_axi_awcache;
    reg  [2:0]            s_axi_awprot;
    reg  [3:0]            s_axi_awqos;
    reg                   s_axi_awvalid;

    wire                  s_axi_awready;

    // ========================================================
    // AXI4 Write Data Channel
    // ========================================================

    reg  [DATA_WIDTH-1:0]   s_axi_wdata;
    reg  [DATA_WIDTH/8-1:0] s_axi_wstrb;
    reg                     s_axi_wlast;
    reg                     s_axi_wvalid;

    wire                    s_axi_wready;

    // ========================================================
    // AXI4 Write Response Channel
    // ========================================================

    wire [ID_WIDTH-1:0] s_axi_bid;
    wire [1:0]          s_axi_bresp;
    wire                s_axi_bvalid;

    reg                 s_axi_bready;

    // ========================================================
    // AXI4 Read Address Channel
    // ========================================================

    reg  [ID_WIDTH-1:0]   s_axi_arid;
    reg  [ADDR_WIDTH-1:0] s_axi_araddr;
    reg  [7:0]            s_axi_arlen;
    reg  [2:0]            s_axi_arsize;
    reg  [1:0]            s_axi_arburst;
    reg                   s_axi_arlock;
    reg  [3:0]            s_axi_arcache;
    reg  [2:0]            s_axi_arprot;
    reg  [3:0]            s_axi_arqos;
    reg                   s_axi_arvalid;

    wire                  s_axi_arready;

    // ========================================================
    // AXI4 Read Data Channel
    // ========================================================

    wire [ID_WIDTH-1:0]   s_axi_rid;
    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0]            s_axi_rresp;
    wire                  s_axi_rlast;
    wire                  s_axi_rvalid;

    reg                   s_axi_rready;

    // ========================================================
    // DUT
    // ========================================================

    qrs_axi4_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .FS(360),
        .BASE_ADDR(QRS_BASE)
    ) dut (

        .clk(clk),
        .rst(rst),

        // -------------------------------
        // AXI Write Address
        // -------------------------------
        .s_axi_awid(s_axi_awid),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen),
        .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst),
        .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awqos(s_axi_awqos),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        // -------------------------------
        // AXI Write Data
        // -------------------------------
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wlast(s_axi_wlast),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        // -------------------------------
        // AXI Write Response
        // -------------------------------
        .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        // -------------------------------
        // AXI Read Address
        // -------------------------------
        .s_axi_arid(s_axi_arid),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen),
        .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst),
        .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arqos(s_axi_arqos),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        // -------------------------------
        // AXI Read Data
        // -------------------------------
        .s_axi_rid(s_axi_rid),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rlast(s_axi_rlast),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

    // ========================================================
    // Testbench Variables
    // ========================================================

    integer errors;
    integer i;

    reg [31:0] read_value;
    reg signed [15:0] sample;

    // ========================================================
    // AXI WRITE TASK
    // ========================================================

    task automatic axi_write(
        input [31:0] addr,
        input [31:0] data
    );

        begin

            $display("");
            $display("--------------------------------------------------");
            $display("AXI WRITE");
            $display("Address : %08h", addr);
            $display("Data    : %08h", data);
            $display("--------------------------------------------------");

            // --------------------------------------------
            // Write Address
            // --------------------------------------------

            @(negedge clk);

            s_axi_awid    = 8'h2A;
            s_axi_awaddr  = addr;
            s_axi_awlen   = 8'd0;
            s_axi_awsize  = 3'd2;
            s_axi_awburst = 2'b01;
            s_axi_awlock  = 1'b0;
            s_axi_awcache = 4'd0;
            s_axi_awprot  = 3'd0;
            s_axi_awqos   = 4'd0;
            s_axi_awvalid = 1'b1;

            do begin
                @(posedge clk);
            end while (!s_axi_awready);

            $display("[WRITE] AW handshake successful");

            @(negedge clk);

            s_axi_awvalid = 1'b0;

            // --------------------------------------------
            // Write Data
            // --------------------------------------------

            s_axi_wdata  = data;
            s_axi_wstrb  = 4'b1111;
            s_axi_wlast  = 1'b1;
            s_axi_wvalid = 1'b1;

            do begin
                @(posedge clk);
            end while (!s_axi_wready);

            $display("[WRITE] W handshake successful");

            @(negedge clk);

            s_axi_wvalid = 1'b0;
            s_axi_wlast  = 1'b0;

            // --------------------------------------------
            // Write Response
            // --------------------------------------------

            s_axi_bready = 1'b1;

            do begin
                @(posedge clk);
            end while (!s_axi_bvalid);

            $display("[WRITE] BID   = %02h", s_axi_bid);
            $display("[WRITE] BRESP = %02b", s_axi_bresp);

            if (s_axi_bid !== 8'h2A) begin

                $display("ERROR: Write response ID mismatch");
                errors = errors + 1;

            end

            if (s_axi_bresp !== 2'b00) begin

                $display("ERROR: AXI write response not OKAY");
                errors = errors + 1;

            end
            else begin

                $display("[WRITE] Response = OKAY");

            end

            @(negedge clk);

            s_axi_bready = 1'b0;

        end

    endtask

    // ========================================================
    // AXI READ TASK
    // ========================================================

    task automatic axi_read(
        input  [31:0] addr,
        output [31:0] data
    );

        begin

            $display("");
            $display("--------------------------------------------------");
            $display("AXI READ");
            $display("Address : %08h", addr);
            $display("--------------------------------------------------");

            // --------------------------------------------
            // Read Address
            // --------------------------------------------

            @(negedge clk);

            s_axi_arid    = 8'h35;
            s_axi_araddr  = addr;
            s_axi_arlen   = 8'd0;
            s_axi_arsize  = 3'd2;
            s_axi_arburst = 2'b01;
            s_axi_arlock  = 1'b0;
            s_axi_arcache = 4'd0;
            s_axi_arprot  = 3'd0;
            s_axi_arqos   = 4'd0;
            s_axi_arvalid = 1'b1;

            do begin
                @(posedge clk);
            end while (!s_axi_arready);

            $display("[READ] AR handshake successful");

            @(negedge clk);

            s_axi_arvalid = 1'b0;
            s_axi_rready  = 1'b1;

            // --------------------------------------------
            // Read Response
            // --------------------------------------------

            do begin
                @(posedge clk);
            end while (!s_axi_rvalid);

            data = s_axi_rdata;

            $display("[READ] RID   = %02h", s_axi_rid);
            $display("[READ] RDATA = %08h", s_axi_rdata);
            $display("[READ] RRESP = %02b", s_axi_rresp);
            $display("[READ] RLAST = %b", s_axi_rlast);

            if (s_axi_rid !== 8'h35) begin

                $display("ERROR: Read response ID mismatch");
                errors = errors + 1;

            end

            if (s_axi_rresp !== 2'b00) begin

                $display("ERROR: AXI read response not OKAY");
                errors = errors + 1;

            end

            if (s_axi_rlast !== 1'b1) begin

                $display("ERROR: RLAST was not asserted");
                errors = errors + 1;

            end

            if ((s_axi_rresp === 2'b00) &&
                (s_axi_rid === 8'h35) &&
                (s_axi_rlast === 1'b1)) begin

                $display("[READ] Response = OKAY");

            end

            @(negedge clk);

            s_axi_rready = 1'b0;

        end

    endtask

    // ========================================================
    // REGISTER READBACK CHECK
    // ========================================================

    task automatic check_read(
        input [31:0] addr,
        input [31:0] expected,
        input [255:0] label_text
    );

        begin

            axi_read(addr, read_value);

            if (read_value !== expected) begin

                $display("FAIL: %0s", label_text);
                $display("      Expected = %08h", expected);
                $display("      Got      = %08h", read_value);

                errors = errors + 1;

            end
            else begin

                $display("PASS: %0s = %08h",
                         label_text,
                         read_value);

            end

        end

    endtask

    // ========================================================
    // MAIN TEST
    // ========================================================

    initial begin

        errors = 0;

        // ----------------------------------------------------
        // Initialize AXI signals
        // ----------------------------------------------------

        s_axi_awid    = 0;
        s_axi_awaddr  = 0;
        s_axi_awlen   = 0;
        s_axi_awsize  = 0;
        s_axi_awburst = 0;
        s_axi_awlock  = 0;
        s_axi_awcache = 0;
        s_axi_awprot  = 0;
        s_axi_awqos   = 0;
        s_axi_awvalid = 0;

        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wlast   = 0;
        s_axi_wvalid  = 0;

        s_axi_bready  = 0;

        s_axi_arid    = 0;
        s_axi_araddr  = 0;
        s_axi_arlen   = 0;
        s_axi_arsize  = 0;
        s_axi_arburst = 0;
        s_axi_arlock  = 0;
        s_axi_arcache = 0;
        s_axi_arprot  = 0;
        s_axi_arqos   = 0;
        s_axi_arvalid = 0;

        s_axi_rready  = 0;

        // ----------------------------------------------------
        // Start with reset asserted
        // ----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("          QRS AXI4 WRAPPER TESTBENCH");
        $display("==================================================");

        $display("");
        $display("[RESET] Reset asserted");

        repeat (5) @(negedge clk);

        rst = 1'b0;

        $display("[RESET] Reset released");

        repeat (3) @(negedge clk);

        // ----------------------------------------------------
        // TEST 1: CONTROL REGISTER
        // ----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("TEST 1: CONTROL REGISTER");
        $display("==================================================");

        axi_write(
            REG_CONTROL,
            32'h0000_0001
        );

        check_read(
            REG_CONTROL,
            32'h0000_0001,
            "CONTROL register"
        );

        // ----------------------------------------------------
        // TEST 2: ECG INPUT REGISTER
        // ----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("TEST 2: ECG INPUT REGISTER");
        $display("==================================================");

        axi_write(
            REG_ECG_INPUT,
            32'h0000_1234
        );

        check_read(
            REG_ECG_INPUT,
            32'h0000_1234,
            "ECG_INPUT register"
        );

        // ----------------------------------------------------
        // TEST 3: ECG SAMPLE STREAM
        // ----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("TEST 3: ECG SAMPLE STREAM");
        $display("==================================================");

        $display("Sending 64 ECG samples...");
        $display("");

        for (i = 0; i < 64; i = i + 1) begin

            if ((i % 16) == 8)

                sample = 16'sd12000;

            else if ((i % 16) == 9)

                sample = -16'sd6000;

            else

                sample = 16'sd0;

            $display(
                "ECG SAMPLE [%02d] = %6d  (0x%04h)",
                i,
                sample,
                sample
            );

            axi_write(
                REG_ECG_INPUT,
                {{16{sample[15]}}, sample}
            );

        end

        $display("");
        $display("ECG sample stream completed.");

        // ----------------------------------------------------
        // Allow QRS pipeline to process remaining samples
        // ----------------------------------------------------

        $display("");
        $display("Waiting for QRS pipeline...");
        repeat (20) @(negedge clk);
        $display("QRS pipeline wait completed.");

        // ----------------------------------------------------
        // TEST 4: STATUS
        // ----------------------------------------------------

        $display("");
        $display("==================================================");
        $display("TEST 4: QRS STATUS / RESULT REGISTERS");
        $display("==================================================");

        axi_read(
            REG_STATUS,
            read_value
        );

        $display("STATUS       = %08h", read_value);

        axi_read(
            REG_RPEAK,
            read_value
        );

        $display("RPEAK        = %08h", read_value);

        axi_read(
            REG_RR_INTERVAL,
            read_value
        );

        $display("RR_INTERVAL  = %08h", read_value);

        axi_read(
            REG_BPM,
            read_value
        );

        $display("BPM          = %08h", read_value);

        axi_read(
            REG_RHYTHM,
            read_value
        );

        $display("RHYTHM_CLASS = %08h", read_value);

        // ----------------------------------------------------
        // FINAL RESULT
        // ----------------------------------------------------

        $display("");
        $display("==================================================");

        if (errors == 0) begin

            $display("       QRS AXI WRAPPER TESTBENCH PASS");
            $display("==================================================");
            $display("AXI write transactions : PASS");
            $display("AXI read transactions  : PASS");
            $display("Register access        : PASS");
            $display("ECG input transfer     : PASS");
            $display("QRS result registers   : READ SUCCESSFULLY");
            $display("");
            $display("The QRS AXI wrapper is functionally operational.");
            $display("==================================================");

        end
        else begin

            $display("       QRS AXI WRAPPER TESTBENCH FAIL");
            $display("==================================================");
            $display("Total errors = %0d", errors);
            $display("==================================================");

        end

        // ----------------------------------------------------
        // End simulation
        // ----------------------------------------------------

        repeat (10) @(negedge clk);

        $display("");
        $display("Simulation completed.");
        $finish;

    end

endmodule
