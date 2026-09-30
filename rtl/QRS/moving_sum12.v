
// moving_sum12.v  -- 12-bit input, 18-bit accumulator (saves 6-bit width vs V0).
module moving_sum12 #(parameter N=33)(
    input  wire        clk, rst_n, in_valid,
    input  wire [11:0] data_in,
    output reg  [17:0] sum_out,
    output reg         out_valid
);
    reg [11:0] mem [0:N-1];
    integer    ptr, i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<N;i=i+1) mem[i]<=12'd0;
            ptr<=0; sum_out<=18'd0; out_valid<=1'b0;
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
