// qrs_axi4_wrapper.v
// AXI4 single-beat peripheral wrapper for WTSEE V6.
// Supports single-beat writes/reads (AWLEN/ARLEN == 0).
// Multi-beat bursts are not supported; software should use single transfers.
// Original WTSEE RTL remains unchanged.



module qrs_axi4_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    parameter integer FS = 360,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR = 32'h4000_1000
)(
    input  wire                   clk,
    input  wire                   rst,

    // AXI4 write address channel
    input  wire [ID_WIDTH-1:0]    s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire [3:0]             s_axi_awqos,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // AXI4 write data channel
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // AXI4 write response channel
    output reg [ID_WIDTH-1:0]     s_axi_bid,
    output reg [1:0]              s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // AXI4 read address channel
    input  wire [ID_WIDTH-1:0]    s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire [3:0]             s_axi_arqos,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // AXI4 read data channel
    output reg [ID_WIDTH-1:0]     s_axi_rid,
    output reg [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg [1:0]              s_axi_rresp,
    output reg                    s_axi_rlast,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    localparam [11:0] REG_CONTROL      = 12'h000;
    localparam [11:0] REG_STATUS       = 12'h004;
    localparam [11:0] REG_ECG_INPUT    = 12'h008;
    localparam [11:0] REG_RPEAK        = 12'h00C;
    localparam [11:0] REG_RR_INTERVAL  = 12'h010;
    localparam [11:0] REG_BPM          = 12'h014;
    localparam [11:0] REG_RHYTHM_CLASS = 12'h018;

    reg [ADDR_WIDTH-1:0] awaddr_q;
    reg [ID_WIDTH-1:0]   awid_q;
    reg                  aw_pending;
    reg [31:0]           control_reg;
    reg signed [15:0]    ecg_sample_reg;
    reg                  ecg_valid_pulse;

    reg                  rpeak_q;
    reg [15:0]           rr_q, bpm_q;
    reg [1:0]            rhythm_q;
    reg                  result_valid_q;

    wire rpeak;
    wire [15:0] rr_interval, bpm;
    wire [1:0] rhythm_class;
    wire result_valid;

    ecg_wtsee_v6_top #(.FS(FS)) u_wtsee (
        .clk(clk),
        .rst_n(~rst),
        .ecg_in(ecg_sample_reg),
        .ecg_valid(ecg_valid_pulse),
        .r_peak(rpeak),
        .rr_interval(rr_interval),
        .bpm(bpm),
        .rhythm_class(rhythm_class),
        .result_valid(result_valid)
    );

    wire [11:0] write_offset = awaddr_q[11:0];

    // Single outstanding, single-beat AXI4 write transaction.
    always @(posedge clk) begin
        if (rst) begin
            s_axi_awready <= 1'b1;
            s_axi_wready  <= 1'b0;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00;
            s_axi_bvalid  <= 1'b0;
            awaddr_q      <= {ADDR_WIDTH{1'b0}};
            awid_q        <= {ID_WIDTH{1'b0}};
            aw_pending    <= 1'b0;
            control_reg   <= 32'd0;
            ecg_sample_reg<= 16'sd0;
            ecg_valid_pulse <= 1'b0;
        end else begin
            ecg_valid_pulse <= 1'b0;

            if (s_axi_awready && s_axi_awvalid) begin
                awaddr_q   <= s_axi_awaddr;
                awid_q     <= s_axi_awid;
                aw_pending <= 1'b1;
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b1;
                // AXI DECERR for unsupported burst length; otherwise OKAY.
                s_axi_bresp <= (s_axi_awlen == 0) ? 2'b00 : 2'b11;
            end

            if (s_axi_wready && s_axi_wvalid && aw_pending) begin
                if (s_axi_bresp == 2'b00) begin
                    case (write_offset)
                        REG_CONTROL: begin
                            if (s_axi_wstrb[0]) control_reg[7:0] <= s_axi_wdata[7:0];
                        end
                        REG_ECG_INPUT: begin
                            if (s_axi_wstrb[0] || s_axi_wstrb[1]) begin
                                ecg_sample_reg <= s_axi_wdata[15:0];
                                if (control_reg[0]) ecg_valid_pulse <= 1'b1;
                            end
                        end
                        default: ;
                    endcase
                end
                s_axi_wready <= 1'b0;
                s_axi_bvalid <= 1'b1;
                s_axi_bid    <= awid_q;
                aw_pending   <= 1'b0;
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid  <= 1'b0;
                s_axi_awready <= 1'b1;
            end
        end
    end

    // Capture detector results.
    always @(posedge clk) begin
        if (rst) begin
            rpeak_q        <= 1'b0;
            rr_q           <= 16'd0;
            bpm_q          <= 16'd0;
            rhythm_q       <= 2'd0;
            result_valid_q <= 1'b0;
        end else begin
            rpeak_q        <= rpeak;
            result_valid_q <= result_valid;
            if (result_valid) begin
                rr_q     <= rr_interval;
                bpm_q    <= bpm;
                rhythm_q <= rhythm_class;
            end
        end
    end

    // Single-beat AXI4 read channel.
    reg [ADDR_WIDTH-1:0] araddr_q;
    reg [ID_WIDTH-1:0]   arid_q;

    always @(posedge clk) begin
        if (rst) begin
            s_axi_arready <= 1'b1;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b1;
            s_axi_rvalid  <= 1'b0;
            araddr_q      <= {ADDR_WIDTH{1'b0}};
            arid_q        <= {ID_WIDTH{1'b0}};
        end else begin
            if (s_axi_arready && s_axi_arvalid) begin
                araddr_q <= s_axi_araddr;
                arid_q   <= s_axi_arid;
                s_axi_arready <= 1'b0;
                s_axi_rvalid  <= 1'b1;
                s_axi_rid     <= s_axi_arid;
                s_axi_rlast   <= 1'b1;
                s_axi_rresp   <= (s_axi_arlen == 0) ? 2'b00 : 2'b11;
                if (s_axi_arlen != 0) begin
                    s_axi_rdata <= {DATA_WIDTH{1'b0}};
                end else begin
                    case (s_axi_araddr[11:0])
                        REG_CONTROL:      s_axi_rdata <= {{(DATA_WIDTH-32){1'b0}}, control_reg};
                        REG_STATUS:       s_axi_rdata <= {{(DATA_WIDTH-32){1'b0}}, 30'd0, result_valid_q, control_reg[0]};
                        REG_ECG_INPUT:    s_axi_rdata <= {{(DATA_WIDTH-16){1'b0}}, ecg_sample_reg};
                        REG_RPEAK:        s_axi_rdata <= {{(DATA_WIDTH-1){1'b0}}, rpeak_q};
                        REG_RR_INTERVAL:  s_axi_rdata <= {{(DATA_WIDTH-16){1'b0}}, rr_q};
                        REG_BPM:          s_axi_rdata <= {{(DATA_WIDTH-16){1'b0}}, bpm_q};
                        REG_RHYTHM_CLASS: s_axi_rdata <= {{(DATA_WIDTH-2){1'b0}}, rhythm_q};
                        default:          s_axi_rdata <= {DATA_WIDTH{1'b0}};
                    endcase
                end
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid  <= 1'b0;
                s_axi_arready <= 1'b1;
            end
        end
    end

endmodule
