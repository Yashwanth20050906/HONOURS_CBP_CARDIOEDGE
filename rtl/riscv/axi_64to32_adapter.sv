// ============================================================================
// axi_64to32_adapter.sv
//
// CARDIOEDGE Phase 3 — AXI4 64-bit master → 32-bit slave width converter.
//
// PURPOSE
//   Bridges VeeR EL2's 64-bit AXI master (IFU or LSU) to the 32-bit
//   CARDIOEDGE AXI interconnect.
//
// DESIGN RULES (from VeeR inspection)
//   IFU READ (ARSIZE = 3, ARLEN = 0):
//     VeeR requests one 8-byte aligned read.  We issue two sequential 32-bit
//     reads to the interconnect (low word first, then high word), combine them
//     and return a single 64-bit RDATA beat.
//
//   IFU READ (ARSIZE ≤ 2, ARLEN = 0):
//     Single-beat narrower read.  Issue one 32-bit read; return aligned 32-bit
//     data in the correct 64-bit lane (replicated for simplicity — VeeR ignores
//     the unused half).
//
//   LSU WRITE (AWSIZE ≤ 2):
//     Single-beat write. Extract the active 32-bit lane (AWADDR[2]==1 → upper,
//     else lower) from WDATA[63:0], compress WSTRB[7:0] to WSTRB[3:0].
//     Issue one 32-bit write. Forward BRESP.
//
//   BURST (AWLEN/ARLEN > 0):
//     VeeR EL2 does NOT issue multi-beat bursts in default configuration
//     (ICCM/DCCM disabled, no cache fill).  For safety: each beat of an
//     upstream burst is forwarded as a separate single-beat 32-bit transaction.
//     The RLAST/WLAST protocol is handled correctly.
//
// PARAMETERS
//   M_ID_WIDTH  : ID width from VeeR master  (3 for IFU/LSU)
//   S_ID_WIDTH  : ID width to interconnect   (8 — interconnect ID_WIDTH)
//
// LIMITATIONS
//   - One outstanding transaction at a time per adapter instance.
//   - No out-of-order support (VeeR EL2 issues in-order for these buses).
// ============================================================================

module axi_64to32_adapter #(
    parameter M_ID_WIDTH = 3,   // VeeR AXI ID width
    parameter S_ID_WIDTH = 8    // Interconnect AXI ID width
)(
    input  logic        clk,
    input  logic        rst_l,  // active-low

    // -----------------------------------------------------------------------
    // 64-bit AXI4 slave port (connects to VeeR IFU or LSU)
    // -----------------------------------------------------------------------
    // Write address
    input  logic                    m_axi_awvalid,
    output logic                    m_axi_awready,
    input  logic [M_ID_WIDTH-1:0]   m_axi_awid,
    input  logic [31:0]             m_axi_awaddr,
    input  logic [7:0]              m_axi_awlen,
    input  logic [2:0]              m_axi_awsize,
    input  logic [1:0]              m_axi_awburst,
    input  logic                    m_axi_awlock,
    input  logic [3:0]              m_axi_awcache,
    input  logic [2:0]              m_axi_awprot,
    input  logic [3:0]              m_axi_awqos,
    input  logic [3:0]              m_axi_awregion,
    // Write data
    input  logic                    m_axi_wvalid,
    output logic                    m_axi_wready,
    input  logic [63:0]             m_axi_wdata,
    input  logic [7:0]              m_axi_wstrb,
    input  logic                    m_axi_wlast,
    // Write response
    output logic                    m_axi_bvalid,
    input  logic                    m_axi_bready,
    output logic [M_ID_WIDTH-1:0]   m_axi_bid,
    output logic [1:0]              m_axi_bresp,
    // Read address
    input  logic                    m_axi_arvalid,
    output logic                    m_axi_arready,
    input  logic [M_ID_WIDTH-1:0]   m_axi_arid,
    input  logic [31:0]             m_axi_araddr,
    input  logic [7:0]              m_axi_arlen,
    input  logic [2:0]              m_axi_arsize,
    input  logic [1:0]              m_axi_arburst,
    input  logic                    m_axi_arlock,
    input  logic [3:0]              m_axi_arcache,
    input  logic [2:0]              m_axi_arprot,
    input  logic [3:0]              m_axi_arqos,
    input  logic [3:0]              m_axi_arregion,
    // Read data
    output logic                    m_axi_rvalid,
    input  logic                    m_axi_rready,
    output logic [M_ID_WIDTH-1:0]   m_axi_rid,
    output logic [63:0]             m_axi_rdata,
    output logic [1:0]              m_axi_rresp,
    output logic                    m_axi_rlast,

    // -----------------------------------------------------------------------
    // 32-bit AXI4 master port (connects to interconnect slave port)
    // -----------------------------------------------------------------------
    // Write address
    output logic                    s_axi_awvalid,
    input  logic                    s_axi_awready,
    output logic [S_ID_WIDTH-1:0]   s_axi_awid,
    output logic [31:0]             s_axi_awaddr,
    output logic [7:0]              s_axi_awlen,
    output logic [2:0]              s_axi_awsize,
    output logic [1:0]              s_axi_awburst,
    output logic                    s_axi_awlock,
    output logic [3:0]              s_axi_awcache,
    output logic [2:0]              s_axi_awprot,
    output logic [3:0]              s_axi_awqos,
    output logic [S_ID_WIDTH-1:0]   s_axi_awregion,  // Note: interconnect uses awregion as output
    // Write data
    output logic                    s_axi_wvalid,
    input  logic                    s_axi_wready,
    output logic [31:0]             s_axi_wdata,
    output logic [3:0]              s_axi_wstrb,
    output logic                    s_axi_wlast,
    // Write response
    input  logic                    s_axi_bvalid,
    output logic                    s_axi_bready,
    input  logic [S_ID_WIDTH-1:0]   s_axi_bid,
    input  logic [1:0]              s_axi_bresp,
    // Read address
    output logic                    s_axi_arvalid,
    input  logic                    s_axi_arready,
    output logic [S_ID_WIDTH-1:0]   s_axi_arid,
    output logic [31:0]             s_axi_araddr,
    output logic [7:0]              s_axi_arlen,
    output logic [2:0]              s_axi_arsize,
    output logic [1:0]              s_axi_arburst,
    output logic                    s_axi_arlock,
    output logic [3:0]              s_axi_arcache,
    output logic [2:0]              s_axi_arprot,
    output logic [3:0]              s_axi_arqos,
    output logic [S_ID_WIDTH-1:0]   s_axi_arregion,
    // Read data
    input  logic                    s_axi_rvalid,
    output logic                    s_axi_rready,
    input  logic [S_ID_WIDTH-1:0]   s_axi_rid,
    input  logic [31:0]             s_axi_rdata,
    input  logic [1:0]              s_axi_rresp,
    input  logic                    s_axi_rlast
);

    // ========================================================================
    // READ PATH
    // ========================================================================
    // For ARSIZE==3 (8-byte): issue TWO 32-bit reads (addr and addr+4),
    // assemble 64-bit result, return single RDATA beat with RLAST.
    // For ARSIZE<3: issue ONE 32-bit read, replicate to 64-bit lane.
    //
    // State machine:
    //   RD_IDLE    : waiting for m_axi_arvalid
    //   RD_ADDR_LO : send read of low word (araddr[2]==0 side)
    //   RD_DATA_LO : wait for rdata from low word
    //   RD_ADDR_HI : send read of high word (araddr | 4)
    //   RD_DATA_HI : wait for rdata from high word, then return 64b to master
    //   RD_SINGLE_ADDR : send single read for narrow transactions
    //   RD_SINGLE_DATA : wait for single rdata, return to master
    // ========================================================================

    typedef enum logic [2:0] {
        RD_IDLE        = 3'd0,
        RD_ADDR_LO     = 3'd1,
        RD_DATA_LO     = 3'd2,
        RD_ADDR_HI     = 3'd3,
        RD_DATA_HI     = 3'd4,
        RD_SINGLE_ADDR = 3'd5,
        RD_SINGLE_DATA = 3'd6,
        RD_RESP        = 3'd7
    } rd_state_t;

    rd_state_t rd_state;

    // Captured AR fields
    logic [M_ID_WIDTH-1:0] ar_id_q;
    logic [31:0]           ar_addr_q;
    logic [7:0]            ar_len_q;
    logic [2:0]            ar_size_q;
    logic [1:0]            ar_burst_q;
    logic                  ar_lock_q;
    logic [3:0]            ar_cache_q;
    logic [2:0]            ar_prot_q;
    logic [3:0]            ar_qos_q;
    logic [3:0]            ar_region_q;
    logic [7:0]            ar_beat_cnt;  // current upstream burst beat
    logic [31:0]           ar_cur_addr;  // address for current beat

    // Data assembly
    logic [31:0]           rdata_lo_q;
    logic [31:0]           rdata_hi_q;
    logic [1:0]            rresp_q;

    // Wide-mode flag: 1 if ARSIZE==3 (need two 32-bit reads per 64-bit beat)
    logic wide_read;
    assign wide_read = (ar_size_q == 3'd3);

    // -----------------------------------------------------------------------
    // Read FSM
    // -----------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            rd_state     <= RD_IDLE;
            ar_id_q      <= '0;
            ar_addr_q    <= '0;
            ar_len_q     <= '0;
            ar_size_q    <= '0;
            ar_burst_q   <= '0;
            ar_lock_q    <= '0;
            ar_cache_q   <= '0;
            ar_prot_q    <= '0;
            ar_qos_q     <= '0;
            ar_region_q  <= '0;
            ar_beat_cnt  <= '0;
            ar_cur_addr  <= '0;
            rdata_lo_q   <= '0;
            rresp_q      <= '0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    if (m_axi_arvalid) begin
                        ar_id_q     <= m_axi_arid;
                        ar_addr_q   <= (m_axi_arsize == 3'd3) ? {m_axi_araddr[31:3], 3'b000} : m_axi_araddr;
                        ar_len_q    <= m_axi_arlen;
                        ar_size_q   <= m_axi_arsize;
                        ar_burst_q  <= m_axi_arburst;
                        ar_lock_q   <= m_axi_arlock;
                        ar_cache_q  <= m_axi_arcache;
                        ar_prot_q   <= m_axi_arprot;
                        ar_qos_q    <= m_axi_arqos;
                        ar_region_q <= m_axi_arregion;
                        ar_beat_cnt <= 8'd0;
                        ar_cur_addr <= (m_axi_arsize == 3'd3) ? {m_axi_araddr[31:3], 3'b000} : m_axi_araddr;
                        rresp_q     <= 2'b00;
                        if (m_axi_arsize == 3'd3)
                            rd_state <= RD_ADDR_LO;
                        else
                            rd_state <= RD_SINGLE_ADDR;
                    end
                end

                // ----- Wide read: low 32-bit word -----
                RD_ADDR_LO: begin
                    if (s_axi_arready) begin
                        rd_state <= RD_DATA_LO;
                    end
                end

                RD_DATA_LO: begin
                    if (s_axi_rvalid) begin
                        rdata_lo_q <= s_axi_rdata;
                        rresp_q    <= s_axi_rresp;
                        rd_state   <= RD_ADDR_HI;
                    end
                end

                // ----- Wide read: high 32-bit word -----
                RD_ADDR_HI: begin
                    if (s_axi_arready) begin
                        rd_state <= RD_DATA_HI;
                    end
                end

                RD_DATA_HI: begin
                    if (s_axi_rvalid) begin
                        // Accumulate worst-case RRESP
                        rresp_q <= (s_axi_rresp > rresp_q) ? s_axi_rresp : rresp_q;
                        rd_state <= RD_RESP;
                    end
                end

                // ----- Narrow read: single word -----
                RD_SINGLE_ADDR: begin
                    if (s_axi_arready) begin
                        rd_state <= RD_SINGLE_DATA;
                    end
                end

                RD_SINGLE_DATA: begin
                    if (s_axi_rvalid) begin
                        rdata_lo_q <= s_axi_rdata;
                        rresp_q    <= s_axi_rresp;
                        rd_state   <= RD_RESP;
                    end
                end

                // ----- Return result to master -----
                RD_RESP: begin
                    if (m_axi_rready) begin
                        if (ar_beat_cnt == ar_len_q) begin
                            // Last beat of upstream burst — done
                            rd_state <= RD_IDLE;
                        end else begin
                            // More beats to go: advance address, restart
                            ar_beat_cnt <= ar_beat_cnt + 8'd1;
                            ar_cur_addr <= ar_cur_addr + (wide_read ? 32'd8 : (32'd1 << ar_size_q));
                            rresp_q     <= 2'b00;
                            if (wide_read)
                                rd_state <= RD_ADDR_LO;
                            else
                                rd_state <= RD_SINGLE_ADDR;
                        end
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Read combinatorial outputs
    // -----------------------------------------------------------------------
    // m_axi_arready — accept upstream AR when idle
    assign m_axi_arready = (rd_state == RD_IDLE);

    // s_axi_arvalid / s_axi_araddr / etc.
    always_comb begin
        s_axi_arvalid  = 1'b0;
        s_axi_arid     = {{(S_ID_WIDTH-M_ID_WIDTH){1'b0}}, ar_id_q};
        s_axi_araddr   = ar_cur_addr;
        s_axi_arlen    = 8'd0;   // always single-beat downstream
        s_axi_arsize   = 3'd2;   // 4 bytes
        s_axi_arburst  = ar_burst_q;
        s_axi_arlock   = ar_lock_q;
        s_axi_arcache  = ar_cache_q;
        s_axi_arprot   = ar_prot_q;
        s_axi_arqos    = ar_qos_q;
        s_axi_arregion = {{(S_ID_WIDTH-4){1'b0}}, ar_region_q};

        case (rd_state)
            RD_ADDR_LO: begin
                s_axi_arvalid = 1'b1;
                s_axi_araddr  = {ar_cur_addr[31:3], 3'b000}; // low word
            end
            RD_ADDR_HI: begin
                s_axi_arvalid = 1'b1;
                s_axi_araddr  = {ar_cur_addr[31:3], 3'b100}; // high word (+4)
            end
            RD_SINGLE_ADDR: begin
                s_axi_arvalid = 1'b1;
                s_axi_araddr  = {ar_cur_addr[31:2], 2'b00};  // 4-byte aligned
                s_axi_arsize  = (ar_size_q > 3'd2) ? 3'd2 : ar_size_q;
            end
            default:;
        endcase
    end

    // s_axi_rready
    assign s_axi_rready = (rd_state == RD_DATA_LO) ||
                          (rd_state == RD_DATA_HI)  ||
                          (rd_state == RD_SINGLE_DATA);

    // m_axi_rvalid / m_axi_rdata / m_axi_rresp / m_axi_rlast / m_axi_rid
    always_comb begin
        m_axi_rvalid = 1'b0;
        m_axi_rid    = ar_id_q;
        m_axi_rdata  = 64'b0;
        m_axi_rresp  = rresp_q;
        m_axi_rlast  = (ar_beat_cnt == ar_len_q); // last beat of upstream burst

        if (rd_state == RD_RESP) begin
            m_axi_rvalid = 1'b1;
            if (wide_read) begin
                // RD_DATA_HI has already latched high word via s_axi_rdata
                // We need the current s_axi_rdata for the high word only in
                // RD_DATA_HI.  By RD_RESP state, s_axi_rdata is no longer
                // valid, so we capture it there.  Use rdata_lo_q for [31:0]
                // and a registered hi_word — see below.
                m_axi_rdata = {rdata_hi_q, rdata_lo_q};
            end else begin
                // Narrow: replicate 32-bit data into both halves so VeeR can
                // pick the correct byte lane using ARADDR[2].
                m_axi_rdata = {rdata_lo_q, rdata_lo_q};
            end
        end
    end

    // Capture high word in RD_DATA_HI
    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l)
            rdata_hi_q <= '0;
        else if (rd_state == RD_DATA_HI && s_axi_rvalid)
            rdata_hi_q <= s_axi_rdata;
    end

    // ========================================================================
    // WRITE PATH
    // ========================================================================
    // VeeR LSU issues AWSIZE ≤ 2 (byte/half/word), AWLEN = 0 single-beat.
    // We forward a single 32-bit downstream write.
    //
    // If AWADDR[2] == 1, the active lane is WDATA[63:32] / WSTRB[7:4].
    // If AWADDR[2] == 0, the active lane is WDATA[31:0]  / WSTRB[3:0].
    //
    // State:
    //   WR_IDLE    : waiting for m_axi_awvalid
    //   WR_ADDR    : forward AW downstream
    //   WR_DATA    : forward W downstream
    //   WR_RESP    : wait for B from downstream, forward to master
    // ========================================================================

    typedef enum logic [1:0] {
        WR_IDLE  = 2'd0,
        WR_ADDR  = 2'd1,
        WR_DATA  = 2'd2,
        WR_RESP  = 2'd3
    } wr_state_t;

    wr_state_t wr_state;

    logic [M_ID_WIDTH-1:0] aw_id_q;
    logic [31:0]           aw_addr_q;
    logic [7:0]            aw_len_q;
    logic [2:0]            aw_size_q;
    logic [1:0]            aw_burst_q;
    logic                  aw_lock_q;
    logic [3:0]            aw_cache_q;
    logic [2:0]            aw_prot_q;
    logic [3:0]            aw_qos_q;
    logic [3:0]            aw_region_q;
    logic [7:0]            aw_beat_cnt;
    logic [31:0]           aw_cur_addr;

    // Captured write data
    logic [31:0]           wdata_q;
    logic [3:0]            wstrb_q;
    logic                  wlast_q;
    logic                  w_captured;

    wire wr_is_upper  = m_axi_awaddr[2] || (m_axi_wvalid && (|m_axi_wstrb[7:4]));
    wire wr_cur_upper = aw_cur_addr[2]  || (|m_axi_wstrb[7:4]);

    always_ff @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            wr_state     <= WR_IDLE;
            aw_id_q      <= '0;
            aw_addr_q    <= '0;
            aw_len_q     <= '0;
            aw_size_q    <= '0;
            aw_burst_q   <= '0;
            aw_lock_q    <= '0;
            aw_cache_q   <= '0;
            aw_prot_q    <= '0;
            aw_qos_q     <= '0;
            aw_region_q  <= '0;
            aw_beat_cnt  <= '0;
            aw_cur_addr  <= '0;
            wdata_q      <= '0;
            wstrb_q      <= '0;
            wlast_q      <= '0;
            w_captured   <= 1'b0;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    w_captured <= 1'b0;
                    if (m_axi_awvalid) begin
                        aw_id_q     <= m_axi_awid;
                        aw_addr_q   <= {m_axi_awaddr[31:3], wr_is_upper, m_axi_awaddr[1:0]};
                        aw_len_q    <= m_axi_awlen;
                        aw_size_q   <= m_axi_awsize;
                        aw_burst_q  <= m_axi_awburst;
                        aw_lock_q   <= m_axi_awlock;
                        aw_cache_q  <= m_axi_awcache;
                        aw_prot_q   <= m_axi_awprot;
                        aw_qos_q    <= m_axi_awqos;
                        aw_region_q <= m_axi_awregion;
                        aw_beat_cnt <= 8'd0;
                        aw_cur_addr <= {m_axi_awaddr[31:3], wr_is_upper, m_axi_awaddr[1:0]};
                        wr_state    <= WR_ADDR;
                    end
                    // Also capture W if it arrives simultaneously
                    if (m_axi_wvalid) begin
                        w_captured <= 1'b1;
                        if (wr_is_upper) begin
                            wdata_q <= m_axi_wdata[63:32];
                            wstrb_q <= m_axi_wstrb[7:4];
                        end else begin
                            wdata_q <= m_axi_wdata[31:0];
                            wstrb_q <= m_axi_wstrb[3:0];
                        end
                        wlast_q <= m_axi_wlast;
                    end
                end

                WR_ADDR: begin
                    // Capture W if it arrives while waiting for AWREADY
                    if (m_axi_wvalid && !w_captured) begin
                        w_captured <= 1'b1;
                        aw_cur_addr[2] <= wr_cur_upper;
                        if (wr_cur_upper) begin
                            wdata_q <= m_axi_wdata[63:32];
                            wstrb_q <= m_axi_wstrb[7:4];
                        end else begin
                            wdata_q <= m_axi_wdata[31:0];
                            wstrb_q <= m_axi_wstrb[3:0];
                        end
                        wlast_q <= m_axi_wlast;
                    end
                    if (s_axi_awready) begin
                        wr_state <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    // Capture W if not yet captured
                    if (m_axi_wvalid && !w_captured) begin
                        w_captured <= 1'b1;
                        if (wr_cur_upper) begin
                            wdata_q <= m_axi_wdata[63:32];
                            wstrb_q <= m_axi_wstrb[7:4];
                        end else begin
                            wdata_q <= m_axi_wdata[31:0];
                            wstrb_q <= m_axi_wstrb[3:0];
                        end
                        wlast_q <= m_axi_wlast;
                    end
                    if (s_axi_wready && w_captured) begin
                        wr_state <= WR_RESP;
                    end
                end

                WR_RESP: begin
                    if (s_axi_bvalid) begin
                        // Check if this was the last beat of upstream burst
                        if (aw_beat_cnt == aw_len_q) begin
                            wr_state <= WR_IDLE;
                        end else begin
                            // More beats: advance address
                            aw_beat_cnt <= aw_beat_cnt + 8'd1;
                            aw_cur_addr <= aw_cur_addr + (32'd1 << aw_size_q);
                            w_captured  <= 1'b0;
                            wr_state    <= WR_ADDR;
                        end
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // -----------------------------------------------------------------------
    // Write combinatorial outputs
    // -----------------------------------------------------------------------
    assign m_axi_awready = (wr_state == WR_IDLE);

    // m_axi_wready: accept upstream W when we're ready to capture it
    assign m_axi_wready = (wr_state == WR_IDLE || wr_state == WR_ADDR || wr_state == WR_DATA)
                          && !w_captured;

    // s_axi_awvalid
    assign s_axi_awvalid  = (wr_state == WR_ADDR);
    assign s_axi_awid     = {{(S_ID_WIDTH-M_ID_WIDTH){1'b0}}, aw_id_q};
    assign s_axi_awaddr   = {aw_cur_addr[31:2], 2'b00};
    assign s_axi_awlen    = 8'd0;
    assign s_axi_awsize   = (aw_size_q > 3'd2) ? 3'd2 : aw_size_q;
    assign s_axi_awburst  = aw_burst_q;
    assign s_axi_awlock   = aw_lock_q;
    assign s_axi_awcache  = aw_cache_q;
    assign s_axi_awprot   = aw_prot_q;
    assign s_axi_awqos    = aw_qos_q;
    assign s_axi_awregion = {{(S_ID_WIDTH-4){1'b0}}, aw_region_q};

    // s_axi_wvalid/wdata/wstrb/wlast
    assign s_axi_wvalid = (wr_state == WR_DATA) && w_captured;
    assign s_axi_wdata  = wdata_q;
    assign s_axi_wstrb  = wstrb_q;
    assign s_axi_wlast  = 1'b1; // always last — single beat downstream

    // s_axi_bready
    assign s_axi_bready = (wr_state == WR_RESP);

    // m_axi_bvalid / m_axi_bresp / m_axi_bid
    assign m_axi_bvalid = (wr_state == WR_RESP) && s_axi_bvalid
                          && (aw_beat_cnt == aw_len_q);
    assign m_axi_bresp  = s_axi_bresp;
    assign m_axi_bid    = aw_id_q;

endmodule
