
// icg_generic.v  -- Generic ICG placeholder.
// In real synthesis map this cell to the library ICG primitive.
// en is sampled on the falling edge of clk (latch-based ICG behaviour).
module icg_generic(
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    output wire gclk
);
    reg en_latch;
    always @(clk or en or rst_n)
        if (!clk) en_latch <= rst_n & en;
    assign gclk = clk & en_latch;
endmodule
