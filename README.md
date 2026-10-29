# CARDIOEDGE — RISC-V ECG Processing System-on-Chip

CARDIOEDGE is an RTL-level healthcare System-on-Chip (SoC) project integrating a **Western Digital VeeR EL2 RISC-V processor**, a shared AXI4 interconnect, on-chip instruction and data memories, and dedicated peripherals for ECG acquisition, digital signal processing, and cardiac event detection.

The project combines processor-driven memory-mapped peripheral control with an ECG processing pipeline using an ADC controller, FIR filter, and QRS detection engine. It includes hardware/software co-verification, RISC-V firmware, SystemVerilog testbenches, and waveform-based verification evidence.

**Project scope:** RTL design, hardware integration, firmware development, simulation, and verification. This project does not claim ASIC tape-out or post-silicon validation.

## Table of Contents

- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [IP Blocks and Responsibilities](#ip-blocks-and-responsibilities)
- [AXI4 Interconnect and Address Map](#axi4-interconnect-and-address-map)
- [ECG Processing Data Path](#ecg-processing-data-path)
- [Hardware/Software Co-Verification](#hardwaresoftware-co-verification)
- [Firmware Mailbox and Telemetry](#firmware-mailbox-and-telemetry)
- [18-Test Verification Suite](#18-test-verification-suite)
- [Waveform and Console Evidence](#waveform-and-console-evidence)
- [Repository Structure](#repository-structure)
- [Tools and Technologies](#tools-and-technologies)
- [Firmware Build](#firmware-build)
- [RTL Simulation and Verification](#rtl-simulation-and-verification)
- [Verification Results](#verification-results)
- [References](#references)

## Key Features

- **RISC-V processor:** Western Digital VeeR EL2 configured for RV32IMC.
- **AXI4 interconnect:** Shared 3-master × 18-slave fabric for processor instruction fetches, data transactions, memory access, and peripheral communication.
- **AXI width conversion:** Separate IFU and LSU 64-bit-to-32-bit adapters.
- **On-chip memories:** 64 KiB instruction memory (IMEM) and 64 KiB data memory (DMEM).
- **Peripheral subsystem:** UART, GPIO, Timer, ADC, FIR, SPI, and QRS detection IPs.
- **Biomedical processing:** ECG acquisition, sample buffering, digital filtering, and QRS/R-peak analysis.
- **Firmware:** C and RISC-V assembly with generated firmware images for processor-driven verification.
- **Hardware/software co-verification:** CPU execution, AXI transactions, peripheral register readback, firmware telemetry, and interrupt connectivity.
- **18-test verification plan:** Dedicated architectural tests with console logs and waveform evidence.
- **Simulation debugging:** Synopsys VCS and Synopsys Verdi.

## System Architecture

```text
                  +-----------------------------+
                  |       VeeR EL2 RISC-V       |
                  |          RV32IMC             |
                  +--------------+--------------+
                                 |
                   +-------------+-------------+
                   |                           |
              IFU AXI interface           LSU AXI interface
                   |                           |
             64-bit to 32-bit            64-bit to 32-bit
                 adapter                     adapter
                   |                           |
                   +-------------+-------------+
                                 |
                  +--------------v--------------+
                  |       Shared AXI4 Fabric    |
                  |       3 Masters × 18        |
                  |      Slave Destinations     |
                  +--------------+--------------+
                                 |
        +------------+-----------+----------+-----------+
        |            |           |          |           |
      IMEM          DMEM        UART       GPIO       Timer
     64 KiB        64 KiB
                                                        |
                                                +-------v-------+
                                                | ADC Controller|
                                                +-------+-------+
                                                        |
                                                +-------v-------+
                                                | Sample Buffer |
                                                +-------+-------+
                                                        |
                                                +-------v-------+
                                                |  FIR Filter   |
                                                +-------+-------+
                                                        |
                                                +-------v-------+
                                                | QRS Detector  |
                                                +-------+-------+
                                                        |
                                                R-Peak / Rhythm
                                                  Information

                    Additional peripheral: SPI
```

The processor uses the IFU interface for instruction fetching and the LSU interface for data loads, stores, and memory-mapped peripheral accesses. AXI width adapters connect the processor interfaces to the 32-bit SoC fabric.

The interconnect provides 18 slave-side destinations. In the documented processor-side integration, M00–M06 are assigned to the seven active peripheral IPs, M07 to IMEM, M08 to DMEM, and M09–M17 to dummy-slave or reserved destinations.

The exact routing and address decoding depend on the selected top module and compilation filelist.

## IP Blocks and Responsibilities

| IP Block | Primary responsibility |
|---|---|
| VeeR EL2 RISC-V | Executes firmware and controls the SoC. |
| AXI4 interconnect | Routes requests and responses between masters and slave destinations. |
| IFU/LSU AXI adapters | Convert processor-side AXI transactions from 64-bit to 32-bit. |
| IMEM | Stores the processor instruction image. |
| DMEM | Stores runtime data, test results, and firmware telemetry. |
| UART | Serial communication and firmware diagnostic output. |
| GPIO | Digital input/output, direction control, and interrupt-related registers. |
| Timer | Counter operation, load/control registers, timing events, and interrupts. |
| ADC controller | Sample acquisition, control/status registers, and FIFO-related functionality. |
| FIR filter | Digital filtering with memory-mapped configuration and AXI4-Stream data transfer. |
| SPI controller | Register-controlled serial peripheral communication. |
| QRS detector | ECG analysis and R-peak-related detection/status. |
| Dummy slaves | Return defensive error responses for unsupported or unmapped destinations. |

## AXI4 Interconnect and Address Map

The project address-map document is maintained at [`doc/addressmapping.ods`](doc/addressmapping.ods). Use the designated project document together with the selected top-level RTL to determine the intended address allocation.

The following table records the active CPU/SoC regions documented in the processor-side verification setup.

| Slave | Peripheral / Memory | Base address | Address range | Size |
|---|---|---|---|---|
| M00 | UART | `0x40000000` | `0x40000000–0x40000FFF` | 4 KiB |
| M01 | GPIO | `0x40002000` | `0x40002000–0x40002FFF` | 4 KiB |
| M02 | Timer | `0x40004000` | `0x40004000–0x40004FFF` | 4 KiB |
| M03 | FIR | `0x4000C000` | `0x4000C000–0x4000CFFF` | 4 KiB |
| M04 | ADC | `0x4000E000` | `0x4000E000–0x4000EFFF` | 4 KiB |
| M05 | SPI | `0x40010000` | `0x40010000–0x40010FFF` | 4 KiB |
| M06 | QRS detector | `0x40012000` | `0x40012000–0x40012FFF` | 4 KiB |
| M07 | Instruction memory | `0x00000000` | `0x00000000–0x0000FFFF` | 64 KiB |
| M08 | Data memory | `0x00010000` | `0x00010000–0x0001FFFF` | 64 KiB |
| M09–M17 | Dummy/reserved destinations | Configuration-dependent | See RTL and address-map document | Configuration-dependent |

**Address-map note:** Watchdog is not an active peripheral in the intended CARDIOEDGE feature set. Older configurations may retain a placeholder at its previous slot. Do not interpret that placeholder as an instantiated Watchdog IP.

The interconnect supports:

- Address decoding and transaction routing.
- Arbitration between active master interfaces.
- AXI ready/valid handshakes.
- Read and write response routing.
- Concurrent instruction-fetch and data-access transactions.
- Error responses for unsupported destinations.
- Verification of address boundaries and protocol integrity.

## ECG Processing Data Path

The main biomedical processing path is designed around sample acquisition, digital filtering, and cardiac event detection.

```text
ECG Input / Test Stimulus
           |
           v
    ADC Acquisition
           |
           v
   Sample FIFO / Buffer
           |
           v
     FIR Filtering
           |
           v
    QRS Detection
           |
           v
 R-Peak / RR-Interval /
 Heart-Rate-Related Results
```

### Control path

The processor or testbench configures peripheral registers using memory-mapped AXI transactions. Control and status operations include peripheral initialization, enable/disable operations, register readback, and interrupt-related configuration.

### Data path

ECG samples enter the acquisition path and are passed through buffering and digital filtering before QRS processing. The FIR engine has a memory-mapped control interface and an AXI4-Stream datapath.

### Verification path

The verification environment checks processor execution, memory integrity, AXI transactions, peripheral register access, stream handshakes, interrupt connectivity, and system-level processing behaviour.

## Hardware/Software Co-Verification

CARDIOEDGE uses both RTL testbenches and firmware-driven testing.

The processor-side verification setup uses a program preloaded into IMEM to exercise:

- Reset release and initial instruction fetch.
- RV32 instruction execution, arithmetic, branching, and loops.
- IMEM and DMEM read/write operations.
- CPU-driven UART, GPIO, Timer, FIR, ADC, SPI, and QRS register access.
- Peripheral status readback and memory storage of test results.
- IFU/LSU concurrent activity through the shared interconnect.
- Dummy-slave error responses and unsupported-address handling.
- Interrupt signal connectivity to the VeeR programmable interrupt controller.
- ECG processing pipeline stimulus and interface handshakes.

Firmware sources and build artifacts are maintained in `firmware/`.

## Firmware Mailbox and Telemetry

The latest firmware updates add a mailbox in DMEM for tracking the execution of individual tests and exposing status information to the verification environment.

| Mailbox register | Address | Purpose |
|---|---|---|
| Test ID | `0x00010060` | Identifies the currently executing test. |
| Execution state | `0x00010064` | Indicates the test execution phase. |
| Test status | `0x00010068` | Reports initialization, pass, fail, or blocked status. |
| Extra telemetry | `0x0001006C` | Holds additional test-specific information. |

### Execution state encoding

| Value | Meaning |
|---|---|
| `0` | IDLE |
| `1` | RUNNING |
| `2` | CHECKING |
| `3` | DONE |

### Test status encoding

| Value | Meaning |
|---|---|
| `0` | INIT |
| `1` | PASS |
| `2` | FAIL |
| `3` | BLOCKED |

The firmware mailbox supports test progress tracking and additional telemetry during simulation and waveform inspection. The meaning of the extra telemetry field depends on the test being executed.

Relevant implementation files include:

- `firmware/cardioedge_test.c`
- `firmware/cardioedge_test.s`
- `firmware/cardioedge_test.hex`
- `firmware/cardioedge_test.vhx`
- `firmware/cardioedge_test.dump`

## 18-Test Verification Suite

The latest repository update includes an 18-test verification plan documented in `doc/CardioEdge_Project_Test_Cases_Condensed.xlsx`.

The detailed test-by-test explanation, waveform analysis, and console correlation are available in [`doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md`](doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md).

| Test ID | Verification test | Primary objective |
|---|---|---|
| TC-01 | RISC-V CPU Boot and SoC Reset Bring-Up | Verify reset, initial instruction fetch, and clean startup. |
| TC-02 | Data Memory and RV32I Execution | Verify memory operations, arithmetic, branches, loops, and width adaptation. |
| TC-03 | AXI4 Address Mapping and Handshake Protocol | Verify address decoding, channel handshakes, and protocol integrity. |
| TC-04 | Dual-Master Arbitration | Verify concurrent IFU/LSU activity and arbitration behaviour. |
| TC-05 | UART Subsystem | Verify UART register access and serial communication. |
| TC-06 | GPIO Subsystem | Verify input/output, direction control, and bit-level operations. |
| TC-07 | Timer Subsystem | Verify timer counting, expiration, and interrupt-related behaviour. |
| TC-08 | FIR Filter | Verify configuration and numerical output against the reference/golden model. |
| TC-09 | ADC Controller | Verify sample capture, status, and overrun-related handling. |
| TC-10 | SPI Controller | Verify configuration and serial transfer behaviour. |
| TC-11 | QRS Detection | Verify ECG processing and R-peak detection behaviour. |
| TC-12 | Cardiac Rhythm Classification | Verify rhythm-related processing and heart-rate extraction. |
| TC-13 | Address Boundaries and Dummy-Slave DECERR | Verify invalid or unsupported accesses and error responses. |
| TC-14 | Interrupt Architecture and PIC Routing | Verify interrupt connectivity and interrupt-related behaviour. |
| TC-15 | CPU-Driven Peripheral Integration | Verify firmware-controlled peripheral transactions and telemetry. |
| TC-16 | End-to-End ECG Processing Pipeline | Verify acquisition, filtering, and QRS datapath integration. |
| TC-17 | Reset Recovery | Verify system and peripheral reinitialization after reset. |
| TC-18 | Comprehensive System Regression | Check integrated system behaviour and final regression status. |

The table describes the verification plan; individual test outcomes should be taken from the corresponding recorded console output and detailed analysis.

## Waveform and Console Evidence

The latest update includes dedicated waveform screenshots and a consolidated console transcript to support verification review and viva demonstrations.

### Evidence files

- [`doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md`](doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md) — detailed test descriptions, waveform interpretation, console correlation, and verification notes.
- [`doc/console_output`](doc/console_output) — recorded console transcript for the TC-01 through TC-18 suite.
- [`doc/CardioEdge_Project_Test_Cases_Condensed.xlsx`](doc/CardioEdge_Project_Test_Cases_Condensed.xlsx) — condensed verification test plan.
- [`doc/cardioedge_waveform_evidence/`](doc/cardioedge_waveform_evidence/) — individual waveform screenshots and the regression overview.

The waveform evidence includes:

- Overall regression overview.
- Reset and processor boot.
- DMEM and arithmetic execution.
- AXI address mapping and handshakes.
- Dual-master arbitration.
- UART and GPIO operations.
- Timer counting and interrupt-related behaviour.
- FIR configuration and ADC sample capture.
- SPI transfer and QRS detection.
- Rhythm classification.
- Dummy-slave DECERR handling.
- Interrupt/PIC routing.
- Firmware telemetry.
- End-to-end ECG pipeline.
- Reset recovery.
- Regression scorecard.

The detailed analysis document explains how to correlate test IDs, console messages, firmware mailbox values, and relevant waveform signals.

### Waveform databases

The detailed verification report identifies the following waveform database naming conventions:

- `run/cardioedge_regression.fsdb` — full regression waveform.
- `run/cardioedge_tc01.fsdb` through `run/cardioedge_tc18.fsdb` — dedicated per-test waveform files.

Check the current repository tree and simulation outputs to confirm which waveform databases are present in your checkout.

## Repository Structure

```text
HONOURS_CBP_CARDIOEDGE/
├── doc/
│   ├── addressmapping.ods
│   ├── CardioEdge_AXI4_Specification_v2.docx
│   ├── Combined_SoC_Features_DataPath_ControlPath.pdf
│   ├── CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md
│   ├── CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md
│   ├── CardioEdge_Project_Test_Cases_Condensed.xlsx
│   ├── console_output
│   └── cardioedge_waveform_evidence/
├── firmware/
│   ├── Makefile
│   ├── start.S
│   ├── cardioedge_test.c
│   ├── cardioedge_test.s
│   ├── cardioedge_test.hex
│   ├── cardioedge_test.vhx
│   ├── cardioedge_test.dump
│   ├── cardioedge_test.elf
│   ├── cardioedge.ld
│   └── firmware build and image-generation scripts
├── rtl/
│   ├── ADC/
│   ├── Cores-VeeR-EL2/
│   ├── FIR/
│   ├── QRS/
│   ├── common/
│   ├── gpio/
│   ├── interconnect/
│   ├── riscv/
│   ├── spi/
│   ├── timer/
│   ├── uart/
│   └── soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv
├── run/
│   └── simulation filelists, logs, and generated artifacts
└── tb/
    └── SystemVerilog testbenches
```

This is a high-level overview. Consult the repository tree for the complete list of source files, filelists, and generated artifacts.

## Tools and Technologies

- **HDL:** Verilog and SystemVerilog
- **Firmware:** C and RISC-V assembly
- **Processor:** Western Digital VeeR EL2 RISC-V
- **Bus architecture:** AXI4 and AXI4-Lite where applicable
- **Simulation:** Synopsys VCS
- **Waveform debugging:** Synopsys Verdi
- **Firmware toolchain:** RISC-V GNU toolchain
- **Development environment:** Linux and Git

## Firmware Build

Firmware sources are maintained under `firmware/`.

A compatible RISC-V GNU toolchain is required, including `riscv64-unknown-elf-gcc` and the associated binary utilities, or an equivalent configured toolchain.

From the repository root:

```bash
cd firmware
make
```

Depending on the available Makefile targets, useful commands include:

```bash
make hex
make vhx
make bin
make disassemble
make size
make clean
```

Review the build output and generated memory image before using it in simulation. The exact build targets depend on the current Makefile and toolchain configuration.

## RTL Simulation and Verification

The processor-side verification report identifies `run/filelist_cardioedge_riscv_soc.f` as the filelist for the RISC-V SoC testbench.

Set up the Synopsys environment for your machine and change to the `run/` directory.

### Compile the RISC-V SoC testbench

```bash
cd run

vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \
    -debug_access+all -kdb \
    -f filelist_cardioedge_riscv_soc.f \
    -l compile.log
```

### Run the simulation

```bash
./simv -no_save -l sim.log
```

The generated executable name and available options may vary according to the filelist and local VCS setup.

Use the matching filelist for the intended top module. The repository contains multiple integration stages, including the established peripheral integration top and processor-side integration. Do not combine filelists for different top modules unless required by the simulation flow.

### Inspect waveforms

Open the relevant FSDB database in Synopsys Verdi and correlate the selected test case with:

- IFU instruction-fetch addresses and responses.
- LSU read/write transactions.
- AXI address, valid, ready, and response signals.
- Interconnect master arbitration.
- Peripheral control/status registers.
- ADC-to-FIR-to-QRS data movement.
- Interrupt and PIC connectivity.
- Firmware mailbox test ID, state, and status.
- Reset assertion and recovery.

Refer to the waveform-analysis document for test-specific signals and interpretation.

## Verification Results

The repository contains a processor-side RISC-V SoC verification report documenting an earlier **18/18 passing regression**. The latest October 29 update adds the condensed 18-test plan, detailed test-case analysis, waveform evidence, console transcript, and firmware mailbox instrumentation.

These are distinct artifacts: the earlier regression summary should not automatically be treated as proof that every newly documented test case or every firmware execution has passed. Use the latest console transcript and test-case analysis to establish the result for each specific test.

The project verification covers processor boot, memory access, peripheral transactions, AXI protocol integrity, concurrent bus activity, ECG datapath checks, interrupt connectivity, error handling, and reset recovery.

## Development Status

CARDIOEDGE brings together:

- A VeeR EL2 RISC-V processor and shared 3×18 AXI4 fabric.
- Dedicated instruction and data memories.
- Seven active peripheral IPs: UART, GPIO, Timer, ADC, FIR, SPI, and QRS detector.
- A firmware-driven peripheral control path and ECG processing datapath.
- An 18-test verification plan with console and waveform evidence.
- Firmware mailbox telemetry for test execution monitoring.

The current project focus is RTL-level integration and verification, with documented simulation evidence for the processor-side SoC.

## References

- [CARDIOEDGE GitHub Repository](https://github.com/Yashwanth20050906/HONOURS_CBP_CARDIOEDGE)
- [Latest Repository Update](https://github.com/Yashwanth20050906/HONOURS_CBP_CARDIOEDGE/commit/a5b701e9dcaed207019eaefcc1efca23e45793f3)
- [VeeR EL2 RISC-V Core](https://github.com/chipsalliance/Cores-VeeR-EL2)
- [Project Address Map](doc/addressmapping.ods)
- [RISC-V SoC Verification Report](doc/CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md)
- [Test-Case Waveform and Console Analysis](doc/CARDIOEDGE_TESTCASE_WAVEFORM_AND_CONSOLE_ANALYSIS.md)
- [Condensed Verification Test Plan](doc/CardioEdge_Project_Test_Cases_Condensed.xlsx)

---

*CARDIOEDGE — RTL Integration, ECG Signal Processing, and RISC-V SoC Verification.*
