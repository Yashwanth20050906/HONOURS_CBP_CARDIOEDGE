// =============================================================================
// aes_inv_cipher_top.v
// AES-256 Decryption Engine
//
// AES-256:
//   Key        : 256 bits
//   Block      : 128 bits
//   Rounds     : 14
//
// IMPORTANT:
// This module uses the SAME internal state representation as the working
// aes_cipher_top.v:
//
//   s[0]  s[1]  s[2]  s[3]
//   s[4]  s[5]  s[6]  s[7]
//   s[8]  s[9]  s[10] s[11]
//   s[12] s[13] s[14] s[15]
//
// This is a row-major representation of the AES state.
//
// External 128-bit data is mapped into the state exactly like the encryption
// core:
//
//   text[127:120] -> s[0]
//   text[119:112] -> s[4]
//   text[111:104] -> s[8]
//   text[103:96]  -> s[12]
//
//   text[95:88]   -> s[1]
//   text[87:80]   -> s[5]
//   text[79:72]   -> s[9]
//   text[71:64]   -> s[13]
//
//   text[63:56]   -> s[2]
//   text[55:48]   -> s[6]
//   text[47:40]   -> s[10]
//   text[39:32]   -> s[14]
//
//   text[31:24]   -> s[3]
//   text[23:16]   -> s[7]
//   text[15:8]    -> s[11]
//   text[7:0]     -> s[15]
//
// AES-256 decryption:
//
//   Initial:
//       AddRoundKey using Round Key 14
//
//   Rounds 13 down to 1:
//       InvShiftRows
//       InvSubBytes
//       AddRoundKey
//       InvMixColumns
//
//   Final Round 0:
//       InvShiftRows
//       InvSubBytes
//       AddRoundKey
//       NO InvMixColumns
//
// =============================================================================

module aes_inv_cipher_top (
    input              clk,
    input              rst_n,
    input              start,
    input  [255:0]     key,
    input  [127:0]     text_in,
    output reg [127:0] text_out,
    output reg         busy,
    output reg         done
);

    // =========================================================================
    // FSM
    // =========================================================================

    localparam [2:0]
        ST_IDLE    = 3'd0,
        ST_KEY_EXP = 3'd1,
        ST_ROUND   = 3'd2,
        ST_DONE    = 3'd3;

    reg [2:0] state;

    // Decryption round counter:
    //
    // Initial AddRoundKey = round 14
    // Then 13,12,...,1,0
    //
    reg [3:0] round_cnt;


    // =========================================================================
    // AES-256 KEY EXPANSION
    // =========================================================================

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


    // =========================================================================
    // AES STATE
    //
    // Same representation as aes_cipher_top.v
    //
    //        col0 col1 col2 col3
    //
    // row0    s0   s1   s2   s3
    // row1    s4   s5   s6   s7
    // row2    s8   s9   s10  s11
    // row3    s12  s13  s14  s15
    //
    // =========================================================================

    reg [7:0] s [0:15];


    // =========================================================================
    // INVSHIFTROWS
    //
    // Current:
    //
    // Row 0: s0  s1  s2  s3
    // Row 1: s4  s5  s6  s7
    // Row 2: s8  s9  s10 s11
    // Row 3: s12 s13 s14 s15
    //
    // Inverse ShiftRows:
    //
    // Row 0: unchanged
    //
    // Row 1: right rotate by 1
    //        [s4 s5 s6 s7]
    //        [s7 s4 s5 s6]
    //
    // Row 2: right rotate by 2
    //        [s8 s9 s10 s11]
    //        [s10 s11 s8 s9]
    //
    // Row 3: right rotate by 3
    //        [s12 s13 s14 s15]
    //        [s13 s14 s15 s12]
    //
    // =========================================================================

    wire [7:0] isr [0:15];

    // Row 0
    assign isr[0] = s[0];
    assign isr[1] = s[1];
    assign isr[2] = s[2];
    assign isr[3] = s[3];

    // Row 1
    assign isr[4] = s[7];
    assign isr[5] = s[4];
    assign isr[6] = s[5];
    assign isr[7] = s[6];

    // Row 2
    assign isr[8]  = s[10];
    assign isr[9]  = s[11];
    assign isr[10] = s[8];
    assign isr[11] = s[9];

    // Row 3
    assign isr[12] = s[13];
    assign isr[13] = s[14];
    assign isr[14] = s[15];
    assign isr[15] = s[12];


    // =========================================================================
    // INVERSE SUB BYTES
    // =========================================================================

    wire [7:0] isr_isb [0:15];

    genvar i;

    generate

        for (i = 0; i < 16; i = i + 1) begin : GEN_INV_SBOX

            aes_inv_sbox u_inv_sbox (
                .a (isr[i]),
                .d (isr_isb[i])
            );

        end

    endgenerate


    // =========================================================================
    // ROUND KEY SELECTION
    // =========================================================================

    reg [127:0] cur_rk;

    always @(*) begin

        case (round_cnt)

            4'd0:
                cur_rk = rk[0];

            4'd1:
                cur_rk = rk[1];

            4'd2:
                cur_rk = rk[2];

            4'd3:
                cur_rk = rk[3];

            4'd4:
                cur_rk = rk[4];

            4'd5:
                cur_rk = rk[5];

            4'd6:
                cur_rk = rk[6];

            4'd7:
                cur_rk = rk[7];

            4'd8:
                cur_rk = rk[8];

            4'd9:
                cur_rk = rk[9];

            4'd10:
                cur_rk = rk[10];

            4'd11:
                cur_rk = rk[11];

            4'd12:
                cur_rk = rk[12];

            4'd13:
                cur_rk = rk[13];

            4'd14:
                cur_rk = rk[14];

            default:
                cur_rk = 128'h00000000000000000000000000000000;

        endcase

    end


    // =========================================================================
    // ROUND KEY BYTE MAPPING
    //
    // Same mapping as aes_cipher_top.v
    //
    // rk[127:120] -> state 0
    // rk[119:112] -> state 4
    // rk[111:104] -> state 8
    // rk[103:96]  -> state 12
    //
    // rk[95:88]   -> state 1
    // rk[87:80]   -> state 5
    // rk[79:72]   -> state 9
    // rk[71:64]   -> state 13
    //
    // rk[63:56]   -> state 2
    // rk[55:48]   -> state 6
    // rk[47:40]   -> state 10
    // rk[39:32]   -> state 14
    //
    // rk[31:24]   -> state 3
    // rk[23:16]   -> state 7
    // rk[15:8]    -> state 11
    // rk[7:0]     -> state 15
    //
    // =========================================================================

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


    // =========================================================================
    // ADD ROUND KEY
    // =========================================================================

    wire [7:0] ark [0:15];

    genvar j;

    generate

        for (j = 0; j < 16; j = j + 1) begin : GEN_ARK

            assign ark[j] =
                isr_isb[j] ^ rk_byte[j];

        end

    endgenerate


    // =========================================================================
    // GF(2^8) MULTIPLICATION
    // =========================================================================

    function [7:0] xtime;

        input [7:0] b;

        begin

            xtime =
                {b[6:0],1'b0} ^
                (8'h1b & {8{b[7]}});

        end

    endfunction


    // =========================================================================
    // MULTIPLY BY 0x09
    // =========================================================================

    function [7:0] mul09;

        input [7:0] b;

        reg [7:0] x2;
        reg [7:0] x4;
        reg [7:0] x8;

        begin

            x2 = xtime(b);
            x4 = xtime(x2);
            x8 = xtime(x4);

            mul09 = x8 ^ b;

        end

    endfunction


    // =========================================================================
    // MULTIPLY BY 0x0B
    // =========================================================================

    function [7:0] mul0b;

        input [7:0] b;

        reg [7:0] x2;
        reg [7:0] x4;
        reg [7:0] x8;

        begin

            x2 = xtime(b);
            x4 = xtime(x2);
            x8 = xtime(x4);

            mul0b = x8 ^ x2 ^ b;

        end

    endfunction


    // =========================================================================
    // MULTIPLY BY 0x0D
    // =========================================================================

    function [7:0] mul0d;

        input [7:0] b;

        reg [7:0] x2;
        reg [7:0] x4;
        reg [7:0] x8;

        begin

            x2 = xtime(b);
            x4 = xtime(x2);
            x8 = xtime(x4);

            mul0d = x8 ^ x4 ^ b;

        end

    endfunction


    // =========================================================================
    // MULTIPLY BY 0x0E
    // =========================================================================

    function [7:0] mul0e;

        input [7:0] b;

        reg [7:0] x2;
        reg [7:0] x4;
        reg [7:0] x8;

        begin

            x2 = xtime(b);
            x4 = xtime(x2);
            x8 = xtime(x4);

            mul0e = x8 ^ x4 ^ x2;

        end

    endfunction


    // =========================================================================
    // INV MIX COLUMNS
    //
    // Each AES column consists of:
    //
    //   [state[row0][col]]
    //   [state[row1][col]]
    //   [state[row2][col]]
    //   [state[row3][col]]
    //
    // In our flat representation:
    //
    // Column 0 = s[0], s[4], s[8],  s[12]
    // Column 1 = s[1], s[5], s[9],  s[13]
    // Column 2 = s[2], s[6], s[10], s[14]
    // Column 3 = s[3], s[7], s[11], s[15]
    //
    // =========================================================================

    function [31:0] inv_mix_col;

        input [7:0] a0;
        input [7:0] a1;
        input [7:0] a2;
        input [7:0] a3;

        reg [7:0] t0;
        reg [7:0] t1;
        reg [7:0] t2;
        reg [7:0] t3;

        begin

            t0 =
                mul0e(a0) ^
                mul0b(a1) ^
                mul0d(a2) ^
                mul09(a3);

            t1 =
                mul09(a0) ^
                mul0e(a1) ^
                mul0b(a2) ^
                mul0d(a3);

            t2 =
                mul0d(a0) ^
                mul09(a1) ^
                mul0e(a2) ^
                mul0b(a3);

            t3 =
                mul0b(a0) ^
                mul0d(a1) ^
                mul09(a2) ^
                mul0e(a3);

            inv_mix_col = {t0,t1,t2,t3};

        end

    endfunction


    // =========================================================================
    // INV MIX COLUMNS
    // =========================================================================

    wire [31:0] imc_col0;
    wire [31:0] imc_col1;
    wire [31:0] imc_col2;
    wire [31:0] imc_col3;

    assign imc_col0 =
        inv_mix_col(
            ark[0],
            ark[4],
            ark[8],
            ark[12]
        );

    assign imc_col1 =
        inv_mix_col(
            ark[1],
            ark[5],
            ark[9],
            ark[13]
        );

    assign imc_col2 =
        inv_mix_col(
            ark[2],
            ark[6],
            ark[10],
            ark[14]
        );

    assign imc_col3 =
        inv_mix_col(
            ark[3],
            ark[7],
            ark[11],
            ark[15]
        );


    // =========================================================================
    // REBUILD STATE
    // =========================================================================

    wire [7:0] imc [0:15];

    assign imc[0]  = imc_col0[31:24];
    assign imc[4]  = imc_col0[23:16];
    assign imc[8]  = imc_col0[15:8];
    assign imc[12] = imc_col0[7:0];

    assign imc[1]  = imc_col1[31:24];
    assign imc[5]  = imc_col1[23:16];
    assign imc[9]  = imc_col1[15:8];
    assign imc[13] = imc_col1[7:0];

    assign imc[2]  = imc_col2[31:24];
    assign imc[6]  = imc_col2[23:16];
    assign imc[10] = imc_col2[15:8];
    assign imc[14] = imc_col2[7:0];

    assign imc[3]  = imc_col3[31:24];
    assign imc[7]  = imc_col3[23:16];
    assign imc[11] = imc_col3[15:8];
    assign imc[15] = imc_col3[7:0];


    // =========================================================================
    // FINAL ROUND DETECTION
    // =========================================================================

    wire is_final_round;

    assign is_final_round =
        (round_cnt == 4'd0);


    // =========================================================================
    // NEXT STATE
    //
    // Round 13..1:
    //     InvShiftRows
    //     InvSubBytes
    //     AddRoundKey
    //     InvMixColumns
    //
    // Round 0:
    //     InvShiftRows
    //     InvSubBytes
    //     AddRoundKey
    //
    // =========================================================================

    wire [7:0] next_s [0:15];

    genvar k;

    generate

        for (k = 0; k < 16; k = k + 1) begin : GEN_NEXT

            assign next_s[k] =
                is_final_round ?
                ark[k] :
                imc[k];

        end

    endgenerate


    // =========================================================================
    // INPUT REGISTER
    // =========================================================================

    reg [127:0] text_in_r;


    // =========================================================================
    // FSM
    // =========================================================================

    integer idx;

    always @(posedge clk) begin

        // =====================================================================
        // RESET
        // =====================================================================

        if (!rst_n) begin

            state     <= ST_IDLE;

            round_cnt <= 4'd14;

            busy      <= 1'b0;
            done      <= 1'b0;
            kld       <= 1'b0;

            text_out  <= 128'h00000000000000000000000000000000;

            text_in_r <= 128'h00000000000000000000000000000000;

            for (idx = 0; idx < 16; idx = idx + 1)
                s[idx] <= 8'h00;

        end

        else begin

            // Default values

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

                        state <= ST_KEY_EXP;

                    end

                end


                // =============================================================
                // KEY EXPANSION
                // =============================================================

                ST_KEY_EXP: begin

                    if (key_ready) begin

                        // =====================================================
                        // INITIAL ADD ROUND KEY
                        //
                        // Ciphertext XOR Round Key 14
                        // =====================================================

                        s[0]  <= text_in_r[127:120] ^ rk[14][127:120];
                        s[4]  <= text_in_r[119:112] ^ rk[14][119:112];
                        s[8]  <= text_in_r[111:104] ^ rk[14][111:104];
                        s[12] <= text_in_r[103:96]  ^ rk[14][103:96];

                        s[1]  <= text_in_r[95:88] ^ rk[14][95:88];
                        s[5]  <= text_in_r[87:80] ^ rk[14][87:80];
                        s[9]  <= text_in_r[79:72] ^ rk[14][79:72];
                        s[13] <= text_in_r[71:64] ^ rk[14][71:64];

                        s[2]  <= text_in_r[63:56] ^ rk[14][63:56];
                        s[6]  <= text_in_r[55:48] ^ rk[14][55:48];
                        s[10] <= text_in_r[47:40] ^ rk[14][47:40];
                        s[14] <= text_in_r[39:32] ^ rk[14][39:32];

                        s[3]  <= text_in_r[31:24] ^ rk[14][31:24];
                        s[7]  <= text_in_r[23:16] ^ rk[14][23:16];
                        s[11] <= text_in_r[15:8] ^ rk[14][15:8];
                        s[15] <= text_in_r[7:0] ^ rk[14][7:0];


                        // Start round 13

                        round_cnt <= 4'd13;

                        state <= ST_ROUND;

                    end

                end


                // =============================================================
                // DECRYPTION ROUNDS
                // =============================================================

                ST_ROUND: begin

                    // Register calculated next state

                    for (idx = 0; idx < 16; idx = idx + 1)
                        s[idx] <= next_s[idx];


                    // =========================================================
                    // FINAL ROUND
                    // =========================================================

                    if (round_cnt == 4'd0) begin

                        // Convert internal state back to external AES format.
                        //
                        // This is the SAME output mapping used by the
                        // working encryption core.

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


                        done <= 1'b1;

                        busy <= 1'b0;

                        state <= ST_DONE;

                    end

                    // =========================================================
                    // NORMAL ROUND
                    // =========================================================

                    else begin

                        round_cnt <= round_cnt - 4'd1;

                    end

                end


                // =============================================================
                // DONE
                // =============================================================

                ST_DONE: begin

                    // Allow another transaction without reset

                    if (start) begin

                        text_in_r <= text_in;

                        kld <= 1'b1;

                        busy <= 1'b1;

                        state <= ST_KEY_EXP;

                    end

                end


                // =============================================================
                // DEFAULT
                // =============================================================

                default: begin

                    state <= ST_IDLE;

                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule
