// ============================================================================
// File: cardioedge_env.sv
// Directory: tb/uvm_cardioedge/
// Description: Common UVM Verification Environment instantiating all 4 VIPs
// ============================================================================

`ifndef CARDIOEDGE_ENV_SV
`define CARDIOEDGE_ENV_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class cardioedge_env extends uvm_env;

    // VIP Agents
    adc_pkguvm::adc_agent   adc_agent_h;
    gpio_pkg::gpio_agent    gpio_agent_h;
    spi_pkg::spi_agent      spi_agent_h;
    uart_pkg::uart_agent    uart_agent_h;

    // VIP Scoreboards
    adc_pkguvm::adc_scoreboard   adc_sb;
    gpio_pkg::gpio_scoreboard    gpio_sb;
    spi_pkg::spi_scoreboard      spi_sb;
    uart_pkg::uart_scoreboard    uart_sb;

    // Virtual Sequencer
    cardioedge_virtual_sequencer vseqr;

    `uvm_component_utils(cardioedge_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Instantiate Agents
        adc_agent_h  = adc_pkguvm::adc_agent::type_id::create("adc_agent_h", this);
        gpio_agent_h = gpio_pkg::gpio_agent::type_id::create("gpio_agent_h", this);
        spi_agent_h  = spi_pkg::spi_agent::type_id::create("spi_agent_h", this);
        uart_agent_h = uart_pkg::uart_agent::type_id::create("uart_agent_h", this);

        // Instantiate Scoreboards
        adc_sb  = adc_pkguvm::adc_scoreboard::type_id::create("adc_sb", this);
        gpio_sb = gpio_pkg::gpio_scoreboard::type_id::create("gpio_sb", this);
        spi_sb  = spi_pkg::spi_scoreboard::type_id::create("spi_sb", this);
        uart_sb = uart_pkg::uart_scoreboard::type_id::create("uart_sb", this);

        // Instantiate Virtual Sequencer
        vseqr = cardioedge_virtual_sequencer::type_id::create("vseqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect Monitors to Scoreboards
        adc_agent_h.mon.ap.connect(adc_sb.item_collected_export);
        gpio_agent_h.mon.ap.connect(gpio_sb.item_collected_export);
        spi_agent_h.mon.ap.connect(spi_sb.item_collected_export);
        uart_agent_h.mon.ap.connect(uart_sb.item_collected_export);

        // Connect Virtual Sequencer sub-sequencers
        vseqr.adc_seqr  = adc_agent_h.seqr;
        vseqr.gpio_seqr = gpio_agent_h.seqr;
        vseqr.spi_seqr  = spi_agent_h.seqr;
        vseqr.uart_seqr = uart_agent_h.seqr;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("\n============================================================");
        $display("       CARDIOEDGE TOP-LEVEL UVM VERIFICATION SUMMARY        ");
        $display("============================================================");
        $display("  VIP 1 (ADC)  : %0d transactions checked, %0d passed, %0d failed",
                 adc_sb.total_trans, adc_sb.pass_count, adc_sb.fail_count);
        $display("  VIP 2 (GPIO) : %0d transitions checked, %0d passed, %0d failed",
                 gpio_sb.total_trans, gpio_sb.pass_count, gpio_sb.fail_count);
        $display("  VIP 3 (SPI)  : %0d transfers checked,   %0d passed, %0d failed",
                 spi_sb.total_trans, spi_sb.pass_count, spi_sb.fail_count);
        $display("  VIP 4 (UART) : %0d characters checked,  %0d passed, %0d failed",
                 uart_sb.total_trans, uart_sb.pass_count, uart_sb.fail_count);
        $display("  DMEM[15] (SPI SR) = 0x%08h, DMEM[13] (ADC) = 0x%08h, DMEM[6] (GPIO) = 0x%08h",
                 tb_cardioedge_uvm_soc.dut.u_dmem.mem[15],
                 tb_cardioedge_uvm_soc.dut.u_dmem.mem[13],
                 tb_cardioedge_uvm_soc.dut.u_dmem.mem[6]);
        $display("------------------------------------------------------------");
        if ((adc_sb.fail_count == 0) && (gpio_sb.fail_count == 0) &&
            (spi_sb.fail_count == 0) && (uart_sb.fail_count == 0) &&
            (adc_sb.total_trans > 0 || gpio_sb.total_trans > 0 || spi_sb.total_trans > 0 || uart_sb.total_trans > 0)) begin
            $display("  OVERALL SYSTEM STATUS: *** ALL FOUR UVM VIPS PASSED ***");
        end else begin
            $display("  OVERALL SYSTEM STATUS: *** VERIFICATION FAILED ***");
        end
        $display("============================================================\n");
    endfunction

endclass : cardioedge_env

`endif // CARDIOEDGE_ENV_SV
