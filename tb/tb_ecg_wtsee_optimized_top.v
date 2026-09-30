module tb_ecg_wtsee_optimized_top;

    //============================================================
    // DUT INTERFACE
    //============================================================

    reg clk;
    reg rst_n;

    reg signed [15:0] ecg_in;
    reg               ecg_valid;

    wire              r_peak;
    wire [15:0]       rr_interval;
    wire [15:0]       bpm;
    wire [1:0]        rhythm_class;
    wire              result_valid;


    //============================================================
    // FILE / COUNTERS
    //============================================================

    integer fd;
    integer rc;
    integer sample;

    integer sample_count;
    integer peak_count;
    integer result_count;


    //============================================================
    // EXPECTED R-PEAK LOCATIONS
    //
    // ECG input contains approximately:
    //
    // 220
    // 580
    // 940
    // 1300
    // 1660
    // 2020
    //
    //============================================================

    integer expected_peaks [0:5];

    integer detected_sample;


    //============================================================
    // DUT
    //============================================================

    ecg_wtsee_v6_top #(
        .FS(360)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .ecg_in       (ecg_in),
        .ecg_valid    (ecg_valid),
        .r_peak       (r_peak),
        .rr_interval  (rr_interval),
        .bpm          (bpm),
        .rhythm_class (rhythm_class),
        .result_valid (result_valid)
    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //============================================================
    // INITIALIZE EXPECTED PEAKS
    //============================================================

    initial begin

        expected_peaks[0] = 220;
        expected_peaks[1] = 580;
        expected_peaks[2] = 940;
        expected_peaks[3] = 1300;
        expected_peaks[4] = 1660;
        expected_peaks[5] = 2020;

    end


    //============================================================
    // MAIN TEST
    //============================================================

    initial begin

        rst_n        = 1'b0;
        ecg_in       = 16'sd0;
        ecg_valid    = 1'b0;

        sample_count = 0;
        peak_count   = 0;
        result_count = 0;


        $display("");
        $display("============================================================");
        $display("          WTSEE QRS STANDALONE VERIFICATION");
        $display("============================================================");
        $display("");


        //========================================================
        // RESET
        //========================================================

        $display("[TB] Applying reset...");

        repeat (10) @(posedge clk);

        rst_n <= 1'b1;

        $display("[TB] Reset released.");
        $display("");


        //========================================================
        // OPEN ECG FILE
        //========================================================

        fd = $fopen("tb/ecg_input.txt", "r");

        if (fd == 0) begin

            $display("============================================================");
            $display("ERROR: Cannot open tb/ecg_input.txt");
            $display("============================================================");

            $finish;

        end


        $display("[TB] ECG input file opened successfully.");
        $display("");


        //========================================================
        // SEND ECG SAMPLES
        //========================================================

        while (!$feof(fd)) begin

            rc = $fscanf(fd, "%d\n", sample);

            if (rc == 1) begin

                @(posedge clk);

                ecg_in    <= sample[15:0];
                ecg_valid <= 1'b1;

                sample_count = sample_count + 1;


                if ((sample_count % 1000) == 0) begin

                    $display(
                        "[ECG] Samples processed = %0d | Current sample = %0d",
                        sample_count,
                        sample
                    );

                end

            end

        end


        //========================================================
        // STOP INPUT
        //========================================================

        @(posedge clk);

        ecg_valid <= 1'b0;
        ecg_in    <= 16'sd0;

        $fclose(fd);


        $display("");
        $display("============================================================");
        $display("ECG INPUT COMPLETE");
        $display("Total samples = %0d", sample_count);
        $display("============================================================");
        $display("");


        //========================================================
        // WAIT FOR PIPELINE
        //========================================================

        $display("[TB] Waiting for QRS pipeline...");

        repeat (5000) @(posedge clk);


        //========================================================
        // FINAL SUMMARY
        //========================================================

        $display("");
        $display("============================================================");
        $display("             QRS VERIFICATION SUMMARY");
        $display("============================================================");

        $display("Input Samples       : %0d", sample_count);
        $display("Detected R-Peaks    : %0d", peak_count);
        $display("Valid Results       : %0d", result_count);

        $display("------------------------------------------------------------");

        $display("Expected R-Peaks:");
        $display("  Peak 1 : sample %0d", expected_peaks[0]);
        $display("  Peak 2 : sample %0d", expected_peaks[1]);
        $display("  Peak 3 : sample %0d", expected_peaks[2]);
        $display("  Peak 4 : sample %0d", expected_peaks[3]);
        $display("  Peak 5 : sample %0d", expected_peaks[4]);
        $display("  Peak 6 : sample %0d", expected_peaks[5]);

        $display("============================================================");


        //========================================================
        // VERIFICATION DECISION
        //========================================================

        if (peak_count >= 2 && result_count > 0) begin

            $display("QRS TEST : PASS");
            $display("Multiple R-peaks and valid QRS results were observed.");

        end
        else if (peak_count >= 2) begin

            $display("QRS TEST : PARTIAL");
            $display("Multiple R-peaks detected, but no valid result was generated.");

        end
        else if (peak_count == 1) begin

            $display("QRS TEST : PARTIAL");
            $display("Only one R-peak was detected.");
            $display("RR/BPM calculation requires additional detected peaks.");

        end
        else begin

            $display("QRS TEST : FAIL");
            $display("No R-peaks were detected.");

        end


        $display("============================================================");
        $display("");


        $finish;

    end


    //============================================================
    // REAL-TIME QRS MONITOR
    //============================================================

    always @(posedge clk) begin

        if (r_peak) begin

            peak_count = peak_count + 1;

            detected_sample = sample_count;


            $display("");
            $display("------------------------------------------------------------");
            $display("R-PEAK DETECTED");
            $display("------------------------------------------------------------");

            $display("Simulation Time : %0t", $time);
            $display("Detection Count  : %0d", peak_count);
            $display("Approx Input Sample : %0d", detected_sample);

            $display("ECG Input        : %0d", $signed(ecg_in));
            $display("RR Interval      : %0d", rr_interval);
            $display("BPM              : %0d", bpm);
            $display("Rhythm Class     : %b", rhythm_class);
            $display("Result Valid     : %0d", result_valid);

            $display("------------------------------------------------------------");
            $display("");

        end


        if (result_valid) begin

            result_count = result_count + 1;

            $display("");
            $display("**************** QRS RESULT ****************");

            $display("Time          : %0t", $time);
            $display("Result Number : %0d", result_count);
            $display("R-Peak        : %0d", r_peak);
            $display("RR Interval   : %0d", rr_interval);
            $display("BPM           : %0d", bpm);
            $display("Rhythm Class  : %b", rhythm_class);

            $display("*********************************************");
            $display("");

        end

    end


    //============================================================
    // VERDI FSDB DUMP
    //============================================================

    initial begin

        $fsdbDumpfile("qrs_standalone.fsdb");

        $fsdbDumpvars(
            0,
            tb_ecg_wtsee_optimized_top
        );

        $fsdbDumpMDA();

    end


endmodule
