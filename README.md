# CARDIOEDGE — RISC-V ECG Processing System-on-Chip

CARDIOEDGE is an RTL-level healthcare SoC project that integrates a **Western Digital VeeR EL2 RISC-V processor**, a shared **AXI4 interconnect**, on-chip instruction/data memories, and dedicated peripherals for ECG acquisition and processing.

The system combines memory-mapped control and status registers with streaming signal-processing hardware. The current repository includes the peripheral integration design, processor-side SoC RTL, firmware sources/build artifacts, simulation testbenches, and verification logs.

> **Scope:** RTL development and simulation verification. This repository does not claim ASIC tape-out or silicon validation.

## Highlights

- VeeR EL2 processor configured for the RV32IMC instruction set.
- Shared **3-master × 18-slave AXI4 interconnect** for instruction fetch, data access, peripheral access, and reserved/dummy-slave handling.
- Separate IFU and LSU **64-bit-to-32-bit AXI adapters**.
- 64 KiB instruction memory (IMEM) and 64 KiB data memory (DMEM).
- AXI4 / AXI4-Lite integration, including the common AXI4-to-AXI4-Lite bridge where used by the peripheral subsystem.
- UART, GPIO, Timer, FIR, ADC, SPI, and QRS detection IP.
- ECG test stimulus and end-to-end ADC/FIR/QRS pipeline verification.
- C firmware and a RISC-V toolchain-based build flow.
- Synopsys VCS simulation with optional waveform debugging in Verdi.

## Architecture

```text
                   +--------------------------+
                   |      VeeR EL2 Core       |
                   |       RV32IMC             |
                   +-------------+------------+
                                 |
                    +------------+------------+
                    |                         |
               IFU AXI64                  LSU AXI64
                    |                         |
              64-to-32 Adapter         64-to-32 Adapter
                    |                         |
                    +------------+------------+
                                 |
                     +-----------v-----------+
                     | Shared AXI4 Fabric    |
                     |   3 masters × 18      |
                     | address-decoded slaves|
                     +-----------+-----------+
                                 |
      +-------------+-------------+-------------+-------------+
      |             |             |             |             |
    IMEM          DMEM          UART          GPIO          Timer
   64 KiB        64 KiB                                      |
      |                                                     FIR
      |                                                      |
      |                         ADC → FIR stream → QRS Detector
      |                                                      |
      +--------------------- SPI ----------------------------+
```

The 3×18 fabric has 18 slave-side destinations. The seven active CARDIOEDGE peripheral blocks and the IMEM/DMEM occupy their documented ports; remaining ports are reserved or connected to dummy-slave responses in the relevant integration top. The exact instantiated routing and port assignments are defined in the RTL and the verification filelists.

## System Components

| Block | Purpose | Key functions |
|---|---|---|
| **VeeR EL2 RISC-V** | Embedded CPU | Executes firmware, initiates instruction fetches and load/store operations |
| **AXI4 interconnect** | Shared on-chip fabric | Address decode, arbitration, independent master access and response routing |
| **AXI 64-to-32 adapters** | Width adaptation | Connects the processor's 64-bit AXI interfaces to the 32-bit SoC fabric |
| **IMEM** | Instruction memory | 64 KiB region beginning at `0x00000000` |
| **DMEM** | Data memory | 64 KiB region beginning at `0x00010000` |
| **UART** | Serial telemetry | Memory-mapped configuration and serial transmit/receive |
| **GPIO** | Digital input/output | Direction, input/output data, atomic set/clear/toggle and interrupt registers |
| **Timer** | Time/event generation | Counter, load/control, capture/PWM-related functions and interrupt status |
| **ADC controller** | Sample acquisition | Sampling control, sample/status registers and FIFO buffering |
| **FIR filter** | Digital signal filtering | Memory-mapped configuration and AXI4-Stream sample processing |
| **SPI controller** | Serial peripheral bus | Register-controlled SPI transfers and external serial pins |
| **QRS detector** | ECG analysis | ECG sample input, R-peak processing and cardiac interval/rhythm-related outputs |
| **Dummy slaves** | Defensive routing | Error responses for unused/unimplemented address destinations |

## Current RTL Entry Points

### Peripheral integration top

`rtl/soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv`

This is the established peripheral integration top. Preserve it as the baseline when working on the separate processor-side integration.

### RISC-V integration RTL

| File | Role |
|---|---|
| `rtl/riscv/cardioedge_veer_wrapper.sv` | Thin VeeR EL2 wrapper exposing IFU and LSU AXI interfaces |
| `rtl/riscv/axi_64to32_adapter.sv` | Processor-to-fabric data-width adapter |
| `rtl/riscv/axi_imem_slave.sv` | AXI-accessible instruction memory |
| `rtl/riscv/axi_dmem_slave.sv` | AXI-accessible data memory |
| `rtl/riscv/cardioedge_veer_soc_top.sv` | Earlier / staged VeeR integration top |
| `rtl/riscv/cardioedge_cpu_soc_top.sv` | CPU SoC top used by the comprehensive regression environment |

### Interconnect and shared AXI support

```text
rtl/interconnect/axi_interconnect.v
rtl/interconnect/axi_interconnect_wrap_3x14.v
rtl/interconnect/axi_interconnect_wrap_3x18.v
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v

rtl/common/axi4_to_axi4lite_bridge.sv
rtl/common/axi4lite_slave_adapter.sv
rtl/common/axi_dummy_slave.sv
```

The repository retains both the 3×14 wrapper and the 3×18 wrapper. The comprehensive RISC-V SoC verification filelist selects the **3×18 wrapper**. Do not infer that every wrapper or top is interchangeable: use the filelist matching the top-level testbench being run.

## Address Map

The project address-map document is maintained at **[`doc/addressmapping.ods`](doc/addressmapping.ods)**. Use this file as the designated project source of truth for the documented peripheral address allocation; do not use historical README tables or stale logs to redefine the map.

The current processor-side comprehensive simulation reports these active regions:

| Destination | Base address | Address range | Size |
|---|---:|---:|---:|
| UART | `0x40000000` | `0x40000000–0x40000FFF` | 4 KiB |
| GPIO | `0x40002000` | `0x40002000–0x40002FFF` | 4 KiB |
| Timer | `0x40004000` | `0x40004000–0x40004FFF` | 4 KiB |
| FIR control | `0x4000C000` | `0x4000C000–0x4000CFFF` | 4 KiB |
| ADC | `0x4000E000` | `0x4000E000–0x4000EFFF` | 4 KiB |
| SPI | `0x40010000` | `0x40010000–0x40010FFF` | 4 KiB |
| QRS detector | `0x40012000` | `0x40012000–0x40012FFF` | 4 KiB |
| IMEM | `0x00000000` | `0x00000000–0x0000FFFF` | 64 KiB |
| DMEM | `0x00010000` | `0x00010000–0x0001FFFF` | 64 KiB |

**Important:** The above table documents the active CPU/SoC simulation destinations. Reserved, placeholder, and dummy-slave locations must be interpreted from the designated ODS address map and the selected top-level RTL. The Watchdog is not an active CARDIOEDGE peripheral in the intended feature set; a legacy placeholder at its old slot, if present in a test configuration, should not be treated as a connected Watchdog IP.

## ECG Data Path

The main biomedical processing path is designed around acquisition, filtering, and cardiac event analysis:

```text
ECG sample stimulus / ADC input
              |
              v
      ADC acquisition logic
              |
              v
       Sample FIFO / stream
              |
              v
       FIR filtering engine
              |
              v
       QRS detection pipeline
              |
              v
   R-peak / RR / heart-rate-related outputs
```

The FIR engine has a **memory-mapped control path** and a separate **AXI4-Stream datapath**. Firmware can configure the filter through registers, while sample movement through the stream must be driven by the hardware/testbench data path. The QRS wrapper also provides a memory-mapped control/status interface and an ECG sample input register in the CPU integration design.

## Firmware

Firmware sources and build support are located in `firmware/`.

Key files include:

- `firmware/cardioedge_test.c` — C-level peripheral and SoC test program.
- `firmware/start.S` — startup assembly.
- `firmware/cardioedge.ld` — linker script.
- `firmware/Makefile` — firmware build targets.
- `firmware/build_firmware.py` and `firmware/generate_hex.sh` — helper scripts for producing simulation images.
- `firmware/tb_cardioedge_firmware.sv` — firmware-oriented simulation testbench.
- `firmware/filelist_cardioedge_firmware.f` — firmware simulation filelist.

The firmware Makefile targets RV32IMC with the ILP32 ABI.

### Build firmware

Install or load a compatible RISC-V GCC toolchain that provides `riscv64-unknown-elf-gcc`, `objcopy`, `objdump`, and `size` (or configure the equivalent toolchain available in your environment).

```bash
cd firmware
make
```

Useful individual targets:

```bash
make hex
make vhx
make bin
make disassemble
make size
make clean
```

If the compiler is not in `PATH`, the Makefile attempts to use `build_firmware.py`. Check that script's requirements and output before running the RTL simulation.

## Simulation and Verification

The project uses **Synopsys VCS** for compilation and simulation. **Synopsys Verdi** can be used for waveform and database-based debugging when enabled in the local environment.

### Main testbenches

| Testbench | Scope |
|---|---|
| `tb/tb_cardioedge_comprehensive_soc.sv` | Comprehensive VeeR/SoC integration regression |
| `tb/tb_cardioedge_riscv_soc.sv` | Earlier RISC-V integration testbench |
| `tb/tb_cardioedge_firmware.sv` or the firmware-local equivalent | Firmware execution and peripheral exercise |
| `tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv` | Peripheral integration top |
| `tb/tb_axi_interconnect_wrap_3x18.sv` | 3×18 interconnect testing |
| `tb/tb_gpio_axi.sv` | GPIO standalone/integration tests |
| `tb/tb_timer_axi.sv` | Timer tests |
| `tb/tb_fir_top.v` | FIR tests |
| `tb/qrs_axi4_wrapper_tb.sv` | QRS wrapper verification |
| `tb/uart_standalone_tb.sv` | UART tests |

### Comprehensive regression

The current tracked comprehensive simulation log is `run/sim_comprehensive.log`. Its recorded VCS run on **14 October 2026** reports:

- **21 tests passed, 0 failed** in the comprehensive testbench.
- Reset and VeeR instruction-fetch checks.
- IMEM and DMEM access and data-integrity checks.
- CPU-driven access to UART, GPIO, Timer, FIR, ADC, SPI, and QRS.
- ECG sample processing through acquisition/filtering stages.
- Dummy-slave DECERR handling and address-boundary checks.
- Interrupt routing checks, IFU/LSU master concurrency, and AXI backpressure/integrity checks.
- Warm-reset repeatability and final execution completion checks.

This pass summary applies specifically to the regression recorded in `run/sim_comprehensive.log`; it should not be interpreted as every historical testbench, alternate top module, or every firmware invocation passing. Other logs in `run/` capture earlier or different development stages and may include failures.

### Run the comprehensive simulation

First set up Synopsys VCS and the environment required by your lab machine. From the `run/` directory, compile the comprehensive filelist:

```bash
cd run
vcs -full64 -sverilog -timescale=1ns/1ps \\
    -debug_access+all -kdb \\
    -f filelist_cardioedge_comprehensive_soc.f \\
    -l compile_comprehensive.log
```

Then run the generated simulation executable:

```bash
./simv_comprehensive -no_save -l sim_comprehensive.log
```

The exact VCS options and executable path can vary by installation. The checked-in log and filelist are the references for the recorded run.

### Other integration filelists

```text
run/filelist_cardioedge_comprehensive_soc.f
run/filelist_cardioedge_riscv_soc.f
run/filelist_uart_qrs_spi_fir_adc_gpio_timer_integration_BRIDGED.f
run/filelist_veer_phase4.f
run/filelist_axi_interconnect_wrap_3x18.f
```

Select the filelist according to the intended top module. Avoid combining source lists for multiple top modules into one run unless the simulation flow explicitly requires it.

## Repository Layout

```text
HONOURS_CBP_CARDIOEDGE/
├── doc/
│   ├── addressmapping.ods
│   ├── CardioEdge_AXI4_Specification_v2.docx
│   ├── Combined_SoC_Features_DataPath_ControlPath.pdf
│   └── CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md
├── firmware/
│   ├── Makefile
│   ├── start.S
│   ├── cardioedge_test.c
│   ├── cardioedge.ld
│   ├── build_firmware.py
│   ├── generate_hex.sh
│   └── filelist_cardioedge_firmware.f
├── rtl/
│   ├── ADC/
│   ├── Cores-VeeR-EL2/       # Git submodule
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
│   ├── filelist_cardioedge_comprehensive_soc.f
│   ├── filelist_cardioedge_riscv_soc.f
│   ├── filelist_uart_qrs_spi_fir_adc_gpio_timer_integration_BRIDGED.f
│   └── sim_comprehensive.log
└── tb/
    ├── tb_cardioedge_comprehensive_soc.sv
    ├── tb_cardioedge_riscv_soc.sv
    ├── tb_axi_interconnect_wrap_3x18.sv
    └── peripheral-specific testbenches
```

This is a functional overview; consult the current repository tree for the complete set of RTL, testbench, and generated simulation files.

## Tools

- Verilog and SystemVerilog
- C and RISC-V assembly
- Synopsys VCS
- Synopsys Verdi (optional)
- RISC-V GNU toolchain
- Linux and Git

## Development Status

The repository contains the established peripheral integration design and a processor-side SoC integration with VeeR EL2, IMEM/DMEM, AXI adapters, the 3×18 fabric, and the comprehensive regression environment. The logged comprehensive testbench run reports **21/21 tests passing** on 14 October 2026.

Continue to keep the legacy working peripheral top separate from processor-side integration changes, use the designated address-map document, and verify the exact top/filelist combination selected for each simulation.

## References

- [CARDIOEDGE repository](https://github.com/Yashwanth20050906/HONOURS_CBP_CARDIOEDGE)
- [VeeR EL2 core](https://github.com/chipsalliance/Cores-VeeR-EL2)
- [Project address map](doc/addressmapping.ods)
- [RISC-V SoC verification report](doc/CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md)
