//`timescale 1ns/1ps

module soc_uart_qrs_spi_fir_adc_gpio_timer_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter STRB_WIDTH = 4,
    parameter ID_WIDTH   = 8
)(
    input  wire                     clk,
    input  wire                     rst,

    /* ============================================================
     * S00 AXI interface
     * This is driven by the testbench now.
     * Later this will connect to the RISC-V master/interconnect side.
     * ============================================================ */

    input  wire [ID_WIDTH-1:0]      s00_axi_awid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_awaddr,
    input  wire [7:0]               s00_axi_awlen,
    input  wire [2:0]               s00_axi_awsize,
    input  wire [1:0]               s00_axi_awburst,
    input  wire                     s00_axi_awlock,
    input  wire [3:0]               s00_axi_awcache,
    input  wire [2:0]               s00_axi_awprot,
    input  wire [3:0]               s00_axi_awqos,
    input  wire [0:0]               s00_axi_awuser,
    input  wire                     s00_axi_awvalid,
    output wire                     s00_axi_awready,

    input  wire [DATA_WIDTH-1:0]    s00_axi_wdata,
    input  wire [STRB_WIDTH-1:0]    s00_axi_wstrb,
    input  wire                     s00_axi_wlast,
    input  wire [0:0]               s00_axi_wuser,
    input  wire                     s00_axi_wvalid,
    output wire                     s00_axi_wready,

    output wire [ID_WIDTH-1:0]      s00_axi_bid,
    output wire [1:0]               s00_axi_bresp,
    output wire [0:0]               s00_axi_buser,
    output wire                     s00_axi_bvalid,
    input  wire                     s00_axi_bready,

    input  wire [ID_WIDTH-1:0]      s00_axi_arid,
    input  wire [ADDR_WIDTH-1:0]    s00_axi_araddr,
    input  wire [7:0]               s00_axi_arlen,
    input  wire [2:0]               s00_axi_arsize,
    input  wire [1:0]               s00_axi_arburst,
    input  wire                     s00_axi_arlock,
    input  wire [3:0]               s00_axi_arcache,
    input  wire [2:0]               s00_axi_arprot,
    input  wire [3:0]               s00_axi_arqos,
    input  wire [0:0]               s00_axi_aruser,
    input  wire                     s00_axi_arvalid,
    output wire                     s00_axi_arready,

    output wire [ID_WIDTH-1:0]      s00_axi_rid,
    output wire [DATA_WIDTH-1:0]    s00_axi_rdata,
    output wire [1:0]               s00_axi_rresp,
    output wire                     s00_axi_rlast,
    output wire [0:0]               s00_axi_ruser,
    output wire                     s00_axi_rvalid,
    input  wire                     s00_axi_rready,

    /* UART external pins */
    input  wire                     uart_rx_i,
    output wire                     uart_tx_o,

    /* SPI external pins */
    input  wire                     spi_miso_i,
    output wire                     spi_clk_o,
    output wire                     spi_cs_n_o,
    output wire                     spi_mosi_o,

    /* FIR AXI4-Stream input */
    input  wire                     fir_s_axis_tvalid,
    output wire                     fir_s_axis_tready,
    input  wire [15:0]              fir_s_axis_tdata,

    /* FIR AXI4-Stream output */
    output wire                     fir_m_axis_tvalid,
    input  wire                     fir_m_axis_tready,
    output wire [39:0]              fir_m_axis_tdata,

    /* ADC external sample interface */
    input  wire [11:0]              adc_sample_in,
    input  wire                     adc_sample_valid,
    output wire                     adc_irq_sample,
    output wire                     adc_irq_overrun,

    /* GPIO external pins */
    inout  wire [7:0]               gpio_io,
    output wire                     gpio_irq,

    /* Timer external pins */
    input  wire                     timer_ext_meas_i,
    input  wire                     timer_capture_i,
    output wire                     timer_pwm_o,
    output wire                     timer_trigger_o,
    output wire                     timer_irq
);



    /* ============================================================
     * INTERCONNECT M01 <-> QRS AXI4 WRAPPER
     *
     * M01 address window:
     *   0x4000_1000 - 0x4000_1FFF
     * ============================================================ */

    wire [ID_WIDTH-1:0]   m01_axi_awid;
    wire [ADDR_WIDTH-1:0] m01_axi_awaddr;
    wire [7:0]            m01_axi_awlen;
    wire [2:0]            m01_axi_awsize;
    wire [1:0]            m01_axi_awburst;
    wire                  m01_axi_awlock;
    wire [3:0]            m01_axi_awcache;
    wire [2:0]            m01_axi_awprot;
    wire [3:0]            m01_axi_awqos;
    wire [3:0]            m01_axi_awregion;
    wire [0:0]            m01_axi_awuser;
    wire                  m01_axi_awvalid;
    wire                  m01_axi_awready;

    wire [DATA_WIDTH-1:0] m01_axi_wdata;
    wire [STRB_WIDTH-1:0] m01_axi_wstrb;
    wire                  m01_axi_wlast;
    wire [0:0]            m01_axi_wuser;
    wire                  m01_axi_wvalid;
    wire                  m01_axi_wready;

    wire [ID_WIDTH-1:0]   m01_axi_bid;
    wire [1:0]            m01_axi_bresp;
    wire [0:0]            m01_axi_buser;
    wire                  m01_axi_bvalid;
    wire                  m01_axi_bready;

    wire [ID_WIDTH-1:0]   m01_axi_arid;
    wire [ADDR_WIDTH-1:0] m01_axi_araddr;
    wire [7:0]            m01_axi_arlen;
    wire [2:0]            m01_axi_arsize;
    wire [1:0]            m01_axi_arburst;
    wire                  m01_axi_arlock;
    wire [3:0]            m01_axi_arcache;
    wire [2:0]            m01_axi_arprot;
    wire [3:0]            m01_axi_arqos;
    wire [3:0]            m01_axi_arregion;
    wire [0:0]            m01_axi_aruser;
    wire                  m01_axi_arvalid;
    wire                  m01_axi_arready;

    wire [ID_WIDTH-1:0]   m01_axi_rid;
    wire [DATA_WIDTH-1:0] m01_axi_rdata;
    wire [1:0]            m01_axi_rresp;
    wire                  m01_axi_rlast;
    wire [0:0]            m01_axi_ruser;
    wire                  m01_axi_rvalid;
    wire                  m01_axi_rready;

    /* ============================================================
     * INTERCONNECT M00 <-> UART
     * ============================================================ */

    wire [ID_WIDTH-1:0]   m00_axi_awid;
    wire [ADDR_WIDTH-1:0] m00_axi_awaddr;
    wire [7:0]            m00_axi_awlen;
    wire [2:0]            m00_axi_awsize;
    wire [1:0]            m00_axi_awburst;
    wire                  m00_axi_awlock;
    wire [3:0]            m00_axi_awcache;
    wire [2:0]            m00_axi_awprot;
    wire [3:0]            m00_axi_awqos;
    wire [3:0]            m00_axi_awregion;
    wire [0:0]            m00_axi_awuser;
    wire                  m00_axi_awvalid;
    wire                  m00_axi_awready;

    wire [DATA_WIDTH-1:0] m00_axi_wdata;
    wire [STRB_WIDTH-1:0] m00_axi_wstrb;
    wire                  m00_axi_wlast;
    wire [0:0]            m00_axi_wuser;
    wire                  m00_axi_wvalid;
    wire                  m00_axi_wready;

    wire [ID_WIDTH-1:0]   m00_axi_bid;
    wire [1:0]            m00_axi_bresp;
    wire [0:0]            m00_axi_buser;
    wire                  m00_axi_bvalid;
    wire                  m00_axi_bready;

    wire [ID_WIDTH-1:0]   m00_axi_arid;
    wire [ADDR_WIDTH-1:0] m00_axi_araddr;
    wire [7:0]            m00_axi_arlen;
    wire [2:0]            m00_axi_arsize;
    wire [1:0]            m00_axi_arburst;
    wire                  m00_axi_arlock;
    wire [3:0]            m00_axi_arcache;
    wire [2:0]            m00_axi_arprot;
    wire [3:0]            m00_axi_arqos;
    wire [3:0]            m00_axi_arregion;
    wire [0:0]            m00_axi_aruser;
    wire                  m00_axi_arvalid;
    wire                  m00_axi_arready;

    wire [ID_WIDTH-1:0]   m00_axi_rid;
    wire [DATA_WIDTH-1:0] m00_axi_rdata;
    wire [1:0]            m00_axi_rresp;
    wire                  m00_axi_rlast;
    wire [0:0]            m00_axi_ruser;
    wire                  m00_axi_rvalid;
    wire                  m00_axi_rready;


    /* ============================================================
     * INTERCONNECT M03 <-> FIR AXI4-Lite
     *
     * M03 address window:
     *   0x4000_3000 - 0x4000_3FFF
     * ============================================================ */

    wire [ID_WIDTH-1:0]   m03_axi_awid;
    wire [ADDR_WIDTH-1:0] m03_axi_awaddr;
    wire [7:0]            m03_axi_awlen;
    wire [2:0]            m03_axi_awsize;
    wire [1:0]            m03_axi_awburst;
    wire                  m03_axi_awlock;
    wire [3:0]            m03_axi_awcache;
    wire [2:0]            m03_axi_awprot;
    wire [3:0]            m03_axi_awqos;
    wire [3:0]            m03_axi_awregion;
    wire [0:0]            m03_axi_awuser;
    wire                  m03_axi_awvalid;
    wire                  m03_axi_awready;

    wire [DATA_WIDTH-1:0] m03_axi_wdata;
    wire [STRB_WIDTH-1:0] m03_axi_wstrb;
    wire                  m03_axi_wlast;
    wire [0:0]            m03_axi_wuser;
    wire                  m03_axi_wvalid;
    wire                  m03_axi_wready;

    wire [ID_WIDTH-1:0]   m03_axi_bid;
    wire [1:0]            m03_axi_bresp;
    wire [0:0]            m03_axi_buser;
    wire                  m03_axi_bvalid;
    wire                  m03_axi_bready;

    wire [ID_WIDTH-1:0]   m03_axi_arid;
    wire [ADDR_WIDTH-1:0] m03_axi_araddr;
    wire [7:0]            m03_axi_arlen;
    wire [2:0]            m03_axi_arsize;
    wire [1:0]            m03_axi_arburst;
    wire                  m03_axi_arlock;
    wire [3:0]            m03_axi_arcache;
    wire [2:0]            m03_axi_arprot;
    wire [3:0]            m03_axi_arqos;
    wire [3:0]            m03_axi_arregion;
    wire [0:0]            m03_axi_aruser;
    wire                  m03_axi_arvalid;
    wire                  m03_axi_arready;

    wire [ID_WIDTH-1:0]   m03_axi_rid;
    wire [DATA_WIDTH-1:0] m03_axi_rdata;
    wire [1:0]            m03_axi_rresp;
    wire                  m03_axi_rlast;
    wire [0:0]            m03_axi_ruser;
    wire                  m03_axi_rvalid;
    wire                  m03_axi_rready;

    /* ============================================================
     * INTERCONNECT M02 <-> SPI AXI4-Lite
     *
     * M02 address window:
     *   0x4000_2000 - 0x4000_2FFF
     * ============================================================ */

    wire [ID_WIDTH-1:0]   m02_axi_awid;
    wire [ADDR_WIDTH-1:0] m02_axi_awaddr;
    wire [7:0]            m02_axi_awlen;
    wire [2:0]            m02_axi_awsize;
    wire [1:0]            m02_axi_awburst;
    wire                  m02_axi_awlock;
    wire [3:0]            m02_axi_awcache;
    wire [2:0]            m02_axi_awprot;
    wire [3:0]            m02_axi_awqos;
    wire [3:0]            m02_axi_awregion;
    wire [0:0]            m02_axi_awuser;
    wire                  m02_axi_awvalid;
    wire                  m02_axi_awready;

    wire [DATA_WIDTH-1:0] m02_axi_wdata;
    wire [STRB_WIDTH-1:0] m02_axi_wstrb;
    wire                  m02_axi_wlast;
    wire [0:0]            m02_axi_wuser;
    wire                  m02_axi_wvalid;
    wire                  m02_axi_wready;

    wire [ID_WIDTH-1:0]   m02_axi_bid;
    wire [1:0]            m02_axi_bresp;
    wire [0:0]            m02_axi_buser;
    wire                  m02_axi_bvalid;
    wire                  m02_axi_bready;

    wire [ID_WIDTH-1:0]   m02_axi_arid;
    wire [ADDR_WIDTH-1:0] m02_axi_araddr;
    wire [7:0]            m02_axi_arlen;
    wire [2:0]            m02_axi_arsize;
    wire [1:0]            m02_axi_arburst;
    wire                  m02_axi_arlock;
    wire [3:0]            m02_axi_arcache;
    wire [2:0]            m02_axi_arprot;
    wire [3:0]            m02_axi_arqos;
    wire [3:0]            m02_axi_arregion;
    wire [0:0]            m02_axi_aruser;
    wire                  m02_axi_arvalid;
    wire                  m02_axi_arready;

    wire [ID_WIDTH-1:0]   m02_axi_rid;
    wire [DATA_WIDTH-1:0] m02_axi_rdata;
    wire [1:0]            m02_axi_rresp;
    wire                  m02_axi_rlast;
    wire [0:0]            m02_axi_ruser;
    wire                  m02_axi_rvalid;
    wire                  m02_axi_rready;

    /* ============================================================
     * M04 AXI4-Lite ADC connection
     *
     * ADC base address:
     *   0x4000_4000 - 0x4000_4FFF
     *
     * The ADC IP is natively AXI4-Lite. No AXI4-to-AXI4-Lite
     * wrapper is used. The AXI4 burst/ID/user signals on M04 are
     * intentionally unused; the ADC uses the AXI4-Lite subset.
     * ============================================================ */

    wire [ID_WIDTH-1:0]   m04_axi_awid;
    wire [ADDR_WIDTH-1:0] m04_axi_awaddr;
    wire [7:0]            m04_axi_awlen;
    wire [2:0]            m04_axi_awsize;
    wire [1:0]            m04_axi_awburst;
    wire                  m04_axi_awlock;
    wire [3:0]            m04_axi_awcache;
    wire [2:0]            m04_axi_awprot;
    wire [3:0]            m04_axi_awqos;
    wire [3:0]            m04_axi_awregion;
    wire [0:0]            m04_axi_awuser;
    wire                  m04_axi_awvalid;
    wire                  m04_axi_awready;

    wire [DATA_WIDTH-1:0] m04_axi_wdata;
    wire [STRB_WIDTH-1:0] m04_axi_wstrb;
    wire                  m04_axi_wlast;
    wire [0:0]            m04_axi_wuser;
    wire                  m04_axi_wvalid;
    wire                  m04_axi_wready;

    wire [ID_WIDTH-1:0]   m04_axi_bid;
    wire [1:0]            m04_axi_bresp;
    wire [0:0]            m04_axi_buser;
    wire                  m04_axi_bvalid;
    wire                  m04_axi_bready;

    wire [ID_WIDTH-1:0]   m04_axi_arid;
    wire [ADDR_WIDTH-1:0] m04_axi_araddr;
    wire [7:0]            m04_axi_arlen;
    wire [2:0]            m04_axi_arsize;
    wire [1:0]            m04_axi_arburst;
    wire                  m04_axi_arlock;
    wire [3:0]            m04_axi_arcache;
    wire [2:0]            m04_axi_arprot;
    wire [3:0]            m04_axi_arqos;
    wire [3:0]            m04_axi_arregion;
    wire [0:0]            m04_axi_aruser;
    wire                  m04_axi_arvalid;
    wire                  m04_axi_arready;

    wire [ID_WIDTH-1:0]   m04_axi_rid;
    wire [DATA_WIDTH-1:0] m04_axi_rdata;
    wire [1:0]            m04_axi_rresp;
    wire                  m04_axi_rlast;
    wire [0:0]            m04_axi_ruser;
    wire                  m04_axi_rvalid;
    wire                  m04_axi_rready;

    /* ============================================================
     * INTERCONNECT M05 <-> GPIO AXI4-Lite
     * Address window: 0x4000_5000 - 0x4000_5FFF
     * ============================================================ */
    wire [ID_WIDTH-1:0]   m05_axi_awid;
    wire [ADDR_WIDTH-1:0] m05_axi_awaddr;
    wire [7:0]            m05_axi_awlen;
    wire [2:0]            m05_axi_awsize;
    wire [1:0]            m05_axi_awburst;
    wire                  m05_axi_awlock;
    wire [3:0]            m05_axi_awcache;
    wire [2:0]            m05_axi_awprot;
    wire [3:0]            m05_axi_awqos;
    wire [3:0]            m05_axi_awregion;
    wire [0:0]            m05_axi_awuser;
    wire                  m05_axi_awvalid;
    wire                  m05_axi_awready;
    wire [DATA_WIDTH-1:0] m05_axi_wdata;
    wire [STRB_WIDTH-1:0] m05_axi_wstrb;
    wire                  m05_axi_wlast;
    wire [0:0]            m05_axi_wuser;
    wire                  m05_axi_wvalid;
    wire                  m05_axi_wready;
    wire [ID_WIDTH-1:0]   m05_axi_bid;
    wire [1:0]            m05_axi_bresp;
    wire [0:0]            m05_axi_buser;
    wire                  m05_axi_bvalid;
    wire                  m05_axi_bready;
    wire [ID_WIDTH-1:0]   m05_axi_arid;
    wire [ADDR_WIDTH-1:0] m05_axi_araddr;
    wire [7:0]            m05_axi_arlen;
    wire [2:0]            m05_axi_arsize;
    wire [1:0]            m05_axi_arburst;
    wire                  m05_axi_arlock;
    wire [3:0]            m05_axi_arcache;
    wire [2:0]            m05_axi_arprot;
    wire [3:0]            m05_axi_arqos;
    wire [3:0]            m05_axi_arregion;
    wire [0:0]            m05_axi_aruser;
    wire                  m05_axi_arvalid;
    wire                  m05_axi_arready;
    wire [ID_WIDTH-1:0]   m05_axi_rid;
    wire [DATA_WIDTH-1:0] m05_axi_rdata;
    wire [1:0]            m05_axi_rresp;
    wire                  m05_axi_rlast;
    wire [0:0]            m05_axi_ruser;
    wire                  m05_axi_rvalid;
    wire                  m05_axi_rready;

    /* ============================================================
     * INTERCONNECT M06 <-> TIMER AXI4-Lite
     * Address window: 0x4000_6000 - 0x4000_6FFF
     * ============================================================ */
    wire [ID_WIDTH-1:0]   m06_axi_awid;
    wire [ADDR_WIDTH-1:0] m06_axi_awaddr;
    wire [7:0]            m06_axi_awlen;
    wire [2:0]            m06_axi_awsize;
    wire [1:0]            m06_axi_awburst;
    wire                  m06_axi_awlock;
    wire [3:0]            m06_axi_awcache;
    wire [2:0]            m06_axi_awprot;
    wire [3:0]            m06_axi_awqos;
    wire [3:0]            m06_axi_awregion;
    wire [0:0]            m06_axi_awuser;
    wire                  m06_axi_awvalid;
    wire                  m06_axi_awready;
    wire [DATA_WIDTH-1:0] m06_axi_wdata;
    wire [STRB_WIDTH-1:0] m06_axi_wstrb;
    wire                  m06_axi_wlast;
    wire [0:0]            m06_axi_wuser;
    wire                  m06_axi_wvalid;
    wire                  m06_axi_wready;
    wire [ID_WIDTH-1:0]   m06_axi_bid;
    wire [1:0]            m06_axi_bresp;
    wire [0:0]            m06_axi_buser;
    wire                  m06_axi_bvalid;
    wire                  m06_axi_bready;
    wire [ID_WIDTH-1:0]   m06_axi_arid;
    wire [ADDR_WIDTH-1:0] m06_axi_araddr;
    wire [7:0]            m06_axi_arlen;
    wire [2:0]            m06_axi_arsize;
    wire [1:0]            m06_axi_arburst;
    wire                  m06_axi_arlock;
    wire [3:0]            m06_axi_arcache;
    wire [2:0]            m06_axi_arprot;
    wire [3:0]            m06_axi_arqos;
    wire [3:0]            m06_axi_arregion;
    wire [0:0]            m06_axi_aruser;
    wire                  m06_axi_arvalid;
    wire                  m06_axi_arready;
    wire [ID_WIDTH-1:0]   m06_axi_rid;
    wire [DATA_WIDTH-1:0] m06_axi_rdata;
    wire [1:0]            m06_axi_rresp;
    wire                  m06_axi_rlast;
    wire [0:0]            m06_axi_ruser;
    wire                  m06_axi_rvalid;
    wire                  m06_axi_rready;

    /* ============================================================
     * AXI INTERCONNECT
     *
     * M00 = UART
     * M01 = QRS
     *
     * UART address range:
     *   0x4000_0000 - 0x4000_0FFF
     *
     * QRS address range:
     *   0x4000_1000 - 0x4000_1FFF
     *
     * M04-M13 remain unused.
     * ============================================================ */

    axi_interconnect_wrap_3x14 #(
        .DATA_WIDTH        (DATA_WIDTH),
        .ADDR_WIDTH        (ADDR_WIDTH),
        .STRB_WIDTH        (STRB_WIDTH),
        .ID_WIDTH          (ID_WIDTH),

        .AWUSER_WIDTH      (1),
        .WUSER_WIDTH       (1),
        .BUSER_WIDTH       (1),
        .ARUSER_WIDTH      (1),
        .RUSER_WIDTH       (1),

        .M_REGIONS         (1),

        /* UART */
        .M00_BASE_ADDR     (32'h4000_0000),
        .M00_ADDR_WIDTH    (32'd12),
        .M00_CONNECT_READ  (3'b001),
        .M00_CONNECT_WRITE (3'b001),

        /* QRS */
        .M01_BASE_ADDR     (32'h4000_1000),
        .M01_ADDR_WIDTH    (32'd12),
        .M01_CONNECT_READ  (3'b001),
        .M01_CONNECT_WRITE (3'b001),

        .M02_BASE_ADDR     (32'h4000_2000),
        .M02_ADDR_WIDTH    (32'd12),
        .M02_CONNECT_READ  (3'b001),
        .M02_CONNECT_WRITE (3'b001),

        .M03_BASE_ADDR     (32'h4000_3000),
        .M03_ADDR_WIDTH    (32'd12),
        .M03_CONNECT_READ  (3'b001),
        .M03_CONNECT_WRITE (3'b001),

        .M04_BASE_ADDR     (32'h4000_4000),
        .M04_ADDR_WIDTH    (32'd12),
        .M04_CONNECT_READ  (3'b001),
        .M04_CONNECT_WRITE (3'b001),

        .M05_BASE_ADDR     (32'h4000_5000),
        .M05_ADDR_WIDTH    (32'd12),
        .M05_CONNECT_READ  (3'b001),
        .M05_CONNECT_WRITE (3'b001),

        .M06_BASE_ADDR     (32'h4000_6000),
        .M06_ADDR_WIDTH    (32'd12),
        .M06_CONNECT_READ  (3'b001),
        .M06_CONNECT_WRITE (3'b001),

        .M07_ADDR_WIDTH    (32'd0),
        .M07_CONNECT_READ  (3'b000),
        .M07_CONNECT_WRITE (3'b000),

        .M08_ADDR_WIDTH    (32'd0),
        .M08_CONNECT_READ  (3'b000),
        .M08_CONNECT_WRITE (3'b000),

        .M09_ADDR_WIDTH    (32'd0),
        .M09_CONNECT_READ  (3'b000),
        .M09_CONNECT_WRITE (3'b000),

        .M10_ADDR_WIDTH    (32'd0),
        .M10_CONNECT_READ  (3'b000),
        .M10_CONNECT_WRITE (3'b000),

        .M11_ADDR_WIDTH    (32'd0),
        .M11_CONNECT_READ  (3'b000),
        .M11_CONNECT_WRITE (3'b000),

        .M12_ADDR_WIDTH    (32'd0),
        .M12_CONNECT_READ  (3'b000),
        .M12_CONNECT_WRITE (3'b000),

        .M13_ADDR_WIDTH    (32'd0),
        .M13_CONNECT_READ  (3'b000),
        .M13_CONNECT_WRITE (3'b000)

    ) u_interconnect (

        .clk              (clk),
        .rst              (rst),

        /* ========================================================
         * S00 ACTIVE
         * ======================================================== */

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

        .s00_axi_wdata    (s00_axi_wdata),
        .s00_axi_wstrb    (s00_axi_wstrb),
        .s00_axi_wlast    (s00_axi_wlast),
        .s00_axi_wuser    (s00_axi_wuser),
        .s00_axi_wvalid   (s00_axi_wvalid),
        .s00_axi_wready   (s00_axi_wready),

        .s00_axi_bid      (s00_axi_bid),
        .s00_axi_bresp    (s00_axi_bresp),
        .s00_axi_buser    (s00_axi_buser),
        .s00_axi_bvalid   (s00_axi_bvalid),
        .s00_axi_bready   (s00_axi_bready),

        .s00_axi_arid     (s00_axi_arid),
        .s00_axi_araddr   (s00_axi_araddr),
        .s00_axi_arlen    (s00_axi_arlen),
        .s00_axi_arsize   (s00_axi_arsize),
        .s00_axi_arburst  (s00_axi_arburst),
        .s00_axi_arlock   (s00_axi_arlock),
        .s00_axi_arcache  (s00_axi_arcache),
        .s00_axi_arprot   (s00_axi_arprot),
        .s00_axi_arqos    (s00_axi_arqos),
        .s00_axi_aruser   (s00_axi_aruser),
        .s00_axi_arvalid  (s00_axi_arvalid),
        .s00_axi_arready  (s00_axi_arready),

        .s00_axi_rid      (s00_axi_rid),
        .s00_axi_rdata    (s00_axi_rdata),
        .s00_axi_rresp    (s00_axi_rresp),
        .s00_axi_rlast    (s00_axi_rlast),
        .s00_axi_ruser    (s00_axi_ruser),
        .s00_axi_rvalid   (s00_axi_rvalid),
        .s00_axi_rready   (s00_axi_rready),


        /* ========================================================
         * S01 INACTIVE
         * ======================================================== */

        .s01_axi_awid     (8'd0),
        .s01_axi_awaddr   (32'd0),
        .s01_axi_awlen    (8'd0),
        .s01_axi_awsize   (3'd0),
        .s01_axi_awburst  (2'd0),
        .s01_axi_awlock   (1'b0),
        .s01_axi_awcache  (4'd0),
        .s01_axi_awprot   (3'd0),
        .s01_axi_awqos    (4'd0),
        .s01_axi_awuser   (1'b0),
        .s01_axi_awvalid  (1'b0),

        .s01_axi_wdata    (32'd0),
        .s01_axi_wstrb    (4'd0),
        .s01_axi_wlast    (1'b0),
        .s01_axi_wuser    (1'b0),
        .s01_axi_wvalid   (1'b0),
        .s01_axi_bready   (1'b0),

        .s01_axi_arid     (8'd0),
        .s01_axi_araddr   (32'd0),
        .s01_axi_arlen    (8'd0),
        .s01_axi_arsize   (3'd0),
        .s01_axi_arburst  (2'd0),
        .s01_axi_arlock   (1'b0),
        .s01_axi_arcache  (4'd0),
        .s01_axi_arprot   (3'd0),
        .s01_axi_arqos    (4'd0),
        .s01_axi_aruser   (1'b0),
        .s01_axi_arvalid  (1'b0),
        .s01_axi_rready   (1'b0),


        /* ========================================================
         * S02 INACTIVE
         * ======================================================== */

        .s02_axi_awid     (8'd0),
        .s02_axi_awaddr   (32'd0),
        .s02_axi_awlen    (8'd0),
        .s02_axi_awsize   (3'd0),
        .s02_axi_awburst  (2'd0),
        .s02_axi_awlock   (1'b0),
        .s02_axi_awcache  (4'd0),
        .s02_axi_awprot   (3'd0),
        .s02_axi_awqos    (4'd0),
        .s02_axi_awuser   (1'b0),
        .s02_axi_awvalid  (1'b0),

        .s02_axi_wdata    (32'd0),
        .s02_axi_wstrb    (4'd0),
        .s02_axi_wlast    (1'b0),
        .s02_axi_wuser    (1'b0),
        .s02_axi_wvalid   (1'b0),
        .s02_axi_bready   (1'b0),

        .s02_axi_arid     (8'd0),
        .s02_axi_araddr   (32'd0),
        .s02_axi_arlen    (8'd0),
        .s02_axi_arsize   (3'd0),
        .s02_axi_arburst  (2'd0),
        .s02_axi_arlock   (1'b0),
        .s02_axi_arcache  (4'd0),
        .s02_axi_arprot   (3'd0),
        .s02_axi_arqos    (4'd0),
        .s02_axi_aruser   (1'b0),
        .s02_axi_arvalid  (1'b0),
        .s02_axi_rready   (1'b0),


        /* ========================================================
         * M00 ACTIVE -> UART
         * ======================================================== */

        .m00_axi_awid     (m00_axi_awid),
        .m00_axi_awaddr   (m00_axi_awaddr),
        .m00_axi_awlen    (m00_axi_awlen),
        .m00_axi_awsize   (m00_axi_awsize),
        .m00_axi_awburst  (m00_axi_awburst),
        .m00_axi_awlock   (m00_axi_awlock),
        .m00_axi_awcache  (m00_axi_awcache),
        .m00_axi_awprot   (m00_axi_awprot),
        .m00_axi_awqos    (m00_axi_awqos),
        .m00_axi_awregion (m00_axi_awregion),
        .m00_axi_awuser   (m00_axi_awuser),
        .m00_axi_awvalid  (m00_axi_awvalid),
        .m00_axi_awready  (m00_axi_awready),

        .m00_axi_wdata    (m00_axi_wdata),
        .m00_axi_wstrb    (m00_axi_wstrb),
        .m00_axi_wlast    (m00_axi_wlast),
        .m00_axi_wuser    (m00_axi_wuser),
        .m00_axi_wvalid   (m00_axi_wvalid),
        .m00_axi_wready   (m00_axi_wready),

        .m00_axi_bid      (m00_axi_bid),
        .m00_axi_bresp    (m00_axi_bresp),
        .m00_axi_buser    (m00_axi_buser),
        .m00_axi_bvalid   (m00_axi_bvalid),
        .m00_axi_bready   (m00_axi_bready),

        .m00_axi_arid     (m00_axi_arid),
        .m00_axi_araddr   (m00_axi_araddr),
        .m00_axi_arlen    (m00_axi_arlen),
        .m00_axi_arsize   (m00_axi_arsize),
        .m00_axi_arburst  (m00_axi_arburst),
        .m00_axi_arlock   (m00_axi_arlock),
        .m00_axi_arcache  (m00_axi_arcache),
        .m00_axi_arprot   (m00_axi_arprot),
        .m00_axi_arqos    (m00_axi_arqos),
        .m00_axi_arregion (m00_axi_arregion),
        .m00_axi_aruser   (m00_axi_aruser),
        .m00_axi_arvalid  (m00_axi_arvalid),
        .m00_axi_arready  (m00_axi_arready),

        .m00_axi_rid      (m00_axi_rid),
        .m00_axi_rdata    (m00_axi_rdata),
        .m00_axi_rresp    (m00_axi_rresp),
        .m00_axi_rlast    (m00_axi_rlast),
        .m00_axi_ruser    (m00_axi_ruser),
        .m00_axi_rvalid   (m00_axi_rvalid),
        .m00_axi_rready   (m00_axi_rready),

        /* ========================================================
         * M01 ACTIVE -> QRS
         * ======================================================== */

        .m01_axi_awid     (m01_axi_awid),
        .m01_axi_awaddr   (m01_axi_awaddr),
        .m01_axi_awlen    (m01_axi_awlen),
        .m01_axi_awsize   (m01_axi_awsize),
        .m01_axi_awburst  (m01_axi_awburst),
        .m01_axi_awlock   (m01_axi_awlock),
        .m01_axi_awcache  (m01_axi_awcache),
        .m01_axi_awprot   (m01_axi_awprot),
        .m01_axi_awqos    (m01_axi_awqos),
        .m01_axi_awregion (m01_axi_awregion),
        .m01_axi_awuser   (m01_axi_awuser),
        .m01_axi_awvalid  (m01_axi_awvalid),
        .m01_axi_awready  (m01_axi_awready),

        .m01_axi_wdata    (m01_axi_wdata),
        .m01_axi_wstrb    (m01_axi_wstrb),
        .m01_axi_wlast    (m01_axi_wlast),
        .m01_axi_wuser    (m01_axi_wuser),
        .m01_axi_wvalid   (m01_axi_wvalid),
        .m01_axi_wready   (m01_axi_wready),

        .m01_axi_bid      (m01_axi_bid),
        .m01_axi_bresp    (m01_axi_bresp),
        .m01_axi_buser    (m01_axi_buser),
        .m01_axi_bvalid   (m01_axi_bvalid),
        .m01_axi_bready   (m01_axi_bready),

        .m01_axi_arid     (m01_axi_arid),
        .m01_axi_araddr   (m01_axi_araddr),
        .m01_axi_arlen    (m01_axi_arlen),
        .m01_axi_arsize   (m01_axi_arsize),
        .m01_axi_arburst  (m01_axi_arburst),
        .m01_axi_arlock   (m01_axi_arlock),
        .m01_axi_arcache  (m01_axi_arcache),
        .m01_axi_arprot   (m01_axi_arprot),
        .m01_axi_arqos    (m01_axi_arqos),
        .m01_axi_arregion (m01_axi_arregion),
        .m01_axi_aruser   (m01_axi_aruser),
        .m01_axi_arvalid  (m01_axi_arvalid),
        .m01_axi_arready  (m01_axi_arready),

        .m01_axi_rid      (m01_axi_rid),
        .m01_axi_rdata    (m01_axi_rdata),
        .m01_axi_rresp    (m01_axi_rresp),
        .m01_axi_rlast    (m01_axi_rlast),
        .m01_axi_ruser    (m01_axi_ruser),
        .m01_axi_rvalid   (m01_axi_rvalid),
        .m01_axi_rready   (m01_axi_rready),

        /* ========================================================
         * M02 = SPI
         * ======================================================== */

        .m02_axi_awid     (m02_axi_awid),
        .m02_axi_awaddr   (m02_axi_awaddr),
        .m02_axi_awlen    (m02_axi_awlen),
        .m02_axi_awsize   (m02_axi_awsize),
        .m02_axi_awburst  (m02_axi_awburst),
        .m02_axi_awlock   (m02_axi_awlock),
        .m02_axi_awcache  (m02_axi_awcache),
        .m02_axi_awprot   (m02_axi_awprot),
        .m02_axi_awqos    (m02_axi_awqos),
        .m02_axi_awregion (m02_axi_awregion),
        .m02_axi_awuser   (m02_axi_awuser),
        .m02_axi_awvalid  (m02_axi_awvalid),
        .m02_axi_awready  (m02_axi_awready),

        .m02_axi_wdata    (m02_axi_wdata),
        .m02_axi_wstrb    (m02_axi_wstrb),
        .m02_axi_wlast    (m02_axi_wlast),
        .m02_axi_wuser    (m02_axi_wuser),
        .m02_axi_wvalid   (m02_axi_wvalid),
        .m02_axi_wready   (m02_axi_wready),

        .m02_axi_bid      (m02_axi_bid),
        .m02_axi_bresp    (m02_axi_bresp),
        .m02_axi_buser    (m02_axi_buser),
        .m02_axi_bvalid   (m02_axi_bvalid),
        .m02_axi_bready   (m02_axi_bready),

        .m02_axi_arid     (m02_axi_arid),
        .m02_axi_araddr   (m02_axi_araddr),
        .m02_axi_arlen    (m02_axi_arlen),
        .m02_axi_arsize   (m02_axi_arsize),
        .m02_axi_arburst  (m02_axi_arburst),
        .m02_axi_arlock   (m02_axi_arlock),
        .m02_axi_arcache  (m02_axi_arcache),
        .m02_axi_arprot   (m02_axi_arprot),
        .m02_axi_arqos    (m02_axi_arqos),
        .m02_axi_arregion (m02_axi_arregion),
        .m02_axi_aruser   (m02_axi_aruser),
        .m02_axi_arvalid  (m02_axi_arvalid),
        .m02_axi_arready  (m02_axi_arready),

        .m02_axi_rid      (m02_axi_rid),
        .m02_axi_rdata    (m02_axi_rdata),
        .m02_axi_rresp    (m02_axi_rresp),
        .m02_axi_rlast    (m02_axi_rlast),
        .m02_axi_ruser    (m02_axi_ruser),
        .m02_axi_rvalid   (m02_axi_rvalid),
        .m02_axi_rready   (m02_axi_rready),

        /* ========================================================
         * M03 ACTIVE -> FIR AXI4-Lite adaptation
         * ======================================================== */
        .m03_axi_awid     (m03_axi_awid),
        .m03_axi_awaddr   (m03_axi_awaddr),
        .m03_axi_awlen    (m03_axi_awlen),
        .m03_axi_awsize   (m03_axi_awsize),
        .m03_axi_awburst  (m03_axi_awburst),
        .m03_axi_awlock   (m03_axi_awlock),
        .m03_axi_awcache  (m03_axi_awcache),
        .m03_axi_awprot   (m03_axi_awprot),
        .m03_axi_awqos    (m03_axi_awqos),
        .m03_axi_awregion (m03_axi_awregion),
        .m03_axi_awuser   (m03_axi_awuser),
        .m03_axi_awvalid  (m03_axi_awvalid),
        .m03_axi_awready  (m03_axi_awready),

        .m03_axi_wdata    (m03_axi_wdata),
        .m03_axi_wstrb    (m03_axi_wstrb),
        .m03_axi_wlast    (m03_axi_wlast),
        .m03_axi_wuser    (m03_axi_wuser),
        .m03_axi_wvalid   (m03_axi_wvalid),
        .m03_axi_wready   (m03_axi_wready),

        .m03_axi_bid      (m03_axi_bid),
        .m03_axi_bresp    (m03_axi_bresp),
        .m03_axi_buser    (m03_axi_buser),
        .m03_axi_bvalid   (m03_axi_bvalid),
        .m03_axi_bready   (m03_axi_bready),

        .m03_axi_arid     (m03_axi_arid),
        .m03_axi_araddr   (m03_axi_araddr),
        .m03_axi_arlen    (m03_axi_arlen),
        .m03_axi_arsize   (m03_axi_arsize),
        .m03_axi_arburst  (m03_axi_arburst),
        .m03_axi_arlock   (m03_axi_arlock),
        .m03_axi_arcache  (m03_axi_arcache),
        .m03_axi_arprot   (m03_axi_arprot),
        .m03_axi_arqos    (m03_axi_arqos),
        .m03_axi_arregion (m03_axi_arregion),
        .m03_axi_aruser   (m03_axi_aruser),
        .m03_axi_arvalid  (m03_axi_arvalid),
        .m03_axi_arready  (m03_axi_arready),

        .m03_axi_rid      (m03_axi_rid),
        .m03_axi_rdata    (m03_axi_rdata),
        .m03_axi_rresp    (m03_axi_rresp),
        .m03_axi_rlast    (m03_axi_rlast),
        .m03_axi_ruser    (m03_axi_ruser),
        .m03_axi_rvalid   (m03_axi_rvalid),
        .m03_axi_rready   (m03_axi_rready),

        /* ========================================================
         * M04 ACTIVE -> ADC (native AXI4-Lite subset)
         * ======================================================== */

        .m04_axi_awid     (m04_axi_awid),
        .m04_axi_awaddr   (m04_axi_awaddr),
        .m04_axi_awlen    (m04_axi_awlen),
        .m04_axi_awsize   (m04_axi_awsize),
        .m04_axi_awburst  (m04_axi_awburst),
        .m04_axi_awlock   (m04_axi_awlock),
        .m04_axi_awcache  (m04_axi_awcache),
        .m04_axi_awprot   (m04_axi_awprot),
        .m04_axi_awqos    (m04_axi_awqos),
        .m04_axi_awregion (m04_axi_awregion),
        .m04_axi_awuser   (m04_axi_awuser),
        .m04_axi_awvalid  (m04_axi_awvalid),
        .m04_axi_awready  (m04_axi_awready),

        .m04_axi_wdata    (m04_axi_wdata),
        .m04_axi_wstrb    (m04_axi_wstrb),
        .m04_axi_wlast    (m04_axi_wlast),
        .m04_axi_wuser    (m04_axi_wuser),
        .m04_axi_wvalid   (m04_axi_wvalid),
        .m04_axi_wready   (m04_axi_wready),

        .m04_axi_bid      (m04_axi_bid),
        .m04_axi_bresp    (m04_axi_bresp),
        .m04_axi_buser    (m04_axi_buser),
        .m04_axi_bvalid   (m04_axi_bvalid),
        .m04_axi_bready   (m04_axi_bready),

        .m04_axi_arid     (m04_axi_arid),
        .m04_axi_araddr   (m04_axi_araddr),
        .m04_axi_arlen    (m04_axi_arlen),
        .m04_axi_arsize   (m04_axi_arsize),
        .m04_axi_arburst  (m04_axi_arburst),
        .m04_axi_arlock   (m04_axi_arlock),
        .m04_axi_arcache  (m04_axi_arcache),
        .m04_axi_arprot   (m04_axi_arprot),
        .m04_axi_arqos    (m04_axi_arqos),
        .m04_axi_arregion (m04_axi_arregion),
        .m04_axi_aruser   (m04_axi_aruser),
        .m04_axi_arvalid  (m04_axi_arvalid),
        .m04_axi_arready  (m04_axi_arready),

        .m04_axi_rid      (m04_axi_rid),
        .m04_axi_rdata    (m04_axi_rdata),
        .m04_axi_rresp    (m04_axi_rresp),
        .m04_axi_rlast    (m04_axi_rlast),
        .m04_axi_ruser    (m04_axi_ruser),
        .m04_axi_rvalid   (m04_axi_rvalid),
        .m04_axi_rready   (m04_axi_rready),

        /* ========================================================
         * M05 ACTIVE -> GPIO
         * ======================================================== */
        .m05_axi_awid     (m05_axi_awid),
        .m05_axi_awaddr   (m05_axi_awaddr),
        .m05_axi_awlen    (m05_axi_awlen),
        .m05_axi_awsize   (m05_axi_awsize),
        .m05_axi_awburst  (m05_axi_awburst),
        .m05_axi_awlock   (m05_axi_awlock),
        .m05_axi_awcache  (m05_axi_awcache),
        .m05_axi_awprot   (m05_axi_awprot),
        .m05_axi_awqos    (m05_axi_awqos),
        .m05_axi_awregion (m05_axi_awregion),
        .m05_axi_awuser   (m05_axi_awuser),
        .m05_axi_awvalid  (m05_axi_awvalid),
        .m05_axi_awready  (m05_axi_awready),
        .m05_axi_wdata    (m05_axi_wdata),
        .m05_axi_wstrb    (m05_axi_wstrb),
        .m05_axi_wlast    (m05_axi_wlast),
        .m05_axi_wuser    (m05_axi_wuser),
        .m05_axi_wvalid   (m05_axi_wvalid),
        .m05_axi_wready   (m05_axi_wready),
        .m05_axi_bid      (m05_axi_bid),
        .m05_axi_bresp    (m05_axi_bresp),
        .m05_axi_buser    (m05_axi_buser),
        .m05_axi_bvalid   (m05_axi_bvalid),
        .m05_axi_bready   (m05_axi_bready),
        .m05_axi_arid     (m05_axi_arid),
        .m05_axi_araddr   (m05_axi_araddr),
        .m05_axi_arlen    (m05_axi_arlen),
        .m05_axi_arsize   (m05_axi_arsize),
        .m05_axi_arburst  (m05_axi_arburst),
        .m05_axi_arlock   (m05_axi_arlock),
        .m05_axi_arcache  (m05_axi_arcache),
        .m05_axi_arprot   (m05_axi_arprot),
        .m05_axi_arqos    (m05_axi_arqos),
        .m05_axi_arregion (m05_axi_arregion),
        .m05_axi_aruser   (m05_axi_aruser),
        .m05_axi_arvalid  (m05_axi_arvalid),
        .m05_axi_arready  (m05_axi_arready),
        .m05_axi_rid      (m05_axi_rid),
        .m05_axi_rdata    (m05_axi_rdata),
        .m05_axi_rresp    (m05_axi_rresp),
        .m05_axi_rlast    (m05_axi_rlast),
        .m05_axi_ruser    (m05_axi_ruser),
        .m05_axi_rvalid   (m05_axi_rvalid),
        .m05_axi_rready   (m05_axi_rready),

        /* ========================================================
         * M06 ACTIVE -> TIMER
         * ======================================================== */
        .m06_axi_awid     (m06_axi_awid),
        .m06_axi_awaddr   (m06_axi_awaddr),
        .m06_axi_awlen    (m06_axi_awlen),
        .m06_axi_awsize   (m06_axi_awsize),
        .m06_axi_awburst  (m06_axi_awburst),
        .m06_axi_awlock   (m06_axi_awlock),
        .m06_axi_awcache  (m06_axi_awcache),
        .m06_axi_awprot   (m06_axi_awprot),
        .m06_axi_awqos    (m06_axi_awqos),
        .m06_axi_awregion (m06_axi_awregion),
        .m06_axi_awuser   (m06_axi_awuser),
        .m06_axi_awvalid  (m06_axi_awvalid),
        .m06_axi_awready  (m06_axi_awready),
        .m06_axi_wdata    (m06_axi_wdata),
        .m06_axi_wstrb    (m06_axi_wstrb),
        .m06_axi_wlast    (m06_axi_wlast),
        .m06_axi_wuser    (m06_axi_wuser),
        .m06_axi_wvalid   (m06_axi_wvalid),
        .m06_axi_wready   (m06_axi_wready),
        .m06_axi_bid      (m06_axi_bid),
        .m06_axi_bresp    (m06_axi_bresp),
        .m06_axi_buser    (m06_axi_buser),
        .m06_axi_bvalid   (m06_axi_bvalid),
        .m06_axi_bready   (m06_axi_bready),
        .m06_axi_arid     (m06_axi_arid),
        .m06_axi_araddr   (m06_axi_araddr),
        .m06_axi_arlen    (m06_axi_arlen),
        .m06_axi_arsize   (m06_axi_arsize),
        .m06_axi_arburst  (m06_axi_arburst),
        .m06_axi_arlock   (m06_axi_arlock),
        .m06_axi_arcache  (m06_axi_arcache),
        .m06_axi_arprot   (m06_axi_arprot),
        .m06_axi_arqos    (m06_axi_arqos),
        .m06_axi_arregion (m06_axi_arregion),
        .m06_axi_aruser   (m06_axi_aruser),
        .m06_axi_arvalid  (m06_axi_arvalid),
        .m06_axi_arready  (m06_axi_arready),
        .m06_axi_rid      (m06_axi_rid),
        .m06_axi_rdata    (m06_axi_rdata),
        .m06_axi_rresp    (m06_axi_rresp),
        .m06_axi_rlast    (m06_axi_rlast),
        .m06_axi_ruser    (m06_axi_ruser),
        .m06_axi_rvalid   (m06_axi_rvalid),
        .m06_axi_rready   (m06_axi_rready)

    );


    /* ============================================================
     * UART
     *
     * Interconnect ID = 8 bits
     * UART ID         = 12 bits
     *
     * Therefore IDs are zero-extended toward UART and the lower
     * 8 bits are returned to the interconnect.
     * ============================================================ */

    wire [11:0] uart_axi_arid;
    wire [4:0]  uart_axi_araddr;
    wire        uart_axi_arvalid;
    wire        uart_axi_arready;

    wire [11:0] uart_axi_rid;
    wire [31:0] uart_axi_rdata;
    wire [1:0]  uart_axi_rresp;
    wire        uart_axi_rvalid;
    wire        uart_axi_rready;

    wire [11:0] uart_axi_awid;
    wire [4:0]  uart_axi_awaddr;
    wire        uart_axi_awvalid;
    wire        uart_axi_awready;

    wire [31:0] uart_axi_wdata;
    wire [3:0]  uart_axi_wstrb;
    wire        uart_axi_wvalid;
    wire        uart_axi_wready;

    wire [11:0] uart_axi_bid;
    wire [1:0]  uart_axi_bresp;
    wire        uart_axi_bvalid;
    wire        uart_axi_bready;

    wire uart_read_interrupt;


    /* ---------------- READ ADDRESS ---------------- */

    assign uart_axi_arid    = {4'b0000, m00_axi_arid};
    assign uart_axi_araddr  = m00_axi_araddr[4:0];
    assign uart_axi_arvalid = m00_axi_arvalid;

    assign m00_axi_arready  = uart_axi_arready;


    /* ---------------- READ RESPONSE ---------------- */

    assign m00_axi_rid     = uart_axi_rid[7:0];
    assign m00_axi_rdata   = uart_axi_rdata;
    assign m00_axi_rresp   = uart_axi_rresp;

    /* UART is AXI4-Lite, therefore every response is one beat. */
    assign m00_axi_rlast   = 1'b1;

    assign m00_axi_ruser   = 1'b0;
    assign m00_axi_rvalid  = uart_axi_rvalid;

    assign uart_axi_rready = m00_axi_rready;


    /* ---------------- WRITE ADDRESS ---------------- */

    assign uart_axi_awid    = {4'b0000, m00_axi_awid};
    assign uart_axi_awaddr  = m00_axi_awaddr[4:0];
    assign uart_axi_awvalid = m00_axi_awvalid;

    assign m00_axi_awready  = uart_axi_awready;


    /* ---------------- WRITE DATA ---------------- */

    assign uart_axi_wdata   = m00_axi_wdata;
    assign uart_axi_wstrb   = m00_axi_wstrb;
    assign uart_axi_wvalid  = m00_axi_wvalid;

    assign m00_axi_wready   = uart_axi_wready;


    /* ---------------- WRITE RESPONSE ---------------- */

    assign m00_axi_bid      = uart_axi_bid[7:0];
    assign m00_axi_bresp    = uart_axi_bresp;
    assign m00_axi_buser    = 1'b0;
    assign m00_axi_bvalid   = uart_axi_bvalid;

    assign uart_axi_bready  = m00_axi_bready;


    /* ============================================================
     * UART INSTANCE
     * Exact port names taken from the supplied axi_uart_top.v
     * ============================================================ */

    axi_uart_top u_uart (

        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (uart_axi_arid),
        .axi_araddr_i      (uart_axi_araddr),
        .axi_arvalid_i     (uart_axi_arvalid),
        .axi_arready_o     (uart_axi_arready),

        .axi_rid_o         (uart_axi_rid),
        .axi_rdata_o       (uart_axi_rdata),
        .axi_rresp_o       (uart_axi_rresp),
        .axi_rvalid_o      (uart_axi_rvalid),
        .axi_rready_i      (uart_axi_rready),

        .axi_awid_i        (uart_axi_awid),
        .axi_awaddr_i      (uart_axi_awaddr),
        .axi_awvalid_i     (uart_axi_awvalid),
        .axi_awready_o     (uart_axi_awready),

        .axi_wdata_i       (uart_axi_wdata),
        .axi_wstrb_i       (uart_axi_wstrb),
        .axi_wvalid_i      (uart_axi_wvalid),
        .axi_wready_o      (uart_axi_wready),

        .axi_bid_o         (uart_axi_bid),
        .axi_bresp_o       (uart_axi_bresp),
        .axi_bvalid_o      (uart_axi_bvalid),
        .axi_bready_i      (uart_axi_bready),

        .read_interrupt_o  (uart_read_interrupt),

        .uart_rx_i         (uart_rx_i),
        .uart_tx_o         (uart_tx_o)
    );


    /* ============================================================
     * SPI AXI4-Lite ADAPTATION
     *
     * Interconnect M02:
     *   AXI ID    = 8 bits
     *   AXI addr  = 32 bits
     *   AXI data  = 32 bits
     *
     * axi_spi_top:
     *   AXI ID    = 12 bits
     *   AXI addr  = 7 bits
     *   AXI data  = 32 bits
     *
     * The interconnect already decodes the 0x4000_2000 window,
     * therefore only the low 7 address bits are passed to SPI.
     * The SPI IP is AXI4-Lite, so burst-related signals from the
     * interconnect are intentionally not passed to it.
     * ============================================================ */

    wire [11:0] spi_axi_arid;
    wire [6:0]  spi_axi_araddr;
    wire        spi_axi_arvalid;
    wire        spi_axi_arready;

    wire [11:0] spi_axi_rid;
    wire [31:0] spi_axi_rdata;
    wire [1:0]  spi_axi_rresp;
    wire        spi_axi_rvalid;
    wire        spi_axi_rready;

    wire [11:0] spi_axi_awid;
    wire [6:0]  spi_axi_awaddr;
    wire        spi_axi_awvalid;
    wire        spi_axi_awready;

    wire [31:0] spi_axi_wdata;
    wire [3:0]  spi_axi_wstrb;
    wire        spi_axi_wvalid;
    wire        spi_axi_wready;

    wire [11:0] spi_axi_bid;
    wire [1:0]  spi_axi_bresp;
    wire        spi_axi_bvalid;
    wire        spi_axi_bready;

    assign spi_axi_arid    = {4'b0000, m02_axi_arid};
    assign spi_axi_araddr  = m02_axi_araddr[6:0];
    assign spi_axi_arvalid = m02_axi_arvalid;
    assign m02_axi_arready = spi_axi_arready;

    assign m02_axi_rid     = spi_axi_rid[7:0];
    assign m02_axi_rdata   = spi_axi_rdata;
    assign m02_axi_rresp   = spi_axi_rresp;
    assign m02_axi_rlast   = 1'b1;
    assign m02_axi_ruser   = 1'b0;
    assign m02_axi_rvalid  = spi_axi_rvalid;
    assign spi_axi_rready  = m02_axi_rready;

    assign spi_axi_awid    = {4'b0000, m02_axi_awid};
    assign spi_axi_awaddr  = m02_axi_awaddr[6:0];
    assign spi_axi_awvalid = m02_axi_awvalid;
    assign m02_axi_awready = spi_axi_awready;

    assign spi_axi_wdata   = m02_axi_wdata;
    assign spi_axi_wstrb   = m02_axi_wstrb;
    assign spi_axi_wvalid  = m02_axi_wvalid;
    assign m02_axi_wready  = spi_axi_wready;

    assign m02_axi_bid     = spi_axi_bid[7:0];
    assign m02_axi_bresp   = spi_axi_bresp;
    assign m02_axi_buser   = 1'b0;
    assign m02_axi_bvalid  = spi_axi_bvalid;
    assign spi_axi_bready  = m02_axi_bready;

    /* ============================================================
     * SPI INSTANCE
     * Exact port names taken from the supplied axi_spi_top.v.
     * ============================================================ */

    axi_spi_top u_spi (
        .fixed_clk_i       (clk),
        .axi_aclk_i        (clk),
        .axi_aresetn_i     (~rst),

        .axi_arid_i        (spi_axi_arid),
        .axi_araddr_i      (spi_axi_araddr),
        .axi_arvalid_i     (spi_axi_arvalid),
        .axi_arready_o     (spi_axi_arready),

        .axi_rid_o         (spi_axi_rid),
        .axi_rdata_o       (spi_axi_rdata),
        .axi_rresp_o       (spi_axi_rresp),
        .axi_rvalid_o      (spi_axi_rvalid),
        .axi_rready_i      (spi_axi_rready),

        .axi_awid_i        (spi_axi_awid),
        .axi_awaddr_i      (spi_axi_awaddr),
        .axi_awvalid_i     (spi_axi_awvalid),
        .axi_awready_o     (spi_axi_awready),

        .axi_wdata_i       (spi_axi_wdata),
        .axi_wstrb_i       (spi_axi_wstrb),
        .axi_wvalid_i      (spi_axi_wvalid),
        .axi_wready_o      (spi_axi_wready),

        .axi_bid_o         (spi_axi_bid),
        .axi_bresp_o       (spi_axi_bresp),
        .axi_bvalid_o      (spi_axi_bvalid),
        .axi_bready_i      (spi_axi_bready),

        .spi_clk_o         (spi_clk_o),
        .spi_cs_n_o        (spi_cs_n_o),
        .spi_mosi_o        (spi_mosi_o),
        .spi_miso_i        (spi_miso_i)
    );

    /* ============================================================
     * FIR AXI4-Lite ADAPTATION
     *
     * Interconnect M03:
     *   AXI ID   = 8 bits
     *   AXI addr = 32 bits
     *   AXI data = 32 bits
     *
     * FIR AXI4-Lite:
     *   AXI addr = 32 bits
     *   AXI data = 32 bits
     *
     * The interconnect performs the 0x4000_3000 window decode.
     * Only the AXI4-Lite subset is passed to the FIR.
     * ============================================================ */

    wire [31:0] fir_axi_awaddr;
    wire        fir_axi_awvalid;
    wire        fir_axi_awready;

    wire [31:0] fir_axi_wdata;
    wire [3:0]  fir_axi_wstrb;
    wire        fir_axi_wvalid;
    wire        fir_axi_wready;

    wire        fir_axi_bvalid;
    wire [1:0]  fir_axi_bresp;
    wire        fir_axi_bready;

    wire [31:0] fir_axi_araddr;
    wire        fir_axi_arvalid;
    wire        fir_axi_arready;

    wire [31:0] fir_axi_rdata;
    wire        fir_axi_rvalid;
    wire [1:0]  fir_axi_rresp;
    wire        fir_axi_rready;

    // Convert SoC absolute M03 address to FIR local AXI4-Lite offset.
    // M03 base = 0x4000_3000, while FIR registers are decoded from 0x0000_0000.
    localparam [31:0] FIR_BASE_ADDR = 32'h4000_3000;

    assign fir_axi_awaddr  = m03_axi_awaddr - FIR_BASE_ADDR;
    assign fir_axi_awvalid = m03_axi_awvalid;
    assign m03_axi_awready = fir_axi_awready;

    assign fir_axi_wdata   = m03_axi_wdata;
    assign fir_axi_wstrb   = m03_axi_wstrb;
    assign fir_axi_wvalid  = m03_axi_wvalid;
    assign m03_axi_wready  = fir_axi_wready;

    assign m03_axi_bresp   = fir_axi_bresp;
    assign m03_axi_bvalid  = fir_axi_bvalid;
    assign m03_axi_buser   = 1'b0;
    assign m03_axi_bid     = m03_axi_awid;
    assign fir_axi_bready  = m03_axi_bready;

    assign fir_axi_araddr  = m03_axi_araddr - FIR_BASE_ADDR;
    assign fir_axi_arvalid = m03_axi_arvalid;
    assign m03_axi_arready = fir_axi_arready;

    assign m03_axi_rdata   = fir_axi_rdata;
    assign m03_axi_rresp   = fir_axi_rresp;
    assign m03_axi_rvalid  = fir_axi_rvalid;
    assign m03_axi_ruser   = 1'b0;
    assign m03_axi_rid     = m03_axi_arid;
    assign m03_axi_rlast   = 1'b1;
    assign fir_axi_rready  = m03_axi_rready;

    fir_top #(
        .DATA_WIDTH (16),
        .COEFF_WIDTH(16),
        .ACC_WIDTH  (40),
        .NUM_TAPS   (32),
        .FIFO_DEPTH (8)
    ) u_fir (
        .clk                (clk),
        .rst_n              (~rst),

        .s_axis_tvalid     (fir_s_axis_tvalid),
        .s_axis_tready     (fir_s_axis_tready),
        .s_axis_tdata      (fir_s_axis_tdata),

        .m_axis_tvalid     (fir_m_axis_tvalid),
        .m_axis_tready     (fir_m_axis_tready),
        .m_axis_tdata      (fir_m_axis_tdata),

        .s_axi_awaddr      (fir_axi_awaddr),
        .s_axi_awvalid     (fir_axi_awvalid),
        .s_axi_awready     (fir_axi_awready),

        .s_axi_wdata       (fir_axi_wdata),
        .s_axi_wstrb       (fir_axi_wstrb),
        .s_axi_wvalid      (fir_axi_wvalid),
        .s_axi_wready      (fir_axi_wready),

        .s_axi_bvalid      (fir_axi_bvalid),
        .s_axi_bresp       (fir_axi_bresp),
        .s_axi_bready      (fir_axi_bready),

        .s_axi_araddr      (fir_axi_araddr),
        .s_axi_arvalid     (fir_axi_arvalid),
        .s_axi_arready     (fir_axi_arready),

        .s_axi_rdata       (fir_axi_rdata),
        .s_axi_rvalid      (fir_axi_rvalid),
        .s_axi_rresp       (fir_axi_rresp),
        .s_axi_rready      (fir_axi_rready),

        .input_fifo_full   (),
        .input_fifo_empty  (),
        .output_fifo_empty ()
    );

    /* ============================================================
     * QRS AXI4 WRAPPER
     *
     * Interconnect M01:
     *   0x4000_1000 - 0x4000_1FFF
     *
     * QRS register offsets:
     *   +0x00 CONTROL
     *   +0x04 STATUS
     *   +0x08 ECG_INPUT
     *   +0x0C RPEAK
     *   +0x10 RR_INTERVAL
     *   +0x14 BPM
     *   +0x18 RHYTHM_CLASS
     * ============================================================ */

    qrs_axi4_wrapper #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .FS         (360),
        .BASE_ADDR  (32'h4000_1000)
    ) u_qrs (
        .clk          (clk),
        .rst          (rst),

        .s_axi_awid   (m01_axi_awid),
        .s_axi_awaddr (m01_axi_awaddr),
        .s_axi_awlen  (m01_axi_awlen),
        .s_axi_awsize (m01_axi_awsize),
        .s_axi_awburst(m01_axi_awburst),
        .s_axi_awlock (m01_axi_awlock),
        .s_axi_awcache(m01_axi_awcache),
        .s_axi_awprot (m01_axi_awprot),
        .s_axi_awqos  (m01_axi_awqos),
        .s_axi_awvalid(m01_axi_awvalid),
        .s_axi_awready(m01_axi_awready),

        .s_axi_wdata  (m01_axi_wdata),
        .s_axi_wstrb  (m01_axi_wstrb),
        .s_axi_wlast  (m01_axi_wlast),
        .s_axi_wvalid (m01_axi_wvalid),
        .s_axi_wready (m01_axi_wready),

        .s_axi_bid    (m01_axi_bid),
        .s_axi_bresp  (m01_axi_bresp),
        .s_axi_bvalid (m01_axi_bvalid),
        .s_axi_bready (m01_axi_bready),

        .s_axi_arid   (m01_axi_arid),
        .s_axi_araddr (m01_axi_araddr),
        .s_axi_arlen  (m01_axi_arlen),
        .s_axi_arsize (m01_axi_arsize),
        .s_axi_arburst(m01_axi_arburst),
        .s_axi_arlock (m01_axi_arlock),
        .s_axi_arcache(m01_axi_arcache),
        .s_axi_arprot (m01_axi_arprot),
        .s_axi_arqos  (m01_axi_arqos),
        .s_axi_arvalid(m01_axi_arvalid),
        .s_axi_arready(m01_axi_arready),

        .s_axi_rid    (m01_axi_rid),
        .s_axi_rdata  (m01_axi_rdata),
        .s_axi_rresp  (m01_axi_rresp),
        .s_axi_rlast  (m01_axi_rlast),
        .s_axi_rvalid (m01_axi_rvalid),
        .s_axi_rready (m01_axi_rready)
    );

    /* ============================================================
     * ADC INSTANCE
     *
     * Native 32-bit AXI4-Lite interface.
     * No wrapper is used.
     * ============================================================ */

    adc_controller #(
        .ADC_RESOLUTION    (12),
        .NUM_CHANNELS      (1),
        .FIFO_DEPTH        (32),
        .CLK_FREQ_HZ       (50_000_000),
        .SAMPLE_RATE_HZ    (250),
        .BASE_ADDR         (32'h4000_4000),
        .ENABLE_FIFO       (1),
        .ENABLE_INTERRUPTS (1)
    ) u_adc (
        .aclk            (clk),
        .aresetn         (~rst),

        .sample_in       (adc_sample_in),
        .sample_valid    (adc_sample_valid),

        .irq_sample      (adc_irq_sample),
        .irq_overrun     (adc_irq_overrun),

        .s_axi_awaddr    (m04_axi_awaddr),
        .s_axi_awvalid   (m04_axi_awvalid),
        .s_axi_awready   (m04_axi_awready),

        .s_axi_wdata    (m04_axi_wdata),
        .s_axi_wstrb    (m04_axi_wstrb),
        .s_axi_wvalid   (m04_axi_wvalid),
        .s_axi_wready   (m04_axi_wready),

        .s_axi_bresp    (m04_axi_bresp),
        .s_axi_bvalid   (m04_axi_bvalid),
        .s_axi_bready   (m04_axi_bready),

        .s_axi_araddr   (m04_axi_araddr),
        .s_axi_arvalid  (m04_axi_arvalid),
        .s_axi_arready  (m04_axi_arready),

        .s_axi_rdata    (m04_axi_rdata),
        .s_axi_rresp   (m04_axi_rresp),
        .s_axi_rvalid  (m04_axi_rvalid),
        .s_axi_rready  (m04_axi_rready)
    );

    /*
     * AXI4 fields not used by the native AXI4-Lite ADC.
     * M04 transactions in this integration are single-beat.
     */
    assign m04_axi_bid   = {ID_WIDTH{1'b0}};
    assign m04_axi_buser = 1'b0;
    assign m04_axi_rid   = {ID_WIDTH{1'b0}};
    assign m04_axi_ruser = 1'b0;
    assign m04_axi_rlast = 1'b1;

    /* ============================================================
     * M05 AXI4 -> AXI4-Lite BRIDGE -> GPIO
     *
     * The AXI 3x14 interconnect is a full AXI4 fabric. The Gemini GPIO
     * peripheral is AXI4-Lite. Do not connect the two protocols directly.
     * This bridge provides the required single-beat protocol boundary.
     * ============================================================ */

    wire [ADDR_WIDTH-1:0] gpio_lite_awaddr;
    wire [2:0]            gpio_lite_awprot;
    wire                  gpio_lite_awvalid;
    wire                  gpio_lite_awready;
    wire [DATA_WIDTH-1:0] gpio_lite_wdata;
    wire [STRB_WIDTH-1:0] gpio_lite_wstrb;
    wire                  gpio_lite_wvalid;
    wire                  gpio_lite_wready;
    wire [1:0]            gpio_lite_bresp;
    wire                  gpio_lite_bvalid;
    wire                  gpio_lite_bready;
    wire [ADDR_WIDTH-1:0] gpio_lite_araddr;
    wire [2:0]            gpio_lite_arprot;
    wire                  gpio_lite_arvalid;
    wire                  gpio_lite_arready;
    wire [DATA_WIDTH-1:0] gpio_lite_rdata;
    wire [1:0]            gpio_lite_rresp;
    wire                  gpio_lite_rvalid;
    wire                  gpio_lite_rready;

    axi4_to_axi4lite_bridge #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .STRB_WIDTH (STRB_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .USER_WIDTH (1)
    ) u_gpio_axi_bridge (
        .aclk        (clk),
        .aresetn     (~rst),

        .s_awid      (m05_axi_awid),
        .s_awaddr    (m05_axi_awaddr),
        .s_awlen     (m05_axi_awlen),
        .s_awsize    (m05_axi_awsize),
        .s_awburst   (m05_axi_awburst),
        .s_awlock    (m05_axi_awlock),
        .s_awcache   (m05_axi_awcache),
        .s_awprot    (m05_axi_awprot),
        .s_awqos     (m05_axi_awqos),
        .s_awregion  (m05_axi_awregion),
        .s_awuser    (m05_axi_awuser),
        .s_awvalid   (m05_axi_awvalid),
        .s_awready   (m05_axi_awready),

        .s_wdata     (m05_axi_wdata),
        .s_wstrb     (m05_axi_wstrb),
        .s_wlast     (m05_axi_wlast),
        .s_wuser     (m05_axi_wuser),
        .s_wvalid    (m05_axi_wvalid),
        .s_wready    (m05_axi_wready),

        .s_bid       (m05_axi_bid),
        .s_bresp     (m05_axi_bresp),
        .s_buser     (m05_axi_buser),
        .s_bvalid    (m05_axi_bvalid),
        .s_bready    (m05_axi_bready),

        .s_arid      (m05_axi_arid),
        .s_araddr    (m05_axi_araddr),
        .s_arlen     (m05_axi_arlen),
        .s_arsize    (m05_axi_arsize),
        .s_arburst   (m05_axi_arburst),
        .s_arlock    (m05_axi_arlock),
        .s_arcache   (m05_axi_arcache),
        .s_arprot    (m05_axi_arprot),
        .s_arqos     (m05_axi_arqos),
        .s_arregion  (m05_axi_arregion),
        .s_aruser    (m05_axi_aruser),
        .s_arvalid   (m05_axi_arvalid),
        .s_arready   (m05_axi_arready),

        .s_rid       (m05_axi_rid),
        .s_rdata     (m05_axi_rdata),
        .s_rresp     (m05_axi_rresp),
        .s_rlast     (m05_axi_rlast),
        .s_ruser     (m05_axi_ruser),
        .s_rvalid    (m05_axi_rvalid),
        .s_rready    (m05_axi_rready),

        .m_awaddr    (gpio_lite_awaddr),
        .m_awprot    (gpio_lite_awprot),
        .m_awvalid   (gpio_lite_awvalid),
        .m_awready   (gpio_lite_awready),
        .m_wdata     (gpio_lite_wdata),
        .m_wstrb     (gpio_lite_wstrb),
        .m_wvalid    (gpio_lite_wvalid),
        .m_wready    (gpio_lite_wready),
        .m_bresp     (gpio_lite_bresp),
        .m_bvalid    (gpio_lite_bvalid),
        .m_bready    (gpio_lite_bready),
        .m_araddr    (gpio_lite_araddr),
        .m_arprot    (gpio_lite_arprot),
        .m_arvalid   (gpio_lite_arvalid),
        .m_arready   (gpio_lite_arready),
        .m_rdata     (gpio_lite_rdata),
        .m_rresp     (gpio_lite_rresp),
        .m_rvalid    (gpio_lite_rvalid),
        .m_rready    (gpio_lite_rready)
    );

    gpio_axi #(
        .NUM_BITS(8)
    ) u_gpio (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (~rst),

        .s_axi_awaddr  (gpio_lite_awaddr),
        .s_axi_awprot  (gpio_lite_awprot),
        .s_axi_awvalid (gpio_lite_awvalid),
        .s_axi_awready (gpio_lite_awready),
        .s_axi_wdata   (gpio_lite_wdata),
        .s_axi_wstrb   (gpio_lite_wstrb),
        .s_axi_wvalid  (gpio_lite_wvalid),
        .s_axi_wready  (gpio_lite_wready),
        .s_axi_bresp   (gpio_lite_bresp),
        .s_axi_bvalid  (gpio_lite_bvalid),
        .s_axi_bready  (gpio_lite_bready),
        .s_axi_araddr  (gpio_lite_araddr),
        .s_axi_arprot  (gpio_lite_arprot),
        .s_axi_arvalid (gpio_lite_arvalid),
        .s_axi_arready (gpio_lite_arready),
        .s_axi_rdata   (gpio_lite_rdata),
        .s_axi_rresp   (gpio_lite_rresp),
        .s_axi_rvalid  (gpio_lite_rvalid),
        .s_axi_rready  (gpio_lite_rready),
        .io            (gpio_io),
        .intr          (gpio_irq)
    );

    /* ============================================================
     * M06 AXI4 -> AXI4-Lite BRIDGE -> TIMER
     * ============================================================ */

    wire [ADDR_WIDTH-1:0] timer_lite_awaddr;
    wire [2:0]            timer_lite_awprot;
    wire                  timer_lite_awvalid;
    wire                  timer_lite_awready;
    wire [DATA_WIDTH-1:0] timer_lite_wdata;
    wire [STRB_WIDTH-1:0] timer_lite_wstrb;
    wire                  timer_lite_wvalid;
    wire                  timer_lite_wready;
    wire [1:0]            timer_lite_bresp;
    wire                  timer_lite_bvalid;
    wire                  timer_lite_bready;
    wire [ADDR_WIDTH-1:0] timer_lite_araddr;
    wire [2:0]            timer_lite_arprot;
    wire                  timer_lite_arvalid;
    wire                  timer_lite_arready;
    wire [DATA_WIDTH-1:0] timer_lite_rdata;
    wire [1:0]            timer_lite_rresp;
    wire                  timer_lite_rvalid;
    wire                  timer_lite_rready;

    axi4_to_axi4lite_bridge #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH),
        .STRB_WIDTH (STRB_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .USER_WIDTH (1)
    ) u_timer_axi_bridge (
        .aclk        (clk),
        .aresetn     (~rst),

        .s_awid      (m06_axi_awid),
        .s_awaddr    (m06_axi_awaddr),
        .s_awlen     (m06_axi_awlen),
        .s_awsize    (m06_axi_awsize),
        .s_awburst   (m06_axi_awburst),
        .s_awlock    (m06_axi_awlock),
        .s_awcache   (m06_axi_awcache),
        .s_awprot    (m06_axi_awprot),
        .s_awqos     (m06_axi_awqos),
        .s_awregion  (m06_axi_awregion),
        .s_awuser    (m06_axi_awuser),
        .s_awvalid   (m06_axi_awvalid),
        .s_awready   (m06_axi_awready),

        .s_wdata     (m06_axi_wdata),
        .s_wstrb     (m06_axi_wstrb),
        .s_wlast     (m06_axi_wlast),
        .s_wuser     (m06_axi_wuser),
        .s_wvalid    (m06_axi_wvalid),
        .s_wready    (m06_axi_wready),

        .s_bid       (m06_axi_bid),
        .s_bresp     (m06_axi_bresp),
        .s_buser     (m06_axi_buser),
        .s_bvalid    (m06_axi_bvalid),
        .s_bready    (m06_axi_bready),

        .s_arid      (m06_axi_arid),
        .s_araddr    (m06_axi_araddr),
        .s_arlen     (m06_axi_arlen),
        .s_arsize    (m06_axi_arsize),
        .s_arburst   (m06_axi_arburst),
        .s_arlock    (m06_axi_arlock),
        .s_arcache   (m06_axi_arcache),
        .s_arprot    (m06_axi_arprot),
        .s_arqos     (m06_axi_arqos),
        .s_arregion  (m06_axi_arregion),
        .s_aruser    (m06_axi_aruser),
        .s_arvalid   (m06_axi_arvalid),
        .s_arready   (m06_axi_arready),

        .s_rid       (m06_axi_rid),
        .s_rdata     (m06_axi_rdata),
        .s_rresp     (m06_axi_rresp),
        .s_rlast     (m06_axi_rlast),
        .s_ruser     (m06_axi_ruser),
        .s_rvalid    (m06_axi_rvalid),
        .s_rready    (m06_axi_rready),

        .m_awaddr    (timer_lite_awaddr),
        .m_awprot    (timer_lite_awprot),
        .m_awvalid   (timer_lite_awvalid),
        .m_awready   (timer_lite_awready),
        .m_wdata     (timer_lite_wdata),
        .m_wstrb     (timer_lite_wstrb),
        .m_wvalid    (timer_lite_wvalid),
        .m_wready    (timer_lite_wready),
        .m_bresp     (timer_lite_bresp),
        .m_bvalid    (timer_lite_bvalid),
        .m_bready    (timer_lite_bready),
        .m_araddr    (timer_lite_araddr),
        .m_arprot    (timer_lite_arprot),
        .m_arvalid   (timer_lite_arvalid),
        .m_arready   (timer_lite_arready),
        .m_rdata     (timer_lite_rdata),
        .m_rresp     (timer_lite_rresp),
        .m_rvalid    (timer_lite_rvalid),
        .m_rready    (timer_lite_rready)
    );

    timer_axi u_timer (
        .aclk         (clk),
        .aresetn      (~rst),
        .awaddr       (timer_lite_awaddr),
        .awprot       (timer_lite_awprot),
        .awvalid      (timer_lite_awvalid),
        .awready      (timer_lite_awready),
        .wdata        (timer_lite_wdata),
        .wstrb        (timer_lite_wstrb),
        .wvalid       (timer_lite_wvalid),
        .wready       (timer_lite_wready),
        .bresp        (timer_lite_bresp),
        .bvalid       (timer_lite_bvalid),
        .bready       (timer_lite_bready),
        .araddr       (timer_lite_araddr),
        .arprot       (timer_lite_arprot),
        .arvalid      (timer_lite_arvalid),
        .arready      (timer_lite_arready),
        .rdata        (timer_lite_rdata),
        .rresp        (timer_lite_rresp),
        .rvalid       (timer_lite_rvalid),
        .rready       (timer_lite_rready),
        .ext_meas_i   (timer_ext_meas_i),
        .capture_i    (timer_capture_i),
        .pwm_o        (timer_pwm_o),
        .trigger_o    (timer_trigger_o),
        .irq          (timer_irq)
    );

endmodule
