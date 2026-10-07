// ============================================================================
// cardioedge_veer_soc_top.sv
//
// CARDIOEDGE Phase 4 — VeeR EL2 SoC integration top (IFU + IMEM only)
//
// Architecture:
//   VeeR IFU AXI64
//     → axi_64to32_adapter (IFU)
//       → S00 of 3x14 AXI interconnect
//         → M07 → axi_imem_slave  (0x00000000–0x0000FFFF, 64 KB)
//
//   VeeR LSU AXI64
//     → axi_64to32_adapter (LSU)
//       → S01 of 3x14 AXI interconnect (no masters connected yet)
//
//   S02 = dummy / inactive
//   M00–M06 = tied off (not yet connected)
//   M08–M13 = tied off (reserved)
//
// Reset convention:
//   External active-high rst_n_in → inverted to active-low rst_l for VeeR
//   Active-low aresetn for AXI slaves / interconnect
//
// DO NOT modify soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv.
// This is a completely separate integration top.
// ============================================================================

`include "common_defines.vh"

module cardioedge_veer_soc_top (
    input  logic clk,
    input  logic rst_n      // active-low system reset
);

    // -----------------------------------------------------------------------
    // Reset distribution
    // -----------------------------------------------------------------------
    // VeeR wants active-low rst_l
    logic rst_l;
    assign rst_l = rst_n;

    // AXI slaves want active-low aresetn
    logic aresetn;
    assign aresetn = rst_n;

    // Interconnect wants active-high rst
    logic rst;
    assign rst = ~rst_n;

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 32;
    localparam STRB_WIDTH = DATA_WIDTH/8;
    localparam ID_WIDTH   = 8;

    // -----------------------------------------------------------------------
    // Internal 64-bit AXI buses: VeeR → adapters
    // -----------------------------------------------------------------------

    // --- IFU (VeeR master → adapter slave) ---
    logic                  ifu64_awvalid, ifu64_awready;
    logic [2:0]            ifu64_awid;
    logic [31:0]           ifu64_awaddr;
    logic [3:0]            ifu64_awregion;
    logic [7:0]            ifu64_awlen;
    logic [2:0]            ifu64_awsize;
    logic [1:0]            ifu64_awburst;
    logic                  ifu64_awlock;
    logic [3:0]            ifu64_awcache;
    logic [2:0]            ifu64_awprot;
    logic [3:0]            ifu64_awqos;
    logic                  ifu64_wvalid, ifu64_wready;
    logic [63:0]           ifu64_wdata;
    logic [7:0]            ifu64_wstrb;
    logic                  ifu64_wlast;
    logic                  ifu64_bvalid, ifu64_bready;
    logic [1:0]            ifu64_bresp;
    logic [2:0]            ifu64_bid;
    logic                  ifu64_arvalid, ifu64_arready;
    logic [2:0]            ifu64_arid;
    logic [31:0]           ifu64_araddr;
    logic [3:0]            ifu64_arregion;
    logic [7:0]            ifu64_arlen;
    logic [2:0]            ifu64_arsize;
    logic [1:0]            ifu64_arburst;
    logic                  ifu64_arlock;
    logic [3:0]            ifu64_arcache;
    logic [2:0]            ifu64_arprot;
    logic [3:0]            ifu64_arqos;
    logic                  ifu64_rvalid, ifu64_rready;
    logic [2:0]            ifu64_rid;
    logic [63:0]           ifu64_rdata;
    logic [1:0]            ifu64_rresp;
    logic                  ifu64_rlast;

    // --- LSU (VeeR master → adapter slave) ---
    logic                  lsu64_awvalid, lsu64_awready;
    logic [2:0]            lsu64_awid;
    logic [31:0]           lsu64_awaddr;
    logic [3:0]            lsu64_awregion;
    logic [7:0]            lsu64_awlen;
    logic [2:0]            lsu64_awsize;
    logic [1:0]            lsu64_awburst;
    logic                  lsu64_awlock;
    logic [3:0]            lsu64_awcache;
    logic [2:0]            lsu64_awprot;
    logic [3:0]            lsu64_awqos;
    logic                  lsu64_wvalid, lsu64_wready;
    logic [63:0]           lsu64_wdata;
    logic [7:0]            lsu64_wstrb;
    logic                  lsu64_wlast;
    logic                  lsu64_bvalid, lsu64_bready;
    logic [1:0]            lsu64_bresp;
    logic [2:0]            lsu64_bid;
    logic                  lsu64_arvalid, lsu64_arready;
    logic [2:0]            lsu64_arid;
    logic [31:0]           lsu64_araddr;
    logic [3:0]            lsu64_arregion;
    logic [7:0]            lsu64_arlen;
    logic [2:0]            lsu64_arsize;
    logic [1:0]            lsu64_arburst;
    logic                  lsu64_arlock;
    logic [3:0]            lsu64_arcache;
    logic [2:0]            lsu64_arprot;
    logic [3:0]            lsu64_arqos;
    logic                  lsu64_rvalid, lsu64_rready;
    logic [2:0]            lsu64_rid;
    logic [63:0]           lsu64_rdata;
    logic [1:0]            lsu64_rresp;
    logic                  lsu64_rlast;

    // -----------------------------------------------------------------------
    // Internal 32-bit AXI buses: adapters → interconnect slave ports
    // -----------------------------------------------------------------------

    // --- S00 (IFU adapter → interconnect) ---
    logic [ID_WIDTH-1:0]   s00_awid;
    logic [ADDR_WIDTH-1:0] s00_awaddr;
    logic [7:0]            s00_awlen;
    logic [2:0]            s00_awsize;
    logic [1:0]            s00_awburst;
    logic                  s00_awlock;
    logic [3:0]            s00_awcache;
    logic [2:0]            s00_awprot;
    logic [3:0]            s00_awqos;
    logic                  s00_awvalid, s00_awready;
    logic [DATA_WIDTH-1:0] s00_wdata;
    logic [STRB_WIDTH-1:0] s00_wstrb;
    logic                  s00_wlast;
    logic                  s00_wvalid, s00_wready;
    logic [ID_WIDTH-1:0]   s00_bid;
    logic [1:0]            s00_bresp;
    logic                  s00_bvalid, s00_bready;
    logic [ID_WIDTH-1:0]   s00_arid;
    logic [ADDR_WIDTH-1:0] s00_araddr;
    logic [7:0]            s00_arlen;
    logic [2:0]            s00_arsize;
    logic [1:0]            s00_arburst;
    logic                  s00_arlock;
    logic [3:0]            s00_arcache;
    logic [2:0]            s00_arprot;
    logic [3:0]            s00_arqos;
    logic                  s00_arvalid, s00_arready;
    logic [ID_WIDTH-1:0]   s00_rid;
    logic [DATA_WIDTH-1:0] s00_rdata;
    logic [1:0]            s00_rresp;
    logic                  s00_rlast;
    logic                  s00_rvalid, s00_rready;

    // --- S01 (LSU adapter → interconnect) ---
    logic [ID_WIDTH-1:0]   s01_awid;
    logic [ADDR_WIDTH-1:0] s01_awaddr;
    logic [7:0]            s01_awlen;
    logic [2:0]            s01_awsize;
    logic [1:0]            s01_awburst;
    logic                  s01_awlock;
    logic [3:0]            s01_awcache;
    logic [2:0]            s01_awprot;
    logic [3:0]            s01_awqos;
    logic                  s01_awvalid, s01_awready;
    logic [DATA_WIDTH-1:0] s01_wdata;
    logic [STRB_WIDTH-1:0] s01_wstrb;
    logic                  s01_wlast;
    logic                  s01_wvalid, s01_wready;
    logic [ID_WIDTH-1:0]   s01_bid;
    logic [1:0]            s01_bresp;
    logic                  s01_bvalid, s01_bready;
    logic [ID_WIDTH-1:0]   s01_arid;
    logic [ADDR_WIDTH-1:0] s01_araddr;
    logic [7:0]            s01_arlen;
    logic [2:0]            s01_arsize;
    logic [1:0]            s01_arburst;
    logic                  s01_arlock;
    logic [3:0]            s01_arcache;
    logic [2:0]            s01_arprot;
    logic [3:0]            s01_arqos;
    logic                  s01_arvalid, s01_arready;
    logic [ID_WIDTH-1:0]   s01_rid;
    logic [DATA_WIDTH-1:0] s01_rdata;
    logic [1:0]            s01_rresp;
    logic                  s01_rlast;
    logic                  s01_rvalid, s01_rready;

    // -----------------------------------------------------------------------
    // Internal 32-bit AXI buses: interconnect master → IMEM slave (M07)
    // -----------------------------------------------------------------------
    logic [ID_WIDTH-1:0]   m07_awid;
    logic [ADDR_WIDTH-1:0] m07_awaddr;
    logic [7:0]            m07_awlen;
    logic [2:0]            m07_awsize;
    logic [1:0]            m07_awburst;
    logic                  m07_awlock;
    logic [3:0]            m07_awcache;
    logic [2:0]            m07_awprot;
    logic [3:0]            m07_awqos;
    logic [3:0]            m07_awregion;
    logic                  m07_awvalid, m07_awready;
    logic [DATA_WIDTH-1:0] m07_wdata;
    logic [STRB_WIDTH-1:0] m07_wstrb;
    logic                  m07_wlast;
    logic                  m07_wvalid, m07_wready;
    logic [ID_WIDTH-1:0]   m07_bid;
    logic [1:0]            m07_bresp;
    logic                  m07_bvalid, m07_bready;
    logic [ID_WIDTH-1:0]   m07_arid;
    logic [ADDR_WIDTH-1:0] m07_araddr;
    logic [7:0]            m07_arlen;
    logic [2:0]            m07_arsize;
    logic [1:0]            m07_arburst;
    logic                  m07_arlock;
    logic [3:0]            m07_arcache;
    logic [2:0]            m07_arprot;
    logic [3:0]            m07_arqos;
    logic [3:0]            m07_arregion;
    logic                  m07_arvalid, m07_arready;
    logic [ID_WIDTH-1:0]   m07_rid;
    logic [DATA_WIDTH-1:0] m07_rdata;
    logic [1:0]            m07_rresp;
    logic                  m07_rlast;
    logic                  m07_rvalid, m07_rready;

    // -----------------------------------------------------------------------
    // VeeR wrapper
    // -----------------------------------------------------------------------
    cardioedge_veer_wrapper u_veer (
        .clk            (clk),
        .rst_l          (rst_l),

        // IFU
        .ifu_axi_awvalid  (ifu64_awvalid),
        .ifu_axi_awready  (ifu64_awready),
        .ifu_axi_awid     (ifu64_awid),
        .ifu_axi_awaddr   (ifu64_awaddr),
        .ifu_axi_awregion (ifu64_awregion),
        .ifu_axi_awlen    (ifu64_awlen),
        .ifu_axi_awsize   (ifu64_awsize),
        .ifu_axi_awburst  (ifu64_awburst),
        .ifu_axi_awlock   (ifu64_awlock),
        .ifu_axi_awcache  (ifu64_awcache),
        .ifu_axi_awprot   (ifu64_awprot),
        .ifu_axi_awqos    (ifu64_awqos),
        .ifu_axi_wvalid   (ifu64_wvalid),
        .ifu_axi_wready   (ifu64_wready),
        .ifu_axi_wdata    (ifu64_wdata),
        .ifu_axi_wstrb    (ifu64_wstrb),
        .ifu_axi_wlast    (ifu64_wlast),
        .ifu_axi_bvalid   (ifu64_bvalid),
        .ifu_axi_bready   (ifu64_bready),
        .ifu_axi_bresp    (ifu64_bresp),
        .ifu_axi_bid      (ifu64_bid),
        .ifu_axi_arvalid  (ifu64_arvalid),
        .ifu_axi_arready  (ifu64_arready),
        .ifu_axi_arid     (ifu64_arid),
        .ifu_axi_araddr   (ifu64_araddr),
        .ifu_axi_arregion (ifu64_arregion),
        .ifu_axi_arlen    (ifu64_arlen),
        .ifu_axi_arsize   (ifu64_arsize),
        .ifu_axi_arburst  (ifu64_arburst),
        .ifu_axi_arlock   (ifu64_arlock),
        .ifu_axi_arcache  (ifu64_arcache),
        .ifu_axi_arprot   (ifu64_arprot),
        .ifu_axi_arqos    (ifu64_arqos),
        .ifu_axi_rvalid   (ifu64_rvalid),
        .ifu_axi_rready   (ifu64_rready),
        .ifu_axi_rid      (ifu64_rid),
        .ifu_axi_rdata    (ifu64_rdata),
        .ifu_axi_rresp    (ifu64_rresp),
        .ifu_axi_rlast    (ifu64_rlast),

        // LSU
        .lsu_axi_awvalid  (lsu64_awvalid),
        .lsu_axi_awready  (lsu64_awready),
        .lsu_axi_awid     (lsu64_awid),
        .lsu_axi_awaddr   (lsu64_awaddr),
        .lsu_axi_awregion (lsu64_awregion),
        .lsu_axi_awlen    (lsu64_awlen),
        .lsu_axi_awsize   (lsu64_awsize),
        .lsu_axi_awburst  (lsu64_awburst),
        .lsu_axi_awlock   (lsu64_awlock),
        .lsu_axi_awcache  (lsu64_awcache),
        .lsu_axi_awprot   (lsu64_awprot),
        .lsu_axi_awqos    (lsu64_awqos),
        .lsu_axi_wvalid   (lsu64_wvalid),
        .lsu_axi_wready   (lsu64_wready),
        .lsu_axi_wdata    (lsu64_wdata),
        .lsu_axi_wstrb    (lsu64_wstrb),
        .lsu_axi_wlast    (lsu64_wlast),
        .lsu_axi_bvalid   (lsu64_bvalid),
        .lsu_axi_bready   (lsu64_bready),
        .lsu_axi_bresp    (lsu64_bresp),
        .lsu_axi_bid      (lsu64_bid),
        .lsu_axi_arvalid  (lsu64_arvalid),
        .lsu_axi_arready  (lsu64_arready),
        .lsu_axi_arid     (lsu64_arid),
        .lsu_axi_araddr   (lsu64_araddr),
        .lsu_axi_arregion (lsu64_arregion),
        .lsu_axi_arlen    (lsu64_arlen),
        .lsu_axi_arsize   (lsu64_arsize),
        .lsu_axi_arburst  (lsu64_arburst),
        .lsu_axi_arlock   (lsu64_arlock),
        .lsu_axi_arcache  (lsu64_arcache),
        .lsu_axi_arprot   (lsu64_arprot),
        .lsu_axi_arqos    (lsu64_arqos),
        .lsu_axi_rvalid   (lsu64_rvalid),
        .lsu_axi_rready   (lsu64_rready),
        .lsu_axi_rid      (lsu64_rid),
        .lsu_axi_rdata    (lsu64_rdata),
        .lsu_axi_rresp    (lsu64_rresp),
        .lsu_axi_rlast    (lsu64_rlast),

        // Interrupts (tied off for Phase 4)
        .timer_int        (1'b0),
        .soft_int         (1'b0),
        .extintsrc_req    (8'b0)
    );

    // -----------------------------------------------------------------------
    // IFU 64→32 adapter  (S00)
    // -----------------------------------------------------------------------
    axi_64to32_adapter #(
        .M_ID_WIDTH (3),
        .S_ID_WIDTH (8)
    ) u_ifu_adapter (
        .clk            (clk),
        .rst_l          (rst_l),

        // 64-bit side (VeeR IFU)
        .m_axi_awvalid  (ifu64_awvalid),
        .m_axi_awready  (ifu64_awready),
        .m_axi_awid     (ifu64_awid),
        .m_axi_awaddr   (ifu64_awaddr),
        .m_axi_awlen    (ifu64_awlen),
        .m_axi_awsize   (ifu64_awsize),
        .m_axi_awburst  (ifu64_awburst),
        .m_axi_awlock   (ifu64_awlock),
        .m_axi_awcache  (ifu64_awcache),
        .m_axi_awprot   (ifu64_awprot),
        .m_axi_awqos    (ifu64_awqos),
        .m_axi_awregion (ifu64_awregion),
        .m_axi_wvalid   (ifu64_wvalid),
        .m_axi_wready   (ifu64_wready),
        .m_axi_wdata    (ifu64_wdata),
        .m_axi_wstrb    (ifu64_wstrb),
        .m_axi_wlast    (ifu64_wlast),
        .m_axi_bvalid   (ifu64_bvalid),
        .m_axi_bready   (ifu64_bready),
        .m_axi_bid      (ifu64_bid),
        .m_axi_bresp    (ifu64_bresp),
        .m_axi_arvalid  (ifu64_arvalid),
        .m_axi_arready  (ifu64_arready),
        .m_axi_arid     (ifu64_arid),
        .m_axi_araddr   (ifu64_araddr),
        .m_axi_arlen    (ifu64_arlen),
        .m_axi_arsize   (ifu64_arsize),
        .m_axi_arburst  (ifu64_arburst),
        .m_axi_arlock   (ifu64_arlock),
        .m_axi_arcache  (ifu64_arcache),
        .m_axi_arprot   (ifu64_arprot),
        .m_axi_arqos    (ifu64_arqos),
        .m_axi_arregion (ifu64_arregion),
        .m_axi_rvalid   (ifu64_rvalid),
        .m_axi_rready   (ifu64_rready),
        .m_axi_rid      (ifu64_rid),
        .m_axi_rdata    (ifu64_rdata),
        .m_axi_rresp    (ifu64_rresp),
        .m_axi_rlast    (ifu64_rlast),

        // 32-bit side (S00 of interconnect)
        .s_axi_awvalid  (s00_awvalid),
        .s_axi_awready  (s00_awready),
        .s_axi_awid     (s00_awid),
        .s_axi_awaddr   (s00_awaddr),
        .s_axi_awlen    (s00_awlen),
        .s_axi_awsize   (s00_awsize),
        .s_axi_awburst  (s00_awburst),
        .s_axi_awlock   (s00_awlock),
        .s_axi_awcache  (s00_awcache),
        .s_axi_awprot   (s00_awprot),
        .s_axi_awqos    (s00_awqos),
        .s_axi_awregion (/* open — adapter drives 8-bit, interconnect AWUSER unused */),
        .s_axi_wvalid   (s00_wvalid),
        .s_axi_wready   (s00_wready),
        .s_axi_wdata    (s00_wdata),
        .s_axi_wstrb    (s00_wstrb),
        .s_axi_wlast    (s00_wlast),
        .s_axi_bvalid   (s00_bvalid),
        .s_axi_bready   (s00_bready),
        .s_axi_bid      (s00_bid),
        .s_axi_bresp    (s00_bresp),
        .s_axi_arvalid  (s00_arvalid),
        .s_axi_arready  (s00_arready),
        .s_axi_arid     (s00_arid),
        .s_axi_araddr   (s00_araddr),
        .s_axi_arlen    (s00_arlen),
        .s_axi_arsize   (s00_arsize),
        .s_axi_arburst  (s00_arburst),
        .s_axi_arlock   (s00_arlock),
        .s_axi_arcache  (s00_arcache),
        .s_axi_arprot   (s00_arprot),
        .s_axi_arqos    (s00_arqos),
        .s_axi_arregion (/* open */),
        .s_axi_rvalid   (s00_rvalid),
        .s_axi_rready   (s00_rready),
        .s_axi_rid      (s00_rid),
        .s_axi_rdata    (s00_rdata),
        .s_axi_rresp    (s00_rresp),
        .s_axi_rlast    (s00_rlast)
    );

    // -----------------------------------------------------------------------
    // LSU 64→32 adapter  (S01)
    // -----------------------------------------------------------------------
    axi_64to32_adapter #(
        .M_ID_WIDTH (3),
        .S_ID_WIDTH (8)
    ) u_lsu_adapter (
        .clk            (clk),
        .rst_l          (rst_l),

        // 64-bit side (VeeR LSU)
        .m_axi_awvalid  (lsu64_awvalid),
        .m_axi_awready  (lsu64_awready),
        .m_axi_awid     (lsu64_awid),
        .m_axi_awaddr   (lsu64_awaddr),
        .m_axi_awlen    (lsu64_awlen),
        .m_axi_awsize   (lsu64_awsize),
        .m_axi_awburst  (lsu64_awburst),
        .m_axi_awlock   (lsu64_awlock),
        .m_axi_awcache  (lsu64_awcache),
        .m_axi_awprot   (lsu64_awprot),
        .m_axi_awqos    (lsu64_awqos),
        .m_axi_awregion (lsu64_awregion),
        .m_axi_wvalid   (lsu64_wvalid),
        .m_axi_wready   (lsu64_wready),
        .m_axi_wdata    (lsu64_wdata),
        .m_axi_wstrb    (lsu64_wstrb),
        .m_axi_wlast    (lsu64_wlast),
        .m_axi_bvalid   (lsu64_bvalid),
        .m_axi_bready   (lsu64_bready),
        .m_axi_bid      (lsu64_bid),
        .m_axi_bresp    (lsu64_bresp),
        .m_axi_arvalid  (lsu64_arvalid),
        .m_axi_arready  (lsu64_arready),
        .m_axi_arid     (lsu64_arid),
        .m_axi_araddr   (lsu64_araddr),
        .m_axi_arlen    (lsu64_arlen),
        .m_axi_arsize   (lsu64_arsize),
        .m_axi_arburst  (lsu64_arburst),
        .m_axi_arlock   (lsu64_arlock),
        .m_axi_arcache  (lsu64_arcache),
        .m_axi_arprot   (lsu64_arprot),
        .m_axi_arqos    (lsu64_arqos),
        .m_axi_arregion (lsu64_arregion),
        .m_axi_rvalid   (lsu64_rvalid),
        .m_axi_rready   (lsu64_rready),
        .m_axi_rid      (lsu64_rid),
        .m_axi_rdata    (lsu64_rdata),
        .m_axi_rresp    (lsu64_rresp),
        .m_axi_rlast    (lsu64_rlast),

        // 32-bit side (S01 of interconnect)
        .s_axi_awvalid  (s01_awvalid),
        .s_axi_awready  (s01_awready),
        .s_axi_awid     (s01_awid),
        .s_axi_awaddr   (s01_awaddr),
        .s_axi_awlen    (s01_awlen),
        .s_axi_awsize   (s01_awsize),
        .s_axi_awburst  (s01_awburst),
        .s_axi_awlock   (s01_awlock),
        .s_axi_awcache  (s01_awcache),
        .s_axi_awprot   (s01_awprot),
        .s_axi_awqos    (s01_awqos),
        .s_axi_awregion (),
        .s_axi_wvalid   (s01_wvalid),
        .s_axi_wready   (s01_wready),
        .s_axi_wdata    (s01_wdata),
        .s_axi_wstrb    (s01_wstrb),
        .s_axi_wlast    (s01_wlast),
        .s_axi_bvalid   (s01_bvalid),
        .s_axi_bready   (s01_bready),
        .s_axi_bid      (s01_bid),
        .s_axi_bresp    (s01_bresp),
        .s_axi_arvalid  (s01_arvalid),
        .s_axi_arready  (s01_arready),
        .s_axi_arid     (s01_arid),
        .s_axi_araddr   (s01_araddr),
        .s_axi_arlen    (s01_arlen),
        .s_axi_arsize   (s01_arsize),
        .s_axi_arburst  (s01_arburst),
        .s_axi_arlock   (s01_arlock),
        .s_axi_arcache  (s01_arcache),
        .s_axi_arprot   (s01_arprot),
        .s_axi_arqos    (s01_arqos),
        .s_axi_arregion (),
        .s_axi_rvalid   (s01_rvalid),
        .s_axi_rready   (s01_rready),
        .s_axi_rid      (s01_rid),
        .s_axi_rdata    (s01_rdata),
        .s_axi_rresp    (s01_rresp),
        .s_axi_rlast    (s01_rlast)
    );

    // -----------------------------------------------------------------------
    // 3×14 AXI Interconnect
    // -----------------------------------------------------------------------
    // CONNECT_READ/WRITE bitmask: bit[0]=S00, bit[1]=S01, bit[2]=S02
    // M07 (IMEM): IFU (S00) read-only
    // M08–M13: not connected
    // -----------------------------------------------------------------------
    axi_interconnect_wrap_3x14 #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_WIDTH         (ADDR_WIDTH),
        .STRB_WIDTH         (STRB_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .AWUSER_WIDTH       (1),
        .WUSER_WIDTH        (1),
        .BUSER_WIDTH        (1),
        .ARUSER_WIDTH       (1),
        .RUSER_WIDTH        (1),
        .M_REGIONS          (1),

        // M00–M06: not connected (Phase 4 - peripherals not yet wired)
        .M00_ADDR_WIDTH     (32'd0),
        .M00_CONNECT_READ   (3'b000),
        .M00_CONNECT_WRITE  (3'b000),
        .M01_ADDR_WIDTH     (32'd0),
        .M01_CONNECT_READ   (3'b000),
        .M01_CONNECT_WRITE  (3'b000),
        .M02_ADDR_WIDTH     (32'd0),
        .M02_CONNECT_READ   (3'b000),
        .M02_CONNECT_WRITE  (3'b000),
        .M03_ADDR_WIDTH     (32'd0),
        .M03_CONNECT_READ   (3'b000),
        .M03_CONNECT_WRITE  (3'b000),
        .M04_ADDR_WIDTH     (32'd0),
        .M04_CONNECT_READ   (3'b000),
        .M04_CONNECT_WRITE  (3'b000),
        .M05_ADDR_WIDTH     (32'd0),
        .M05_CONNECT_READ   (3'b000),
        .M05_CONNECT_WRITE  (3'b000),
        .M06_ADDR_WIDTH     (32'd0),
        .M06_CONNECT_READ   (3'b000),
        .M06_CONNECT_WRITE  (3'b000),

        // M07 = IMEM 0x00000000–0x0000FFFF (64 KB)
        // Connected to S00 (IFU) read and write (VeeR issues both via IFU path)
        .M07_BASE_ADDR      (32'h0000_0000),
        .M07_ADDR_WIDTH     (32'd16),
        .M07_CONNECT_READ   (3'b001),   // S00 only
        .M07_CONNECT_WRITE  (3'b001),   // S00 only (IFU write channel exists in AXI4)

        // M08–M13: reserved
        .M08_ADDR_WIDTH     (32'd0),
        .M08_CONNECT_READ   (3'b000),
        .M08_CONNECT_WRITE  (3'b000),
        .M09_ADDR_WIDTH     (32'd0),
        .M09_CONNECT_READ   (3'b000),
        .M09_CONNECT_WRITE  (3'b000),
        .M10_ADDR_WIDTH     (32'd0),
        .M10_CONNECT_READ   (3'b000),
        .M10_CONNECT_WRITE  (3'b000),
        .M11_ADDR_WIDTH     (32'd0),
        .M11_CONNECT_READ   (3'b000),
        .M11_CONNECT_WRITE  (3'b000),
        .M12_ADDR_WIDTH     (32'd0),
        .M12_CONNECT_READ   (3'b000),
        .M12_CONNECT_WRITE  (3'b000),
        .M13_ADDR_WIDTH     (32'd0),
        .M13_CONNECT_READ   (3'b000),
        .M13_CONNECT_WRITE  (3'b000)

    ) u_interconnect (
        .clk  (clk),
        .rst  (rst),

        // --- Slave S00 (IFU) ---
        .s00_axi_awid     (s00_awid),
        .s00_axi_awaddr   (s00_awaddr),
        .s00_axi_awlen    (s00_awlen),
        .s00_axi_awsize   (s00_awsize),
        .s00_axi_awburst  (s00_awburst),
        .s00_axi_awlock   (s00_awlock),
        .s00_axi_awcache  (s00_awcache),
        .s00_axi_awprot   (s00_awprot),
        .s00_axi_awqos    (s00_awqos),
        .s00_axi_awuser   (1'b0),
        .s00_axi_awvalid  (s00_awvalid),
        .s00_axi_awready  (s00_awready),
        .s00_axi_wdata    (s00_wdata),
        .s00_axi_wstrb    (s00_wstrb),
        .s00_axi_wlast    (s00_wlast),
        .s00_axi_wuser    (1'b0),
        .s00_axi_wvalid   (s00_wvalid),
        .s00_axi_wready   (s00_wready),
        .s00_axi_bid      (s00_bid),
        .s00_axi_bresp    (s00_bresp),
        .s00_axi_buser    (/* open */),
        .s00_axi_bvalid   (s00_bvalid),
        .s00_axi_bready   (s00_bready),
        .s00_axi_arid     (s00_arid),
        .s00_axi_araddr   (s00_araddr),
        .s00_axi_arlen    (s00_arlen),
        .s00_axi_arsize   (s00_arsize),
        .s00_axi_arburst  (s00_arburst),
        .s00_axi_arlock   (s00_arlock),
        .s00_axi_arcache  (s00_arcache),
        .s00_axi_arprot   (s00_arprot),
        .s00_axi_arqos    (s00_arqos),
        .s00_axi_aruser   (1'b0),
        .s00_axi_arvalid  (s00_arvalid),
        .s00_axi_arready  (s00_arready),
        .s00_axi_rid      (s00_rid),
        .s00_axi_rdata    (s00_rdata),
        .s00_axi_rresp    (s00_rresp),
        .s00_axi_rlast    (s00_rlast),
        .s00_axi_ruser    (/* open */),
        .s00_axi_rvalid   (s00_rvalid),
        .s00_axi_rready   (s00_rready),

        // --- Slave S01 (LSU) ---
        .s01_axi_awid     (s01_awid),
        .s01_axi_awaddr   (s01_awaddr),
        .s01_axi_awlen    (s01_awlen),
        .s01_axi_awsize   (s01_awsize),
        .s01_axi_awburst  (s01_awburst),
        .s01_axi_awlock   (s01_awlock),
        .s01_axi_awcache  (s01_awcache),
        .s01_axi_awprot   (s01_awprot),
        .s01_axi_awqos    (s01_awqos),
        .s01_axi_awuser   (1'b0),
        .s01_axi_awvalid  (s01_awvalid),
        .s01_axi_awready  (s01_awready),
        .s01_axi_wdata    (s01_wdata),
        .s01_axi_wstrb    (s01_wstrb),
        .s01_axi_wlast    (s01_wlast),
        .s01_axi_wuser    (1'b0),
        .s01_axi_wvalid   (s01_wvalid),
        .s01_axi_wready   (s01_wready),
        .s01_axi_bid      (s01_bid),
        .s01_axi_bresp    (s01_bresp),
        .s01_axi_buser    (/* open */),
        .s01_axi_bvalid   (s01_bvalid),
        .s01_axi_bready   (s01_bready),
        .s01_axi_arid     (s01_arid),
        .s01_axi_araddr   (s01_araddr),
        .s01_axi_arlen    (s01_arlen),
        .s01_axi_arsize   (s01_arsize),
        .s01_axi_arburst  (s01_arburst),
        .s01_axi_arlock   (s01_arlock),
        .s01_axi_arcache  (s01_arcache),
        .s01_axi_arprot   (s01_arprot),
        .s01_axi_arqos    (s01_arqos),
        .s01_axi_aruser   (1'b0),
        .s01_axi_arvalid  (s01_arvalid),
        .s01_axi_arready  (s01_arready),
        .s01_axi_rid      (s01_rid),
        .s01_axi_rdata    (s01_rdata),
        .s01_axi_rresp    (s01_rresp),
        .s01_axi_rlast    (s01_rlast),
        .s01_axi_ruser    (/* open */),
        .s01_axi_rvalid   (s01_rvalid),
        .s01_axi_rready   (s01_rready),

        // --- Slave S02 (dummy / inactive — tie off) ---
        .s02_axi_awid     ({ID_WIDTH{1'b0}}),
        .s02_axi_awaddr   ({ADDR_WIDTH{1'b0}}),
        .s02_axi_awlen    (8'd0),
        .s02_axi_awsize   (3'd0),
        .s02_axi_awburst  (2'd1),
        .s02_axi_awlock   (1'b0),
        .s02_axi_awcache  (4'd0),
        .s02_axi_awprot   (3'd0),
        .s02_axi_awqos    (4'd0),
        .s02_axi_awuser   (1'b0),
        .s02_axi_awvalid  (1'b0),
        .s02_axi_awready  (/* open */),
        .s02_axi_wdata    ({DATA_WIDTH{1'b0}}),
        .s02_axi_wstrb    ({STRB_WIDTH{1'b0}}),
        .s02_axi_wlast    (1'b0),
        .s02_axi_wuser    (1'b0),
        .s02_axi_wvalid   (1'b0),
        .s02_axi_wready   (/* open */),
        .s02_axi_bid      (/* open */),
        .s02_axi_bresp    (/* open */),
        .s02_axi_buser    (/* open */),
        .s02_axi_bvalid   (/* open */),
        .s02_axi_bready   (1'b1),
        .s02_axi_arid     ({ID_WIDTH{1'b0}}),
        .s02_axi_araddr   ({ADDR_WIDTH{1'b0}}),
        .s02_axi_arlen    (8'd0),
        .s02_axi_arsize   (3'd0),
        .s02_axi_arburst  (2'd1),
        .s02_axi_arlock   (1'b0),
        .s02_axi_arcache  (4'd0),
        .s02_axi_arprot   (3'd0),
        .s02_axi_arqos    (4'd0),
        .s02_axi_aruser   (1'b0),
        .s02_axi_arvalid  (1'b0),
        .s02_axi_arready  (/* open */),
        .s02_axi_rid      (/* open */),
        .s02_axi_rdata    (/* open */),
        .s02_axi_rresp    (/* open */),
        .s02_axi_rlast    (/* open */),
        .s02_axi_ruser    (/* open */),
        .s02_axi_rvalid   (/* open */),
        .s02_axi_rready   (1'b1),

        // --- Master M00–M06: tie ready/data signals (not connected) ---
        .m00_axi_awready  (1'b0), .m00_axi_wready  (1'b0), .m00_axi_bid({ID_WIDTH{1'b0}}),
        .m00_axi_bresp    (2'b00), .m00_axi_buser  (1'b0),  .m00_axi_bvalid(1'b0),
        .m00_axi_arready  (1'b0), .m00_axi_rid     ({ID_WIDTH{1'b0}}),
        .m00_axi_rdata    ({DATA_WIDTH{1'b0}}), .m00_axi_rresp(2'b00),
        .m00_axi_rlast    (1'b0), .m00_axi_ruser   (1'b0), .m00_axi_rvalid(1'b0),

        .m01_axi_awready  (1'b0), .m01_axi_wready  (1'b0), .m01_axi_bid({ID_WIDTH{1'b0}}),
        .m01_axi_bresp    (2'b00), .m01_axi_buser  (1'b0),  .m01_axi_bvalid(1'b0),
        .m01_axi_arready  (1'b0), .m01_axi_rid     ({ID_WIDTH{1'b0}}),
        .m01_axi_rdata    ({DATA_WIDTH{1'b0}}), .m01_axi_rresp(2'b00),
        .m01_axi_rlast    (1'b0), .m01_axi_ruser   (1'b0), .m01_axi_rvalid(1'b0),

        .m02_axi_awready  (1'b0), .m02_axi_wready  (1'b0), .m02_axi_bid({ID_WIDTH{1'b0}}),
        .m02_axi_bresp    (2'b00), .m02_axi_buser  (1'b0),  .m02_axi_bvalid(1'b0),
        .m02_axi_arready  (1'b0), .m02_axi_rid     ({ID_WIDTH{1'b0}}),
        .m02_axi_rdata    ({DATA_WIDTH{1'b0}}), .m02_axi_rresp(2'b00),
        .m02_axi_rlast    (1'b0), .m02_axi_ruser   (1'b0), .m02_axi_rvalid(1'b0),

        .m03_axi_awready  (1'b0), .m03_axi_wready  (1'b0), .m03_axi_bid({ID_WIDTH{1'b0}}),
        .m03_axi_bresp    (2'b00), .m03_axi_buser  (1'b0),  .m03_axi_bvalid(1'b0),
        .m03_axi_arready  (1'b0), .m03_axi_rid     ({ID_WIDTH{1'b0}}),
        .m03_axi_rdata    ({DATA_WIDTH{1'b0}}), .m03_axi_rresp(2'b00),
        .m03_axi_rlast    (1'b0), .m03_axi_ruser   (1'b0), .m03_axi_rvalid(1'b0),

        .m04_axi_awready  (1'b0), .m04_axi_wready  (1'b0), .m04_axi_bid({ID_WIDTH{1'b0}}),
        .m04_axi_bresp    (2'b00), .m04_axi_buser  (1'b0),  .m04_axi_bvalid(1'b0),
        .m04_axi_arready  (1'b0), .m04_axi_rid     ({ID_WIDTH{1'b0}}),
        .m04_axi_rdata    ({DATA_WIDTH{1'b0}}), .m04_axi_rresp(2'b00),
        .m04_axi_rlast    (1'b0), .m04_axi_ruser   (1'b0), .m04_axi_rvalid(1'b0),

        .m05_axi_awready  (1'b0), .m05_axi_wready  (1'b0), .m05_axi_bid({ID_WIDTH{1'b0}}),
        .m05_axi_bresp    (2'b00), .m05_axi_buser  (1'b0),  .m05_axi_bvalid(1'b0),
        .m05_axi_arready  (1'b0), .m05_axi_rid     ({ID_WIDTH{1'b0}}),
        .m05_axi_rdata    ({DATA_WIDTH{1'b0}}), .m05_axi_rresp(2'b00),
        .m05_axi_rlast    (1'b0), .m05_axi_ruser   (1'b0), .m05_axi_rvalid(1'b0),

        .m06_axi_awready  (1'b0), .m06_axi_wready  (1'b0), .m06_axi_bid({ID_WIDTH{1'b0}}),
        .m06_axi_bresp    (2'b00), .m06_axi_buser  (1'b0),  .m06_axi_bvalid(1'b0),
        .m06_axi_arready  (1'b0), .m06_axi_rid     ({ID_WIDTH{1'b0}}),
        .m06_axi_rdata    ({DATA_WIDTH{1'b0}}), .m06_axi_rresp(2'b00),
        .m06_axi_rlast    (1'b0), .m06_axi_ruser   (1'b0), .m06_axi_rvalid(1'b0),

        // --- Master M07: IMEM ---
        .m07_axi_awid     (m07_awid),
        .m07_axi_awaddr   (m07_awaddr),
        .m07_axi_awlen    (m07_awlen),
        .m07_axi_awsize   (m07_awsize),
        .m07_axi_awburst  (m07_awburst),
        .m07_axi_awlock   (m07_awlock),
        .m07_axi_awcache  (m07_awcache),
        .m07_axi_awprot   (m07_awprot),
        .m07_axi_awqos    (m07_awqos),
        .m07_axi_awregion (m07_awregion),
        .m07_axi_awuser   (/* open */),
        .m07_axi_awvalid  (m07_awvalid),
        .m07_axi_awready  (m07_awready),
        .m07_axi_wdata    (m07_wdata),
        .m07_axi_wstrb    (m07_wstrb),
        .m07_axi_wlast    (m07_wlast),
        .m07_axi_wuser    (/* open */),
        .m07_axi_wvalid   (m07_wvalid),
        .m07_axi_wready   (m07_wready),
        .m07_axi_bid      (m07_bid),
        .m07_axi_bresp    (m07_bresp),
        .m07_axi_buser    (1'b0),
        .m07_axi_bvalid   (m07_bvalid),
        .m07_axi_bready   (m07_bready),
        .m07_axi_arid     (m07_arid),
        .m07_axi_araddr   (m07_araddr),
        .m07_axi_arlen    (m07_arlen),
        .m07_axi_arsize   (m07_arsize),
        .m07_axi_arburst  (m07_arburst),
        .m07_axi_arlock   (m07_arlock),
        .m07_axi_arcache  (m07_arcache),
        .m07_axi_arprot   (m07_arprot),
        .m07_axi_arqos    (m07_arqos),
        .m07_axi_arregion (m07_arregion),
        .m07_axi_aruser   (/* open */),
        .m07_axi_arvalid  (m07_arvalid),
        .m07_axi_arready  (m07_arready),
        .m07_axi_rid      (m07_rid),
        .m07_axi_rdata    (m07_rdata),
        .m07_axi_rresp    (m07_rresp),
        .m07_axi_rlast    (m07_rlast),
        .m07_axi_ruser    (1'b0),
        .m07_axi_rvalid   (m07_rvalid),
        .m07_axi_rready   (m07_rready),

        // --- Master M08–M13: not connected ---
        .m08_axi_awready  (1'b0), .m08_axi_wready  (1'b0), .m08_axi_bid({ID_WIDTH{1'b0}}),
        .m08_axi_bresp    (2'b00), .m08_axi_buser  (1'b0),  .m08_axi_bvalid(1'b0),
        .m08_axi_arready  (1'b0), .m08_axi_rid     ({ID_WIDTH{1'b0}}),
        .m08_axi_rdata    ({DATA_WIDTH{1'b0}}), .m08_axi_rresp(2'b00),
        .m08_axi_rlast    (1'b0), .m08_axi_ruser   (1'b0), .m08_axi_rvalid(1'b0),

        .m09_axi_awready  (1'b0), .m09_axi_wready  (1'b0), .m09_axi_bid({ID_WIDTH{1'b0}}),
        .m09_axi_bresp    (2'b00), .m09_axi_buser  (1'b0),  .m09_axi_bvalid(1'b0),
        .m09_axi_arready  (1'b0), .m09_axi_rid     ({ID_WIDTH{1'b0}}),
        .m09_axi_rdata    ({DATA_WIDTH{1'b0}}), .m09_axi_rresp(2'b00),
        .m09_axi_rlast    (1'b0), .m09_axi_ruser   (1'b0), .m09_axi_rvalid(1'b0),

        .m10_axi_awready  (1'b0), .m10_axi_wready  (1'b0), .m10_axi_bid({ID_WIDTH{1'b0}}),
        .m10_axi_bresp    (2'b00), .m10_axi_buser  (1'b0),  .m10_axi_bvalid(1'b0),
        .m10_axi_arready  (1'b0), .m10_axi_rid     ({ID_WIDTH{1'b0}}),
        .m10_axi_rdata    ({DATA_WIDTH{1'b0}}), .m10_axi_rresp(2'b00),
        .m10_axi_rlast    (1'b0), .m10_axi_ruser   (1'b0), .m10_axi_rvalid(1'b0),

        .m11_axi_awready  (1'b0), .m11_axi_wready  (1'b0), .m11_axi_bid({ID_WIDTH{1'b0}}),
        .m11_axi_bresp    (2'b00), .m11_axi_buser  (1'b0),  .m11_axi_bvalid(1'b0),
        .m11_axi_arready  (1'b0), .m11_axi_rid     ({ID_WIDTH{1'b0}}),
        .m11_axi_rdata    ({DATA_WIDTH{1'b0}}), .m11_axi_rresp(2'b00),
        .m11_axi_rlast    (1'b0), .m11_axi_ruser   (1'b0), .m11_axi_rvalid(1'b0),

        .m12_axi_awready  (1'b0), .m12_axi_wready  (1'b0), .m12_axi_bid({ID_WIDTH{1'b0}}),
        .m12_axi_bresp    (2'b00), .m12_axi_buser  (1'b0),  .m12_axi_bvalid(1'b0),
        .m12_axi_arready  (1'b0), .m12_axi_rid     ({ID_WIDTH{1'b0}}),
        .m12_axi_rdata    ({DATA_WIDTH{1'b0}}), .m12_axi_rresp(2'b00),
        .m12_axi_rlast    (1'b0), .m12_axi_ruser   (1'b0), .m12_axi_rvalid(1'b0),

        .m13_axi_awready  (1'b0), .m13_axi_wready  (1'b0), .m13_axi_bid({ID_WIDTH{1'b0}}),
        .m13_axi_bresp    (2'b00), .m13_axi_buser  (1'b0),  .m13_axi_bvalid(1'b0),
        .m13_axi_arready  (1'b0), .m13_axi_rid     ({ID_WIDTH{1'b0}}),
        .m13_axi_rdata    ({DATA_WIDTH{1'b0}}), .m13_axi_rresp(2'b00),
        .m13_axi_rlast    (1'b0), .m13_axi_ruser   (1'b0), .m13_axi_rvalid(1'b0)
    );

    // -----------------------------------------------------------------------
    // AXI IMEM slave (M07)
    // -----------------------------------------------------------------------
    axi_imem_slave #(
        .AXI_ID_WIDTH   (ID_WIDTH),
        .AXI_DATA_WIDTH (DATA_WIDTH),
        .AXI_ADDR_WIDTH (ADDR_WIDTH),
        .MEM_SIZE_BYTES (65536),
        .BASE_ADDR      (32'h0000_0000)
    ) u_imem (
        .aclk    (clk),
        .aresetn (aresetn),

        .s_awid     (m07_awid),
        .s_awaddr   (m07_awaddr),
        .s_awlen    (m07_awlen),
        .s_awsize   (m07_awsize),
        .s_awburst  (m07_awburst),
        .s_awlock   (m07_awlock),
        .s_awcache  (m07_awcache),
        .s_awprot   (m07_awprot),
        .s_awqos    (m07_awqos),
        .s_awregion (m07_awregion),
        .s_awvalid  (m07_awvalid),
        .s_awready  (m07_awready),

        .s_wdata    (m07_wdata),
        .s_wstrb    (m07_wstrb),
        .s_wlast    (m07_wlast),
        .s_wvalid   (m07_wvalid),
        .s_wready   (m07_wready),

        .s_bid      (m07_bid),
        .s_bresp    (m07_bresp),
        .s_bvalid   (m07_bvalid),
        .s_bready   (m07_bready),

        .s_arid     (m07_arid),
        .s_araddr   (m07_araddr),
        .s_arlen    (m07_arlen),
        .s_arsize   (m07_arsize),
        .s_arburst  (m07_arburst),
        .s_arlock   (m07_arlock),
        .s_arcache  (m07_arcache),
        .s_arprot   (m07_arprot),
        .s_arqos    (m07_arqos),
        .s_arregion (m07_arregion),
        .s_arvalid  (m07_arvalid),
        .s_arready  (m07_arready),

        .s_rid      (m07_rid),
        .s_rdata    (m07_rdata),
        .s_rresp    (m07_rresp),
        .s_rlast    (m07_rlast),
        .s_rvalid   (m07_rvalid),
        .s_rready   (m07_rready)
    );

endmodule
