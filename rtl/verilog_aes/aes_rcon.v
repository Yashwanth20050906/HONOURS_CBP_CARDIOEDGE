// =============================================================================
// aes_rcon.v
// AES Round Constants (Rcon) for Key Expansion
//
// For AES-256, key expansion uses Rcon values for i = 1 to 7 (since
// i%8==0 condition fires 7 times for 60 words: i=8,16,24,32,40,48,56).
// Rcon[i] = [x^(i-1), 0, 0, 0] where x^k is computed in GF(2^8).
//
// Rcon values (FIPS-197, Section 5.2):
//   Rcon[1]  = 01 00 00 00
//   Rcon[2]  = 02 00 00 00
//   Rcon[3]  = 04 00 00 00
//   Rcon[4]  = 08 00 00 00
//   Rcon[5]  = 10 00 00 00
//   Rcon[6]  = 20 00 00 00
//   Rcon[7]  = 40 00 00 00
//
// This module provides a registered, sequential Rcon value.
// It resets on kld (key-load) and advances each clock.
// The output 'out' is the full 32-bit Rcon word.
// =============================================================================

module aes_rcon (
    input        clk,
    input        kld,    // key load (synchronous reset to Rcon[1])
    output [31:0] out
);

    // Rcon counter: tracks which Rcon value to output
    // Indexed 1..7 for AES-256 (only 7 SubWord+Rcon operations)
    reg [7:0] rcon_byte;

    // Advance rcon_byte: xtime each clock step
    // xtime(b) = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}})
    function [7:0] xtime;
        input [7:0] b;
        xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
    endfunction

    always @(posedge clk) begin
        if (kld)
            rcon_byte <= 8'h01;  // Rcon[1] = 01
        else
            rcon_byte <= xtime(rcon_byte);
    end

    // Full Rcon word: [rcon_byte, 24'h000000]
    assign out = {rcon_byte, 24'h000000};

endmodule
