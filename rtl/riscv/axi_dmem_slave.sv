// ============================================================================
// axi_dmem_slave.sv
//
// CARDIOEDGE — AXI4 32-bit DMEM slave, 64 KB, zero-initialized.
// Maps to 0x00010000–0x0001FFFF.
// Identical structure to axi_imem_slave, just zero-init.
// ============================================================================

module axi_dmem_slave #(
    parameter AXI_ID_WIDTH   = 8,
    parameter AXI_DATA_WIDTH = 32,
    parameter AXI_ADDR_WIDTH = 32,
    parameter MEM_SIZE_BYTES = 65536,
    parameter BASE_ADDR      = 32'h0001_0000
)(
    input  logic                        aclk,
    input  logic                        aresetn,

    input  logic [AXI_ID_WIDTH-1:0]     s_awid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_awaddr,
    input  logic [7:0]                  s_awlen,
    input  logic [2:0]                  s_awsize,
    input  logic [1:0]                  s_awburst,
    input  logic                        s_awlock,
    input  logic [3:0]                  s_awcache,
    input  logic [2:0]                  s_awprot,
    input  logic [3:0]                  s_awqos,
    input  logic [3:0]                  s_awregion,
    input  logic                        s_awvalid,
    output logic                        s_awready,

    input  logic [AXI_DATA_WIDTH-1:0]   s_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0] s_wstrb,
    input  logic                        s_wlast,
    input  logic                        s_wvalid,
    output logic                        s_wready,

    output logic [AXI_ID_WIDTH-1:0]     s_bid,
    output logic [1:0]                  s_bresp,
    output logic                        s_bvalid,
    input  logic                        s_bready,

    input  logic [AXI_ID_WIDTH-1:0]     s_arid,
    input  logic [AXI_ADDR_WIDTH-1:0]   s_araddr,
    input  logic [7:0]                  s_arlen,
    input  logic [2:0]                  s_arsize,
    input  logic [1:0]                  s_arburst,
    input  logic                        s_arlock,
    input  logic [3:0]                  s_arcache,
    input  logic [2:0]                  s_arprot,
    input  logic [3:0]                  s_arqos,
    input  logic [3:0]                  s_arregion,
    input  logic                        s_arvalid,
    output logic                        s_arready,

    output logic [AXI_ID_WIDTH-1:0]     s_rid,
    output logic [AXI_DATA_WIDTH-1:0]   s_rdata,
    output logic [1:0]                  s_rresp,
    output logic                        s_rlast,
    output logic                        s_rvalid,
    input  logic                        s_rready
);
    localparam MEM_DEPTH = MEM_SIZE_BYTES / (AXI_DATA_WIDTH/8);
    localparam ADDR_BITS = $clog2(MEM_DEPTH);

    logic [AXI_DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 32'h0;
    end

    function automatic logic [ADDR_BITS-1:0] word_addr(input logic [31:0] ba);
        return ba[ADDR_BITS+1:2];
    endfunction

    function automatic logic in_range(input logic [31:0] addr);
        return (addr >= BASE_ADDR) && (addr < (BASE_ADDR + MEM_SIZE_BYTES));
    endfunction

    function automatic logic [31:0] next_addr(input logic [31:0] addr, input logic [1:0] burst, input logic [2:0] size);
        if (burst == 2'b01) return addr + (32'd1 << size);
        else                return addr;
    endfunction

    // Read
    typedef enum logic [1:0] { RD_IDLE=2'd0, RD_RESP=2'd1 } rd_st_t;
    rd_st_t rd_state;
    logic [AXI_ID_WIDTH-1:0] r_id_q;
    logic [31:0] r_addr_q;
    logic [7:0]  r_len_q, r_cnt;
    logic [1:0]  r_burst_q;
    logic        r_range_err;

    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin rd_state<=RD_IDLE; r_id_q<='0; r_addr_q<='0; r_len_q<='0; r_cnt<='0; r_burst_q<='0; r_range_err<=0; end
        else case (rd_state)
            RD_IDLE: if (s_arvalid) begin r_id_q<=s_arid; r_addr_q<=s_araddr; r_len_q<=s_arlen; r_cnt<=8'd0; r_burst_q<=s_arburst; r_range_err<=!in_range(s_araddr); rd_state<=RD_RESP; end
            RD_RESP: if (s_rready) begin if (r_cnt==r_len_q) rd_state<=RD_IDLE; else begin r_cnt<=r_cnt+8'd1; r_addr_q<=next_addr(r_addr_q,r_burst_q,3'd2); r_range_err<=!in_range(next_addr(r_addr_q,r_burst_q,3'd2)); end end
        endcase
    end
    assign s_arready = (rd_state==RD_IDLE);
    assign s_rvalid  = (rd_state==RD_RESP);
    assign s_rid     = r_id_q;
    assign s_rresp   = r_range_err ? 2'b10 : 2'b00;
    assign s_rlast   = (r_cnt==r_len_q);
    assign s_rdata   = r_range_err ? 32'hDEAD_BEEF : mem[word_addr(r_addr_q)];

    // Write
    typedef enum logic [1:0] { WR_IDLE=2'd0, WR_DATA=2'd1, WR_RESP=2'd2 } wr_st_t;
    wr_st_t wr_state;
    logic [AXI_ID_WIDTH-1:0] w_id_q;
    logic [31:0] w_addr_q;
    logic [7:0]  w_len_q, w_cnt;
    logic [1:0]  w_burst_q;
    logic [2:0]  w_size_q;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin wr_state<=WR_IDLE; w_id_q<='0; w_addr_q<='0; w_len_q<='0; w_cnt<='0; w_burst_q<='0; w_size_q<='0; end
        else case (wr_state)
            WR_IDLE: if (s_awvalid) begin w_id_q<=s_awid; w_addr_q<=s_awaddr; w_len_q<=s_awlen; w_cnt<=8'd0; w_burst_q<=s_awburst; w_size_q<=s_awsize; wr_state<=WR_DATA; end
            WR_DATA: if (s_wvalid) begin
                if (in_range(w_addr_q)) for (int b=0;b<AXI_DATA_WIDTH/8;b++) if(s_wstrb[b]) mem[word_addr(w_addr_q)][b*8+:8]<=s_wdata[b*8+:8];
                if (s_wlast||w_cnt==w_len_q) wr_state<=WR_RESP;
                else begin w_cnt<=w_cnt+8'd1; w_addr_q<=next_addr(w_addr_q,w_burst_q,w_size_q); end
            end
            WR_RESP: if (s_bready) wr_state<=WR_IDLE;
        endcase
    end
    assign s_awready = (wr_state==WR_IDLE);
    assign s_wready  = (wr_state==WR_DATA);
    assign s_bvalid  = (wr_state==WR_RESP);
    assign s_bid     = w_id_q;
    assign s_bresp   = 2'b00;

endmodule
