
// pow2_normalizer.v  -- Bit-width optimization: replaces live divider with
// leading-one barrel shift.  IN_W input, OUT_W output. No divider cell.
module pow2_normalizer #(parameter IN_W=17, OUT_W=12)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire signed [IN_W-1:0] data_in,
    input  wire              in_valid,
    output reg  [OUT_W-1:0]  data_out,
    output reg               out_valid
);
    reg [IN_W-1:0] mag;
    integer        msb_pos, i;
    always @(*) begin
        mag = data_in[IN_W-1] ? (~data_in + 1) : data_in;
        msb_pos = 0;
        for (i = 0; i < IN_W; i = i+1)
            if (mag[i]) msb_pos = i;
    end
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin data_out <= 0; out_valid <= 1'b0; end
        else begin
            out_valid <= in_valid;
            if (in_valid) begin
                if (mag == 0)
                    data_out <= 0;
                else if (msb_pos >= OUT_W-1)
                    data_out <= mag >> (msb_pos - (OUT_W-1));
                else
                    data_out <= mag << ((OUT_W-1) - msb_pos);
            end
        end
    end
endmodule
