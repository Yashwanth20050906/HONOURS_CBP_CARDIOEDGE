
// moving_sum20.v  -- 20-bit input, 26-bit accumulator.
module moving_sum20 #(parameter N=43)(
    input  wire        clk, rst_n, in_valid,
    input  wire [19:0] data_in,
    output reg  [25:0] sum_out,
    output reg         out_valid
);
    reg [19:0] mem [0:N-1];
    integer    ptr, i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<N;i=i+1) mem[i]<=20'd0;
            ptr<=0; sum_out<=26'd0; out_valid<=1'b0;
        end else begin
            out_valid <= in_valid;
            if (in_valid) begin
                sum_out <= sum_out + {6'd0,data_in} - {6'd0,mem[ptr]};
                mem[ptr]<= data_in;
                ptr     <= (ptr==N-1)?0:ptr+1;
            end
        end
    end
endmodule
