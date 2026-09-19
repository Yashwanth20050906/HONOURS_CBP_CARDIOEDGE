// =============================================================================
// aes_axi_slave_tb.sv
// AES-256 AXI4-Lite Slave Testbench
// =============================================================================

module aes_axi_slave_tb;

    // =========================================================================
    // Clock and Reset
    // =========================================================================

    logic clk;
    logic rst_n;

    initial clk = 1'b0;

    always #5 clk = ~clk;


    // =========================================================================
    // AXI4-Lite signals
    // =========================================================================

    logic [31:0] m_awaddr;
    logic        m_awvalid;
    logic        m_awready;

    logic [31:0] m_wdata;
    logic [3:0]  m_wstrb;
    logic        m_wvalid;
    logic        m_wready;

    logic [1:0]  m_bresp;
    logic        m_bvalid;
    logic        m_bready;

    logic [31:0] m_araddr;
    logic        m_arvalid;
    logic        m_arready;

    logic [31:0] m_rdata;
    logic [1:0]  m_rresp;
    logic        m_rvalid;
    logic        m_rready;


    // =========================================================================
    // DUT
    // =========================================================================

    aes_axi_slave #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(32)
    ) u_dut (
        .S_AXI_ACLK    (clk),
        .S_AXI_ARESETN (rst_n),

        .S_AXI_AWADDR  (m_awaddr),
        .S_AXI_AWVALID (m_awvalid),
        .S_AXI_AWREADY (m_awready),

        .S_AXI_WDATA   (m_wdata),
        .S_AXI_WSTRB   (m_wstrb),
        .S_AXI_WVALID  (m_wvalid),
        .S_AXI_WREADY  (m_wready),

        .S_AXI_BRESP   (m_bresp),
        .S_AXI_BVALID  (m_bvalid),
        .S_AXI_BREADY  (m_bready),

        .S_AXI_ARADDR  (m_araddr),
        .S_AXI_ARVALID (m_arvalid),
        .S_AXI_ARREADY (m_arready),

        .S_AXI_RDATA   (m_rdata),
        .S_AXI_RRESP   (m_rresp),
        .S_AXI_RVALID  (m_rvalid),
        .S_AXI_RREADY  (m_rready)
    );


    // =========================================================================
    // AXI WRITE TASK
    // =========================================================================

    task automatic axi_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );

        begin

            @(posedge clk);

            m_awaddr  <= addr;
            m_awvalid <= 1'b1;

            m_wdata   <= data;
            m_wstrb   <= 4'hF;
            m_wvalid  <= 1'b1;

            m_bready  <= 1'b1;

            @(posedge clk);

            while (!(m_awready && m_wready))
                @(posedge clk);

            m_awvalid <= 1'b0;
            m_wvalid  <= 1'b0;

            while (!m_bvalid)
                @(posedge clk);

            @(posedge clk);

            m_bready <= 1'b0;

        end

    endtask


    // =========================================================================
    // AXI READ TASK
    // =========================================================================

    task automatic axi_read(
        input  logic [31:0] addr,
        output logic [31:0] data
    );

        begin

            @(posedge clk);

            m_araddr  <= addr;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;

            @(posedge clk);

            while (!m_arready)
                @(posedge clk);

            m_arvalid <= 1'b0;

            while (!m_rvalid)
                @(posedge clk);

            data = m_rdata;

            @(posedge clk);

            m_rready <= 1'b0;

        end

    endtask


    // =========================================================================
    // WAIT FOR DONE
    //
    // CSR:
    // bit 0 = START
    // bit 1 = DECRYPT
    // bit 2 = DONE
    // bit 3 = BUSY
    // =========================================================================

    task automatic wait_done(
        output logic timeout_flag
    );

        logic [31:0] csr;
        integer iter;

        begin

            timeout_flag = 1'b0;
            iter = 0;

            do begin

                axi_read(32'h00, csr);

                iter = iter + 1;

                if (iter > 500) begin

                    $display("ERROR: Timeout waiting for DONE!");

                    timeout_flag = 1'b1;

                    return;

                end

            end while (!csr[2]);

        end

    endtask


    // =========================================================================
    // AES-256 TEST VECTORS
    // =========================================================================

    logic [255:0] tv_key    [0:2];
    logic [127:0] tv_plain  [0:2];
    logic [127:0] tv_cipher [0:2];


    // =========================================================================
    // Result tracking
    // =========================================================================

    logic test_pass [0:2];

    integer pass_count;
    integer fail_count;

    integer t;

    logic [31:0] rd_data;

    logic [127:0] result_cipher;
    logic [127:0] result_plain;

    logic timeout_f;


    // =========================================================================
    // MAIN TEST
    // =========================================================================

    initial begin

        // =====================================================================
        // Initialize AXI signals
        // =====================================================================

        m_awaddr  = 32'h00000000;
        m_awvalid = 1'b0;

        m_wdata   = 32'h00000000;
        m_wstrb   = 4'h0;
        m_wvalid  = 1'b0;

        m_bready  = 1'b0;

        m_araddr  = 32'h00000000;
        m_arvalid = 1'b0;

        m_rready  = 1'b0;


        pass_count = 0;
        fail_count = 0;

        for (t = 0; t < 3; t = t + 1)
            test_pass[t] = 1'b0;


        // =====================================================================
        // RESET
        // =====================================================================

        rst_n = 1'b0;

        repeat (10)
            @(posedge clk);

        rst_n = 1'b1;

        repeat (5)
            @(posedge clk);


        // =====================================================================
        // HEADER
        // =====================================================================

        $display("=============================================================");
        $display("  AES-256 AXI4-Lite Peripheral Testbench");
        $display("=============================================================");


        // =====================================================================
        // TEST VECTOR 1
        // =====================================================================

        tv_key[0] =
            256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;

        tv_plain[0] =
            128'h6bc1bee22e409f96e93d7e117393172a;

        tv_cipher[0] =
            128'hf3eed1bdb5d2a03c064b5a7e3db181f8;


        // =====================================================================
        // TEST VECTOR 2
        // =====================================================================

        tv_key[1] =
            256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;

        tv_plain[1] =
            128'hae2d8a571e03ac9c9eb76fac45af8e51;

        // CORRECT AES-256 CIPHERTEXT
        tv_cipher[1] =
            128'h591ccb10d410ed26dc5ba74a31362870;


        // =====================================================================
        // TEST VECTOR 3
        // =====================================================================

        tv_key[2] =
            256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;

        tv_plain[2] =
            128'h30c81c46a35ce411e5fbc1191a0a52ef;

        tv_cipher[2] =
            128'hb6ed21b99ca6f4f9f153e7b1beafed1d;


        // =====================================================================
        // RUN ALL THREE TESTS
        // =====================================================================

        for (t = 0; t < 3; t = t + 1) begin

            $display("-------------------------------------------------------------");
            $display("  AES-256 TEST %0d", t + 1);
            $display("-------------------------------------------------------------");

            $display("  Key:       %064x", tv_key[t]);
            $display("  Plaintext: %032x", tv_plain[t]);
            $display("  Expected:  %032x", tv_cipher[t]);


            // =================================================================
            // WRITE KEY
            // =================================================================

            axi_write(32'h04, tv_key[t][31:0]);
            axi_write(32'h08, tv_key[t][63:32]);
            axi_write(32'h0C, tv_key[t][95:64]);
            axi_write(32'h10, tv_key[t][127:96]);

            axi_write(32'h14, tv_key[t][159:128]);
            axi_write(32'h18, tv_key[t][191:160]);
            axi_write(32'h1C, tv_key[t][223:192]);
            axi_write(32'h20, tv_key[t][255:224]);


            // =================================================================
            // WRITE PLAINTEXT
            // =================================================================

            axi_write(32'h24, tv_plain[t][31:0]);
            axi_write(32'h28, tv_plain[t][63:32]);
            axi_write(32'h2C, tv_plain[t][95:64]);
            axi_write(32'h30, tv_plain[t][127:96]);


            // =================================================================
            // START ENCRYPTION
            // =================================================================

            axi_write(32'h00, 32'h00000001);


            // =================================================================
            // WAIT FOR ENCRYPTION
            // =================================================================

            wait_done(timeout_f);


            if (timeout_f) begin

                $display(
                    "  AES-256 TEST %0d ENCRYPT: TIMEOUT",
                    t + 1
                );

                fail_count = fail_count + 1;

                test_pass[t] = 1'b0;

                continue;

            end


            // =================================================================
            // READ CIPHERTEXT
            // =================================================================

            axi_read(32'h34, rd_data);
            result_cipher[31:0] = rd_data;

            axi_read(32'h38, rd_data);
            result_cipher[63:32] = rd_data;

            axi_read(32'h3C, rd_data);
            result_cipher[95:64] = rd_data;

            axi_read(32'h40, rd_data);
            result_cipher[127:96] = rd_data;


            $display(
                "  Got cipher:   %032x",
                result_cipher
            );


            // =================================================================
            // CHECK ENCRYPTION
            // =================================================================

            if (result_cipher === tv_cipher[t]) begin

                $display(
                    "  AES-256 TEST %0d ENCRYPT: PASS",
                    t + 1
                );

            end

            else begin

                $display(
                    "  AES-256 TEST %0d ENCRYPT: FAIL",
                    t + 1
                );

                $display(
                    "    Expected: %032x",
                    tv_cipher[t]
                );

                $display(
                    "    Got:      %032x",
                    result_cipher
                );

                fail_count = fail_count + 1;

                test_pass[t] = 1'b0;

                continue;

            end


            // =================================================================
            // WRITE CIPHERTEXT FOR DECRYPTION
            // =================================================================

            axi_write(32'h24, tv_cipher[t][31:0]);
            axi_write(32'h28, tv_cipher[t][63:32]);
            axi_write(32'h2C, tv_cipher[t][95:64]);
            axi_write(32'h30, tv_cipher[t][127:96]);


            // =================================================================
            // START DECRYPTION
            //
            // bit 0 = START
            // bit 1 = DECRYPT
            //
            // Therefore:
            // 00000003 = START + DECRYPT
            // =================================================================

            axi_write(32'h00, 32'h00000003);


            // =================================================================
            // WAIT FOR DECRYPTION
            // =================================================================

            wait_done(timeout_f);


            if (timeout_f) begin

                $display(
                    "  AES-256 TEST %0d DECRYPT: TIMEOUT",
                    t + 1
                );

                fail_count = fail_count + 1;

                test_pass[t] = 1'b0;

                continue;

            end


            // =================================================================
            // READ DECRYPTED PLAINTEXT
            // =================================================================

            axi_read(32'h34, rd_data);
            result_plain[31:0] = rd_data;

            axi_read(32'h38, rd_data);
            result_plain[63:32] = rd_data;

            axi_read(32'h3C, rd_data);
            result_plain[95:64] = rd_data;

            axi_read(32'h40, rd_data);
            result_plain[127:96] = rd_data;


            $display(
                "  Got plain:    %032x",
                result_plain
            );


            // =================================================================
            // CHECK DECRYPTION
            // =================================================================

            if (result_plain === tv_plain[t]) begin

                $display(
                    "  AES-256 TEST %0d DECRYPT: PASS",
                    t + 1
                );

                test_pass[t] = 1'b1;

                pass_count = pass_count + 1;

            end

            else begin

                $display(
                    "  AES-256 TEST %0d DECRYPT: FAIL",
                    t + 1
                );

                $display(
                    "    Expected: %032x",
                    tv_plain[t]
                );

                $display(
                    "    Got:      %032x",
                    result_plain
                );

                test_pass[t] = 1'b0;

                fail_count = fail_count + 1;

            end

        end


        // =====================================================================
        // FINAL REPORT
        // =====================================================================

        $display("=============================================================");

        if (test_pass[0])
            $display("  AES-256 TEST 1: PASS");
        else
            $display("  AES-256 TEST 1: FAIL");


        if (test_pass[1])
            $display("  AES-256 TEST 2: PASS");
        else
            $display("  AES-256 TEST 2: FAIL");


        if (test_pass[2])
            $display("  AES-256 TEST 3: PASS");
        else
            $display("  AES-256 TEST 3: FAIL");


        $display("=============================================================");


        if ((test_pass[0] == 1'b1) &&
            (test_pass[1] == 1'b1) &&
            (test_pass[2] == 1'b1)) begin

            $display("  AES-256 ALL TESTS PASSED");

        end

        else begin

            $display(
                "  AES-256 TEST FAILED (%0d/3 passed)",
                pass_count
            );

        end


        $display("=============================================================");


        // =====================================================================
        // END SIMULATION
        // =====================================================================

        $finish;

    end


    // =========================================================================
    // FSDB DUMP
    // =========================================================================

`ifdef FSDB_DUMP

    initial begin

        $fsdbDumpfile("aes256.fsdb");

        $fsdbDumpvars(
            0,
            aes_axi_slave_tb
        );

    end

`endif


    // =========================================================================
    // GLOBAL TIMEOUT
    // =========================================================================

    initial begin

        #2000000;

        $display(
            "GLOBAL TIMEOUT: simulation exceeded 2 ms"
        );

        $finish;

    end

endmodule
