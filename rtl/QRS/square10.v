
// square10.v  -- 10x10 -> 20-bit squarer with operand isolation.
// ISOLATE=0 here (V2); becomes ISOLATE=1 in V3.
module square10 #(parameter ISOLATE=0)(
    input  wire        clk, rst_n, in_valid,
    input  wire [9:0]  data_in,
    output reg  [19:0] data_out,
    output reg         out_valid
);
    wire [9:0] op = (ISOLATE && !in_valid) ? 10'd0 : data_in;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin data_out<=20'd0; out_valid<=1'b0; end
        else begin
            out_valid <= in_valid;
            if (in_valid) data_out <= op * op;
        end
    end
endmodule
