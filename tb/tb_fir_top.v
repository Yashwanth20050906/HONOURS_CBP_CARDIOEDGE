`timescale 1ns/1ps

module tb_fir_top;

    localparam DATA_WIDTH  = 16;
    localparam COEFF_WIDTH = 16;
    localparam ACC_WIDTH   = 40;
    localparam NUM_TAPS    = 32;
    localparam FIFO_DEPTH  = 8;
    localparam NUM_SAMPLES = 80;

    reg clk = 0;
    reg rst_n = 0;

    always #5 clk = ~clk;

    // ============================================================
    // AXI4-STREAM INPUT
    // ============================================================
    reg         s_axis_tvalid;
    wire        s_axis_tready;
    reg  [15:0] s_axis_tdata;

    // ============================================================
    // AXI4-STREAM OUTPUT
    // ============================================================
    wire        m_axis_tvalid;
    reg         m_axis_tready;
    wire [39:0] m_axis_tdata;

    // ============================================================
    // AXI4-LITE WRITE CHANNEL
    // ============================================================
    reg  [31:0] s_axi_awaddr;
    reg         s_axi_awvalid;
    wire        s_axi_awready;

    reg  [31:0] s_axi_wdata;
    reg  [3:0]  s_axi_wstrb;
    reg         s_axi_wvalid;
    wire        s_axi_wready;

    wire        s_axi_bvalid;
    wire [1:0]  s_axi_bresp;
    reg         s_axi_bready;

    // ============================================================
    // AXI4-LITE READ CHANNEL
    // ============================================================
    reg  [31:0] s_axi_araddr;
    reg         s_axi_arvalid;
    wire        s_axi_arready;

    wire [31:0] s_axi_rdata;
    wire        s_axi_rvalid;
    wire [1:0]  s_axi_rresp;
    reg         s_axi_rready;

    // ============================================================
    // FIFO STATUS
    // ============================================================
    wire input_fifo_full;
    wire input_fifo_empty;
    wire output_fifo_empty;

    // ============================================================
    // REFERENCE MODEL
    // ============================================================
    reg signed [15:0] ref_delay [0:31];
    reg signed [15:0] ref_coeff [0:31];
    reg signed [39:0] expected [0:NUM_SAMPLES-1];

    integer sent;
    integer received;
    integer errors;
    integer cycles;
    integer i;

    reg random_ready_enable;

    // ============================================================
    // DUT
    // ============================================================
    fir_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH),
        .NUM_TAPS   (NUM_TAPS),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),

        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tdata(s_axis_tdata),

        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rready(s_axi_rready),

        .input_fifo_full(input_fifo_full),
        .input_fifo_empty(input_fifo_empty),
        .output_fifo_empty(output_fifo_empty)
    );

    // ============================================================
    // AXI4-LITE WRITE TASK
    // ============================================================
    task axi_write;
        input [31:0] addr;
        input [31:0] data;

        begin
            @(negedge clk);

            s_axi_awaddr  = addr;
            s_axi_awvalid = 1'b1;

            s_axi_wdata   = data;
            s_axi_wstrb   = 4'hF;
            s_axi_wvalid  = 1'b1;

            while (!(s_axi_awready && s_axi_wready))
                @(negedge clk);

            $display("[%0t ns] AXI WRITE  addr=0x%08h data=0x%08h",
                     $time, addr, data);

            @(negedge clk);

            s_axi_awvalid = 1'b0;
            s_axi_wvalid  = 1'b0;
            s_axi_bready  = 1'b1;

            while (!s_axi_bvalid)
                @(negedge clk);

            if (s_axi_bresp != 2'b00) begin
                $display("[%0t ns] AXI WRITE ERROR: BRESP=%b",
                         $time, s_axi_bresp);
                errors = errors + 1;
            end
            else begin
                $display("[%0t ns] AXI WRITE RESPONSE OK",
                         $time);
            end

            @(negedge clk);
            s_axi_bready = 1'b0;
        end
    endtask

    // ============================================================
    // AXI4-LITE READ TASK
    // ============================================================
    task axi_read_check;
        input [31:0] addr;
        input [31:0] expected_data;

        begin
            @(negedge clk);

            s_axi_araddr  = addr;
            s_axi_arvalid = 1'b1;
            s_axi_rready  = 1'b1;

            while (!s_axi_arready)
                @(negedge clk);

            @(negedge clk);

            s_axi_arvalid = 1'b0;

            while (!s_axi_rvalid)
                @(negedge clk);

            $display("[%0t ns] AXI READ   addr=0x%08h got=0x%08h expected=0x%08h",
                     $time, addr, s_axi_rdata, expected_data);

            if (s_axi_rdata !== expected_data ||
                s_axi_rresp != 2'b00) begin

                $display("[%0t ns] AXI READ ERROR",
                         $time);

                errors = errors + 1;
            end
            else begin
                $display("[%0t ns] AXI READ CHECK PASSED",
                         $time);
            end

            @(negedge clk);
            s_axi_rready = 1'b0;
        end
    endtask

    // ============================================================
    // SEND SAMPLE TASK
    // ============================================================
    task send_sample;
        input signed [15:0] value;

        integer j;
        reg signed [39:0] sum;

        begin
            @(negedge clk);

            s_axis_tdata  = value;
            s_axis_tvalid = 1'b1;

            while (!s_axis_tready)
                @(negedge clk);

            // Reference FIR calculation
            sum = $signed(value) * $signed(ref_coeff[0]);

            for (j = 1; j < NUM_TAPS; j = j + 1)
                sum = sum +
                      $signed(ref_delay[j-1]) *
                      $signed(ref_coeff[j]);

            expected[sent] = sum;

            // Shift delay line
            for (j = NUM_TAPS-1; j > 0; j = j - 1)
                ref_delay[j] = ref_delay[j-1];

            ref_delay[0] = value;

            $display("[%0t ns] SAMPLE %0d  INPUT=%0d  EXPECTED_OUTPUT=%0d",
                     $time, sent, value, sum);

            sent = sent + 1;

            @(negedge clk);

            s_axis_tvalid = 1'b0;
        end
    endtask

    // ============================================================
    // RANDOM OUTPUT READY
    // ============================================================
    always @(negedge clk) begin

        if (!rst_n)
            m_axis_tready <= 1'b0;

        else if (random_ready_enable)
            m_axis_tready <= ($urandom_range(0,3) != 0);

    end

    // ============================================================
    // OUTPUT MONITOR
    // ============================================================
    always @(posedge clk) begin

        if (rst_n &&
            m_axis_tvalid &&
            m_axis_tready) begin

            $display("[%0t ns] OUTPUT %0d  GOT=%0d  EXPECTED=%0d",
                     $time,
                     received,
                     $signed(m_axis_tdata),
                     expected[received]);

            if ($signed(m_axis_tdata) !== expected[received]) begin

                $display("             *** OUTPUT ERROR ***");

                errors = errors + 1;
            end
            else begin

                $display("             OUTPUT CHECK PASSED");

            end

            received = received + 1;

        end
    end

    // ============================================================
    // FIFO STATUS MONITOR
    // ============================================================
    always @(posedge clk) begin

        if (rst_n && (input_fifo_full || input_fifo_empty)) begin

            $display("[%0t ns] FIFO STATUS: INPUT_FULL=%b INPUT_EMPTY=%b OUTPUT_EMPTY=%b",
                     $time,
                     input_fifo_full,
                     input_fifo_empty,
                     output_fifo_empty);

        end

    end

    // ============================================================
    // MAIN TEST
    // ============================================================
    initial begin

        // --------------------------------------------------------
        // INITIALIZATION
        // --------------------------------------------------------
        s_axis_tvalid = 1'b0;
        s_axis_tdata  = 16'd0;

        m_axis_tready = 1'b0;

        s_axi_awaddr  = 32'd0;
        s_axi_awvalid = 1'b0;

        s_axi_wdata   = 32'd0;
        s_axi_wstrb   = 4'd0;
        s_axi_wvalid  = 1'b0;

        s_axi_bready  = 1'b0;

        s_axi_araddr  = 32'd0;
        s_axi_arvalid = 1'b0;
        s_axi_rready  = 1'b0;

        sent    = 0;
        received = 0;
        errors  = 0;
        cycles  = 0;

        random_ready_enable = 1'b0;

        // --------------------------------------------------------
        // INITIALIZE REFERENCE COEFFICIENTS
        // --------------------------------------------------------
        for (i = 0; i < NUM_TAPS; i = i + 1) begin

            ref_delay[i] = 0;
            ref_coeff[i] = (i % 5) - 2;

        end

        // --------------------------------------------------------
        // TEST START
        // --------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("          FIR FILTER STANDALONE VERIFICATION");
        $display("============================================================");
        $display("DATA WIDTH   : %0d", DATA_WIDTH);
        $display("COEFF WIDTH  : %0d", COEFF_WIDTH);
        $display("ACC WIDTH    : %0d", ACC_WIDTH);
        $display("NUMBER TAPS  : %0d", NUM_TAPS);
        $display("FIFO DEPTH   : %0d", FIFO_DEPTH);
        $display("SAMPLES      : %0d", NUM_SAMPLES);
        $display("============================================================");
        $display("");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------
        $display("[%0t ns] Applying reset...", $time);

        repeat (4)
            @(posedge clk);

        rst_n = 1'b1;

        $display("[%0t ns] Reset released.", $time);

        repeat (2)
            @(posedge clk);

        // --------------------------------------------------------
        // CHECK RESET/IDLE CONDITION
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 1: RESET / IDLE CHECK");
        $display("------------------------------------------------------------");

        if (s_axis_tready !== 0) begin

            $display("[%0t ns] ERROR: AXI-Stream READY high while disabled",
                     $time);

            errors = errors + 1;

        end
        else begin

            $display("[%0t ns] RESET / IDLE CHECK PASSED",
                     $time);

        end

        // --------------------------------------------------------
        // WRITE FIR COEFFICIENTS
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 2: AXI4-LITE COEFFICIENT WRITE");
        $display("------------------------------------------------------------");

        for (i = 0; i < NUM_TAPS; i = i + 1) begin

            axi_write(
                32'h10 + i*4,
                {{16{ref_coeff[i][15]}}, ref_coeff[i]}
            );

        end

        $display("[%0t ns] All %0d coefficients written.",
                 $time, NUM_TAPS);

        // --------------------------------------------------------
        // READ BACK COEFFICIENTS
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 3: AXI4-LITE COEFFICIENT READBACK");
        $display("------------------------------------------------------------");

        for (i = 0; i < NUM_TAPS; i = i + 1) begin

            axi_read_check(
                32'h10 + i*4,
                {16'b0, ref_coeff[i]}
            );

        end

        $display("[%0t ns] Coefficient readback completed.",
                 $time);

        // --------------------------------------------------------
        // COMMIT COEFFICIENTS
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 4: COEFFICIENT COMMIT");
        $display("------------------------------------------------------------");

        axi_write(32'h04, 32'h00000001);

        $display("[%0t ns] Coefficients committed to active bank.",
                 $time);

        // --------------------------------------------------------
        // SHADOW REGISTER TEST
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 5: SHADOW COEFFICIENT WRITE");
        $display("------------------------------------------------------------");

        axi_write(32'h10, 32'h00007FFF);

        $display("[%0t ns] Shadow coefficient write completed.",
                 $time);

        $display("[%0t ns] Active coefficient set remains unchanged.",
                 $time);

        // --------------------------------------------------------
        // START FIR
        // --------------------------------------------------------
        $display("");
        $display("------------------------------------------------------------");
        $display("TEST 6: FIR PROCESSING");
        $display("------------------------------------------------------------");

        axi_write(32'h00, 32'h00000001);

        $display("[%0t ns] FIR processing enabled.",
                 $time);

        random_ready_enable = 1'b1;

        // --------------------------------------------------------
        // SEND INPUT SAMPLES
        // --------------------------------------------------------
        $display("");
        $display("Sending %0d input samples...", NUM_SAMPLES);
        $display("");

        for (i = 0; i < NUM_SAMPLES; i = i + 1)
            send_sample((i % 19) - 9);

        $display("");
        $display("[%0t ns] All %0d samples transmitted.",
                 $time, NUM_SAMPLES);

        // --------------------------------------------------------
        // WAIT FOR ALL OUTPUTS
        // --------------------------------------------------------
        $display("");
        $display("Waiting for FIR outputs...");

        cycles = 0;

        while (received < NUM_SAMPLES &&
               cycles < 5000) begin

            @(posedge clk);
            cycles = cycles + 1;

        end

        // --------------------------------------------------------
        // RESULT
        // --------------------------------------------------------
        $display("");
        $display("============================================================");
        $display("                    TEST SUMMARY");
        $display("============================================================");

        $display("Input samples sent     : %0d", sent);
        $display("Output samples received: %0d", received);
        $display("Total errors           : %0d", errors);
        $display("Simulation wait cycles : %0d", cycles);

        if (received != NUM_SAMPLES) begin

            $display("");
            $display("TIMEOUT: received %0d of %0d samples.",
                     received, NUM_SAMPLES);

            errors = errors + 1;

        end

        $display("");

        if (errors == 0) begin

            $display("****************************************************");
            $display("*                                                  *");
            $display("*        FIR TOP-LEVEL TEST PASSED                *");
            $display("*                                                  *");
            $display("****************************************************");

        end
        else begin

            $display("****************************************************");
            $display("*                                                  *");
            $display("*        FIR TOP-LEVEL TEST FAILED                 *");
            $display("*                                                  *");
            $display("*        Errors = %0d                              *", errors);
            $display("*                                                  *");
            $display("****************************************************");

        end

        $display("");
        $display("FIR standalone verification completed.");
        $display("");

        $finish;

    end

endmodule
