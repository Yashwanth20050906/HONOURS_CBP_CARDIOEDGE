//`timescale 1ns/1ps

module soc_uart_qrs_spi_top #(
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
    output wire                     spi_mosi_o
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
     * M02-M13 remain unused.
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

        .M03_ADDR_WIDTH    (32'd0),
        .M03_CONNECT_READ  (3'b000),
        .M03_CONNECT_WRITE (3'b000),

        .M04_ADDR_WIDTH    (32'd0),
        .M04_CONNECT_READ  (3'b000),
        .M04_CONNECT_WRITE (3'b000),

        .M05_ADDR_WIDTH    (32'd0),
        .M05_CONNECT_READ  (3'b000),
        .M05_CONNECT_WRITE (3'b000),

        .M06_ADDR_WIDTH    (32'd0),
        .M06_CONNECT_READ  (3'b000),
        .M06_CONNECT_WRITE (3'b000),

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
        .m02_axi_rready   (m02_axi_rready)

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

endmodule
