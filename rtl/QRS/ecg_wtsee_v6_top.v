// =============================================================
// WTSEE V6 - Functional Verification Version
//
// V6 processing pipeline:
//   1. Schmitt trigger + search-back detection
//   2. 12-bit intermediates
//   3. 10-bit squarer
//   4. Operand isolation
//   5. Pipeline cuts
//
// NOTE:
// The RR/search-back clock is kept on the main clock for
// functional verification. The original RR clock gating
// prevents the RR classifier from counting every PEE sample.
// =============================================================

module ecg_wtsee_v6_top #(parameter FS=360)(
    input  wire clk,
    input  wire rst_n,

    input  wire signed [15:0] ecg_in,
    input  wire ecg_valid,

    output wire r_peak,
    output wire [15:0] rr_interval,
    output wire [15:0] bpm,
    output wire [1:0] rhythm_class,
    output wire result_valid
);

    // =========================================================
    // Pipeline valid signals
    // =========================================================

    wire v0;
    wire v1;
    wire v2;
    wire v3;
    wire v4;
    wire v5;
    wire v6;
    wire v7;
    wire v8;


    // =========================================================
    // Pipeline data
    // =========================================================

    wire signed [15:0] f0;
    wire signed [16:0] d1;

    wire [11:0] n1;
    wire [11:0] se;

    // Keep original V6 width here.
    // moving_sum12 internally produces 18 bits.
    wire [11:0] see_sum;

    wire signed [12:0] dsee;
    wire [9:0] n2;

    wire [19:0] pe;
    wire [25:0] pee_sum;


    // =========================================================
    // Detection signal
    // =========================================================

    wire schmitt_peak;


    // =========================================================
    // Clock gating for input/core pipeline
    // =========================================================

    wire core_en;

    wire gclk_in;
    wire gclk_core;

    assign core_en =
          v0 |
          v1 |
          v2 |
          v3 |
          v4 |
          v5 |
          v6 |
          v7 |
          v8;


    icg_generic cg0(
        .clk  (clk),
        .rst_n(rst_n),
        .en   (ecg_valid),
        .gclk (gclk_in)
    );


    icg_generic cg1(
        .clk  (clk),
        .rst_n(rst_n),
        .en   (core_en),
        .gclk (gclk_core)
    );


    // =========================================================
    // WTSEE PIPELINE
    // =========================================================

    // Stage 0: baseline filtering

    baseline_filter u0(
        .clk       (gclk_in),
        .rst_n     (rst_n),
        .in_valid  (ecg_valid),
        .sample_in (ecg_in),
        .sample_out(f0),
        .out_valid (v0)
    );


    // Stage 1: first difference

    first_difference #(
        .W(16)
    ) u1(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v0),
        .data_in  (f0),
        .data_out (d1),
        .out_valid(v1)
    );


    // Stage 2: power-of-two normalization

    pow2_normalizer #(
        .IN_W (17),
        .OUT_W(12)
    ) u2(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v1),
        .data_in  (d1),
        .data_out (n1),
        .out_valid(v2)
    );


    // Stage 3: Shannon energy

    shannon_lut12 u3(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v2),
        .data_in  (n1),
        .data_out (se),
        .out_valid(v3)
    );


    // Stage 4: SEE moving sum

    moving_sum12 #(
        .N(33)
    ) u4(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v3),
        .data_in  (se),
        .sum_out  (see_sum),
        .out_valid(v4)
    );


    // =========================================================
    // Pipeline Cut 1
    // SEE window -> difference
    // =========================================================

    reg [11:0] see_pipe;
    reg        see_pv;


    always @(posedge gclk_core or negedge rst_n) begin

        if (!rst_n) begin

            see_pipe <= 12'd0;
            see_pv   <= 1'b0;

        end
        else begin

            see_pv <= v4;

            if (v4)
                see_pipe <= see_sum;

        end

    end


    // Stage 5: second difference

    first_difference #(
        .W(12)
    ) u5(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (see_pv),
        .data_in  (see_pipe),
        .data_out (dsee),
        .out_valid(v5)
    );


    // Stage 6: normalization

    pow2_normalizer #(
        .IN_W (13),
        .OUT_W(10)
    ) u6(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v5),
        .data_in  (dsee),
        .data_out (n2),
        .out_valid(v6)
    );


    // Stage 7: squaring

    square10 #(
        .ISOLATE(1)
    ) u7(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v6),
        .data_in  (n2),
        .data_out (pe),
        .out_valid(v7)
    );


    // Stage 8: PEE moving sum

    moving_sum20 #(
        .N(43)
    ) u8(
        .clk      (gclk_core),
        .rst_n    (rst_n),
        .in_valid (v7),
        .data_in  (pe),
        .sum_out  (pee_sum),
        .out_valid(v8)
    );


    // =========================================================
    // Pipeline Cut 2
    // PEE window -> detector
    // =========================================================

    reg [25:0] pee_pipe;
    reg        pee_pv;


    always @(posedge gclk_core or negedge rst_n) begin

        if (!rst_n) begin

            pee_pipe <= 26'd0;
            pee_pv   <= 1'b0;

        end
        else begin

            pee_pv <= v8;

            if (v8)
                pee_pipe <= pee_sum;

        end

    end


    // =========================================================
    // Schmitt Peak Detector
    // =========================================================

    schmitt_peak_detector #(
        .DATA_W  (26),
        .MIN_DIST(90)
    ) u_schmitt(

        .clk        (gclk_core),
        .rst_n      (rst_n),
        .data_in    (pee_pipe),
        .in_valid   (pee_pv),
        .peak_out   (schmitt_peak)

    );


    // =========================================================
    // Search Back
    //
    // IMPORTANT:
    // Use gclk_core here during functional verification.
    // search_back must see every PEE-valid sample.
    // =========================================================

    search_back #(
        .DATA_W  (26),
        .MIN_DIST(90)
    ) u_sb(

        .clk         (gclk_core),
        .rst_n       (rst_n),
        .in_valid    (pee_pv),
        .schmitt_peak(schmitt_peak),
        .pee_value   (pee_pipe),
        .r_peak      (r_peak)

    );


    // =========================================================
    // RR Classifier
    //
    // IMPORTANT:
    // It must count every valid PEE sample between peaks.
    // =========================================================

    rr_classifier #(
        .FS(FS)
    ) u10(

        .clk         (gclk_core),
        .rst_n       (rst_n),
        .sample_valid(pee_pv),
        .peak_in     (r_peak),
        .rr          (rr_interval),
        .bpm         (bpm),
        .rhythm      (rhythm_class),
        .result_valid(result_valid)

    );


endmodule
