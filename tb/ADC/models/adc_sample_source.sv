`default_nettype none
module adc_sample_source #(
  parameter integer ADC_RESOLUTION = 12
)(
  input logic clk,
  input logic rst_n,
  output logic [ADC_RESOLUTION-1:0] sample_out,
  output logic sample_valid
);
  initial begin
    sample_out = '0;
    sample_valid = 1'b0;
  end

  task automatic drive_sample(input logic [ADC_RESOLUTION-1:0] value);
    @(negedge clk);
    sample_out  <= value;
    sample_valid <= 1'b1;
    @(negedge clk);
    sample_valid <= 1'b0;
    sample_out <= '0;
  endtask

  task automatic drive_sample_hold(
    input logic [ADC_RESOLUTION-1:0] value,
    input integer cycles
  );
    @(negedge clk);
    sample_out <= value;
    sample_valid <= 1'b1;
    repeat (cycles) @(negedge clk);
    sample_valid <= 1'b0;
    sample_out <= '0;
  endtask

  task automatic idle();
    @(negedge clk);
    sample_valid <= 1'b0;
    sample_out <= '0;
  endtask
endmodule
`default_nettype wire
