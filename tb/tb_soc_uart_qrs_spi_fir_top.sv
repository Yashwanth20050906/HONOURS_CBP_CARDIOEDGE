`timescale 1ns/1ps

module tb_soc_uart_qrs_spi_fir_top;

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam ID_WIDTH   = 8;
    localparam STRB_WIDTH = 4;

    localparam FIR_BASE   = 32'h4000_3000;
    localparam FIR_CTRL   = 32'h4000_3000;
    localparam FIR_COMMIT = 32'h4000_3004;
    localparam FIR_STATUS = 32'h4000_3008;
    localparam FIR_COEFF0 = 32'h4000_3010;

    logic clk;
    logic rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    logic uart_rx_i;
    wire  uart_tx_o;
    logic spi_miso_i;
    wire  spi_clk_o;
    wire  spi_cs_n_o;
    wire  spi_mosi_o;

    // FIR AXI4-Stream
    logic        fir_s_axis_tvalid;
    wire         fir_s_axis_tready;
    logic [15:0] fir_s_axis_tdata;
    wire         fir_m_axis_tvalid;
    logic        fir_m_axis_tready;
    wire [39:0]  fir_m_axis_tdata;

    // AXI4 master input to the 3x14 interconnect
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

    logic [DATA_WIDTH-1:0] s00_axi_wdata;
    logic [STRB_WIDTH-1:0] s00_axi_wstrb;
    logic                  s00_axi_wlast;
    logic                  s00_axi_wuser;
    logic                  s00_axi_wvalid;
    wire                   s00_axi_wready;

    wire [ID_WIDTH-1:0]    s00_axi_bid;
    wire [1:0]             s00_axi_bresp;
    wire                   s00_axi_buser;
    wire                   s00_axi_bvalid;
    logic                  s00_axi_bready;

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

    wire [ID_WIDTH-1:0]    s00_axi_rid;
    wire [DATA_WIDTH-1:0]  s00_axi_rdata;
    wire [1:0]             s00_axi_rresp;
    wire                   s00_axi_rlast;
    wire                   s00_axi_ruser;
    wire                   s00_axi_rvalid;
    logic                  s00_axi_rready;

    integer errors;
    integer received;
    integer sent;
    integer i;
    integer j;
    reg signed [15:0] coeff [0:31];
    reg signed [15:0] delay_line [0:31];
    reg signed [39:0] expected [0:63];

    soc_uart_qrs_spi_fir_top dut (
        .clk(clk),
        .rst(rst),
        .uart_rx_i(uart_rx_i),
        .uart_tx_o(uart_tx_o),
        .spi_miso_i(spi_miso_i),
        .spi_clk_o(spi_clk_o),
        .spi_cs_n_o(spi_cs_n_o),
        .spi_mosi_o(spi_mosi_o),
        .fir_s_axis_tvalid(fir_s_axis_tvalid),
        .fir_s_axis_tready(fir_s_axis_tready),
        .fir_s_axis_tdata(fir_s_axis_tdata),
        .fir_m_axis_tvalid(fir_m_axis_tvalid),
        .fir_m_axis_tready(fir_m_axis_tready),
        .fir_m_axis_tdata(fir_m_axis_tdata),
        .s00_axi_awid(s00_axi_awid),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awlen(s00_axi_awlen),
        .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst),
        .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos),
        .s00_axi_awuser(s00_axi_awuser),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wuser(s00_axi_wuser),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bid(s00_axi_bid),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_buser(s00_axi_buser),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_arid(s00_axi_arid),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen),
        .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst),
        .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos),
        .s00_axi_aruser(s00_axi_aruser),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rid(s00_axi_rid),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast),
        .s00_axi_ruser(s00_axi_ruser),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
    );

    task automatic axi_write;
        input [31:0] addr;
        input [31:0] data;
        integer timeout;
        reg aw_done;
        reg w_done;
        begin
            aw_done = 1'b0;
            w_done  = 1'b0;
            timeout = 0;

            @(negedge clk);
            s00_axi_awid    = 8'h01;
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

            s00_axi_wdata   = data;
            s00_axi_wstrb   = 4'hF;
            s00_axi_wlast   = 1'b1;
            s00_axi_wuser   = 1'b0;
            s00_axi_wvalid  = 1'b1;
            s00_axi_bready  = 1'b1;

            while (!(aw_done && w_done)) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (!aw_done && s00_axi_awvalid && s00_axi_awready) begin
                    aw_done = 1'b1;
                    @(negedge clk);
                    s00_axi_awvalid = 1'b0;
                end
                if (!w_done && s00_axi_wvalid && s00_axi_wready) begin
                    w_done = 1'b1;
                    @(negedge clk);
                    s00_axi_wvalid = 1'b0;
                end
                if (timeout > 200) begin
                    $display("ERROR: AXI write timeout addr=0x%08h", addr);
                    errors = errors + 1;
                    s00_axi_awvalid = 1'b0;
                    s00_axi_wvalid  = 1'b0;
                    s00_axi_bready  = 1'b0;
                    disable axi_write;
                end
            end

            timeout = 0;
            while (!s00_axi_bvalid) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("ERROR: AXI B response timeout addr=0x%08h", addr);
                    errors = errors + 1;
                    s00_axi_bready = 1'b0;
                    disable axi_write;
                end
            end

            if (s00_axi_bresp !== 2'b00) begin
                $display("ERROR: FIR write BRESP=%b addr=0x%08h", s00_axi_bresp, addr);
                errors = errors + 1;
            end else begin
                $display("[FIR AXI WRITE] addr=0x%08h data=0x%08h PASS", addr, data);
            end

            @(negedge clk);
            s00_axi_bready = 1'b0;
        end
    endtask

    task automatic axi_read;
        input [31:0] addr;
        input [31:0] expected_data;
        integer timeout;
        begin
            timeout = 0;
            @(negedge clk);
            s00_axi_arid    = 8'h02;
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

            while (!s00_axi_arready) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("ERROR: AXI read address timeout addr=0x%08h", addr);
                    errors = errors + 1;
                    s00_axi_arvalid = 1'b0;
                    s00_axi_rready  = 1'b0;
                    disable axi_read;
                end
            end

            @(negedge clk);
            s00_axi_arvalid = 1'b0;

            timeout = 0;
            while (!s00_axi_rvalid) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 200) begin
                    $display("ERROR: AXI R response timeout addr=0x%08h", addr);
                    errors = errors + 1;
                    s00_axi_rready = 1'b0;
                    disable axi_read;
                end
            end

            if (s00_axi_rresp !== 2'b00 || s00_axi_rdata !== expected_data) begin
                $display("[FIR AXI READ ] addr=0x%08h got=0x%08h expected=0x%08h FAIL",
                         addr, s00_axi_rdata, expected_data);
                errors = errors + 1;
            end else begin
                $display("[FIR AXI READ ] addr=0x%08h data=0x%08h PASS", addr, s00_axi_rdata);
            end

            @(negedge clk);
            s00_axi_rready = 1'b0;
        end
    endtask

    task automatic send_sample;
        input signed [15:0] value;
        reg signed [39:0] sum;
        begin
            @(negedge clk);
            fir_s_axis_tdata  = value;
            fir_s_axis_tvalid = 1'b1;
            while (!fir_s_axis_tready)
                @(negedge clk);

            sum = $signed(value) * $signed(coeff[0]);
            for (j = 1; j < 32; j = j + 1)
                sum = sum + $signed(delay_line[j-1]) * $signed(coeff[j]);
            expected[sent] = sum;

            for (j = 31; j > 0; j = j - 1)
                delay_line[j] = delay_line[j-1];
            delay_line[0] = value;

            $display("[FIR STREAM TX] sample=%0d input=%0d expected=%0d", sent, value, sum);
            sent = sent + 1;

            @(negedge clk);
            fir_s_axis_tvalid = 1'b0;
        end
    endtask

    always @(posedge clk) begin
        if (fir_m_axis_tvalid && fir_m_axis_tready) begin
            $display("[FIR STREAM RX] sample=%0d got=%0d expected=%0d",
                     received, $signed(fir_m_axis_tdata), expected[received]);
            if ($signed(fir_m_axis_tdata) !== expected[received]) begin
                $display("    OUTPUT FAIL");
                errors = errors + 1;
            end else begin
                $display("    OUTPUT PASS");
            end
            received = received + 1;
        end
    end

    initial begin
        uart_rx_i = 1'b1;
        spi_miso_i = 1'b0;
        fir_s_axis_tvalid = 1'b0;
        fir_s_axis_tdata = 16'd0;
        fir_m_axis_tready = 1'b1;

        s00_axi_awid = 0;
        s00_axi_awaddr = 0;
        s00_axi_awlen = 0;
        s00_axi_awsize = 3'b010;
        s00_axi_awburst = 2'b01;
        s00_axi_awlock = 0;
        s00_axi_awcache = 0;
        s00_axi_awprot = 0;
        s00_axi_awqos = 0;
        s00_axi_awuser = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata = 0;
        s00_axi_wstrb = 4'hF;
        s00_axi_wlast = 1;
        s00_axi_wuser = 0;
        s00_axi_wvalid = 0;
        s00_axi_bready = 0;
        s00_axi_arid = 0;
        s00_axi_araddr = 0;
        s00_axi_arlen = 0;
        s00_axi_arsize = 3'b010;
        s00_axi_arburst = 2'b01;
        s00_axi_arlock = 0;
        s00_axi_arcache = 0;
        s00_axi_arprot = 0;
        s00_axi_arqos = 0;
        s00_axi_aruser = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready = 0;

        errors = 0;
        sent = 0;
        received = 0;

        for (i = 0; i < 32; i = i + 1) begin
            coeff[i] = (i % 5) - 2;
            delay_line[i] = 0;
        end

        $display("============================================================");
        $display(" CARDIOEDGE FIR INTERCONNECT INTEGRATION TEST");
        $display(" M03 FIR BASE = 0x40003000");
        $display("============================================================");

        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        $display("\nTEST 1: FIR COEFFICIENT WRITE THROUGH AXI 3x14 M03");
        for (i = 0; i < 32; i = i + 1)
            axi_write(FIR_COEFF0 + i*4, {{16{coeff[i][15]}}, coeff[i]});

        $display("\nTEST 2: FIR COEFFICIENT READBACK THROUGH M03");
        for (i = 0; i < 32; i = i + 1)
            axi_read(FIR_COEFF0 + i*4, {16'b0, coeff[i]});

        $display("\nTEST 3: FIR COMMIT THROUGH M03");
        axi_write(FIR_COMMIT, 32'h00000001);

        $display("\nTEST 4: FIR ENABLE THROUGH M03");
        axi_write(FIR_CTRL, 32'h00000001);

        $display("\nTEST 5: FIR AXI4-STREAM DATA PATH");
        for (i = 0; i < 20; i = i + 1)
            send_sample((i % 19) - 9);

        while (received < 20)
            @(posedge clk);

        $display("\n============================================================");
        $display(" FIR INTEGRATION TEST SUMMARY");
        $display(" Samples sent     : %0d", sent);
        $display(" Samples received : %0d", received);
        $display(" Errors           : %0d", errors);
        $display("============================================================");

        if (errors == 0 && received == 20)
            $display("FIR AXI 3x14 INTEGRATION TEST PASSED");
        else
            $display("FIR AXI 3x14 INTEGRATION TEST FAILED");

        #100;
        $finish;
    end

endmodule
