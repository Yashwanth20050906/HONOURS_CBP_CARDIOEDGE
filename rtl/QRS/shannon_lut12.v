module shannon_lut12 (

    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,

    input  wire [11:0] data_in,

    output reg  [11:0] data_out,
    output reg         out_valid

);


    //============================================================
    // LUT MEMORY
    //============================================================

    reg [11:0] lut [0:4095];

    integer ii;


    //============================================================
    // LUT GENERATION
    //
    // Shannon energy:
    //
    // E = -x * ln(x)
    //
    // x = ii / 4096
    //
    // Output scaled to 12 bits.
    //============================================================

    initial begin

        lut[0] = 12'd0;

        for (ii = 1; ii < 4096; ii = ii + 1) begin

            lut[ii] = $rtoi(
                (
                    -((ii * 1.0) / 4096.0)
                    *
                    $ln((ii * 1.0) / 4096.0)
                )
                * 4095.0
            );

        end

    end


    //============================================================
    // SYNCHRONOUS LUT OUTPUT
    //============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            data_out  <= 12'd0;
            out_valid <= 1'b0;

        end
        else begin

            out_valid <= in_valid;

            if (in_valid) begin

                data_out <= lut[data_in];

            end

        end

    end


endmodule
