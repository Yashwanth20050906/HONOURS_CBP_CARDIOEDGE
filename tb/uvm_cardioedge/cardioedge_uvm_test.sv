// ============================================================================
// File: cardioedge_uvm_test.sv
// Directory: tb/uvm_cardioedge/
// Description: Top-level UVM Test for CardioEdge SoC Multi-VIP Verification
//              and Complete 18-Test Regression Suite (TC-01 through TC-18).
// ============================================================================

`ifndef CARDIOEDGE_UVM_TEST_SV
`define CARDIOEDGE_UVM_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

// ----------------------------------------------------------------------------
// Base UVM Test
// ----------------------------------------------------------------------------
class cardioedge_sync_base_test extends uvm_test;

    cardioedge_env env;
    string sync_vip = "ALL";
    int    test_id  = 0;

    `uvm_component_utils(cardioedge_sync_base_test)

    function new(string name = "cardioedge_sync_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("SYNC_VIP=%s", sync_vip));
        void'($value$plusargs("TEST_ID=%d", test_id));
        uvm_config_db#(string)::set(this, "*", "sync_vip", sync_vip);
        uvm_config_db#(int)::set(this, "*", "test_id", test_id);
        `uvm_info(get_name(), $sformatf("[TEST CONFIG] Synchronization mode: %s | Test ID: %0d", sync_vip, test_id), UVM_LOW)
        env = cardioedge_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info(get_name(), "Printing UVM Component Hierarchy Topology:", UVM_LOW)
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        cardioedge_virtual_sequence vseq;

        phase.raise_objection(this, {"Starting ", get_name()});
        $display("\n===============================================================");
        $display("              CARDIOEDGE UVM LIVE MONITOR OUTPUT               ");
        $display("===============================================================\n");
        `uvm_info(get_name(), "Starting cardioedge_virtual_sequence on virtual sequencer...", UVM_LOW)

        vseq = cardioedge_virtual_sequence::type_id::create("vseq");
        vseq.target_test_id = test_id;
        vseq.start(env.vseqr);

        `uvm_info(get_name(), "cardioedge_virtual_sequence execution completed.", UVM_LOW)
        #2000ns; // Drain time
        phase.drop_objection(this, {"Completed ", get_name()});
    endtask

endclass : cardioedge_sync_base_test

// ----------------------------------------------------------------------------
// Mode 1: Individual VIP Synchronization Tests
// ----------------------------------------------------------------------------
class cardioedge_uart_sync_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_uart_sync_test)
    function new(string name = "cardioedge_uart_sync_test", uvm_component parent = null);
        super.new(name, parent);
        sync_vip = "UART";
    endfunction
endclass : cardioedge_uart_sync_test

class cardioedge_gpio_sync_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_gpio_sync_test)
    function new(string name = "cardioedge_gpio_sync_test", uvm_component parent = null);
        super.new(name, parent);
        sync_vip = "GPIO";
    endfunction
endclass : cardioedge_gpio_sync_test

class cardioedge_spi_sync_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_spi_sync_test)
    function new(string name = "cardioedge_spi_sync_test", uvm_component parent = null);
        super.new(name, parent);
        sync_vip = "SPI";
    endfunction
endclass : cardioedge_spi_sync_test

class cardioedge_adc_sync_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_adc_sync_test)
    function new(string name = "cardioedge_adc_sync_test", uvm_component parent = null);
        super.new(name, parent);
        sync_vip = "ADC";
    endfunction
endclass : cardioedge_adc_sync_test

// ----------------------------------------------------------------------------
// Mode 2: Combined Four-VIP Synchronization Test
// ----------------------------------------------------------------------------
class cardioedge_vip_sync_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_vip_sync_test)
    function new(string name = "cardioedge_vip_sync_test", uvm_component parent = null);
        super.new(name, parent);
        sync_vip = "ALL";
    endfunction
endclass : cardioedge_vip_sync_test

// ----------------------------------------------------------------------------
// Mode 3: 18 Dedicated SoC Verification Tests (TC-01 through TC-18)
// ----------------------------------------------------------------------------
class cardioedge_tc01_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc01_test)
    function new(string name = "cardioedge_tc01_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 1;
    endfunction
endclass : cardioedge_tc01_test

class cardioedge_tc02_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc02_test)
    function new(string name = "cardioedge_tc02_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 2;
    endfunction
endclass : cardioedge_tc02_test

class cardioedge_tc03_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc03_test)
    function new(string name = "cardioedge_tc03_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 3;
    endfunction
endclass : cardioedge_tc03_test

class cardioedge_tc04_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc04_test)
    function new(string name = "cardioedge_tc04_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 4;
    endfunction
endclass : cardioedge_tc04_test

class cardioedge_tc05_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc05_test)
    function new(string name = "cardioedge_tc05_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 5;
    endfunction
endclass : cardioedge_tc05_test

class cardioedge_tc06_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc06_test)
    function new(string name = "cardioedge_tc06_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 6;
    endfunction
endclass : cardioedge_tc06_test

class cardioedge_tc07_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc07_test)
    function new(string name = "cardioedge_tc07_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 7;
    endfunction
endclass : cardioedge_tc07_test

class cardioedge_tc08_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc08_test)
    function new(string name = "cardioedge_tc08_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 8;
    endfunction
endclass : cardioedge_tc08_test

class cardioedge_tc09_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc09_test)
    function new(string name = "cardioedge_tc09_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 9;
    endfunction
endclass : cardioedge_tc09_test

class cardioedge_tc10_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc10_test)
    function new(string name = "cardioedge_tc10_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 10;
    endfunction
endclass : cardioedge_tc10_test

class cardioedge_tc11_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc11_test)
    function new(string name = "cardioedge_tc11_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 11;
    endfunction
endclass : cardioedge_tc11_test

class cardioedge_tc12_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc12_test)
    function new(string name = "cardioedge_tc12_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 12;
    endfunction
endclass : cardioedge_tc12_test

class cardioedge_tc13_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc13_test)
    function new(string name = "cardioedge_tc13_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 13;
    endfunction
endclass : cardioedge_tc13_test

class cardioedge_tc14_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc14_test)
    function new(string name = "cardioedge_tc14_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 14;
    endfunction
endclass : cardioedge_tc14_test

class cardioedge_tc15_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc15_test)
    function new(string name = "cardioedge_tc15_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 15;
    endfunction
endclass : cardioedge_tc15_test

class cardioedge_tc16_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc16_test)
    function new(string name = "cardioedge_tc16_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 16;
    endfunction
endclass : cardioedge_tc16_test

class cardioedge_tc17_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc17_test)
    function new(string name = "cardioedge_tc17_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 17;
    endfunction
endclass : cardioedge_tc17_test

class cardioedge_tc18_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_tc18_test)
    function new(string name = "cardioedge_tc18_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 18;
    endfunction
endclass : cardioedge_tc18_test

// Full Regression Test
class cardioedge_regression_test extends cardioedge_sync_base_test;
    `uvm_component_utils(cardioedge_regression_test)
    function new(string name = "cardioedge_regression_test", uvm_component parent = null);
        super.new(name, parent);
        test_id = 0;
    endfunction
endclass : cardioedge_regression_test

// Default UVM Test alias
class cardioedge_uvm_test extends cardioedge_regression_test;
    `uvm_component_utils(cardioedge_uvm_test)
    function new(string name = "cardioedge_uvm_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass : cardioedge_uvm_test

`endif // CARDIOEDGE_UVM_TEST_SV