
module first_difference #(parameter int W=16)(
    input  logic clk, rst_n, in_valid,
    input  logic signed [W-1:0] data_in,
    output logic signed [W:0] data_out,
    output logic out_valid
);
    logic signed [W-1:0] prev;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin prev<='0; data_out<='0; out_valid<=1'b0; end
        else begin
            out_valid <= in_valid;
            if(in_valid) begin
                data_out <= $signed(data_in)-$signed(prev);
                prev <= data_in;
            end
        end
    end
endmodule
