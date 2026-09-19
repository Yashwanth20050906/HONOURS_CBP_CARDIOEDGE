// =============================================================================
// aes_cipher_top.v
// AES-256 Encryption Engine
// =============================================================================

module aes_cipher_top (
    input              clk,
    input              rst_n,
    input              start,
    input  [255:0]     key,
    input  [127:0]     text_in,
    output reg [127:0] text_out,
    output reg         busy,
    output reg         done
);

    // -------------------------------------------------------------------------
    // FSM
    // -------------------------------------------------------------------------
    localparam [2:0]
        ST_IDLE    = 3'd0,
        ST_KEY_EXP = 3'd1,
        ST_LOAD    = 3'd2,
        ST_ROUND   = 3'd3,
        ST_DONE    = 3'd4;

    reg [2:0] state;

    // AES rounds: 1..14
    reg [3:0] round_cnt;

    // -------------------------------------------------------------------------
    // AES-256 key expansion
    // -------------------------------------------------------------------------
    reg          kld;
    wire         key_ready;

    wire [127:0] rk [0:14];

    aes_key_expand_256 u_kexp (
        .clk       (clk),
        .rst_n     (rst_n),
        .kld       (kld),
        .key       (key),
        .key_ready (key_ready),
        .rk0       (rk[0]),
        .rk1       (rk[1]),
        .rk2       (rk[2]),
        .rk3       (rk[3]),
        .rk4       (rk[4]),
        .rk5       (rk[5]),
        .rk6       (rk[6]),
        .rk7       (rk[7]),
        .rk8       (rk[8]),
        .rk9       (rk[9]),
        .rk10      (rk[10]),
        .rk11      (rk[11]),
        .rk12      (rk[12]),
        .rk13      (rk[13]),
        .rk14      (rk[14])
    );

    // -------------------------------------------------------------------------
    // AES state
    // -------------------------------------------------------------------------
    reg [7:0] s [0:15];

    // -------------------------------------------------------------------------
    // S-box
    // -------------------------------------------------------------------------
    wire [7:0] sb [0:15];

    genvar gi;

    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : gen_sbox
            aes_sbox u_sb (
                .a(s[gi]),
                .d(sb[gi])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // ShiftRows
    // -------------------------------------------------------------------------

    wire [7:0] sr [0:15];

    // Row 0
    assign sr[0]  = sb[0];
    assign sr[1]  = sb[1];
    assign sr[2]  = sb[2];
    assign sr[3]  = sb[3];

    // Row 1
    assign sr[4]  = sb[5];
    assign sr[5]  = sb[6];
    assign sr[6]  = sb[7];
    assign sr[7]  = sb[4];

    // Row 2
    assign sr[8]  = sb[10];
    assign sr[9]  = sb[11];
    assign sr[10] = sb[8];
    assign sr[11] = sb[9];

    // Row 3
    assign sr[12] = sb[15];
    assign sr[13] = sb[12];
    assign sr[14] = sb[13];
    assign sr[15] = sb[14];

    // -------------------------------------------------------------------------
    // MixColumns
    // -------------------------------------------------------------------------

    function [7:0] xtime;
        input [7:0] b;

        begin
            xtime = {b[6:0],1'b0} ^
                    (8'h1b & {8{b[7]}});
        end
    endfunction

    function [31:0] mix_col;

        input [7:0] a0;
        input [7:0] a1;
        input [7:0] a2;
        input [7:0] a3;

        reg [7:0] x0;
        reg [7:0] x1;
        reg [7:0] x2;
        reg [7:0] x3;

        reg [7:0] t0;
        reg [7:0] t1;
        reg [7:0] t2;
        reg [7:0] t3;

        begin

            x0 = xtime(a0);
            x1 = xtime(a1);
            x2 = xtime(a2);
            x3 = xtime(a3);

            t0 = x0 ^ (x1 ^ a1) ^ a2 ^ a3;

            t1 = a0 ^ x1 ^ (x2 ^ a2) ^ a3;

            t2 = a0 ^ a1 ^ x2 ^ (x3 ^ a3);

            t3 = (x0 ^ a0) ^ a1 ^ a2 ^ x3;

            mix_col = {t0,t1,t2,t3};

        end

    endfunction

    wire [31:0] mc_col0;
    wire [31:0] mc_col1;
    wire [31:0] mc_col2;
    wire [31:0] mc_col3;

    assign mc_col0 = mix_col(
        sr[0],
        sr[4],
        sr[8],
        sr[12]
    );

    assign mc_col1 = mix_col(
        sr[1],
        sr[5],
        sr[9],
        sr[13]
    );

    assign mc_col2 = mix_col(
        sr[2],
        sr[6],
        sr[10],
        sr[14]
    );

    assign mc_col3 = mix_col(
        sr[3],
        sr[7],
        sr[11],
        sr[15]
    );

    wire [7:0] mc [0:15];

    assign {mc[0],mc[4],mc[8],mc[12]} = mc_col0;
    assign {mc[1],mc[5],mc[9],mc[13]} = mc_col1;
    assign {mc[2],mc[6],mc[10],mc[14]} = mc_col2;
    assign {mc[3],mc[7],mc[11],mc[15]} = mc_col3;

    // -------------------------------------------------------------------------
    // Round-key selection
    // -------------------------------------------------------------------------

    reg [127:0] cur_rk;

    always @(*) begin

        case (round_cnt)

            4'd0:  cur_rk = rk[0];
            4'd1:  cur_rk = rk[1];
            4'd2:  cur_rk = rk[2];
            4'd3:  cur_rk = rk[3];
            4'd4:  cur_rk = rk[4];
            4'd5:  cur_rk = rk[5];
            4'd6:  cur_rk = rk[6];
            4'd7:  cur_rk = rk[7];
            4'd8:  cur_rk = rk[8];
            4'd9:  cur_rk = rk[9];
            4'd10: cur_rk = rk[10];
            4'd11: cur_rk = rk[11];
            4'd12: cur_rk = rk[12];
            4'd13: cur_rk = rk[13];
            4'd14: cur_rk = rk[14];

            default:
                cur_rk = 128'h0;

        endcase

    end

    // -------------------------------------------------------------------------
    // Round-key byte mapping
    // -------------------------------------------------------------------------

    wire [7:0] rk_byte [0:15];

    assign rk_byte[0]  = cur_rk[127:120];
    assign rk_byte[4]  = cur_rk[119:112];
    assign rk_byte[8]  = cur_rk[111:104];
    assign rk_byte[12] = cur_rk[103:96];

    assign rk_byte[1]  = cur_rk[95:88];
    assign rk_byte[5]  = cur_rk[87:80];
    assign rk_byte[9]  = cur_rk[79:72];
    assign rk_byte[13] = cur_rk[71:64];

    assign rk_byte[2]  = cur_rk[63:56];
    assign rk_byte[6]  = cur_rk[55:48];
    assign rk_byte[10] = cur_rk[47:40];
    assign rk_byte[14] = cur_rk[39:32];

    assign rk_byte[3]  = cur_rk[31:24];
    assign rk_byte[7]  = cur_rk[23:16];
    assign rk_byte[11] = cur_rk[15:8];
    assign rk_byte[15] = cur_rk[7:0];

    // -------------------------------------------------------------------------
    // Final round
    // -------------------------------------------------------------------------

    wire is_final_round;

    assign is_final_round = (round_cnt == 4'd14);

    wire [7:0] next_s [0:15];

    genvar gk;

    generate

        for (gk = 0; gk < 16; gk = gk + 1) begin : gen_next_s

            assign next_s[gk] =
                (is_final_round ? sr[gk] : mc[gk])
                ^ rk_byte[gk];

        end

    endgenerate

    // -------------------------------------------------------------------------
    // Input register
    // -------------------------------------------------------------------------

    reg [127:0] text_in_r;

    // -------------------------------------------------------------------------
    // Main FSM
    // -------------------------------------------------------------------------

    integer i;

    always @(posedge clk) begin

        if (!rst_n) begin

            state     <= ST_IDLE;

            busy      <= 1'b0;
            done      <= 1'b0;
            kld       <= 1'b0;

            round_cnt <= 4'd0;

            text_out  <= 128'h0;
            text_in_r <= 128'h0;

            for (i = 0; i < 16; i = i + 1)
                s[i] <= 8'h00;

        end

        else begin

            // Defaults
            done <= 1'b0;
            kld  <= 1'b0;

            case (state)

                // =============================================================
                // IDLE
                // =============================================================

                ST_IDLE: begin

                    if (start) begin

                        text_in_r <= text_in;

                        kld <= 1'b1;

                        busy <= 1'b1;

                        // Start every transaction from round 0.
                        round_cnt <= 4'd0;

                        $display(
                            "[AES START] key=%064h text_in=%032h",
                            key,
                            text_in
                        );

                        state <= ST_KEY_EXP;

                    end

                end

                // =============================================================
                // KEY EXPANSION
                // =============================================================

                ST_KEY_EXP: begin

                    if (key_ready) begin

                        // -----------------------------------------------------
                        // Initial AddRoundKey
                        //
                        // ALWAYS RK0.
                        // -----------------------------------------------------

                        s[0]  <= text_in_r[127:120] ^ rk[0][127:120];
                        s[4]  <= text_in_r[119:112] ^ rk[0][119:112];
                        s[8]  <= text_in_r[111:104] ^ rk[0][111:104];
                        s[12] <= text_in_r[103:96]  ^ rk[0][103:96];

                        s[1]  <= text_in_r[95:88] ^ rk[0][95:88];
                        s[5]  <= text_in_r[87:80] ^ rk[0][87:80];
                        s[9]  <= text_in_r[79:72] ^ rk[0][79:72];
                        s[13] <= text_in_r[71:64] ^ rk[0][71:64];

                        s[2]  <= text_in_r[63:56] ^ rk[0][63:56];
                        s[6]  <= text_in_r[55:48] ^ rk[0][55:48];
                        s[10] <= text_in_r[47:40] ^ rk[0][47:40];
                        s[14] <= text_in_r[39:32] ^ rk[0][39:32];

                        s[3]  <= text_in_r[31:24] ^ rk[0][31:24];
                        s[7]  <= text_in_r[23:16] ^ rk[0][23:16];
                        s[11] <= text_in_r[15:8]  ^ rk[0][15:8];
                        s[15] <= text_in_r[7:0]   ^ rk[0][7:0];

                        round_cnt <= 4'd1;

                        state <= ST_ROUND;

                    end

                end

                // =============================================================
                // ROUNDS 1..14
                // =============================================================

                ST_ROUND: begin

                    for (i = 0; i < 16; i = i + 1)
                        s[i] <= next_s[i];

                    if (round_cnt == 4'd14) begin

                        text_out <= {
                            next_s[0],
                            next_s[4],
                            next_s[8],
                            next_s[12],

                            next_s[1],
                            next_s[5],
                            next_s[9],
                            next_s[13],

                            next_s[2],
                            next_s[6],
                            next_s[10],
                            next_s[14],

                            next_s[3],
                            next_s[7],
                            next_s[11],
                            next_s[15]
                        };

                        busy <= 1'b0;
                        done <= 1'b1;

                        $display(
                            "[AES DONE] text_out=%032h",
                            {
                                next_s[0],
                                next_s[4],
                                next_s[8],
                                next_s[12],
                                next_s[1],
                                next_s[5],
                                next_s[9],
                                next_s[13],
                                next_s[2],
                                next_s[6],
                                next_s[10],
                                next_s[14],
                                next_s[3],
                                next_s[7],
                                next_s[11],
                                next_s[15]
                            }
                        );

                        state <= ST_DONE;

                    end

                    else begin

                        round_cnt <= round_cnt + 4'd1;

                    end

                end

                // =============================================================
                // DONE
                // =============================================================

                ST_DONE: begin

                    if (start) begin

                        text_in_r <= text_in;

                        kld <= 1'b1;

                        busy <= 1'b1;

                        // IMPORTANT:
                        // Reset round counter for every new operation.
                        round_cnt <= 4'd0;

                        $display(
                            "[AES RESTART] key=%064h text_in=%032h",
                            key,
                            text_in
                        );

                        state <= ST_KEY_EXP;

                    end

                end

                // =============================================================
                // DEFAULT
                // =============================================================

                default: begin

                    state     <= ST_IDLE;
                    busy      <= 1'b0;
                    done      <= 1'b0;
                    kld       <= 1'b0;
                    round_cnt <= 4'd0;

                end

            endcase

        end

    end

endmodule
