// =============================================================
// search_back.v
// Debug version
//
// Original search-back algorithm preserved.
// Additional $display statements are included ONLY to trace:
//   1. Genuine Schmitt peaks
//   2. Search-back activation
//   3. Forced peaks
//   4. RR timing information
//
// Use this version for standalone QRS verification.
// =============================================================

module search_back #(
    parameter DATA_W      = 26,
    parameter MIN_DIST    = 90,
    parameter MAX_RR      = 1080,
    parameter RR_AVG_BITS = 16
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              in_valid,
    input  wire              schmitt_peak,
    input  wire [DATA_W-1:0] pee_value,
    output reg               r_peak
);

    reg [RR_AVG_BITS-1:0] last_rr;
    reg [31:0]            since_peak;
    reg                   first_peak;

    // 1.5 × last RR
    wire [RR_AVG_BITS:0] miss_thr =
        last_rr + (last_rr >> 1);

    // Search-back scanner
    reg              sb_active;
    reg [DATA_W-1:0] sb_max;
    reg [31:0]       sb_timer;


    // =========================================================
    // Main logic
    // =========================================================
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            last_rr    <= MIN_DIST;
            since_peak <= 0;
            first_peak <= 1'b0;
            r_peak     <= 1'b0;

            sb_active  <= 1'b0;
            sb_max     <= {DATA_W{1'b0}};
            sb_timer   <= 0;

        end else begin

            // Default
            r_peak <= 1'b0;


            if (in_valid) begin

                // Count samples since previous peak
                since_peak <= since_peak + 1;


                // =================================================
                // SCHMITT PEAK
                // =================================================
                if (schmitt_peak) begin

                    $display(
                        "[SEARCH_BACK] SCHMITT PEAK : time=%0t | since_peak=%0d | last_rr=%0d | miss_thr=%0d",
                        $time,
                        since_peak,
                        last_rr,
                        miss_thr
                    );

                    r_peak <= 1'b1;


                    // Update RR after first confirmed peak
                    if (first_peak) begin

                        last_rr <=
                            (since_peak > {RR_AVG_BITS{1'b1}})
                            ? {RR_AVG_BITS{1'b1}}
                            : since_peak[RR_AVG_BITS-1:0];

                        $display(
                            "[SEARCH_BACK] RR UPDATED : new_last_rr=%0d",
                            since_peak
                        );

                    end


                    first_peak <= 1'b1;

                    // Reset sample counter
                    since_peak <= 0;

                    // Cancel search-back
                    sb_active <= 1'b0;

                    $display(
                        "[SEARCH_BACK] CONFIRMED PEAK -> r_peak=1"
                    );

                end


                // =================================================
                // AFTER FIRST PEAK
                // =================================================
                else if (first_peak) begin


                    // =================================================
                    // START SEARCH-BACK
                    // =================================================
                    if (!sb_active && since_peak > miss_thr) begin

                        $display(
                            "[SEARCH_BACK] STARTED : time=%0t | since_peak=%0d | miss_thr=%0d | last_rr=%0d | pee=%0d",
                            $time,
                            since_peak,
                            miss_thr,
                            last_rr,
                            pee_value
                        );

                        sb_active <= 1'b1;

                        sb_max <= pee_value;

                        sb_timer <= last_rr;

                    end


                    // =================================================
                    // SEARCH-BACK ACTIVE
                    // =================================================
                    else if (sb_active) begin

                        // Track maximum PEE
                        if (pee_value > sb_max) begin

                            sb_max <= pee_value;

                            $display(
                                "[SEARCH_BACK] NEW MAX : time=%0t | pee=%0d",
                                $time,
                                pee_value
                            );

                        end


                        // Countdown
                        if (sb_timer > 0) begin

                            sb_timer <= sb_timer - 1;

                        end


                        // =================================================
                        // FORCED PEAK
                        // =================================================
                        else begin

                            $display(
                                "[SEARCH_BACK] FORCED PEAK : time=%0t | since_peak=%0d | sb_max=%0d",
                                $time,
                                since_peak,
                                sb_max
                            );

                            r_peak <= 1'b1;

                            since_peak <= 0;

                            sb_active <= 1'b0;

                        end

                    end


                    // =================================================
                    // SAFETY TIMEOUT
                    // =================================================
                    if (since_peak >= MAX_RR) begin

                        $display(
                            "[SEARCH_BACK] MAX_RR TIMEOUT : time=%0t | since_peak=%0d",
                            $time,
                            since_peak
                        );

                        since_peak <= 0;

                        sb_active <= 1'b0;

                    end

                end

            end

        end

    end

endmodule
