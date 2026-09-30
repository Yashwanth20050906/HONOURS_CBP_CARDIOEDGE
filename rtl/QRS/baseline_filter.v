
module baseline_filter(
    input logic clk, rst_n, in_valid,
    input logic signed [15:0] sample_in,
    output logic signed [15:0] sample_out,
    output logic out_valid
);
    logic signed [15:0] x1,x2;
    logic signed [17:0] y;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin x1<='0; x2<='0; sample_out<='0; out_valid<=1'b0; end
        else begin
            out_valid<=in_valid;
            if(in_valid) begin
                // lightweight causal smoothing/high-frequency suppression baseline
                y = $signed(sample_in) + ($signed(x1)<<<1) + $signed(x2);
                sample_out <= y >>> 2;
                x2<=x1; x1<=sample_in;
            end
        end
    end
endmodule
