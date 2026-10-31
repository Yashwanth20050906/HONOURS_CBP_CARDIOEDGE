# CARDIOEDGE UVM VIP Integration & Verification Environment

## Overview
This directory contains the completely new, independent UVM 1.2 verification environment for the **CARDIOEDGE VeeR EL2 RISC-V SoC**. It integrates four functional Universal Verification Methodology (UVM) Verification IPs (VIPs):
1. **ADC VIP** (12-bit Analog-to-Digital Converter acquisition interface)
2. **GPIO VIP** (8-bit Bidirectional General Purpose Input/Output interface)
3. **SPI VIP** (Full-Duplex Serial Peripheral Interface in SPI Slave mode)
4. **UART VIP** (Serial 8N1 Universal Asynchronous Receiver-Transmitter)

All existing reference files (including `tb_cardioedge_comprehensive_soc.sv`, RTL modules, firmware, and scripts) remain completely untouched and unmodified.

---

## Architecture & Directory Structure

```text
tb/
|
|-- tb_cardioedge_comprehensive_soc.sv  (EXISTING MANUAL TB - UNTOUCHED)
|
|-- uvm_cardioedge/
    |-- tb_cardioedge_uvm_soc.sv         # Completely new UVM top-level testbench
    |-- cardioedge_env.sv                # Unified UVM verification environment
    |-- cardioedge_uvm_test.sv           # Unified top-level UVM test
    |-- cardioedge_virtual_sequencer.sv  # Virtual sequencer managing all 4 VIP sequencers
    |-- cardioedge_uvm_compile.f         # Independent VCS compilation filelist
    |-- VIP_DUT_CONNECTIVITY.md          # Comprehensive VIP-to-DUT mapping documentation
    |-- UVM_INTEGRATION_README.md        # This integration guide
    |
    |-- sequences/
    |   |-- adc_sequence.sv              # Multi-sample, continuous, and invalid sequences
    |   |-- gpio_sequence.sv             # Walking patterns, 0s/1s, and direction sequences
    |   |-- spi_sequence.sv              # Full-duplex slave response sequences
    |   |-- uart_sequence.sv             # String and back-to-back fast serial sequences
    |   |-- cardioedge_virtual_sequence.sv # Coordinated master virtual sequence
    |
    |-- scoreboards/
    |   |-- adc_scoreboard.sv            # ADC sample resolution, validity, and count checks
    |   |-- gpio_scoreboard.sv           # GPIO DIR=0xFF, DATA=0xA5, SET=0xA7, CLR=0xA6 checks
    |   |-- spi_scoreboard.sv            # SPI MOSI DTR=0x5A, CS_N, and frame bit checks
    |   |-- uart_scoreboard.sv           # UART characters 'C' (0x43) and 'A' (0x41) checks
    |
    |-- vips/
        |-- adc/                         # Corrected and complete ADC VIP
        |   |-- adc_if.sv
        |   |-- adc_item.sv
        |   |-- adc_sequencer.sv
        |   |-- adc_driver.sv
        |   |-- adc_monitor.sv
        |   |-- adc_agent.sv
        |   |-- adc_pkguvm.sv
        |
        |-- gpio/                        # Corrected and complete GPIO VIP
        |   |-- gpio_if.sv
        |   |-- gpio_item.sv
        |   |-- gpio_sequencer.sv
        |   |-- gpio_driver.sv
        |   |-- gpio_monitor.sv
        |   |-- gpio_agent.sv
        |   |-- gpio_pkg.sv
        |
        |-- spi/                         # Corrected and complete SPI VIP
        |   |-- spi_if.sv
        |   |-- spi_item.sv
        |   |-- spi_sequencer.sv
        |   |-- spi_driver.sv
        |   |-- spi_monitor.sv
        |   |-- spi_agent.sv
        |   |-- spi_pkg.sv
        |
        |-- uart/                        # Corrected and complete UART VIP
            |-- uart_if.sv
            |-- uart_item.sv
            |-- uart_sequencer.sv
            |-- uart_driver.sv
            |-- uart_monitor.sv
            |-- uart_agent.sv
            |-- uart_pkg.sv
```

---

## Corrections Applied to Incomplete VIP Scaffolds

The existing VIP folders (`tb/*_uvm_tb/`) contained placeholder scaffolds with missing interfaces and syntax errors that failed VCS compilation. Fully functional, corrected copies were created in `tb/uvm_cardioedge/vips/` without modifying the originals:

1. **Clock & Reset Integration in Interfaces**:
   - `adc_if`, `gpio_if`, `spi_if`, and `uart_if` now accept `(input logic clk, input logic rst_n)` and provide synchronized clocking blocks.
   - Resolved VCS error: `Could not find member 'clk' in interface`.

2. **Virtual Interface Retrieval**:
   - Added `uvm_config_db#(virtual <vif>)::get(this, "", "vif", vif)` in all drivers and monitors with `uvm_fatal` safety checks.

3. **Active Drivers with Real Protocol Timing**:
   - **ADC Driver**: Drives 12-bit `sample_in` codes and pulses `sample_valid` for one clock cycle.
   - **GPIO Driver**: Manages `gpio_in` stimulus and `gpio_drv_en` tri-state masks without bus contention.
   - **SPI Driver**: Acts as an SPI Slave responder, shifting out MISO data synchronously on `spi_clk_o` when `spi_cs_n_o` is low.
   - **UART Driver**: Generates bit-accurate 8N1 serial frames with precise 1280 ns baud period.

4. **Monitors & Analysis Ports**:
   - All four monitors continuously observe bus activity, assemble high-level sequence items, timestamp them, and broadcast via `uvm_analysis_port`.

5. **Functional Scoreboards**:
   - Implemented real checking of firmware outputs (`UART: 'C', 'A'`, `GPIO: 0xA5, 0xA7, 0xA6`, `SPI: DTR=0x5A`, `ADC: valid 12-bit range`).
   - Reports `total_trans`, `pass_count`, `fail_count`, and final scorecard banner.

---

## VCS Compilation and Simulation Instructions

To run with Synopsys VCS UVM 1.2:

### Environment Setup
```bash
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
```

### 1. Compilation
Navigate to the directory:
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/uvm_cardioedge
vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
    -f cardioedge_uvm_compile.f \
    -top tb_cardioedge_uvm_soc \
    -o simv_uvm
```

### 2. Simulation Execution
```bash
./simv_uvm +UVM_VERBOSITY=UVM_MEDIUM
```
