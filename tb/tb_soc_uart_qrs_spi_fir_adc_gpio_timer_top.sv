`timescale 1ns/1ps

module tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top;

    localparam int DATA_WIDTH = 32;
    localparam int ADDR_WIDTH = 32;
    localparam int ID_WIDTH   = 8;
    localparam int STRB_WIDTH = 4;

    // ============================================================
    // ADC ADDRESS MAP
    // ============================================================
    localparam logic [31:0] ADC_BASE   = 32'h4000_4000;
    localparam logic [31:0] ADC_CTRL   = ADC_BASE + 32'h0000;
    localparam logic [31:0] ADC_STATUS = ADC_BASE + 32'h0004;
    localparam logic [31:0] ADC_SAMPLE = ADC_BASE + 32'h0008;
    localparam logic [31:0] ADC_FIFO   = ADC_BASE + 32'h000C;
    localparam logic [31:0] ADC_IRQ_EN = ADC_BASE + 32'h0010;

    // ============================================================
    // GPIO ADDRESS MAP - M05
    // ============================================================
    localparam logic [31:0] GPIO_BASE   = 32'h4000_5000;
    localparam logic [31:0] GPIO_DATA_I = GPIO_BASE + 32'h0000;
    localparam logic [31:0] GPIO_DATA_O = GPIO_BASE + 32'h0004;
    localparam logic [31:0] GPIO_DIR    = GPIO_BASE + 32'h0008;
    localparam logic [31:0] GPIO_SET_O  = GPIO_BASE + 32'h0020;
    localparam logic [31:0] GPIO_CLR_O  = GPIO_BASE + 32'h0024;
    localparam logic [31:0] GPIO_TGL_O  = GPIO_BASE + 32'h0028;

    // ============================================================
    // TIMER ADDRESS MAP - M06
    // ============================================================
    localparam logic [31:0] TIMER_BASE   = 32'h4000_6000;
    localparam logic [31:0] TIMER_CTRL   = TIMER_BASE + 32'h0000;
    localparam logic [31:0] TIMER_LOAD   = TIMER_BASE + 32'h0004;
    localparam logic [31:0] TIMER_VAL    = TIMER_BASE + 32'h0008;
    localparam logic [31:0] TIMER_PRE    = TIMER_BASE + 32'h000C;
    localparam logic [31:0] TIMER_INT_EN = TIMER_BASE + 32'h0010;
    localparam logic [31:0] TIMER_INT_STS= TIMER_BASE + 32'h0014;
    localparam logic [31:0] TIMER_CMP    = TIMER_BASE + 32'h0018;

    logic clk;
    logic rst;

    // ============================================================
    // UART
    // ============================================================
    logic uart_rx_i;
    wire  uart_tx_o;

    // ============================================================
    // SPI
    // ============================================================
    logic spi_miso_i;
    wire  spi_clk_o;
    wire  spi_cs_n_o;
    wire  spi_mosi_o;

    // ============================================================
    // FIR STREAM
    // ============================================================
    logic        fir_s_axis_tvalid;
    wire         fir_s_axis_tready;
    logic [15:0] fir_s_axis_tdata;

    wire         fir_m_axis_tvalid;
    logic        fir_m_axis_tready;
    wire [39:0]  fir_m_axis_tdata;

    // ============================================================
    // ADC
    // ============================================================
    logic [11:0] adc_sample_in;
    logic        adc_sample_valid;

    wire adc_irq_sample;
    wire adc_irq_overrun;

    // ============================================================
    // GPIO
    // ============================================================
    tri  [7:0] gpio_io;
    logic [7:0] gpio_drive;
    logic       gpio_drive_en;
    wire        gpio_irq;

    assign gpio_io = gpio_drive_en ? gpio_drive : 8'hZZ;

    // ============================================================
    // TIMER
    // ============================================================
    logic timer_ext_meas_i;
    logic timer_capture_i;
    wire  timer_pwm_o;
    wire  timer_trigger_o;
    wire  timer_irq;

    // ============================================================
    // AXI4 MASTER -> S00
    // ============================================================

    // -------------------------
    // Write address channel
    // -------------------------
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

    // -------------------------
    // Write data channel
    // -------------------------
    logic [DATA_WIDTH-1:0] s00_axi_wdata;
    logic [STRB_WIDTH-1:0] s00_axi_wstrb;
    logic                  s00_axi_wlast;
    logic                  s00_axi_wuser;
    logic                  s00_axi_wvalid;
    wire                   s00_axi_wready;

    // -------------------------
    // Write response channel
    // -------------------------
    wire [ID_WIDTH-1:0]    s00_axi_bid;
    wire [1:0]             s00_axi_bresp;
    wire                   s00_axi_buser;
    wire                   s00_axi_bvalid;
    logic                  s00_axi_bready;

    // -------------------------
    // Read address channel
    // -------------------------
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

    // -------------------------
    // Read data channel
    // -------------------------
    wire [ID_WIDTH-1:0]    s00_axi_rid;
    wire [DATA_WIDTH-1:0]  s00_axi_rdata;
    wire [1:0]             s00_axi_rresp;
    wire                   s00_axi_rlast;
    wire                   s00_axi_ruser;
    wire                   s00_axi_rvalid;
    logic                  s00_axi_rready;

    integer errors;

    // ============================================================
    // DUT
    // ============================================================

    soc_uart_qrs_spi_fir_adc_gpio_timer_top dut (
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

        .adc_sample_in(adc_sample_in),
        .adc_sample_valid(adc_sample_valid),
        .adc_irq_sample(adc_irq_sample),
        .adc_irq_overrun(adc_irq_overrun),

        .gpio_io(gpio_io),
        .gpio_irq(gpio_irq),

        .timer_ext_meas_i(timer_ext_meas_i),
        .timer_capture_i(timer_capture_i),
        .timer_pwm_o(timer_pwm_o),
        .timer_trigger_o(timer_trigger_o),
        .timer_irq(timer_irq),

        // AXI WRITE ADDRESS
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

        // AXI WRITE DATA
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wuser(s00_axi_wuser),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),

        // AXI WRITE RESPONSE
        .s00_axi_bid(s00_axi_bid),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_buser(s00_axi_buser),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),

        // AXI READ ADDRESS
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

        // AXI READ DATA
        .s00_axi_rid(s00_axi_rid),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast),
        .s00_axi_ruser(s00_axi_ruser),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // AXI WRITE TASK
    // ============================================================

    task automatic axi_write(
        input logic [31:0] addr,
        input logic [31:0] data
    );

        integer timeout;
        logic aw_done;
        logic w_done;

        begin

            aw_done = 1'b0;
            w_done  = 1'b0;
            timeout = 0;

            // --------------------------------------------
            // Drive AW and W
            // --------------------------------------------

            @(negedge clk);

            s00_axi_awid    = 8'h01;
            s00_axi_awaddr  = addr;
            s00_axi_awlen   = 8'd0;
            s00_axi_awsize  = 3'b010;
            s00_axi_awburst = 2'b01;
            s00_axi_awlock  = 1'b0;
            s00_axi_awcache = 4'b0000;
            s00_axi_awprot  = 3'b000;
            s00_axi_awqos   = 4'b0000;
            s00_axi_awuser  = 1'b0;
            s00_axi_awvalid = 1'b1;

            s00_axi_wdata   = data;
            s00_axi_wstrb   = 4'hF;
            s00_axi_wlast   = 1'b1;
            s00_axi_wuser   = 1'b0;
            s00_axi_wvalid  = 1'b1;

            // BREADY can remain asserted while waiting
            s00_axi_bready  = 1'b1;

            // --------------------------------------------
            // Wait for AW and W independently
            // --------------------------------------------

            while (!(aw_done && w_done)) begin

                @(posedge clk);

                timeout = timeout + 1;

                // AW handshake
                if (!aw_done &&
                    s00_axi_awvalid &&
                    s00_axi_awready) begin

                    aw_done = 1'b1;

                    @(negedge clk);
                    s00_axi_awvalid = 1'b0;

                    $display(
                        "[ADC AXI] AW handshake addr=%08h",
                        addr
                    );
                end

                // W handshake
                if (!w_done &&
                    s00_axi_wvalid &&
                    s00_axi_wready) begin

                    w_done = 1'b1;

                    @(negedge clk);
                    s00_axi_wvalid = 1'b0;

                    $display(
                        "[ADC AXI] W handshake data=%08h",
                        data
                    );
                end

                // ----------------------------------------
                // Timeout
                // ----------------------------------------

                if (timeout > 200) begin

                    $display(
                        "\nERROR: AXI WRITE CHANNEL TIMEOUT"
                    );

                    $display(
                        "addr=0x%08h data=0x%08h",
                        addr,
                        data
                    );

                    $display(
                        "AWVALID=%b AWREADY=%b",
                        s00_axi_awvalid,
                        s00_axi_awready
                    );

                    $display(
                        "WVALID=%b WREADY=%b",
                        s00_axi_wvalid,
                        s00_axi_wready
                    );

                    errors = errors + 1;

                    s00_axi_awvalid = 1'b0;
                    s00_axi_wvalid  = 1'b0;
                    s00_axi_bready  = 1'b0;

                    return;
                end

            end

            // --------------------------------------------
            // Wait for B response
            // --------------------------------------------

            timeout = 0;

            while (!s00_axi_bvalid) begin

                @(posedge clk);

                timeout = timeout + 1;

                if (timeout > 200) begin

                    $display(
                        "\nERROR: AXI WRITE RESPONSE TIMEOUT"
                    );

                    $display(
                        "addr=0x%08h data=0x%08h",
                        addr,
                        data
                    );

                    $display(
                        "BVALID=%b BREADY=%b BRESP=%b",
                        s00_axi_bvalid,
                        s00_axi_bready,
                        s00_axi_bresp
                    );

                    errors = errors + 1;

                    s00_axi_bready = 1'b0;

                    return;
                end

            end

            // --------------------------------------------
            // Check BRESP
            // --------------------------------------------

            if (s00_axi_bresp !== 2'b00) begin

                $display(
                    "[ADC WRITE] addr=%08h data=%08h BRESP=%b FAIL",
                    addr,
                    data,
                    s00_axi_bresp
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "[ADC WRITE] addr=%08h data=%08h PASS",
                    addr,
                    data
                );

            end

            @(negedge clk);

            s00_axi_bready = 1'b0;

        end

    endtask

    // ============================================================
    // AXI READ TASK
    // ============================================================

    task automatic axi_read(
        input  logic [31:0] addr,
        output logic [31:0] data
    );

        integer timeout;

        begin

            data = 32'hXXXXXXXX;
            timeout = 0;

            // --------------------------------------------
            // Drive AR
            // --------------------------------------------

            @(negedge clk);

            s00_axi_arid    = 8'h02;
            s00_axi_araddr  = addr;
            s00_axi_arlen   = 8'd0;
            s00_axi_arsize  = 3'b010;
            s00_axi_arburst = 2'b01;
            s00_axi_arlock  = 1'b0;
            s00_axi_arcache = 4'b0000;
            s00_axi_arprot  = 3'b000;
            s00_axi_arqos   = 4'b0000;
            s00_axi_aruser  = 1'b0;
            s00_axi_arvalid = 1'b1;

            // --------------------------------------------
            // Wait for ARREADY
            // --------------------------------------------

            while (!s00_axi_arready) begin

                @(posedge clk);

                timeout = timeout + 1;

                if (timeout > 200) begin

                    $display(
                        "\nERROR: AXI READ ADDRESS TIMEOUT addr=%08h",
                        addr
                    );

                    $display(
                        "ARVALID=%b ARREADY=%b",
                        s00_axi_arvalid,
                        s00_axi_arready
                    );

                    errors = errors + 1;

                    s00_axi_arvalid = 1'b0;

                    return;
                end

            end

            @(negedge clk);

            s00_axi_arvalid = 1'b0;

            // --------------------------------------------
            // Wait for RVALID
            // --------------------------------------------

            s00_axi_rready = 1'b1;

            timeout = 0;

            while (!s00_axi_rvalid) begin

                @(posedge clk);

                timeout = timeout + 1;

                if (timeout > 200) begin

                    $display(
                        "\nERROR: AXI READ RESPONSE TIMEOUT addr=%08h",
                        addr
                    );

                    $display(
                        "RVALID=%b RREADY=%b",
                        s00_axi_rvalid,
                        s00_axi_rready
                    );

                    errors = errors + 1;

                    s00_axi_rready = 1'b0;

                    return;
                end

            end

            // --------------------------------------------
            // Capture data
            // --------------------------------------------

            data = s00_axi_rdata;

            if (s00_axi_rresp !== 2'b00) begin

                $display(
                    "[ADC READ] addr=%08h RRESP=%b FAIL",
                    addr,
                    s00_axi_rresp
                );

                errors = errors + 1;

            end

            @(negedge clk);

            s00_axi_rready = 1'b0;

        end

    endtask

    // ============================================================
    // EXPECTED READ
    // ============================================================

    task automatic expect_read(
        input logic [31:0] addr,
        input logic [31:0] expected
    );

        logic [31:0] got;

        begin

            axi_read(addr, got);

            if (got !== expected) begin

                $display(
                    "[ADC CHECK] addr=%08h expected=%08h got=%08h FAIL",
                    addr,
                    expected,
                    got
                );

                errors = errors + 1;

            end
            else begin

                $display(
                    "[ADC CHECK] addr=%08h data=%08h PASS",
                    addr,
                    got
                );

            end

        end

    endtask

    // ============================================================
    // ADC SAMPLE CAPTURE
    // ============================================================

    task automatic capture_sample(
        input logic [11:0] sample
    );

        integer timeout;

        begin

            timeout = 0;

            // Wait until ADC acquisition is busy
            while (!dut.u_adc.acq_busy) begin

                @(posedge clk);

                timeout = timeout + 1;

                if (timeout > 200) begin

                    $display(
                        "[ADC SAMPLE] ERROR: acquisition did not start"
                    );

                    errors = errors + 1;

                    return;
                end

            end

            // --------------------------------------------
            // Apply sample
            // --------------------------------------------

            @(negedge clk);

            adc_sample_in    = sample;
            adc_sample_valid = 1'b1;

            @(negedge clk);

            adc_sample_valid = 1'b0;

            // --------------------------------------------
            // Wait until acquisition finishes
            // --------------------------------------------

            timeout = 0;

            while (dut.u_adc.acq_busy) begin

                @(posedge clk);

                timeout = timeout + 1;

                if (timeout > 100) begin

                    $display(
                        "[ADC SAMPLE] ERROR: acquisition did not complete"
                    );

                    errors = errors + 1;

                    return;
                end

            end

            $display(
                "[ADC SAMPLE] sample=%03h CAPTURE COMPLETE",
                sample
            );

        end

    endtask

    // ============================================================
    // INITIALIZATION
    // ============================================================

    initial begin

        errors = 0;

        // --------------------------------------------
        // External signals
        // --------------------------------------------

        uart_rx_i = 1'b1;

        spi_miso_i = 1'b0;

        fir_s_axis_tvalid = 1'b0;
        fir_s_axis_tdata  = 16'h0000;
        fir_m_axis_tready = 1'b1;

        adc_sample_in    = 12'h000;
        adc_sample_valid = 1'b0;

        gpio_drive       = 8'h00;
        gpio_drive_en    = 1'b0;

        timer_ext_meas_i = 1'b0;
        timer_capture_i  = 1'b0;

        // --------------------------------------------
        // AXI defaults
        // --------------------------------------------

        s00_axi_awid    = 0;
        s00_axi_awaddr  = 0;
        s00_axi_awlen   = 0;
        s00_axi_awsize  = 0;
        s00_axi_awburst = 0;
        s00_axi_awlock  = 0;
        s00_axi_awcache = 0;
        s00_axi_awprot  = 0;
        s00_axi_awqos   = 0;
        s00_axi_awuser  = 0;
        s00_axi_awvalid = 0;

        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 0;
        s00_axi_wlast   = 0;
        s00_axi_wuser   = 0;
        s00_axi_wvalid  = 0;

        s00_axi_bready  = 0;

        s00_axi_arid    = 0;
        s00_axi_araddr  = 0;
        s00_axi_arlen   = 0;
        s00_axi_arsize  = 0;
        s00_axi_arburst = 0;
        s00_axi_arlock  = 0;
        s00_axi_arcache = 0;
        s00_axi_arprot  = 0;
        s00_axi_arqos   = 0;
        s00_axi_aruser  = 0;
        s00_axi_arvalid = 0;

        s00_axi_rready  = 0;

        // --------------------------------------------
        // Reset
        // --------------------------------------------

        rst = 1'b1;

        repeat (5)
            @(posedge clk);

        rst = 1'b0;

        repeat (5)
            @(posedge clk);

        // ========================================================
        // TEST HEADER
        // ========================================================

        $display("");
        $display("==============================================");
        $display("ADC INTEGRATION TEST - M04 / AXI4-LITE");
        $display("==============================================");

        // ========================================================
        // TEST 1
        // ========================================================

        $display("");
        $display("TEST 1: RESET STATUS");

        expect_read(
            ADC_STATUS,
            32'h0000_0004
        );

        // ========================================================
        // TEST 2
        // ========================================================

        $display("");
        $display("TEST 2: ENABLE + SOFTWARE START");

        // ENABLE = 1
        axi_write(
            ADC_CTRL,
            32'h0000_0001
        );

        // ENABLE + START pulse
        axi_write(
            ADC_CTRL,
            32'h0000_0003
        );

        // ========================================================
        // TEST 3
        // ========================================================

        $display("");
        $display("TEST 3: SAMPLE CAPTURE");

        capture_sample(12'hA55);

        expect_read(
            ADC_SAMPLE,
            32'h0000_0A55
        );

        // ========================================================
        // TEST 4
        // ========================================================

        $display("");
        $display("TEST 4: FIFO READ");

        expect_read(
            ADC_FIFO,
            32'h0000_0A55
        );

        // ========================================================
        // TEST 5
        // ========================================================

        $display("");
        $display("TEST 5: SAMPLE IRQ");

        // Clear sticky DONE
        axi_write(
            ADC_STATUS,
            32'h0000_0002
        );

        // Enable sample interrupt
        axi_write(
            ADC_IRQ_EN,
            32'h0000_0001
        );

        // START another acquisition
        axi_write(
            ADC_CTRL,
            32'h0000_0002
        );

        capture_sample(12'h5AA);

        // Allow one cycle for IRQ propagation
        @(posedge clk);

        if (adc_irq_sample !== 1'b1) begin

            $display(
                "[ADC IRQ] expected sample IRQ = 1 FAIL"
            );

            errors = errors + 1;

        end
        else begin

            $display(
                "[ADC IRQ] sample IRQ asserted PASS"
            );

        end

        // Clear DONE
        axi_write(
            ADC_STATUS,
            32'h0000_0002
        );

        // Disable sample IRQ
        axi_write(
            ADC_IRQ_EN,
            32'h0000_0000
        );

        // ========================================================
        // TEST 6
        // ========================================================

        $display("");
        $display("TEST 6: DISABLE");

        axi_write(
            ADC_CTRL,
            32'h0000_0000
        );

        expect_read(
            ADC_CTRL,
            32'h0000_0000
        );

        // ========================================================
        // TEST 7: GPIO AXI INTEGRATION - M05
        // ========================================================

        $display("");
        $display("TEST 7: GPIO AXI INTEGRATION");

        // Configure all 8 GPIOs as outputs.
        axi_write(GPIO_DIR, 32'h0000_00FF);
        axi_write(GPIO_DATA_O, 32'h0000_00A5);
        expect_read(GPIO_DATA_O, 32'h0000_00A5);

        // Atomic SET: A5 | 0F = AF
        axi_write(GPIO_SET_O, 32'h0000_000F);
        expect_read(GPIO_DATA_O, 32'h0000_00AF);

        // Atomic CLR: AF & ~03 = AC
        axi_write(GPIO_CLR_O, 32'h0000_0003);
        expect_read(GPIO_DATA_O, 32'h0000_00AC);

        // Atomic TGL: AC ^ 0F = A3
        axi_write(GPIO_TGL_O, 32'h0000_000F);
        expect_read(GPIO_DATA_O, 32'h0000_00A3);

        // Configure as inputs and drive the pins externally.
        axi_write(GPIO_DIR, 32'h0000_0000);
        gpio_drive    = 8'h5A;
        gpio_drive_en = 1'b1;
        #20;
        expect_read(GPIO_DATA_I, 32'h0000_005A);
        gpio_drive_en = 1'b0;

        // ========================================================
        // TEST 8: TIMER AXI INTEGRATION - M06
        // ========================================================

        $display("");
        $display("TEST 8: TIMER AXI INTEGRATION");

        // Register read/write through the complete AXI 3x14 path.
        axi_write(TIMER_LOAD, 32'h0000_0005);
        expect_read(TIMER_LOAD, 32'h0000_0005);

        axi_write(TIMER_CMP, 32'h0000_0002);
        expect_read(TIMER_CMP, 32'h0000_0002);

        // Enable timer-expiry interrupt, then start timer.
        axi_write(TIMER_INT_EN, 32'h0000_0001);
        axi_write(TIMER_CTRL, 32'h0000_0001);

        // Bounded wait for the integrated timer interrupt.
        begin : TIMER_IRQ_WAIT
            integer timer_wait;
            timer_wait = 0;
            while ((timer_irq !== 1'b1) && (timer_wait < 100)) begin
                @(posedge clk);
                timer_wait = timer_wait + 1;
            end

            if (timer_irq !== 1'b1) begin
                $display("[TIMER IRQ] timeout waiting for interrupt FAIL");
                errors = errors + 1;
            end
            else begin
                $display("[TIMER IRQ] integrated interrupt received PASS");
            end
        end

        // Verify interrupt status and clear it.
        expect_read(TIMER_INT_STS, 32'h0000_0001);
        axi_write(TIMER_INT_STS, 32'h0000_0001);

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(
                "ADC INTEGRATION RESULT: PASS"
            );

        end
        else begin

            $display(
                "ADC INTEGRATION RESULT: FAIL (%0d errors)",
                errors
            );

        end

        $display("==============================================");

        #100;

        $finish;

    end

endmodule
