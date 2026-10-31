// ============================================================================
// File: cardioedge_virtual_sequence.sv
// Directory: tb/uvm_cardioedge/sequences/
// Description: Coordinated Virtual Sequence exercising all 4 VIPs concurrently
// ============================================================================

`ifndef CARDIOEDGE_VIRTUAL_SEQUENCE_SV
`define CARDIOEDGE_VIRTUAL_SEQUENCE_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class cardioedge_virtual_sequence extends uvm_sequence;

    `uvm_object_utils(cardioedge_virtual_sequence)
    `uvm_declare_p_sequencer(cardioedge_virtual_sequencer)

    // VIP Sequence instances
    adc_pkguvm::adc_multi_sample_sequence       adc_multi_seq;
    adc_pkguvm::adc_continuous_sequence         adc_cont_seq;
    gpio_pkg::gpio_pattern_sequence             gpio_pat_seq;
    gpio_pkg::gpio_direction_test_sequence      gpio_dir_seq;
    spi_pkg::spi_multi_trans_sequence           spi_multi_seq;
    uart_pkg::uart_string_sequence              uart_str_seq;
    uart_pkg::uart_back_to_back_sequence        uart_b2b_seq;

    function new(string name = "cardioedge_virtual_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_info("VIRT_SEQ", "============================================================", UVM_LOW)
        `uvm_info("VIRT_SEQ", " Starting CARDIOEDGE Comprehensive Multi-VIP Virtual Sequence", UVM_LOW)
        `uvm_info("VIRT_SEQ", " Coordinating: ADC VIP + GPIO VIP + SPI VIP + UART VIP      ", UVM_LOW)
        `uvm_info("VIRT_SEQ", "============================================================", UVM_LOW)

        // Give SoC CPU sufficient initial cycles to boot and perform peripheral setups
        #5000ns;

        // --------------------------------------------------------------------
        // Phase 1: Sequential Functional Stimulus across VIPs
        // --------------------------------------------------------------------
        `uvm_info("VIRT_SEQ", "[PHASE 1] Executing UART VIP Serial Stimulus...", UVM_LOW)
        uart_str_seq = uart_pkg::uart_string_sequence::type_id::create("uart_str_seq");
        uart_str_seq.start(p_sequencer.uart_seqr);

        `uvm_info("VIRT_SEQ", "[PHASE 2] Executing GPIO VIP Multi-Pattern Stimulus...", UVM_LOW)
        gpio_pat_seq = gpio_pkg::gpio_pattern_sequence::type_id::create("gpio_pat_seq");
        gpio_pat_seq.start(p_sequencer.gpio_seqr);

        `uvm_info("VIRT_SEQ", "[PHASE 3] Executing ADC VIP Multi-Sample Acquisition...", UVM_LOW)
        adc_multi_seq = adc_pkguvm::adc_multi_sample_sequence::type_id::create("adc_multi_seq");
        adc_multi_seq.start(p_sequencer.adc_seqr);

        `uvm_info("VIRT_SEQ", "[PHASE 4] Executing SPI VIP Slave Response Configuration...", UVM_LOW)
        spi_multi_seq = spi_pkg::spi_multi_trans_sequence::type_id::create("spi_multi_seq");
        // Start SPI sequence in background so it can respond to any master transaction
        fork
            spi_multi_seq.start(p_sequencer.spi_seqr);
        join_none

        // --------------------------------------------------------------------
        // Phase 5: Concurrent Coordinated Multi-VIP Stress Operation
        // --------------------------------------------------------------------
        `uvm_info("VIRT_SEQ", "[PHASE 5] Launching All 4 VIPs Concurrently (Stress Verification)...", UVM_LOW)
        fork
            begin : th_adc
                adc_cont_seq = adc_pkguvm::adc_continuous_sequence::type_id::create("adc_cont_seq");
                adc_cont_seq.burst_count = 12;
                adc_cont_seq.start(p_sequencer.adc_seqr);
            end
            begin : th_gpio
                gpio_dir_seq = gpio_pkg::gpio_direction_test_sequence::type_id::create("gpio_dir_seq");
                gpio_dir_seq.start(p_sequencer.gpio_seqr);
            end
            begin : th_uart
                uart_b2b_seq = uart_pkg::uart_back_to_back_sequence::type_id::create("uart_b2b_seq");
                uart_b2b_seq.start(p_sequencer.uart_seqr);
            end
        join

        // Allow settling and monitor pipeline flush
        #10000ns;

        `uvm_info("VIRT_SEQ", "============================================================", UVM_LOW)
        `uvm_info("VIRT_SEQ", " CARDIOEDGE Multi-VIP Virtual Sequence Completed Successfully", UVM_LOW)
        `uvm_info("VIRT_SEQ", "============================================================", UVM_LOW)
    endtask

endclass : cardioedge_virtual_sequence

`endif // CARDIOEDGE_VIRTUAL_SEQUENCE_SV
