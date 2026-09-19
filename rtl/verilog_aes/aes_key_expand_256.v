// =============================================================================
// aes_key_expand_256.v
// AES-256 Key Expansion
//
// Parameters:
//   Nk = 8    (key words)
//   Nb = 4    (state words)
//   Nr = 14   (rounds)
//
// Generates 60 32-bit words W[0]..W[59] (15 round keys × 4 words each).
//
// AES-256 Key Expansion Rules (FIPS-197, Section 5.2):
//   W[i] = W[i-Nk] XOR temp
//   where:
//     if (i mod Nk == 0):       temp = SubWord(RotWord(W[i-1])) XOR Rcon[i/Nk]
//     elif (i mod Nk == 4):     temp = SubWord(W[i-1])
//     else:                     temp = W[i-1]
//
// Interface:
//   clk     : clock
//   rst_n   : synchronous active-low reset
//   kld     : key load (start key expansion)
//   key     : 256-bit key input {K[255:224], ..., K[31:0]}
//             = {W[0], W[1], W[2], W[3], W[4], W[5], W[6], W[7]}
//
// Output: 15 × 128-bit round keys as:
//   rk0  = {W[0],  W[1],  W[2],  W[3] }  (Round 0)
//   rk1  = {W[4],  W[5],  W[6],  W[7] }  (Round 1)
//   ...
//   rk14 = {W[56], W[57], W[58], W[59]}  (Round 14)
//
// The module computes round keys sequentially at 2 words per clock
// (to match the Nk=8 structure). A 'done' signal asserts when all
// 60 words are ready.
//
// Design notes:
//   - Two new words are computed per clock (W[i] and W[i+1]).
//   - Rcon advances on i%8==0 hits (every 4 clock cycles).
//   - All 60 words stored in a register array for random access by cipher.
// =============================================================================

module aes_key_expand_256 (
    input              clk,
    input              rst_n,
    input              kld,       // Pulse high to start key expansion
    input  [255:0]     key,       // 256-bit key: key[255:224]=W[0] ... key[31:0]=W[7]
    output             key_ready, // High once all 60 words are expanded
    output [127:0]     rk0,
    output [127:0]     rk1,
    output [127:0]     rk2,
    output [127:0]     rk3,
    output [127:0]     rk4,
    output [127:0]     rk5,
    output [127:0]     rk6,
    output [127:0]     rk7,
    output [127:0]     rk8,
    output [127:0]     rk9,
    output [127:0]     rk10,
    output [127:0]     rk11,
    output [127:0]     rk12,
    output [127:0]     rk13,
    output [127:0]     rk14
);

    // -------------------------------------------------------------------------
    // Round key word storage: W[0..59]
    // W[0]=key[255:224], W[1]=key[223:192], ..., W[7]=key[31:0]
    // -------------------------------------------------------------------------
    reg [31:0] W [0:59];

    // -------------------------------------------------------------------------
    // SubWord: apply S-box to all 4 bytes of a word
    // -------------------------------------------------------------------------
    // We use combinational subword using the aes_sbox module for each byte.
    // During expansion we mux between two possible SubWord candidates.
    // -------------------------------------------------------------------------

    // SubWord wires for RotWord path (i%8==0): RotWord(W[i-1]) then SubWord
    wire [31:0] rot_w_prev;   // RotWord of w_prev (the word being processed)
    wire [31:0] sub_rot;      // SubWord(RotWord(w_prev))

    // SubWord wires for plain SubWord path (i%8==4): SubWord(W[i-1])
    wire [31:0] sub_plain;    // SubWord(w_prev)

    // Expansion state
    reg [5:0]  word_idx;      // Index of next word to generate (8..59)
    reg        expanding;     // High while key expansion is in progress
    reg        key_ready_r;

    // Current W[i-1] during expansion
    // We expand one word per clock, so we need W[word_idx-1]
    wire [31:0] w_prev = W[word_idx - 1];
    wire [31:0] w_prev8 = W[word_idx - 8];

    // RotWord: {w[23:16], w[15:8], w[7:0], w[31:24]}
    assign rot_w_prev = {w_prev[23:16], w_prev[15:8], w_prev[7:0], w_prev[31:24]};

    // Instantiate S-boxes for SubWord(RotWord(w_prev))
    wire [7:0] sub_rot_b3, sub_rot_b2, sub_rot_b1, sub_rot_b0;
    aes_sbox u_sr3 (.a(rot_w_prev[31:24]), .d(sub_rot_b3));
    aes_sbox u_sr2 (.a(rot_w_prev[23:16]), .d(sub_rot_b2));
    aes_sbox u_sr1 (.a(rot_w_prev[15:8]),  .d(sub_rot_b1));
    aes_sbox u_sr0 (.a(rot_w_prev[7:0]),   .d(sub_rot_b0));
    assign sub_rot = {sub_rot_b3, sub_rot_b2, sub_rot_b1, sub_rot_b0};

    // Instantiate S-boxes for SubWord(w_prev) (plain, no rotation)
    wire [7:0] sub_plain_b3, sub_plain_b2, sub_plain_b1, sub_plain_b0;
    aes_sbox u_sp3 (.a(w_prev[31:24]), .d(sub_plain_b3));
    aes_sbox u_sp2 (.a(w_prev[23:16]), .d(sub_plain_b2));
    aes_sbox u_sp1 (.a(w_prev[15:8]),  .d(sub_plain_b1));
    aes_sbox u_sp0 (.a(w_prev[7:0]),   .d(sub_plain_b0));
    assign sub_plain = {sub_plain_b3, sub_plain_b2, sub_plain_b1, sub_plain_b0};

    // Rcon: for AES-256, Rcon is used when word_idx % 8 == 0
    // We need Rcon[word_idx/8]
    // Rcon values (byte only, rest are 0):
    //   i=8  -> Rcon[1] = 01
    //   i=16 -> Rcon[2] = 02
    //   i=24 -> Rcon[3] = 04
    //   i=32 -> Rcon[4] = 08
    //   i=40 -> Rcon[5] = 10
    //   i=48 -> Rcon[6] = 20
    //   i=56 -> Rcon[7] = 40
    // We compute Rcon from word_idx directly using a LUT
    reg [31:0] rcon_val;
    always @(*) begin
        case (word_idx[5:3])  // word_idx / 8
            3'd1: rcon_val = 32'h01000000;
            3'd2: rcon_val = 32'h02000000;
            3'd3: rcon_val = 32'h04000000;
            3'd4: rcon_val = 32'h08000000;
            3'd5: rcon_val = 32'h10000000;
            3'd6: rcon_val = 32'h20000000;
            3'd7: rcon_val = 32'h40000000;
            default: rcon_val = 32'h00000000;
        endcase
    end

    // Compute temp for current word_idx
    wire [31:0] temp;
    wire        is_mod8_eq0 = (word_idx[2:0] == 3'd0);  // word_idx % 8 == 0
    wire        is_mod8_eq4 = (word_idx[2:0] == 3'd4);  // word_idx % 8 == 4

    assign temp = is_mod8_eq0 ? (sub_rot ^ rcon_val) :
                  is_mod8_eq4 ? sub_plain :
                                w_prev;

    // New word value
    wire [31:0] new_word = w_prev8 ^ temp;

    // -------------------------------------------------------------------------
    // Key expansion state machine
    // -------------------------------------------------------------------------
    integer idx;

    always @(posedge clk) begin
        if (!rst_n) begin
            expanding   <= 1'b0;
            key_ready_r <= 1'b0;
            word_idx    <= 6'd8;
            // Clear all words
            for (idx = 0; idx < 60; idx = idx + 1)
                W[idx] <= 32'h0;
        end
        else if (kld) begin
            // Load initial 8 words from key input
            // key[255:224] = W[0], key[223:192] = W[1], ...
            W[0] <= key[255:224];
            W[1] <= key[223:192];
            W[2] <= key[191:160];
            W[3] <= key[159:128];
            W[4] <= key[127:96];
            W[5] <= key[95:64];
            W[6] <= key[63:32];
            W[7] <= key[31:0];
            word_idx    <= 6'd8;
            expanding   <= 1'b1;
            key_ready_r <= 1'b0;
        end
        else if (expanding) begin
            // Generate one word per clock
            W[word_idx] <= new_word;

            if (word_idx == 6'd59) begin
                expanding   <= 1'b0;
                key_ready_r <= 1'b1;
                word_idx    <= 6'd8;
            end
            else begin
                word_idx <= word_idx + 6'd1;
            end
        end
    end

    assign key_ready = key_ready_r;

    // -------------------------------------------------------------------------
    // Round key outputs
    // RK[n] = {W[4n], W[4n+1], W[4n+2], W[4n+3]}
    // -------------------------------------------------------------------------
    assign rk0  = {W[0],  W[1],  W[2],  W[3] };
    assign rk1  = {W[4],  W[5],  W[6],  W[7] };
    assign rk2  = {W[8],  W[9],  W[10], W[11]};
    assign rk3  = {W[12], W[13], W[14], W[15]};
    assign rk4  = {W[16], W[17], W[18], W[19]};
    assign rk5  = {W[20], W[21], W[22], W[23]};
    assign rk6  = {W[24], W[25], W[26], W[27]};
    assign rk7  = {W[28], W[29], W[30], W[31]};
    assign rk8  = {W[32], W[33], W[34], W[35]};
    assign rk9  = {W[36], W[37], W[38], W[39]};
    assign rk10 = {W[40], W[41], W[42], W[43]};
    assign rk11 = {W[44], W[45], W[46], W[47]};
    assign rk12 = {W[48], W[49], W[50], W[51]};
    assign rk13 = {W[52], W[53], W[54], W[55]};
    assign rk14 = {W[56], W[57], W[58], W[59]};

endmodule
