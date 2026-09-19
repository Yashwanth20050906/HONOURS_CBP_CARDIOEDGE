// =============================================================================
// aes_test_bench_top.v
// Top-Level Testbench Wrapper for AES-256 AXI Simulation
//
// This module is the simulation top level.
// It instantiates aes_axi_slave_tb which drives the AXI transactions.
//
// For FSDB waveform dumping (Verdi), compile with +define+FSDB_DUMP
// =============================================================================



module aes_test_bench_top;

    // Instantiate the AXI master testbench
    aes_axi_slave_tb u_tb ();

endmodule
