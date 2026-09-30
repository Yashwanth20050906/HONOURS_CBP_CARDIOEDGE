
module rr_classifier #(parameter int FS=360)(
    input logic clk, rst_n, sample_valid, peak_in,
    output logic [15:0] rr, bpm,
    output logic [1:0] rhythm,
    output logic result_valid
);
    logic [31:0] count, prev_peak, rr_now;
    logic first_peak;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            count<='0; prev_peak<='0; rr<='0; bpm<='0;
            rhythm<=2'b00; result_valid<=1'b0; first_peak<=1'b0;
        end else begin
            result_valid<=1'b0;
            if(sample_valid) count<=count+1'b1;
            if(peak_in) begin
                if(!first_peak) begin prev_peak<=count; first_peak<=1'b1; end
                else begin
                    rr_now = count-prev_peak;
                    prev_peak<=count;
                    rr<=rr_now[15:0];
                    if(rr_now>FS) rhythm<=2'b01;
                    else if(rr_now<((60*FS)/100)) rhythm<=2'b10;
                    else rhythm<=2'b00;
                    if(rr_now!=0) bpm<=(60*FS)/rr_now;
                    result_valid<=1'b1;
                end
            end
        end
    end
endmodule
