// ============================================================================
// File: cardioedge_uvm_test.sv
// Directory: tb/uvm_cardioedge/
// Description: Top-level UVM Test for CardioEdge SoC Multi-VIP Verification
// ============================================================================

`ifndef CARDIOEDGE_UVM_TEST_SV
`define CARDIOEDGE_UVM_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class cardioedge_uvm_test extends uvm_test;

    cardioedge_env env;

    `uvm_component_utils(cardioedge_uvm_test)

    function new(string name = "cardioedge_uvm_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cardioedge_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("CARDIOEDGE_TEST", "Printing UVM Component Hierarchy Topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        cardioedge_virtual_sequence vseq;

        phase.raise_objection(this, "Starting CARDIOEDGE Multi-VIP Verification Test");
        `uvm_info("CARDIOEDGE_TEST", "Starting cardioedge_virtual_sequence on virtual sequencer...", UVM_LOW)

        vseq = cardioedge_virtual_sequence::type_id::create("vseq");
        vseq.start(env.vseqr);

        `uvm_info("CARDIOEDGE_TEST", "cardioedge_virtual_sequence execution completed.", UVM_LOW)
        #2000ns; // Drain time
        phase.drop_objection(this, "Completed CARDIOEDGE Multi-VIP Verification Test");
    endtask

endclass : cardioedge_uvm_test

`endif // CARDIOEDGE_UVM_TEST_SV
