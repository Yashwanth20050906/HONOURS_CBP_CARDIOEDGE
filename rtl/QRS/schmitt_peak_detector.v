// =============================================================
// schmitt_peak_detector.v
// DEBUG VERSION
//
// Original detector logic preserved.
// Debug messages added only for simulation.
//
// Original interface:
//   clk
//   rst_n
//   data_in
//   in_valid
//   peak_out
//
// Original parameters preserved:
//   DATA_W
//   MIN_DIST
//   HIST_LEN
//   INIT_W
// =============================================================
module schmitt_peak_detector #(
    parameter DATA_W   = 26,
    parameter MIN_DIST = 90,
    parameter HIST_LEN = 8,
    parameter INIT_W   = 20
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire [DATA_W-1:0] data_in,
    input  wire              in_valid,
    output reg               peak_out
);

    // ─── history buffer ───────────────────────────────────────
    reg [DATA_W-1:0] hist [0:HIST_LEN-1];
    reg [2:0]        hist_ptr;

    // ─── adaptive thresholds ─────────────────────────────────
    reg [DATA_W-1:0] min_peak;
    reg [DATA_W-1:0] th1, th2;

    integer k;

    always @(*) begin
        min_peak = hist[0];

        for (k = 1; k < HIST_LEN; k = k+1)
            if (hist[k] < min_peak)
                min_peak = hist[k];

        th1 = min_peak - (min_peak >> 2);  // 3/4
        th2 = min_peak >> 1;               // 1/2
    end

    // ─── Schmitt state machine ────────────────────────────────
    reg              qrs_state;
    reg [DATA_W-1:0] win_max;
    reg              win_valid;
    reg [31:0]       refractory;

    integer i;

    // Debug counter
    integer debug_count;


    // =========================================================
    // Main detector
    // =========================================================
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            qrs_state  <= 1'b0;
            win_max    <= {DATA_W{1'b0}};
            win_valid  <= 1'b0;
            refractory <= 32'd0;
            peak_out   <= 1'b0;
            hist_ptr   <= 3'd0;

            debug_count <= 0;

            for (i = 0; i < HIST_LEN; i = i+1)
                hist[i] <=
                    {{(DATA_W-INIT_W){1'b0}},
                     {INIT_W{1'b1}}};

        end else begin

            peak_out <= 1'b0;

            if (refractory > 0)
                refractory <= refractory - 1;


            if (in_valid) begin

                debug_count = debug_count + 1;


                // =================================================
                // PERIODIC DEBUG OUTPUT
                // Print every 100 valid samples
                // =================================================
                if ((debug_count % 100) == 0) begin

                    $display(
                        "[SCHMITT DEBUG] time=%0t | sample=%0d | data_in=%0d | min_peak=%0d | th1=%0d | th2=%0d | state=%0d | refractory=%0d | win_max=%0d",
                        $time,
                        debug_count,
                        data_in,
                        min_peak,
                        th1,
                        th2,
                        qrs_state,
                        refractory,
                        win_max
                    );

                end


                // =================================================
                // WAITING FOR TH1
                // =================================================
                if (!qrs_state) begin

                    if (data_in >= th1 && refractory == 0) begin

                        $display(
                            "[SCHMITT DEBUG] HIGH THRESHOLD CROSSED: time=%0t | sample=%0d | data_in=%0d | th1=%0d",
                            $time,
                            debug_count,
                            data_in,
                            th1
                        );

                        qrs_state <= 1'b1;

                        win_max <= data_in;

                        win_valid <= 1'b1;

                    end

                end


                // =================================================
                // QRS WINDOW ACTIVE
                // =================================================
                else begin

                    // -------------------------------------------------
                    // Falling threshold crossed
                    // -------------------------------------------------
                    if (data_in <= th2) begin

                        $display(
                            "[SCHMITT DEBUG] LOW THRESHOLD CROSSED: time=%0t | sample=%0d | data_in=%0d | th2=%0d | win_max=%0d",
                            $time,
                            debug_count,
                            data_in,
                            th2,
                            win_max
                        );

                        qrs_state <= 1'b0;


                        if (win_valid) begin

                            // -----------------------------------------
                            // PEAK GENERATED
                            // -----------------------------------------
                            peak_out <= 1'b1;

                            refractory <= MIN_DIST;

                            hist[hist_ptr] <= win_max;

                            $display(
                                "[SCHMITT DEBUG] *** PEAK GENERATED *** time=%0t | sample=%0d | PEAK=%0d | hist_ptr=%0d | refractory=%0d",
                                $time,
                                debug_count,
                                win_max,
                                hist_ptr,
                                MIN_DIST
                            );


                            hist_ptr <=
                                (hist_ptr == HIST_LEN-1)
                                ? 3'd0
                                : hist_ptr + 1'b1;

                        end

                        win_valid <= 1'b0;

                    end


                    // -------------------------------------------------
                    // Still inside QRS window
                    // -------------------------------------------------
                    else begin

                        if (data_in > win_max) begin

                            win_max <= data_in;

                        end

                    end

                end

            end

        end

    end

endmodule
