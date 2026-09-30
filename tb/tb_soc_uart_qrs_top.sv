`timescale 1ns/1ps

module tb_soc_uart_qrs_top;

    // ============================================================
    // PARAMETERS
    // ============================================================
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam ID_WIDTH   = 8;
    localparam STRB_WIDTH = 4;

    // ============================================================
    // ADDRESS MAP
    // ============================================================
    localparam UART_BASE       = 32'h4000_0000;
    localparam UART_LSR        = 32'h4000_0014;
    localparam UART_LCR        = 32'h4000_000C;

    localparam QRS_BASE       = 32'h4000_1000;
    localparam QRS_CONTROL    = 32'h4000_1000;
    localparam QRS_STATUS     = 32'h4000_1004;
    localparam QRS_ECG_INPUT  = 32'h4000_1008;
    localparam QRS_RPEAK      = 32'h4000_100C;
    localparam QRS_RR         = 32'h4000_1010;
    localparam QRS_BPM        = 32'h4000_1014;
    localparam QRS_RHYTHM     = 32'h4000_1018;

    // ============================================================
    // CLOCK / RESET
    // ============================================================
    logic clk;
    logic rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // UART
    // ============================================================
    logic uart_rx_i;
    wire  uart_tx_o;

    // ============================================================
    // AXI WRITE ADDRESS CHANNEL
    // ============================================================
    logic [ID_WIDTH-1:0]   s00_axi_awid;
    logic [ADDR_WIDTH-1:0] s00_axi_awaddr;
    logic [7:0]            s00_axi_awlen;
    logic [2:0]            s00_axi_awsize;
    logic [1:0]            s00_axi_awburst;
    logic                  s00_axi_awlock;
    logic [3:0]            s00_axi_awcache;
    logic [2:0]            s00_axi_awprot;
    logic [3:0]            s00_axi_awqos;
    logic                  s00_axi_awuser;
    logic                  s00_axi_awvalid;
    wire                   s00_axi_awready;

    // ============================================================
    // AXI WRITE DATA CHANNEL
    // ============================================================
    logic [DATA_WIDTH-1:0] s00_axi_wdata;
    logic [STRB_WIDTH-1:0] s00_axi_wstrb;
    logic                  s00_axi_wlast;
    logic                  s00_axi_wuser;
    logic                  s00_axi_wvalid;
    wire                   s00_axi_wready;

    // ============================================================
    // AXI WRITE RESPONSE CHANNEL
    // ============================================================
    wire [ID_WIDTH-1:0]    s00_axi_bid;
    wire [1:0]             s00_axi_bresp;
    wire                   s00_axi_buser;
    wire                   s00_axi_bvalid;
    logic                  s00_axi_bready;

    // ============================================================
    // AXI READ ADDRESS CHANNEL
    // ============================================================
    logic [ID_WIDTH-1:0]   s00_axi_arid;
    logic [ADDR_WIDTH-1:0] s00_axi_araddr;
    logic [7:0]            s00_axi_arlen;
    logic [2:0]            s00_axi_arsize;
    logic [1:0]            s00_axi_arburst;
    logic                  s00_axi_arlock;
    logic [3:0]            s00_axi_arcache;
    logic [2:0]            s00_axi_arprot;
    logic [3:0]            s00_axi_arqos;
    logic                  s00_axi_aruser;
    logic                  s00_axi_arvalid;
    wire                   s00_axi_arready;

    // ============================================================
    // AXI READ DATA CHANNEL
    // ============================================================
    wire [ID_WIDTH-1:0]    s00_axi_rid;
    wire [DATA_WIDTH-1:0]  s00_axi_rdata;
    wire [1:0]             s00_axi_rresp;
    wire                   s00_axi_rlast;
    wire                   s00_axi_ruser;
    wire                   s00_axi_rvalid;
    logic                  s00_axi_rready;

    // ============================================================
    // COUNTERS
    // ============================================================
    integer pass_count;
    integer fail_count;

    // ============================================================
    // DUT
    // ============================================================
    soc_uart_qrs_top dut (
        .clk              (clk),
        .rst              (rst),

        .uart_rx_i        (uart_rx_i),
        .uart_tx_o        (uart_tx_o),

        // AXI WRITE ADDRESS
        .s00_axi_awid     (s00_axi_awid),
        .s00_axi_awaddr   (s00_axi_awaddr),
        .s00_axi_awlen    (s00_axi_awlen),
        .s00_axi_awsize   (s00_axi_awsize),
        .s00_axi_awburst  (s00_axi_awburst),
        .s00_axi_awlock   (s00_axi_awlock),
        .s00_axi_awcache  (s00_axi_awcache),
        .s00_axi_awprot   (s00_axi_awprot),
        .s00_axi_awqos    (s00_axi_awqos),
        .s00_axi_awuser   (s00_axi_awuser),
        .s00_axi_awvalid  (s00_axi_awvalid),
        .s00_axi_awready  (s00_axi_awready),

        // AXI WRITE DATA
        .s00_axi_wdata   (s00_axi_wdata),
        .s00_axi_wstrb   (s00_axi_wstrb),
        .s00_axi_wlast   (s00_axi_wlast),
        .s00_axi_wuser   (s00_axi_wuser),
        .s00_axi_wvalid  (s00_axi_wvalid),
        .s00_axi_wready  (s00_axi_wready),

        // AXI WRITE RESPONSE
        .s00_axi_bid     (s00_axi_bid),
        .s00_axi_bresp   (s00_axi_bresp),
        .s00_axi_buser   (s00_axi_buser),
        .s00_axi_bvalid  (s00_axi_bvalid),
        .s00_axi_bready  (s00_axi_bready),

        // AXI READ ADDRESS
        .s00_axi_arid    (s00_axi_arid),
        .s00_axi_araddr  (s00_axi_araddr),
        .s00_axi_arlen   (s00_axi_arlen),
        .s00_axi_arsize  (s00_axi_arsize),
        .s00_axi_arburst (s00_axi_arburst),
        .s00_axi_arlock  (s00_axi_arlock),
        .s00_axi_arcache (s00_axi_arcache),
        .s00_axi_arprot  (s00_axi_arprot),
        .s00_axi_arqos   (s00_axi_arqos),
        .s00_axi_aruser  (s00_axi_aruser),
        .s00_axi_arvalid (s00_axi_arvalid),
        .s00_axi_arready (s00_axi_arready),

        // AXI READ DATA
        .s00_axi_rid     (s00_axi_rid),
        .s00_axi_rdata   (s00_axi_rdata),
        .s00_axi_rresp   (s00_axi_rresp),
        .s00_axi_rlast   (s00_axi_rlast),
        .s00_axi_ruser   (s00_axi_ruser),
        .s00_axi_rvalid  (s00_axi_rvalid),
        .s00_axi_rready  (s00_axi_rready)
    );

    // ============================================================
    // INITIAL BUS VALUES
    // ============================================================
    initial begin

        uart_rx_i = 1'b1;

        s00_axi_awid    = '0;
        s00_axi_awaddr  = '0;
        s00_axi_awlen   = 8'd0;
        s00_axi_awsize  = 3'b010;
        s00_axi_awburst = 2'b01;
        s00_axi_awlock  = 1'b0;
        s00_axi_awcache = 4'b0;
        s00_axi_awprot  = 3'b0;
        s00_axi_awqos   = 4'b0;
        s00_axi_awuser  = 1'b0;
        s00_axi_awvalid = 1'b0;

        s00_axi_wdata   = '0;
        s00_axi_wstrb   = 4'b1111;
        s00_axi_wlast   = 1'b1;
        s00_axi_wuser   = 1'b0;
        s00_axi_wvalid  = 1'b0;

        s00_axi_bready  = 1'b0;

        s00_axi_arid    = '0;
        s00_axi_araddr  = '0;
        s00_axi_arlen   = 8'd0;
        s00_axi_arsize  = 3'b010;
        s00_axi_arburst = 2'b01;
        s00_axi_arlock  = 1'b0;
        s00_axi_arcache = 4'b0;
        s00_axi_arprot  = 3'b0;
        s00_axi_arqos   = 4'b0;
        s00_axi_aruser  = 1'b0;
        s00_axi_arvalid = 1'b0;

        s00_axi_rready  = 1'b0;

        pass_count = 0;
        fail_count = 0;
    end

    // ============================================================
    // AXI WRITE TASK
    //
    // IMPORTANT:
    // AWVALID is deasserted immediately after AW handshake.
    // WVALID  is deasserted immediately after W handshake.
    //
    // This is the main Solution-1 change.
    // ============================================================
    task automatic axi_write;
        input [31:0] addr;
        input [31:0] data;
        input [7:0]  id;

        integer timeout;

        reg aw_done;
        reg w_done;
        reg b_done;

        begin

            aw_done = 1'b0;
            w_done  = 1'b0;
            b_done  = 1'b0;

            timeout = 0;

            @(negedge clk);

            // ----------------------------------------------------
            // DRIVE AW CHANNEL
            // ----------------------------------------------------
            s00_axi_awid    = id;
            s00_axi_awaddr  = addr;
            s00_axi_awlen   = 8'd0;
            s00_axi_awsize  = 3'b010;
            s00_axi_awburst = 2'b01;
            s00_axi_awlock  = 1'b0;
            s00_axi_awcache = 4'b0;
            s00_axi_awprot  = 3'b0;
            s00_axi_awqos   = 4'b0;
            s00_axi_awuser  = 1'b0;
            s00_axi_awvalid = 1'b1;

            // ----------------------------------------------------
            // DRIVE W CHANNEL
            // ----------------------------------------------------
            s00_axi_wdata   = data;
            s00_axi_wstrb   = 4'b1111;
            s00_axi_wlast   = 1'b1;
            s00_axi_wuser   = 1'b0;
            s00_axi_wvalid  = 1'b1;

            // ----------------------------------------------------
            // ACCEPT B RESPONSE
            // ----------------------------------------------------
            s00_axi_bready  = 1'b1;

            // ----------------------------------------------------
            // WAIT FOR ALL CHANNELS
            // ----------------------------------------------------
            while (!b_done) begin

                @(posedge clk);

                // ------------------------------------------------
                // AW HANDSHAKE
                // ------------------------------------------------
                if (!aw_done &&
                    s00_axi_awvalid &&
                    s00_axi_awready) begin

                    aw_done = 1'b1;

                    $display(
                        "[WRITE AW] addr=0x%08h id=0x%02h",
                        addr,
                        id
                    );

                    @(negedge clk);

                    // CRITICAL:
                    // Stop presenting the same AW transaction.
                    s00_axi_awvalid = 1'b0;
                end

                // ------------------------------------------------
                // W HANDSHAKE
                // ------------------------------------------------
                if (!w_done &&
                    s00_axi_wvalid &&
                    s00_axi_wready) begin

                    w_done = 1'b1;

                    $display(
                        "[WRITE W ] data=0x%08h id=0x%02h",
                        data,
                        id
                    );

                    @(negedge clk);

                    // CRITICAL:
                    // Stop presenting the same W transaction.
                    s00_axi_wvalid = 1'b0;
                end

                // ------------------------------------------------
                // B HANDSHAKE
                // ------------------------------------------------
                if (s00_axi_bvalid &&
                    s00_axi_bready) begin

                    b_done = 1'b1;

                    $display(
                        "[WRITE B ] addr=0x%08h data=0x%08h bid=0x%02h expected=0x%02h bresp=%02b",
                        addr,
                        data,
                        s00_axi_bid,
                        id,
                        s00_axi_bresp
                    );

                    if ((s00_axi_bresp == 2'b00) &&
                        (s00_axi_bid   == id)) begin

                        pass_count = pass_count + 1;

                    end
                    else begin

                        $display(
                            "[FAIL] WRITE response mismatch"
                        );

                        fail_count = fail_count + 1;
                    end
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] WRITE timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    b_done = 1'b1;
                end

            end

            @(negedge clk);

            s00_axi_awvalid = 1'b0;
            s00_axi_wvalid  = 1'b0;
            s00_axi_bready  = 1'b0;

            repeat (5) @(posedge clk);

        end
    endtask

    // ============================================================
    // UART READ
    //
    // Existing UART requires ARVALID to remain asserted until
    // the read response.
    //
    // Therefore this special behavior is retained ONLY for UART.
    // ============================================================
    task automatic axi_read_uart;
        input [31:0] addr;
        input [7:0]  id;
        input [31:0] expected;

        integer timeout;

        reg ar_done;
        reg r_done;

        begin

            ar_done = 1'b0;
            r_done  = 1'b0;

            timeout = 0;

            @(negedge clk);

            s00_axi_arid    = id;
            s00_axi_araddr  = addr;
            s00_axi_arlen   = 8'd0;
            s00_axi_arsize  = 3'b010;
            s00_axi_arburst = 2'b01;
            s00_axi_arlock  = 1'b0;
            s00_axi_arcache = 4'b0;
            s00_axi_arprot  = 3'b0;
            s00_axi_arqos   = 4'b0;
            s00_axi_aruser  = 1'b0;

            s00_axi_arvalid = 1'b1;
            s00_axi_rready  = 1'b1;

            // ----------------------------------------------------
            // WAIT FOR AR HANDSHAKE
            // ----------------------------------------------------
            while (!ar_done) begin

                @(posedge clk);

                if (s00_axi_arvalid &&
                    s00_axi_arready) begin

                    ar_done = 1'b1;

                    $display(
                        "[UART READ AR] addr=0x%08h id=0x%02h",
                        addr,
                        id
                    );
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] UART READ AR timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                    s00_axi_rready  = 1'b0;

                    return;
                end
            end

            // ----------------------------------------------------
            // WAIT FOR R RESPONSE
            // ----------------------------------------------------
            timeout = 0;

            while (!r_done) begin

                @(posedge clk);

                if (s00_axi_rvalid &&
                    s00_axi_rready) begin

                    r_done = 1'b1;

                    $display(
                        "[UART READ R ] addr=0x%08h rdata=0x%08h id=0x%02h rresp=%02b rlast=%b",
                        addr,
                        s00_axi_rdata,
                        s00_axi_rid,
                        s00_axi_rresp,
                        s00_axi_rlast
                    );

                    if ((s00_axi_rresp == 2'b00) &&
                        (s00_axi_rid   == id) &&
                        (s00_axi_rlast == 1'b1) &&
                        (s00_axi_rdata == expected)) begin

                        pass_count = pass_count + 1;

                    end
                    else begin

                        $display(
                            "[FAIL] UART READ mismatch: got=0x%08h expected=0x%08h",
                            s00_axi_rdata,
                            expected
                        );

                        fail_count = fail_count + 1;
                    end
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] UART READ R timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                    s00_axi_rready  = 1'b0;

                    return;
                end
            end

            // ----------------------------------------------------
            // END UART READ
            // ----------------------------------------------------
            @(negedge clk);

            s00_axi_arvalid = 1'b0;

            // Give the existing UART/interconnect read state
            // time to return to idle.
            repeat (20) @(posedge clk);

            @(negedge clk);

            s00_axi_rready = 1'b0;

            repeat (5) @(posedge clk);

        end
    endtask

    // ============================================================
    // STANDARD AXI READ
    //
    // Used for QRS.
    //
    // ARVALID is deasserted immediately after AR handshake.
    // ============================================================
    task automatic axi_read_standard;
        input [31:0] addr;
        input [7:0]  id;
        input [31:0] expected;

        integer timeout;

        reg ar_done;
        reg r_done;

        begin

            ar_done = 1'b0;
            r_done  = 1'b0;

            timeout = 0;

            @(negedge clk);

            s00_axi_arid    = id;
            s00_axi_araddr  = addr;
            s00_axi_arlen   = 8'd0;
            s00_axi_arsize  = 3'b010;
            s00_axi_arburst = 2'b01;
            s00_axi_arlock  = 1'b0;
            s00_axi_arcache = 4'b0;
            s00_axi_arprot  = 3'b0;
            s00_axi_arqos   = 4'b0;
            s00_axi_aruser  = 1'b0;

            s00_axi_arvalid = 1'b1;
            s00_axi_rready  = 1'b1;

            // ----------------------------------------------------
            // WAIT FOR AR HANDSHAKE
            // ----------------------------------------------------
            while (!ar_done) begin

                @(posedge clk);

                if (s00_axi_arvalid &&
                    s00_axi_arready) begin

                    ar_done = 1'b1;

                    $display(
                        "[STD READ AR] addr=0x%08h id=0x%02h",
                        addr,
                        id
                    );

                    // Normal AXI behavior:
                    // AR transaction is finished.
                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] STD READ AR timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                    s00_axi_rready  = 1'b0;

                    return;
                end
            end

            // ----------------------------------------------------
            // WAIT FOR R RESPONSE
            // ----------------------------------------------------
            timeout = 0;

            while (!r_done) begin

                @(posedge clk);

                if (s00_axi_rvalid &&
                    s00_axi_rready) begin

                    r_done = 1'b1;

                    $display(
                        "[STD READ R ] addr=0x%08h rdata=0x%08h id=0x%02h rresp=%02b rlast=%b",
                        addr,
                        s00_axi_rdata,
                        s00_axi_rid,
                        s00_axi_rresp,
                        s00_axi_rlast
                    );

                    if ((s00_axi_rresp == 2'b00) &&
                        (s00_axi_rid   == id) &&
                        (s00_axi_rlast == 1'b1) &&
                        (s00_axi_rdata == expected)) begin

                        pass_count = pass_count + 1;

                    end
                    else begin

                        $display(
                            "[FAIL] STD READ mismatch: got=0x%08h expected=0x%08h",
                            s00_axi_rdata,
                            expected
                        );

                        fail_count = fail_count + 1;
                    end
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] STD READ R timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_rready = 1'b0;

                    return;
                end
            end

            @(negedge clk);

            s00_axi_rready = 1'b0;

            repeat (5) @(posedge clk);

        end
    endtask

    // ============================================================
    // STANDARD AXI READ - DATA NOT CHECKED
    // ============================================================
    task automatic axi_read_any_standard;
        input [31:0] addr;
        input [7:0]  id;

        integer timeout;

        reg ar_done;
        reg r_done;

        begin

            ar_done = 1'b0;
            r_done  = 1'b0;

            timeout = 0;

            @(negedge clk);

            s00_axi_arid    = id;
            s00_axi_araddr  = addr;
            s00_axi_arlen   = 8'd0;
            s00_axi_arsize  = 3'b010;
            s00_axi_arburst = 2'b01;
            s00_axi_arlock  = 1'b0;
            s00_axi_arcache = 4'b0;
            s00_axi_arprot  = 3'b0;
            s00_axi_arqos   = 4'b0;
            s00_axi_aruser  = 1'b0;

            s00_axi_arvalid = 1'b1;
            s00_axi_rready  = 1'b1;

            // ----------------------------------------------------
            // AR HANDSHAKE
            // ----------------------------------------------------
            while (!ar_done) begin

                @(posedge clk);

                if (s00_axi_arvalid &&
                    s00_axi_arready) begin

                    ar_done = 1'b1;

                    $display(
                        "[STD READ ANY AR] addr=0x%08h id=0x%02h",
                        addr,
                        id
                    );

                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] STD READ ANY AR timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_arvalid = 1'b0;
                    s00_axi_rready  = 1'b0;

                    return;
                end
            end

            // ----------------------------------------------------
            // R HANDSHAKE
            // ----------------------------------------------------
            timeout = 0;

            while (!r_done) begin

                @(posedge clk);

                if (s00_axi_rvalid &&
                    s00_axi_rready) begin

                    r_done = 1'b1;

                    $display(
                        "[STD READ ANY R ] addr=0x%08h rdata=0x%08h id=0x%02h rresp=%02b rlast=%b",
                        addr,
                        s00_axi_rdata,
                        s00_axi_rid,
                        s00_axi_rresp,
                        s00_axi_rlast
                    );

                    if ((s00_axi_rresp == 2'b00) &&
                        (s00_axi_rid   == id) &&
                        (s00_axi_rlast == 1'b1)) begin

                        pass_count = pass_count + 1;

                    end
                    else begin

                        $display(
                            "[FAIL] STD READ ANY response mismatch"
                        );

                        fail_count = fail_count + 1;
                    end
                end

                timeout = timeout + 1;

                if (timeout > 500) begin

                    $display(
                        "[FAIL] STD READ ANY R timeout at addr=0x%08h",
                        addr
                    );

                    fail_count = fail_count + 1;

                    @(negedge clk);

                    s00_axi_rready = 1'b0;

                    return;
                end
            end

            @(negedge clk);

            s00_axi_rready = 1'b0;

            repeat (5) @(posedge clk);

        end
    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        rst = 1'b1;

        repeat (10) @(posedge clk);

        rst = 1'b0;

        repeat (10) @(posedge clk);

        $display("");
        $display("============================================================");
        $display(" UART + QRS + AXI 3x14 INTERCONNECT INTEGRATION TEST");
        $display(" SOLUTION 1: TESTBENCH-ONLY AXI HANDSHAKE CHECK");
        $display("============================================================");
        $display("");

        // ========================================================
        // TEST 1
        // UART READ
        // ========================================================
        $display("--- TEST 1: Read UART LSR @ 0x40000014 ---");

        axi_read_uart(
            UART_LSR,
            8'h01,
            32'h0000_0060
        );

        // ========================================================
        // TEST 2
        // UART WRITE
        // ========================================================
        $display("");
        $display("--- TEST 2: Write UART LCR @ 0x4000000c data=0x00000003 ---");

        axi_write(
            UART_LCR,
            32'h0000_0003,
            8'h02
        );

        // ========================================================
        // TEST 3
        // QRS CONTROL WRITE
        // ========================================================
        $display("");
        $display("--- TEST 3: QRS CONTROL WRITE @ 0x40001000 ---");

        axi_write(
            QRS_CONTROL,
            32'h0000_0001,
            8'h10
        );

        // ========================================================
        // TEST 4
        // QRS CONTROL READ
        // ========================================================
        $display("");
        $display("--- TEST 4: QRS CONTROL READ @ 0x40001000 ---");

        axi_read_standard(
            QRS_CONTROL,
            8'h11,
            32'h0000_0001
        );

        // ========================================================
        // TEST 5
        // QRS STATUS READ
        // ========================================================
        $display("");
        $display("--- TEST 5: QRS STATUS READ @ 0x40001004 ---");

        axi_read_standard(
            QRS_STATUS,
            8'h12,
            32'h0000_0001
        );

        // ========================================================
        // TEST 6
        // QRS ECG STREAM
        // ========================================================
        $display("");
        $display("--- TEST 6: QRS ECG INPUT STREAM ---");

        begin : ECG_STREAM

            integer k;
            reg [31:0] sample;
            reg [7:0]  sample_id;

            for (k = 0; k < 64; k = k + 1) begin

                sample    = k * 137;
                sample_id = 8'h20 + k;

                axi_write(
                    QRS_ECG_INPUT,
                    sample,
                    sample_id
                );

            end

        end

        // ========================================================
        // TEST 7
        // QRS ECG INPUT READBACK
        //
        // 63 * 137 = 8631 = 0x21B7
        // ========================================================
        $display("");
        $display("--- TEST 7: QRS ECG_INPUT READBACK @ 0x40001008 ---");

        axi_read_standard(
            QRS_ECG_INPUT,
            8'h60,
            32'h0000_21B7
        );

        // ========================================================
        // TEST 8
        // QRS RESULT REGISTERS
        // ========================================================
        $display("");
        $display("--- TEST 8: QRS RESULT REGISTERS ---");

        axi_read_any_standard(
            QRS_RPEAK,
            8'h61
        );

        axi_read_any_standard(
            QRS_RR,
            8'h62
        );

        axi_read_any_standard(
            QRS_BPM,
            8'h63
        );

        axi_read_any_standard(
            QRS_RHYTHM,
            8'h64
        );

        // ========================================================
        // TEST 9
        // UART READ AGAIN
        //
        // This is intentionally last.
        // ========================================================
        $display("");
        $display("--- TEST 9: Read UART LSR AGAIN @ 0x40000014 ---");

        axi_read_uart(
            UART_LSR,
            8'h70,
            32'h0000_0060
        );

        // ========================================================
        // FINAL RESULT
        // ========================================================
        repeat (10) @(posedge clk);

        $display("");
        $display("============================================================");
        $display(" RESULT");
        $display("============================================================");
        $display(" PASSED = %0d", pass_count);
        $display(" FAILED = %0d", fail_count);

        if (fail_count == 0)
            $display(" UART + QRS + AXI 3x14 INTERCONNECT : PASS");
        else
            $display(" UART + QRS + AXI 3x14 INTERCONNECT : FAIL");

        $display("============================================================");

        #100;

        $finish;

    end

endmodule
