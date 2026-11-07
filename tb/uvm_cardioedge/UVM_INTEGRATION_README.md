# CARDIOEDGE Verification Environment: Two Independent Flows Architecture

## Overview
This directory contains the completely new, independent UVM 1.2 verification environment (**Flow 2**) for the **CARDIOEDGE VeeR EL2 RISC-V SoC**, designed to operate in parallel with the existing directed SystemVerilog/C testbench (**Flow 1**). Both flows verify the **same unmodified CARDIOEDGE SoC RTL** (`cardioedge_cpu_soc_top.sv`).

---

## 1. Architectural Comparison: Flow 1 vs. Flow 2

```
                       CARDIOEDGE SoC RTL (READ-ONLY)
                        (cardioedge_cpu_soc_top.sv)
                                     |
         +---------------------------+---------------------------+
         |                                                       |
         v                                                       v
  [ FLOW 1: MANUAL SV/C ]                                 [ FLOW 2: UVM 1.2 VIP ]
  - Top: tb_cardioedge_comprehensive_soc.sv              - Top: tb_cardioedge_uvm_soc.sv
  - 18 Directed Testcases (TC-01 to TC-18)               - UVM Environment: cardioedge_env.sv
  - Precompiled C Firmware (cardioedge_test.c)           - Virtual Sequencer & Multi-VIP Coordination
  - C Golden Reference (fir_calc_ref, Pan-Tompkins)      - 4 UVM Verification IPs (ADC, GPIO, SPI, UART)
  - Direct AXI & Register Checking                       - Independent Protocol Scoreboards
  - Scripts: run_scripts_and_config/                     - VCS Filelist: run_scripts_and_config/cardioedge_uvm_compile.f
```

### Flow 1: Existing Manual Verification Flow (Untouched & Preserved)
- **Top Testbench**: `tb/tb_cardioedge_comprehensive_soc.sv`
- **Simulation Binary**: `run_scripts_and_config/simv_comprehensive`
- **Scope**: 18 exhaustive system testcases covering CPU bring-up, AXI interconnect routing, peripheral register access, FIR/QRS accelerators, interrupt controllers, and DMA operations.
- **Role of C Golden Model**:
  - `firmware/cardioedge_test.c` integrates clinical ECG lead data (`tb/ecg_input.txt`).
  - Computes algorithmic references for bandpass filtering (`fir_calc_ref`) and Pan-Tompkins QRS peak detection.
  - Testbench asserts hardware matching against firmware-computed features in DMEM.
- **Constraint Compliance**: ZERO existing files modified, deleted, or renamed.

### Flow 2: New UVM Verification Flow (Independent & Multi-VIP)
- **Top Testbench**: `tb/uvm_cardioedge/tb_cardioedge_uvm_soc.sv`
- **Simulation Binary**: `run_scripts_and_config/simv_uvm`
- **Compilation Filelist**: `run_scripts_and_config/cardioedge_uvm_compile.f`
- **Scope**: Complete UVM 1.2 object-oriented verification leveraging four independent VIPs (ADC, GPIO, SPI, UART) interacting with the live VeeR EL2 core running peripheral MMIO transactions.
- **Virtual Sequencing**: `cardioedge_virtual_sequence.sv` manages all 4 VIP sequencers concurrently and phase-by-phase without race conditions or bus collisions.
- **Scoreboards**: Non-trivial transaction checking with zero false positives (`total_trans > 0 && fail_count == 0`).

---

## 2. Directory Structure of Flow 2

All filelists and execution scripts reside in `run_scripts_and_config/`, while UVM source code and VIPs reside in `tb/uvm_cardioedge/`:

```text
run_scripts_and_config/
|-- filelist_cardioedge_comprehensive_soc.f  # Flow 1 VCS filelist
|-- cardioedge_all_vips_compile.f            # Legacy VIP filelist
|-- cardioedge_uvm_compile.f                 # Flow 2 UVM compilation filelist
|-- simv_uvm                                 # Compiled UVM simulation executable
|-- cardioedge_uvm.fsdb                      # UVM Verdi FSDB waveform dump
|-- compile_uvm.log, sim_uvm.log             # UVM build and execution logs

tb/uvm_cardioedge/
|-- tb_cardioedge_uvm_soc.sv         # Completely new UVM top-level testbench
|-- cardioedge_env.sv                # Unified UVM verification environment
|-- cardioedge_uvm_test.sv           # Unified top-level UVM test
|-- cardioedge_virtual_sequencer.sv  # Virtual sequencer managing all 4 VIP sequencers
|-- VIP_DUT_CONNECTIVITY.md          # Comprehensive VIP-to-DUT mapping documentation
|-- UVM_INTEGRATION_README.md        # This architectural documentation
|
|-- sequences/
|   |-- adc_sequence.sv              # Multi-sample, continuous, and invalid sample sequences
|   |-- gpio_sequence.sv             # Walking patterns, 0s/1s, and direction sequences
|   |-- spi_sequence.sv              # Full-duplex slave response sequences
|   |-- uart_sequence.sv             # String and back-to-back fast serial sequences
|   |-- cardioedge_virtual_sequence.sv # Coordinated master virtual sequence
|
|-- scoreboards/
|   |-- adc_scoreboard.sv            # ADC sample resolution (12-bit), validity, and count checks
|   |-- gpio_scoreboard.sv           # GPIO DIR=0xFF, DATA=0xA5, SET=0xA7, CLR=0xA6 checks
|   |-- spi_scoreboard.sv            # SPI MOSI DTR=0x5A, 0xA5, 0x3C, 0xC3, CS_N, and frame bit checks
|   |-- uart_scoreboard.sv           # UART characters 'C' (0x43) and 'A' (0x41) checks
|
|-- vips/
    |-- adc/                         # Corrected and complete ADC VIP
    |   |-- adc_if.sv, adc_item.sv, adc_sequencer.sv, adc_driver.sv, adc_monitor.sv, adc_agent.sv, adc_pkguvm.sv
    |-- gpio/                        # Corrected and complete GPIO VIP
    |   |-- gpio_if.sv, gpio_item.sv, gpio_sequencer.sv, gpio_driver.sv, gpio_monitor.sv, gpio_agent.sv, gpio_pkg.sv
    |-- spi/                         # Corrected and complete SPI VIP
    |   |-- spi_if.sv, spi_item.sv, spi_sequencer.sv, spi_driver.sv, spi_monitor.sv, spi_agent.sv, spi_pkg.sv
    |-- uart/                        # Corrected and complete UART VIP
        |-- uart_if.sv, uart_item.sv, uart_sequencer.sv, uart_driver.sv, uart_monitor.sv, uart_agent.sv, uart_pkg.sv
```

---

## 3. C Golden Model & ECG Dataset Integration in Both Flows

The project contains two distinct checking domains linked to clinical cardiac data:

1. **Flow 1 (Algorithmic & DSP Reference)**:
   - Uses `firmware/cardioedge_test.c` compiled to `firmware/cardioedge_test.hex`.
   - Incorporates `clinical_ecg_qrs_vector` (12-bit digitized samples representing clinical arrhythmia and sinus rhythms).
   - The C model acts as an embedded golden model: computes golden FIR filtered outputs and QRS peaks, storing results in DMEM.
   - The manual testbench inspects DMEM to ensure hardware accelerators (FIR filter and QRS detector) match the C algorithm within clinical tolerance.

2. **Flow 2 (Physical Protocol, Bus Fidelity, & Transaction Verification)**:
   - Uses the actual SoC running RISC-V instructions directly from IMEM.
   - The ADC VIP streams clinical ECG signal levels (e.g., QRS pulse wave: `0x800, 0x850, 0x900...`) into the SoC's hardware ADC acquisition FIFO with valid/ready handshaking.
   - The CPU accesses peripheral registers via AXI, driving UART TX (`'C'`, `'A'`), GPIO pin toggles (`0xA5 -> 0xA7 -> 0xA6`), and SPI Master transfers (`0x5A, 0xA5, 0x3C, 0xC3`).
   - The UVM VIP drivers and monitors operate at the physical pin boundaries, checking baud timing, SPI Mode 0 bit shifting, and tri-state bus resolution.

---

## 4. Key Fixes Applied to VIP Scaffolds

The initial VIP files in `tb/*_uvm_tb/` contained non-functional skeleton code. Fully working versions were created inside `tb/uvm_cardioedge/vips/`:

1. **Clock & Reset Integration**:
   - Added `(input logic clk, input logic rst_n)` to `adc_if`, `gpio_if`, `spi_if`, and `uart_if` along with proper clocking blocks.
2. **Dynamic Virtual Interface Binding**:
   - Implemented `uvm_config_db#(virtual <vif>)::get(...)` across all drivers and monitors with null-check assertions.
3. **SPI Slave Architecture & Handshaking**:
   - SoC is an SPI Master; SPI VIP configured as an SPI Slave responder.
   - Resolved blocking monitor wait loops by completing frames upon 8-bit SCK reception without depending on indefinite CS_N deassertion.
   - Implemented Mode 0 MISO bit shifting on falling SCK edges.
4. **Active Drivers & High-Impedance Protection**:
   - GPIO driver controls tri-state nets via `gpio_drv_en` to prevent contention with DUT outputs.
   - UART driver produces 8N1 serial frames with 1280 ns bit timing.
5. **Scoreboards with Genuine Assertion Metrics**:
   - ADC Scoreboard: 12-bit range check, monotonicity check, sample-valid pulse duration check.
   - GPIO Scoreboard: Direction mask verification, transition tracking (`0xA5, 0xA7, 0xA6`).
   - SPI Scoreboard: 4 individual byte checks (`0x5A, 0xA5, 0x3C, 0xC3`), frame completeness.
   - UART Scoreboard: Character sequence verification (`'C'` -> `'A'`).
   - All scoreboards require `total_trans > 0` and `fail_count == 0` for PASS status.

---

## 5. Compilation and Execution Instructions

### Environment Configuration
```bash
export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME=/home/student/snps_tools_target/verdi/U-2023.03-SP1
export SNPSLMD_LICENSE_FILE=27021@14.139.1.126
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$PATH
```

### Flow 1: Running the Existing Manual Verification Flow
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config
# Compile (if needed) using original script:
./run_compile_comprehensive.sh
# Execute testcase (e.g. TC-01):
./simv_comprehensive +TEST_ID=1
```

### Flow 2: Running the New UVM Verification Flow

#### 1. Compilation with Synopsys VCS UVM 1.2 & Verdi FSDB PLI
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config

vcs -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps \
    -debug_access+all -kdb \
    -P /home/student/snps_tools_target/verdi/U-2023.03-SP1/share/PLI/VCS/LINUX64/novas.tab \
       /home/student/snps_tools_target/verdi/U-2023.03-SP1/share/PLI/VCS/LINUX64/pli.a \
    -f cardioedge_uvm_compile.f \
    -top tb_cardioedge_uvm_soc \
    -o simv_uvm -l compile_uvm.log
```

#### 2. Simulation Execution & FSDB Waveform Generation
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config
./simv_uvm -no_save +UVM_VERBOSITY=UVM_MEDIUM -l sim_uvm.log
```

#### 3. Verdi Waveform Inspection
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/run_scripts_and_config
verdi -ssf cardioedge_uvm.fsdb &
```

---

## 6. Verification Results Summary (Flow 2)

```text
============================================================
       CARDIOEDGE TOP-LEVEL UVM VERIFICATION SUMMARY        
============================================================
  VIP 1 (ADC)  : 28 transactions checked, 28 passed, 0 failed
  VIP 2 (GPIO) : 15 transitions checked, 15 passed, 0 failed
  VIP 3 (SPI)  : 4 transfers checked,   4 passed, 0 failed
  VIP 4 (UART) : 2 characters checked,  2 passed, 0 failed
  DMEM[15] (SPI SR) = 0x00000024, DMEM[13] (ADC) = 0x00000004, DMEM[6] (GPIO) = 0x000000a5
------------------------------------------------------------
  OVERALL SYSTEM STATUS: *** ALL FOUR UVM VIPS PASSED ***
============================================================

--- UVM Report Summary ---
UVM_INFO : 123
UVM_WARNING : 0
UVM_ERROR : 0
UVM_FATAL : 0
```
