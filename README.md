
# CARDIOEDGE — RISC-V ECG Processing System-on-Chip

![HDL](https://img.shields.io/badge/HDL-Verilog%20%7C%20SystemVerilog-blue)
![Processor](https://img.shields.io/badge/CPU-VeeR%20EL2%20%7C%20RV32IMC-informational)
![Interconnect](https://img.shields.io/badge/Interconnect-AXI4-orange)
![Simulation](https://img.shields.io/badge/Simulation-Synopsys%20VCS-lightgrey)
![Scope](https://img.shields.io/badge/Scope-RTL%20Design%20%26%20Verification-success)

**CARDIOEDGE** is an RTL-level healthcare System-on-Chip (SoC) integrating a Western Digital VeeR EL2 RISC-V processor, a shared AXI4 interconnect, on-chip instruction and data memories, and dedicated peripherals for ECG acquisition, digital signal processing, and cardiac event detection.

The system combines processor-controlled peripheral operations with a hardware ECG processing pipeline. ECG samples are acquired through an ADC controller, processed through a configurable FIR filter, and analyzed by a QRS detection engine for R-peak detection and rhythm-related information.

**Project Scope:** RTL design, hardware integration, firmware development, simulation, and verification. This project does not claim ASIC tape-out or post-silicon validation.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [System Architecture](#system-architecture)
4. [IP Blocks and Responsibilities](#ip-blocks-and-responsibilities)
5. [AXI4 Interconnect](#axi4-interconnect)
6. [Memory Map](#memory-map)
7. [ECG Processing Datapath](#ecg-processing-datapath)
8. [Control Path](#control-path)
9. [Firmware Architecture](#firmware-architecture)
10. [Verification Strategy](#verification-strategy)
11. [Verification Results](#verification-results)
12. [Repository Structure](#repository-structure)
13. [Tools and Technologies](#tools-and-technologies)
14. [Getting Started](#getting-started)
15. [Firmware Compilation](#firmware-compilation)
16. [RTL Simulation](#rtl-simulation)
17. [Waveform Analysis](#waveform-analysis)
18. [Project Documentation](#project-documentation)
19. [Future Improvements](#future-improvements)
20. [Acknowledgements](#acknowledgements)

---

## 1. Project Overview

CARDIOEDGE is designed to demonstrate the integration of a RISC-V processor with dedicated hardware accelerators and peripheral IPs for ECG signal acquisition and processing.

The SoC consists of:

- Western Digital VeeR EL2 RISC-V processor.
- Shared AXI4 interconnect.
- AXI width-conversion interfaces.
- Instruction Memory (IMEM).
- Data Memory (DMEM).
- UART communication interface.
- GPIO controller.
- Programmable Timer.
- ADC acquisition controller.
- FIR digital filter.
- SPI controller.
- QRS detection accelerator.

The processor executes firmware from instruction memory and accesses peripheral registers through memory-mapped AXI transactions.

The biomedical processing subsystem handles ECG samples through acquisition, buffering, filtering, and QRS detection.

The repository contains RTL source code, firmware, SystemVerilog testbenches, UVM verification components, simulation logs, and waveform evidence.

---

## 2. Key Features

- **RISC-V Processing:** Western Digital VeeR EL2 configured for RV32IMC.
- **AXI4 Interconnect:** Shared 3-master × 18-slave interconnect architecture.
- **AXI Width Conversion:** Separate 64-bit-to-32-bit adapters for IFU and LSU interfaces.
- **On-Chip Memories:** 64 KB Instruction Memory and 64 KB Data Memory.
- **Peripheral Integration:** UART, GPIO, Timer, ADC, FIR, SPI, and QRS detector.
- **ECG Acquisition:** Hardware-based ADC sample acquisition and buffering.
- **Digital Filtering:** Configurable FIR filter with AXI4-Stream datapath.
- **QRS Detection:** Hardware-based ECG processing and R-peak identification.
- **Firmware Integration:** C and RISC-V assembly-based processor control.
- **Interrupt Architecture:** Peripheral interrupt connectivity to the VeeR EL2 PIC.
- **Verification:** Directed SystemVerilog testbenches and UVM-based verification.
- **Simulation Debugging:** Synopsys VCS and Verdi.

---

## 3. System Architecture

```text
                  +-----------------------------+
                  |       VeeR EL2 RISC-V       |
                  |          RV32IMC             |
                  +--------------+--------------+
                                 |
                   +-------------+-------------+
                   |                           |
              IFU AXI Interface           LSU AXI Interface
                   |                           |
             64-bit to 32-bit            64-bit to 32-bit
                 Adapter                     Adapter
                   |                           |
                   +-------------+-------------+
                                 |
                  +--------------v--------------+
                  |       Shared AXI4 Fabric    |
                  |       3 Masters x 18        |
                  |      Slave Destinations     |
                  +--------------+--------------+
                                 |
          +----------+-----------+----------+----------+
          |          |           |          |          |
         IMEM       DMEM        UART       GPIO      TIMER
          |          |           |          |          |
          +----------+-----------+----------+----------+
                                 |
                       Memory-Mapped Peripherals
                                 |
                   +-------------+-------------+
                   |                           |
              ADC Controller              SPI Controller
                   |
                   v
              Sample Buffer
                   |
                   v
               FIR Filter
              AXI4-Stream
                   |
                   v
              QRS Detector
                   |
                   v
          R-Peak / RR Interval / BPM
             Rhythm Information
```

### Architecture Description

The processor uses two principal interfaces:

- **IFU (Instruction Fetch Unit):** Fetches instructions from instruction memory.
- **LSU (Load Store Unit):** Performs data memory accesses and memory-mapped peripheral transactions.

Both processor interfaces are connected through AXI width adapters to the shared interconnect.

The interconnect routes transactions to the appropriate memory or peripheral destination.

The ECG processing subsystem operates through dedicated hardware datapaths, reducing the need for continuous processor intervention in sample-level processing.

---

## 4. IP Blocks and Responsibilities

| IP Block | Functionality |
|---|---|
| VeeR EL2 RISC-V | Executes firmware and controls the SoC |
| AXI4 Interconnect | Address decoding, arbitration and transaction routing |
| IFU Adapter | Converts processor instruction-fetch transactions |
| LSU Adapter | Converts processor data transactions |
| IMEM | Stores executable instructions |
| DMEM | Stores runtime data and test results |
| UART | Serial communication and debugging |
| GPIO | Digital input/output control |
| Timer | Programmable counter and interrupt generation |
| ADC | ECG sample acquisition and buffering |
| FIR | Digital filtering of acquired ECG samples |
| SPI | Serial peripheral communication |
| QRS | R-peak detection and rhythm-related processing |
| Dummy Slaves | Handle unsupported address destinations |

---

## 5. AXI4 Interconnect

The processor-side SoC verification configuration uses a shared **3-master × 18-slave AXI4 interconnect**.

### Main Responsibilities

1. Address decoding.
2. Master-to-slave transaction routing.
3. Read and write channel handshaking.
4. Arbitration between active masters.
5. Response routing.
6. Concurrent instruction-fetch and data-access handling.
7. Error response generation for unsupported destinations.

### AXI Interfaces

The architecture includes:

- AXI4 interfaces for processor-side memory and peripheral transactions.
- AXI4-Lite register interfaces for peripheral control where applicable.
- AXI4-Stream interfaces for FIR sample processing.

The IFU and LSU adapters perform the required width conversion between the processor-side 64-bit interfaces and the 32-bit SoC-side connections.

---

## 6. Memory Map

The following table represents the processor-side SoC configuration documented in the verification report.

| Slave | Peripheral | Base Address | Size |
|---|---|---|---|
| M00 | UART | 0x40000000 | 4 KB |
| M01 | GPIO | 0x40002000 | 4 KB |
| M02 | TIMER | 0x40004000 | 4 KB |
| M03 | FIR | 0x4000C000 | 4 KB |
| M04 | ADC | 0x4000E000 | 4 KB |
| M05 | SPI | 0x40010000 | 4 KB |
| M06 | QRS | 0x40012000 | 4 KB |
| M07 | IMEM | 0x00000000 | 64 KB |
| M08 | DMEM | 0x00010000 | 64 KB |
| M09-M17 | Dummy / Reserved | Configuration-dependent | Configuration-dependent |

**Note:** The table describes the processor-side verification configuration. Refer to the selected top module and its address decoder for the exact configuration used in a particular simulation. Watchdog is not an active peripheral in the intended CARDIOEDGE configuration.

---

## 7. ECG Processing Datapath

The primary biomedical processing pipeline consists of the following stages:

```text
       ECG Input Samples
              |
              v
       ADC Acquisition
              |
              v
        Sample Buffer
              |
              v
         FIR Filter
              |
              v
        QRS Detector
              |
              v
        R-Peak Detection
              |
              v
       RR Interval Analysis
              |
              v
       Heart Rate Calculation
              |
              v
       Rhythm Classification
```

### ADC Acquisition

The ADC controller handles ECG sample acquisition.

Its functionality includes:

- Sample capture.
- Sample-valid handling.
- FIFO management.
- Status monitoring.
- Interrupt generation.
- Overrun detection.

### FIR Digital Filter

The FIR filter performs digital filtering of acquired ECG samples.

Its functionality includes:

- Programmable coefficient configuration.
- Filter enable control.
- Coefficient loading.
- AXI4-Stream input/output.
- Ready/valid handshake management.

The filter's control registers are memory-mapped, while its sample datapath uses AXI4-Stream.

### QRS Detection Engine

The QRS accelerator processes ECG samples to identify R-peaks.

Its documented microarchitecture includes:

- Baseline filtering.
- First-order derivative processing.
- Adaptive normalization.
- Shannon Energy Envelope calculation.
- Power Energy Envelope calculation.
- Adaptive threshold detection.
- Missed-beat search-back.
- RR interval measurement.
- Heart-rate calculation.
- Rhythm classification.

Refer to `doc/qrs/ARCHITECTURE.md` for detailed microarchitecture documentation.

---

## 8. Control Path

The control path is implemented through processor-driven memory-mapped AXI transactions.

The VeeR EL2 processor executes firmware and accesses peripheral control and status registers.

Typical operations include:

1. Peripheral initialization.
2. Register configuration.
3. Enable/disable operations.
4. Status register readback.
5. Interrupt configuration.
6. Test-result storage in DMEM.

This allows the processor to coordinate the hardware accelerators while the dedicated datapaths perform sample-level processing.

---

## 9. Firmware Architecture

The `firmware/` directory contains the software required for processor-side verification.

### Firmware Components

- C application.
- RISC-V assembly startup code.
- Linker script.
- Makefile.
- Firmware generation scripts.
- HEX and VHX memory images.
- Assembly dumps.

### Firmware Functionality

The firmware exercises:

- Processor startup and instruction execution.
- IMEM and DMEM operations.
- UART configuration.
- GPIO configuration.
- Timer operation.
- FIR configuration.
- ADC control and status.
- SPI register access.
- QRS detector control.
- Peripheral readback and telemetry.

### Firmware Build Architecture

```text
       C / Assembly Source
                |
                v
        RISC-V GCC Toolchain
                |
                v
             ELF File
                |
                v
       HEX / VHX Generation
                |
                v
          Instruction Memory
                |
                v
          VeeR EL2 Processor
                |
                v
         AXI4 Interconnect
                |
                v
         Peripheral Control
```

Refer to `firmware/README.md` for detailed build instructions.

---

## 10. Verification Strategy

The project uses both directed SystemVerilog testbenches and UVM-based verification components.

### Verification Areas

| Test Area | Verification Objective |
|---|---|
| Reset and Boot | Verify processor startup and reset behaviour |
| Instruction Execution | Verify arithmetic, branching and instruction execution |
| Memory Access | Verify IMEM and DMEM read/write operations |
| AXI Protocol | Verify address decoding and channel handshakes |
| Arbitration | Verify concurrent master transactions |
| UART | Verify serial communication and register access |
| GPIO | Verify direction and data operations |
| Timer | Verify counting and interrupt functionality |
| FIR | Verify configuration and streaming interface |
| ADC | Verify sample capture and status |
| SPI | Verify register configuration and serial transfer |
| QRS | Verify ECG processing and R-peak detection |
| Interrupts | Verify PIC connectivity |
| Error Handling | Verify dummy-slave DECERR responses |
| ECG Pipeline | Verify integrated acquisition and processing |
| Reset Recovery | Verify system recovery after reset |

### UVM Environment

The repository includes UVM components such as:

- Agents.
- Drivers.
- Monitors.
- Sequencers.
- Sequence items.
- Sequences.
- Scoreboards.
- Virtual sequencer.
- Integrated environment.
- UVM testbench top.

The UVM implementation and connectivity documentation are available under:

`tb/uvm_cardioedge/`

---

## 11. Verification Results

The checked-in processor-side SoC verification report documents:

**18/18 tests passed with 0 reported errors** for the configuration described in that report.

The verification activities include:

- RISC-V processor boot.
- Instruction execution.
- Memory read/write integrity.
- AXI address mapping.
- AXI handshake verification.
- Dual-master arbitration.
- Peripheral register access.
- ECG acquisition and processing.
- Interrupt connectivity.
- Dummy-slave error handling.
- Reset recovery.
- Integrated system regression.

### Verification Evidence

The repository contains:

- Console execution logs.
- Waveform screenshots.
- Regression overview.
- Test-case analysis.
- UVM connectivity reports.
- Verification summary reports.

See:

`doc/CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md`

**Important:** The 18/18 result refers to the specific configuration and regression documented in that report. It should not be interpreted as an automatic PASS for every other testbench or subsequent RTL modification.

---

## 12. Repository Structure

```text
HONOURS_CBP_CARDIOEDGE/
|
|-- doc/
|   |-- README.md
|   |-- addressmapping.ods
|   |-- CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md
|   |-- CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md
|   |-- CARDIOEDGE_UVM_COMPLETE_CONNECTIVITY_REPORT.md
|   |-- CARDIOEDGE_UVM_CONFIGDB_CONNECTIVITY_AUDIT.md
|   |-- Combined_SoC_Features_DataPath_ControlPath.pdf
|   |-- CardioEdge_AXI4_Specification_v2.docx
|   |-- cardioedge_waveform_evidence/
|   |-- qrs/
|
|-- firmware/
|   |-- Makefile
|   |-- start.S
|   |-- cardioedge_test.c
|   |-- cardioedge.ld
|   |-- build_firmware.py
|   |-- generate_hex.sh
|   |-- firmware images
|
|-- rtl/
|   |-- ADC/
|   |-- Cores-VeeR-EL2/
|   |-- FIR/
|   |-- QRS/
|   |-- common/
|   |-- gpio/
|   |-- interconnect/
|   |-- riscv/
|   |-- spi/
|   |-- timer/
|   |-- uart/
|
|-- run_scripts_and_config/
|
|-- scripts/
|
|-- tb/
|   |-- Directed SystemVerilog Testbenches
|   |-- UVM Testbenches
|   |-- uvm_cardioedge/
|
|-- .gitmodules
|-- README.md
```

---

## 13. Tools and Technologies

| Category | Technology |
|---|---|
| HDL | Verilog, SystemVerilog |
| Processor | VeeR EL2 RISC-V |
| Architecture | RV32IMC |
| Interconnect | AXI4 |
| Streaming Interface | AXI4-Stream |
| Firmware | C, RISC-V Assembly |
| Simulation | Synopsys VCS |
| Waveform Analysis | Synopsys Verdi |
| Verification | SystemVerilog, UVM |
| Firmware Compiler | RISC-V GNU Toolchain |
| Version Control | Git, GitHub |
| Operating Environment | Linux |

---

## 14. Getting Started

### Clone the Repository

```bash
git clone --recurse-submodules https://github.com/Yashwanth20050906/HONOURS_CBP_CARDIOEDGE.git

cd HONOURS_CBP_CARDIOEDGE
```

### Initialize Submodules

The VeeR EL2 processor is included as a Git submodule.

If submodules were not initialized during cloning:

```bash
git submodule update --init --recursive
```

### Explore the Repository

```bash
ls
ls rtl
ls tb
ls firmware
ls doc
```

---

## 15. Firmware Compilation

A compatible RISC-V GNU toolchain is required.

Check compiler availability:

```bash
riscv64-unknown-elf-gcc --version
```

Navigate to the firmware directory:

```bash
cd firmware
```

Compile:

```bash
make
```

Other available Makefile targets include:

```bash
make hex
make vhx
make bin
make disassemble
make size
make clean
```

The documented processor target uses:

```text
-march=rv32imc
-mabi=ilp32
```

Refer to `firmware/README.md` for complete instructions.

---

## 16. RTL Simulation

The project uses Synopsys VCS for RTL simulation.

First identify the correct filelist for the intended testbench:

```bash
find . -name '*.f' -o -name 'filelist*'
```

Navigate to the appropriate simulation directory and compile using the matching filelist.

Example compilation:

```bash
vcs -full64 -sverilog -timescale=1ns/1ps \
    -debug_access+all -kdb \
    -f <selected_filelist.f> \
    -l compile.log
```

Run the simulation:

```bash
./simv -no_save -l sim.log
```

For UVM-based simulations, include the appropriate UVM compilation option:

```bash
vcs -full64 -sverilog -ntb_opts uvm \
    -timescale=1ns/1ps \
    -debug_access+all -kdb \
    -f <selected_uvm_filelist.f> \
    -l compile_uvm.log
```

**Note:** Use the filelist corresponding to the selected top module. The repository contains multiple integration stages and verification targets.

---

## 17. Waveform Analysis

Synopsys Verdi is used for waveform inspection and debugging.

Important signals to examine include:

- Processor reset and program counter.
- IFU instruction-fetch transactions.
- LSU read/write transactions.
- AXI address and data channels.
- AXI ready/valid handshakes.
- Interconnect arbitration.
- Peripheral register accesses.
- ADC sample-valid signals.
- FIR AXI4-Stream handshakes.
- QRS R-peak detection signals.
- Interrupt signals.
- Firmware telemetry.

Waveform screenshots and test-case analysis are available under:

`doc/cardioedge_waveform_evidence/`

---

## 18. Project Documentation

| Document | Description |
|---|---|
| `doc/README.md` | Detailed project documentation |
| `doc/CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md` | RISC-V SoC verification report |
| `doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md` | Test-case and waveform analysis |
| `doc/CARDIOEDGE_UVM_COMPLETE_CONNECTIVITY_REPORT.md` | UVM connectivity report |
| `doc/CARDIOEDGE_UVM_CONFIGDB_CONNECTIVITY_AUDIT.md` | UVM configuration audit |
| `doc/addressmapping.ods` | Project address mapping |
| `doc/qrs/ARCHITECTURE.md` | QRS microarchitecture |
| `firmware/README.md` | Firmware architecture and build guide |
| `doc/Combined_SoC_Features_DataPath_ControlPath.pdf` | System features and datapath/control-path documentation |

---

## 19. Future Improvements

Potential future development activities include:

- Further integration of the RISC-V firmware and peripheral subsystem.
- Expanded UVM functional coverage.
- Additional AXI protocol corner-case verification.
- More comprehensive ECG dataset validation.
- Performance characterization of the FIR and QRS accelerators.
- Interrupt-driven firmware execution.
- Power and area estimation.
- FPGA prototyping and hardware demonstration.

---

## 20. Acknowledgements

- [CHIPS Alliance – VeeR EL2 RISC-V Core](https://github.com/chipsalliance/Cores-VeeR-EL2)
- [RISC-V International](https://riscv.org/)
- [Arm AMBA Specifications](https://developer.arm.com/Architectures/AMBA)

---

<p align="center">
  <b>CARDIOEDGE</b><br>
  RISC-V SoC Integration | ECG Signal Processing | RTL Design and Verification
</p>
