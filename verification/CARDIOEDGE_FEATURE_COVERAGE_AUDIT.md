# CARDIOEDGE RISC-V SoC — Complete Feature and Test Coverage Verification Audit

**Project Root**: `/home/student/Documents/HONOURS_CBP_CARDIOEDGE`  
**Target SoC**: Western Digital VeeR EL2 Core (RV32IMC) + Shared Group 3×18 AXI4 Interconnect Fabric + 7 Peripherals (UART, GPIO, Timer, FIR, ADC, SPI, QRS)  
**Audit Date**: October 12, 2026  
**Auditor**: Antigravity Verification Engine  
**Audit Scope**: Strict Read-Only Audit of RTL Source, Interconnect Architecture, Address Mapping, Testbenches, Firmware, Makefiles, Filelists, and Simulation Execution Logs.

---

## 1. Executive Summary

A comprehensive, evidence-based verification audit of the **CARDIOEDGE RISC-V System-on-Chip (SoC)** repository was conducted. The project integrates an open-source Western Digital VeeR EL2 processor core (RV32IMC) with a 3-master × 18-slave AXI4 interconnect fabric, dedicated biomedical hardware (QRS detection engine, 32-tap FIR filter, ADC acquisition controller), and standard embedded microcontroller peripherals (UART, GPIO, 32-bit Timer, SPI).

### Core Findings:
1. **Authoritative 18-Test Integration Regression Baseline**:
   - The primary integration testbench [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv) was compiled via [`run/filelist_cardioedge_riscv_soc.f`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/filelist_cardioedge_riscv_soc.f) using Synopsys VCS U-2023.03 and executed to completion.
   - Simulation log evidence in [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log) (timestamp: *Wed Oct 7 14:32:59 2026*) confirms that the simulation completed at `73,090,000 ps` (`73.09 us`) with **18/18 tests reporting `[PASS]` and 0 cumulative errors**.
   - An earlier simulation run captured in [`run/sim_cardioedge_riscv.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_cardioedge_riscv.log) (*Oct 7 10:57:57 2026*) had failed due to a watchdog timeout at `2,000,000,000 ps` (2 ms) because of an AXI 64-to-32 adapter address bit masking defect and UART read deadlock, both of which were subsequently corrected in the RTL.

2. **Verification Depth vs. False Confidence (Critical Audit Discovery)**:
   - While the 18 integration tests technically pass according to testbench criteria, deep inspection reveals that **many peripheral checks are superficial handshake-counting tests rather than functional verification**:
     - **UART (Test 6)**: Writes/reads only the Line Control Register (`UART_LCR`, `0x4000000C`). No character was ever transmitted via `UART_THR` (0x00), no receiver frame was tested on `uart_rx_i`, and baud rate timing was never exercised.
     - **SPI (Test 11)**: The CPU only accesses unmapped offsets (`0x40010000` and `0x40010004`), which return the hardcoded architectural default token `0x61626364`. Not a single valid SPI control/data register (`CR`, `SR`, `DTR`, `DRR`, `SSR`) was accessed, and no SPI serial clocks or data lines toggled.
     - **FIR Filter (Tests 9 & 13)**: The CPU enables the FIR engine, and the testbench drives an impulse and ECG samples into `fir_s_axis_tdata`. However, the filter output `fir_m_axis_tdata` is **never compared against any reference model or expected numerical value**.
     - **End-to-End ECG Pipeline (Test 13)**: Although documented as an "ADC -> FIR -> QRS" hardware streaming pipeline, **no such hardware pipeline exists in the SoC RTL** ([`cardioedge_cpu_soc_top.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/riscv/cardioedge_cpu_soc_top.sv)). Instead, ADC, FIR, and QRS are completely separate slaves. In Test 13, the testbench drives ADC and FIR input pins from external testbench registers while simultaneously using Verilog `force` statements to bypass the AXI bus and inject ECG samples directly into internal QRS wrapper flip-flops (`dut.u_qrs.ecg_sample_reg` and `dut.u_qrs.ecg_valid_pulse`).
     - **Interrupt System (Test 15)**: Only verifies static identity (`===`) between peripheral IRQ nets and VeeR core PIC input pins while all lines remain deasserted (0). No peripheral interrupt was dynamically fired, and the VeeR core has no trap vector table (`mtvec`) or ISR programmed in IMEM.
     - **Timer (Test 8)**: Configures `TIMER_LOAD` and `TIMER_CTRL`, but never waits for or checks counter decrement, expiration, reload, or interrupt generation.

3. **Firmware Application Status**:
   - Firmware infrastructure exists under [`firmware/`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/) (`start.S`, `cardioedge_test.c`, `tb_cardioedge_firmware.sv`, `Makefile`).
   - The standalone firmware executable was compiled ([`run/compile_firmware_test.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/compile_firmware_test.log), *Oct 9 12:44:04 2026*), but **no execution log (`sim_firmware.log`) exists in the repository**.
   - Inspection of `firmware/cardioedge_test.c` reveals that it does **not** perform heartbeat-level counting, multi-record ECG classification, or ground-truth accuracy evaluation. It only pushes 32 samples into QRS and casts the R-peak status to `(void)`.
   - Inspection of `firmware/tb_cardioedge_firmware.sv` reveals that the testbench explicitly **forces the WTSEE internal clock gates low** (`force dut.u_qrs.u_wtsee.cg0.en = 0; force dut.u_qrs.u_wtsee.cg1.en = 0;`) and forces synthetic results into the QRS status registers based on sample index counting. **Clinical arrhythmia classification on real hardware remains completely unverified.**

4. **Coverage Measurements**:
   - Zero coverage databases (`.vdb`) exist in the repository.
   - Neither code coverage (line, branch, condition, toggle, FSM) nor functional coverage (SystemVerilog `covergroup`/`coverpoint`) was enabled during any simulation build.

---

## 2. Repository and Test Infrastructure Inventory

### A. Repository Structure

```text
/home/student/Documents/HONOURS_CBP_CARDIOEDGE
├── doc/
│   ├── addressmapping.ods                         # Authoritative address map & feature definitions
│   ├── CardioEdge_AXI4_Specification_v2.docx      # Interconnect specification
│   ├── CARDIOEDGE_RISCV_SOC_VERIFICATION_REPORT.md# Previous 18/18 integration verification report
│   ├── Combined_SoC_Features_DataPath_ControlPath.pdf # Architectural datapath diagram
│   └── qrs/
│       ├── ARCHITECTURE.md                        # WTSEE QRS microarchitecture specification
│       └── JOURNAL_VALIDATION_PLAN.md             # Scientific validation plan
├── firmware/
│   ├── build_firmware.py                          # Fallback Python firmware compilation utility
│   ├── cardioedge.ld                              # Linker script (IMEM @ 0x0, DMEM @ 0x10000, Stack @ 0x18000)
│   ├── cardioedge_test.c                          # C firmware exercising MMIO peripheral drivers
│   ├── cardioedge_test.dump / .elf / .hex / .vhx  # Compiled firmware binaries
│   ├── ecg_dataset.h / ecg_dataset.s              # 4-record synthesized ECG dataset
│   ├── filelist_cardioedge_firmware.f             # VCS filelist for firmware testbench
│   ├── generate_hex.sh                            # Script to convert ELF to HEX/VHX
│   ├── Makefile                                   # Firmware build Makefile (targets rv32imc/ilp32)
│   ├── prepare_ecg_dataset.py                     # Synthetic MIT-BIH dataset generation script
│   ├── README.md                                  # Firmware user guide
│   ├── start.S                                    # Assembly entry point (_start)
│   └── tb_cardioedge_firmware.sv                  # Testbench with $readmemh loader & UART sniffer
├── rtl/
│   ├── ADC/                                       # ADC acquisition controller & FIFO (6 SV files)
│   ├── common/                                    # AXI4-to-AXI4Lite bridge & dummy slave (3 SV/V files)
│   ├── Cores-VeeR-EL2/                            # Western Digital VeeR EL2 core submodule (45 SV files)
│   ├── FIR/                                       # 32-tap FIR filter with AXI4-Stream (4 V files)
│   ├── gpio/                                      # 8-bit GPIO controller with IRQ & PWM (4 SV files)
│   ├── interconnect/                              # AXI 3x18 interconnect fabric (5 V files)
│   ├── QRS/                                       # WTSEE V6 QRS detection accelerator (13 V files)
│   ├── riscv/                                     # Top SoC wrapper, adapters, IMEM & DMEM (6 SV files)
│   ├── spi/                                       # AXI4 SPI Master controller (8 V files)
│   ├── timer/                                     # 32-bit Timer with PWM & capture (5 SV files)
│   └── uart/                                      # 16550-compatible AXI4 UART controller (6 V files)
├── run/
│   ├── compile.log / sim.log                      # Authoritative 18/18 SoC integration logs (Oct 7)
│   ├── compile_3x18.log / sim_3x18.log            # Standalone 3x18 interconnect logs (58 passes)
│   ├── compile_fixed.log / sim_fixed.log          # Bridged SoC integration logs (ADC/GPIO/Timer)
│   ├── compile_firmware_test.log                  # Compilation log for simv_firmware (Oct 9)
│   ├── compile_qrs_standalone.log / sim_qrs_standalone.log # Standalone QRS detector log (Oct 7)
│   ├── compile_qrs_wrapper_tb.log / sim_qrs_wrapper_tb.log # QRS AXI wrapper log (Oct 7)
│   ├── filelist_cardioedge_riscv_soc.f            # Authoritative integration compilation filelist
│   └── simv / simv_3x18 / simv_firmware / simv_qrs_standalone / simv_qrs_wrapper_tb # VCS executables
└── tb/
    ├── ADC/                                       # Standalone ADC test suite (adc_tb.sv + 6 tests)
    ├── aes_axi_slave_tb.sv / aes_test_bench_top.v # AES testbenches (IP not integrated in SoC top)
    ├── axi_bfm_tasks.sv                           # Reusable AXI master tasks (single-beat read/write)
    ├── ecg_input.txt                              # 2,200 clinical ECG samples from MIT-BIH Record 100
    ├── qrs_axi4_wrapper_tb.sv                     # Standalone testbench for QRS AXI wrapper
    ├── tb_axi_interconnect_wrap_3x18.sv           # Standalone 3x18 interconnect testbench
    ├── tb_cardioedge_riscv_soc.sv                 # Authoritative 18-Test Integration Testbench
    ├── tb_ecg_wtsee_optimized_top.v               # Standalone WTSEE QRS algorithmic testbench
    ├── tb_fir_top.v / tb_fir_dsp.v                # Standalone FIR testbenches with reference model
    ├── tb_gpio_axi.sv                             # Standalone GPIO testbench (directed tests 1-9)
    ├── tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv # Bridged SoC testbench without CPU
    ├── tb_timer_axi.sv                            # Standalone Timer testbench
    └── uart_standalone_tb.sv                      # Standalone UART testbench (TX/RX frame verification)
```

### B. Identified Testbenches and Available Run Configurations

| Testbench File | Target Module | Scope | Run Script / Command | Log Found? |
|---|---|---|---|:---:|
| [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv) | `cardioedge_cpu_soc_top` | Full SoC + VeeR Core (18 Tests) | `vcs -f filelist_cardioedge_riscv_soc.f; ./simv -no_save` | **YES** ([`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log)) |
| [`firmware/tb_cardioedge_firmware.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/tb_cardioedge_firmware.sv) | `cardioedge_cpu_soc_top` | Full SoC + C Firmware via `$readmemh` | `vcs -f filelist_cardioedge_firmware.f; ./simv_firmware` | **NO** (Only compile log) |
| [`tb/tb_axi_interconnect_wrap_3x18.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_axi_interconnect_wrap_3x18.sv) | `axi_interconnect_wrap_3x18` | Interconnect 3 Masters x 18 Slaves | `vcs -f filelist_axi_interconnect_wrap_3x18.f; ./simv_3x18` | **YES** ([`run/sim_3x18.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_3x18.log)) |
| [`tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv) | `soc_uart_qrs_..._top_BRIDGED` | SoC Peripherals via BFM (No CPU) | `vcs -f filelist_..._BRIDGED.f; ./simv_bridged_3x18` | **YES** ([`run/sim_fixed.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_fixed.log)) |
| [`tb/tb_ecg_wtsee_optimized_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_ecg_wtsee_optimized_top.v) | `ecg_wtsee_v6_top` | Standalone WTSEE Core (2200 samples) | `./simv_qrs_standalone -no_save` | **YES** ([`run/sim_qrs_standalone.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_qrs_standalone.log)) |
| [`tb/qrs_axi4_wrapper_tb.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/qrs_axi4_wrapper_tb.sv) | `qrs_axi4_wrapper` | Standalone QRS AXI4 Wrapper | `./simv_qrs_wrapper_tb -no_save` | **YES** ([`run/sim_qrs_wrapper_tb.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_qrs_wrapper_tb.log)) |
| [`tb/tb_gpio_axi.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_gpio_axi.sv) | `gpio_axi` | Standalone GPIO IP (9 directed tests) | None configured in `run/` | **NO** |
| [`tb/tb_timer_axi.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_timer_axi.sv) | `timer_axi` | Standalone Timer IP | None configured in `run/` | **NO** |
| [`tb/uart_standalone_tb.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/uart_standalone_tb.sv) | `axi_uart_top` | Standalone UART IP (TX/RX frame bit checks) | None configured in `run/` | **NO** |
| [`tb/tb_fir_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_fir_top.v) | `fir_top` | Standalone FIR Filter with Reference Model | None configured in `run/` | **NO** |
| [`tb/tb_fir_dsp.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_fir_dsp.v) | `fir_dsp` | Standalone FIR DSP Engine | None configured in `run/` | **NO** |
| [`tb/ADC/adc_tb.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/ADC/adc_tb.sv) | `adc_controller` | Standalone ADC Subsystem (6 test modules) | None configured in `run/` | **NO** |
| [`tb/aes_axi_slave_tb.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/aes_axi_slave_tb.sv) | `aes_axi_slave` | Standalone AES Slave (Not in Top SoC) | None configured in `run/` | **NO** |

---

## 3. Complete Implemented-Feature Inventory

Extracted from the authoritative project address mapping specification ([`doc/addressmapping.ods`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/doc/addressmapping.ods)), top-level RTL ([`cardioedge_cpu_soc_top.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/riscv/cardioedge_cpu_soc_top.sv)), and individual IP specifications:

### A. RISC-V Processor and Memory Subsystem
- **Core Architecture**: Western Digital VeeR EL2 RISC-V core configured for RV32IMC (Integer, Multiply/Divide, Compressed) with ILP32 ABI.
- **Boot/Reset**: Reset vector at `0x0000_0000`. Cold power-on reset initializes pipeline.
- **Instruction Memory (IMEM / M07)**: 64 KiB synchronous SRAM at `0x0000_0000` – `0x0000_FFFF`. Connected to VeeR IFU via 64-to-32 adapter. Read-only execution memory preloaded with boot code.
- **Data Memory (DMEM / M08)**: 64 KiB synchronous SRAM at `0x0001_0000` – `0x0001_FFFF`. Connected to VeeR LSU via 64-to-32 adapter. Stack base at `0x0001_8000`. Read/write support for word (`sw`/`lw`), half-word, and byte accesses.
- **Interrupt Controller (PIC)**: Core-internal Programmable Interrupt Controller accepting up to 31 external interrupt requests (`extintsrc_req[31:1]`).

### B. AXI Interconnect and Adapters
- **Interconnect Topology**: Shared Group 3-Master × 18-Slave AXI4 matrix ([`axi_interconnect_wrap_3x18.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/interconnect/axi_interconnect_wrap_3x18.v)).
- **Master Ports**:
  - `S00`: VeeR IFU (Instruction Fetch via 64-to-32 adapter).
  - `S01`: VeeR LSU (Load/Store via 64-to-32 adapter).
  - `S02`: External DMA / System Master (tied off / inactive in SoC top).
- **Slave Ports**:
  - `M00` (`0x4000_0000`, 4 KiB): UART Controller
  - `M01` (`0x4000_2000`, 4 KiB): GPIO Controller (via AXI4-to-AXI4-Lite bridge)
  - `M02` (`0x4000_4000`, 4 KiB): Timer Controller (via AXI4-to-AXI4-Lite bridge)
  - `M03` (`0x4000_C000`, 4 KiB): FIR Filter Engine
  - `M04` (`0x4000_E000`, 4 KiB): ADC Controller
  - `M05` (`0x4001_0000`, 4 KiB): SPI Controller
  - `M06` (`0x4001_2000`, 4 KiB): QRS Peak Detector
  - `M07` (`0x0000_0000`, 64 KiB): IMEM Instruction SRAM
  - `M08` (`0x0001_0000`, 64 KiB): DMEM Data SRAM
  - `M09`–`M17` (`0x4000_6000` .. `0x4001_E000`, 4 KiB each): Dummy Slaves returning DECERR (`2'b11`).
- **Protocol Adapters**:
  - `axi_64to32_adapter.sv`: Converts VeeR 64-bit IFU and LSU transactions to 32-bit AXI4.
  - `axi4_to_axi4lite_bridge.sv`: Single-beat protocol bridge for GPIO and Timer.

### C. UART Peripheral
- **RTL Module**: [`rtl/uart/axi_uart_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/uart/axi_uart_top.v)
- **Registers**: `THR/RBR` (`+0x00`), `IER` (`+0x04`), `BAUD_DIV` (`+0x08`), `LCR` (`+0x0C`), `LSR` (`+0x14`).
- **Features**: 8N1 serial framing, programmable baud rate divisor, TX/RX 16-byte internal FIFOs, transmitter-empty status flags (`THRE`, `TEMT`), `uart_irq` interrupt output.

### D. GPIO Peripheral
- **RTL Module**: [`rtl/gpio/gpio_axi.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/gpio/gpio_axi.sv)
- **Registers**: `DATA_I` (`+0x00`), `DATA_O` (`+0x04`), `DIR` (`+0x08`), `INT_EN` (`+0x0C`), `INT_TYP` (`+0x10`), `INT_POL` (`+0x14`), `INT_ANY` (`+0x18`), `INT_STS` (`+0x1C`), `SET_O` (`+0x20`), `CLR_O` (`+0x24`), `TGL_O` (`+0x28`), `DEB_TH`, `DEB_EN`, `INV_IN`, `INV_OUT`, `OD_EN`, `WR_MASK`, `PU_EN`, `PD_EN`, `PWM_EN`, `PWM_CFG`, `PWM_DUTY`.
- **Features**: 8 bidirectional I/O pins, atomic bit set/clear/toggle, programmable edge/level interrupts, input debouncing, output inversion, open-drain mode, integrated multi-channel PWM generators, `gpio_irq` output.

### E. 32-bit Timer Peripheral
- **RTL Module**: [`rtl/timer/timer_axi.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/timer/timer_axi.sv)
- **Registers**: `CTRL` (`+0x00`), `LOAD` (`+0x04`), `VAL` (`+0x08`), `PRE` (`+0x0C`), `INT_EN` (`+0x10`), `INT_STS` (`+0x14`), `CMP` (`+0x18`), `CAP` (`+0x1C`).
- **Features**: 32-bit down/up counter, 16-bit prescaler, periodic/one-shot modes, compare match PWM output (`timer_pwm_o`), external capture (`timer_capture_i`), external measurement, `timer_irq` output.

### F. FIR Filter Engine
- **RTL Module**: [`rtl/FIR/fir_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/FIR/fir_top.v)
- **Registers**: `CTRL` (`+0x00`), `LOAD` (`+0x04`), `STATUS` (`+0x08`), `COEFF[0..31]` (`+0x10`..`+0x8C`).
- **Datapath**: Dedicated 16-bit AXI4-Stream slave input (`fir_s_axis_*`), 40-bit AXI4-Stream master output (`fir_m_axis_*`), 8-entry input/output stream FIFOs.
- **Features**: 32 programmable Q1.15 coefficient taps, 40-bit internal accumulator, coefficient latch strobe, FIFO occupancy status.

### G. ADC Acquisition Controller
- **RTL Module**: [`rtl/ADC/adc_controller.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/ADC/adc_controller.sv)
- **Registers**: `CTRL` (`+0x00`), `STATUS` (`+0x04`), `SAMPLE_DATA` (`+0x08`), `FIFO_DATA` (`+0x0C`), `IRQ_EN` (`+0x10`).
- **Features**: 12-bit sample acquisition from top pins `adc_sample_in` / `adc_sample_valid`, automated periodic sampling scheduler (default 250 Hz from 50 MHz clock), 32-entry sample FIFO with auto-pop on `FIFO_DATA` read, sample-ready interrupt (`adc_irq_sample`), overrun interrupt (`adc_irq_overrun`).

### H. SPI Master Controller
- **RTL Module**: [`rtl/spi/axi_spi_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/spi/axi_spi_top.v)
- **Registers**: `GIER` (`+0x1C`), `ISR` (`+0x20`), `IER` (`+0x28`), `RCLK` (`+0x30`), `SRR` (`+0x40`), `CR` (`+0x60`), `SR` (`+0x64`), `DTR` (`+0x68`), `DRR` (`+0x6C`), `SSR` (`+0x70`), `TFOR` (`+0x74`), `RFOR` (`+0x78`). Unmapped offset `+0x04` returns `0x61626364`.
- **Features**: Full-duplex SPI master, TX/RX 16-byte FIFOs, programmable clock ratio, automated slave select assertion, soft reset (`0x0A` to `SRR`).

### I. WTSEE QRS Detection Accelerator
- **RTL Module**: [`rtl/QRS/qrs_axi4_wrapper.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/QRS/qrs_axi4_wrapper.v) / [`ecg_wtsee_v6_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/QRS/ecg_wtsee_v6_top.v)
- **Registers**: `CONTROL` (`+0x00`), `STATUS` (`+0x04`), `ECG_INPUT` (`+0x08`), `RPEAK` (`+0x0C`), `RR_INTERVAL` (`+0x10`), `BPM` (`+0x14`), `RHYTHM_CLASS` (`+0x18`).
- **Features**: Wavelet-Transform Shannon Energy Envelope (WTSEE V6) hardware pipeline: 3-tap baseline filter, first difference, leading-zero normalizer, 4096-entry Shannon LUT, 33-point moving sum, 43-point power energy sum, dual-threshold adaptive Schmitt trigger, missed-beat search-back rescue, hardware RR interval counter, integer BPM calculation (`60*FS/RR`), and 2-bit rhythm classification (Normal=00, Bradycardia=01, Tachycardia=10).

---

## 4. Feature-to-Test Traceability Matrix

The following table audits every claimed project feature against actual testbench implementations and simulation execution logs.

| ID | Feature | RTL Module | Testbench / Test Name | Evidence in Log | Expected Result | Actual Result | Status | Missing Coverage |
|---|---|---|---|---|---|---|---|---|
| **CPU-01** | Reset & Startup Vector | `el2_veer_wrapper.sv` | `tb_cardioedge_riscv_soc` / Test 1 & 2 | `sim.log` L51-67 | Initial PC fetch at `0x00000000` | ARADDR = `0x00000000` on S00 | **PASS — Verified** | Reset during outstanding transactions |
| **CPU-02** | Instruction Fetch from IMEM | `axi_imem_slave.sv` | `tb_cardioedge_riscv_soc` / Test 3 | `sim.log` L70-84 | >= 5 fetches with OKAY response | 5 fetches observed, RRESP=00 | **PASS — Verified** | Fetch burst addressing, cacheable regions |
| **CPU-03** | RV32I Arithmetic & Shifts | `el2_veer_wrapper.sv` | `tb_cardioedge_riscv_soc` / Test 5 | `sim.log` L109-160 | `add`, `sub`, `slli` results stored | DMEM[4]=30, DMEM[8]=40 | **PASS — Verified** | Logical shifts, comparison, AUIPC, LUI only |
| **CPU-04** | RV32I Branches & Loops | `el2_veer_wrapper.sv` | `tb_cardioedge_riscv_soc` / Test 5 | `sim.log` L109-160 | `beq` taken, `bne` loop exit | Loop exit proof DMEM[12]=0 | **PASS — Verified** | `blt`, `bge`, `bltu`, `bgeu`, untaken branch paths |
| **CPU-05** | RV32M Multiply / Divide | `el2_veer.sv` | None | None | Hardware multiplier execution | Untested | **NOT TESTED** | `mul`, `mulh`, `div`, `rem` instructions |
| **CPU-06** | RV32C Compressed Instructions| `el2_veer.sv` | None | None | 16-bit compressed instruction execution | Untested in regression | **NOT TESTED** | `c.addi`, `c.li`, `c.mv`, `c.j`, etc. |
| **CPU-07** | DMEM Load / Store Integrity | `axi_dmem_slave.sv` | `tb_cardioedge_riscv_soc` / Test 4 | `sim.log` L87-106 | `sw` stores 0x5A, `lw` loads 0x5A | Store=0x5A, Read=0x5A, OKAY | **PASS — Verified** | Byte/halfword writes, boundary checks |
| **CPU-08** | Trap / Exception Handling | `el2_veer.sv` | None | None | Trap entry to `mtvec` on illegal instruction | Untested | **NOT TESTED** | Illegal instruction, unaligned load/store trap |
| **AXI-01** | Interconnect S00 Master (IFU)| `axi_interconnect_wrap_3x18.v`| `tb_cardioedge_riscv_soc` / Test 3, 16 | `sim.log` L70, L451 | Fetches serviced across fabric | 394 IFU beats serviced | **PASS — Verified** | IFU burst wrap/fixed modes |
| **AXI-02** | Interconnect S01 Master (LSU)| `axi_interconnect_wrap_3x18.v`| `tb_cardioedge_riscv_soc` / Test 4-12 | `sim.log` L100-300 | Read/write to all active slaves | 43 LSU beats serviced | **PASS — Verified** | Multi-beat LSU bursts |
| **AXI-03** | Interconnect S02 Master (DMA)| `axi_interconnect_wrap_3x18.v`| `tb_axi_interconnect_wrap_3x18` | `sim_3x18.log` L80-93 | s02 writes and reads to slaves | Selected writes/reads PASS | **PARTIAL** | S02 is tied off in top-level SoC RTL |
| **AXI-04** | Address Decoding M00-M17 | `axi_interconnect_wrap_3x18.v`| `tb_axi_interconnect_wrap_3x18` | `sim_3x18.log` L25-63 | s00 writes/reads all 18 slaves | 58 passes, 0 fails | **PASS — Verified** | Interconnect tested standalone; not all tested via CPU |
| **AXI-05** | Master Concurrency & Arb. | `axi_interconnect_wrap_3x18.v`| `tb_cardioedge_riscv_soc` / Test 16 | `sim.log` L439-454 | IFU and LSU active simultaneously | Concurrent traffic detected | **PARTIAL** | Competing requests to same slave port |
| **AXI-06** | Dummy Slaves DECERR Response | `axi_dummy_slave.sv` | `tb_cardioedge_riscv_soc` / Test 14 | `sim.log` L418-425 | DECERR (`2'b11`) without bus deadlock | Transaction completed, DECERR | **PARTIAL** | Only M09 tested via CPU; M10-M17 not exercised |
| **AXI-07** | 64-to-32 Width Conversion | `axi_64to32_adapter.sv` | `tb_cardioedge_riscv_soc` / Test 4, 5 | `sim.log` L100, L127 | Upper/lower 32-bit word mapping | Correct stores at +0, +4, +8 | **PASS — Verified** | 64-bit multi-word burst conversion |
| **AXI-08** | AXI4-to-AXI4-Lite Bridge | `axi4_to_axi4lite_bridge.sv` | `tb_cardioedge_riscv_soc` / Test 7, 8 | `sim.log` L198, L217 | Bridge translates AXI to Lite for GPIO/Timer | GPIO/Timer accesses pass | **PASS — Verified** | Back-to-back outstanding bridge requests |
| **UART-01**| Line Control Register Config | `axi_uart_top.v` | `tb_cardioedge_riscv_soc` / Test 6 | `sim.log` L163-179 | Write `0x03` to LCR, readback `0x03` | LCR readback = `0x00000003` | **PASS — Verified** | Baud rate setting, parity, stop bits |
| **UART-02**| Serial Data Transmission | `uart_transmitter.v` | `uart_standalone_tb` (Standalone) | None (`uart_standalone_tb` not run) | TX pin serial bit framing verified | Testbench exists, no log | **NOT TESTED** | Top regression never wrote to `UART_THR` |
| **UART-03**| Serial Data Reception | `uart_receiver.v` | `uart_standalone_tb` (Standalone) | None (`uart_standalone_tb` not run) | RX deserialization and data ready | Testbench exists, no log | **NOT TESTED** | Top regression never drove `uart_rx_i` |
| **UART-04**| UART Interrupt Generation | `axi_uart_top.v` | None | None | `uart_irq` assertion on THRE/DR | Untested | **NOT TESTED** | `uart_irq` firing to VeeR PIC |
| **GPIO-01**| Direction & Output Write/Read| `gpio_axi.sv` | `tb_cardioedge_riscv_soc` / Test 7 | `sim.log` L181-204 | DIR=0xFF, DATA_O=0xA5, pins drive 0xA5 | DMEM[5]=0xA5, `gpio_io`=0xA5 | **PASS — Verified** | Partial; CPU only wrote one pattern |
| **GPIO-02**| Atomic Set / Clear / Toggle | `gpio_regs.sv` | `tb_soc_..._BRIDGED` / Test 7 | `sim_fixed.log` L69-80 | SET_O, CLR_O, TGL_O modify DATA_O | Readbacks match modified values | **PASS — Verified** | Verified in bridged BFM; untested in CPU regression |
| **GPIO-03**| External Input Sampling | `gpio_bit.sv` | `tb_soc_..._BRIDGED` / Test 7 | `sim_fixed.log` L81-84 | Drive `gpio_io`=0x5A, read `DATA_I` | Readback = 0x5A | **PASS — Verified** | Verified in bridged BFM; CPU never read `DATA_I` |
| **GPIO-04**| Debounce, Invert, Open-Drain | `gpio_wrapper.sv` | `tb_gpio_axi` (Standalone) | None (`tb_gpio_axi` not run) | Debounce threshold & IO inversion | Testbench exists, no log | **NOT TESTED** | Feature implemented in RTL, not verified in log |
| **GPIO-05**| Integrated PWM Generation | `gpio_wrapper.sv` | `tb_gpio_axi` (Standalone) | None (`tb_gpio_axi` not run) | PWM period, duty cycle, output toggle | Testbench exists, no log | **NOT TESTED** | Feature implemented in RTL, not verified in log |
| **GPIO-06**| GPIO Interrupt Generation | `gpio_regs.sv` | `tb_gpio_axi` (Standalone) | None (`tb_gpio_axi` not run) | Edge/level IRQ assert on input change | Testbench exists, no log | **NOT TESTED** | Top regression never asserted `gpio_irq` |
| **TIM-01** | Timer Load & Control | `timer_axi.sv` | `tb_cardioedge_riscv_soc` / Test 8 | `sim.log` L205-221 | Write LOAD=5, readback=5, enable | Readback LOAD = 5 | **PASS — Verified** | Only checked register write; counting unverified |
| **TIM-02** | Timer Decrement & Expiration | `timer_core.sv` | `tb_soc_..._BRIDGED` / Test 8 | `sim_fixed.log` L87-105 | Load 5, start, count to 0, fire IRQ | Timer IRQ received PASS | **PASS — Verified** | Verified in bridged BFM; untested in CPU regression |
| **TIM-03** | Timer Prescaler | `timer_core.sv` | `tb_soc_..._BRIDGED` / Test 8 | `sim_fixed.log` L91-94 | Prescaler divides clock ticks | Register PRE written/read | **PARTIAL** | Prescaler division ratio not timed |
| **TIM-04** | PWM Output & Capture | `timer_core.sv` | None | None | `timer_pwm_o` toggles at CMP match | Untested | **NOT TESTED** | `timer_pwm_o` and `timer_capture_i` unverified |
| **FIR-01** | FIR Control & Enable | `fir_top.v` | `tb_cardioedge_riscv_soc` / Test 9 | `sim.log` L223-245 | Write CTRL=1, readback=1 | Readback CTRL = 1 | **PASS — Verified** | Register readback verified |
| **FIR-02** | Coefficient Programming | `fir_axi_lite.v` | `tb_fir_top` (Standalone) | None (`tb_fir_top` not run) | Program 32 taps via AXI-Lite & latch | Testbench exists, no log | **NOT TESTED** | Top regression programmed zero coefficients |
| **FIR-03** | AXI-Stream Input Handshake | `fir_top.v` | `tb_cardioedge_riscv_soc` / Test 9 | `sim.log` L243 | Impulse 0x0100 accepted on `s_axis` | `tready` handshake confirmed | **PASS — Verified** | Handshake verified; datapath math unverified |
| **FIR-04** | Filter Numerical Accuracy | `fir_dsp.v` | `tb_fir_top` (Standalone) | None (`tb_fir_top` not run) | 32-tap filtering matches reference model | Testbench exists, no log | **NOT TESTED** | `fir_m_axis_tdata` never checked in regression |
| **ADC-01** | ADC Control & Reset Status | `adc_controller.sv` | `tb_cardioedge_riscv_soc` / Test 10 | `sim.log` L247-263 | Write CTRL=1, read STATUS FIFO empty | STATUS = `0x00000004` (Empty) | **PASS — Verified** | Reset status and enable verified |
| **ADC-02** | Sample Acquisition & Data Reg| `adc_controller.sv` | `tb_soc_..._BRIDGED` / Test 3 | `sim_fixed.log` L29-31 | Drive sample 0xA55, read `SAMPLE_DATA` | Readback = `0x00000a55` PASS | **PASS — Verified** | Verified in bridged BFM; CPU never read SAMPLE_DATA |
| **ADC-03** | Sample FIFO & Pop Behavior | `adc_fifo.sv` | `tb_soc_..._BRIDGED` / Test 4 | `sim_fixed.log` L33-34 | Pop sample from `FIFO_DATA` | Readback = `0x00000a55` PASS | **PASS — Verified** | 32-deep full/overrun verified only in unexecuted TB |
| **ADC-04** | ADC Interrupts (Sample/Overrun)| `adc_registers.sv` | `tb_soc_..._BRIDGED` / Test 5 | `sim_fixed.log` L36-54 | Enable IRQ, drive sample, verify IRQ | Sample IRQ asserted PASS | **PASS — Verified** | Verified in bridged BFM; CPU never received IRQ |
| **SPI-01** | SPI Register Interface | `axi_spi_top.v` | `tb_cardioedge_riscv_soc` / Test 11 | `sim.log` L264-280 | Access SPI space | Readback = `0x61626364` | **FAIL / WEAK** | Offset 0x04 is unmapped; real registers unverified |
| **SPI-02** | SPI Control & Status Regs | `axi_spi_ctrl.v` | None | None | Write `CR`, verify `SR` status flags | Untested in logs | **NOT TESTED** | `CR`, `SR`, `SRR` untested in regression logs |
| **SPI-03** | SPI Master Serial Transfer | `spi_ctrl.v` | None | None | Push byte into `DTR`, clock onto MOSI | Untested in logs | **NOT TESTED** | Serial pins (`MOSI`, `MISO`, `SCK`, `CS`) unverified |
| **QRS-01** | QRS Control Register Enable | `qrs_axi4_wrapper.v` | `tb_cardioedge_riscv_soc` / Test 12 | `sim.log` L281-298 | Write CTRL=1, read STATUS active | STATUS = `0x00000001` (Active) | **PASS — Verified** | Enable bit verified |
| **QRS-02** | Standalone QRS Peak Detect | `ecg_wtsee_v6_top.v` | `tb_ecg_wtsee_optimized_top` | `sim_qrs_standalone.log` L1-695 | Process 2200 samples, find R-peaks | 22 peaks found, PASS | **PARTIAL** | Excessive search-back peaks when input is 0 |
| **QRS-03** | Clinical R-Peak via Regression| `qrs_axi4_wrapper.v` | `tb_cardioedge_riscv_soc` / Test 13 | `sim.log` L385 | Detect sample 220 R-peak | 1 peak detected at sample 220 | **PARTIAL** | Used testbench `force` on internal registers |
| **QRS-04** | RR Interval & BPM Calc | `rr_classifier.v` | `tb_ecg_wtsee_optimized_top` | `sim_qrs_standalone.log` L98-100 | Compute RR interval & BPM | RR=228, BPM=94 reported | **PARTIAL** | Calculated on search-back artifacts |
| **QRS-05** | Arrhythmia Classification | `rr_classifier.v` | None | None | Classify Normal, Brady, Tachy | Never verified with truth data | **NOT TESTED** | `rhythm_class` never verified against annotated ECG |
| **INT-01** | Peripheral to PIC Routing | `cardioedge_cpu_soc_top.sv`| `tb_cardioedge_riscv_soc` / Test 15 | `sim.log` L427-438 | 5 IRQ nets routed to `extintsrc_req` | 100% net match verified | **PASS — Verified** | Structural wire check only; dynamic IRQ unverified |
| **INT-02** | CPU Interrupt Trap Handling | `el2_veer.sv` | None | None | CPU enters ISR, saves context, clears IRQ | Untested | **NOT TESTED** | No ISR or `mstatus.mie` setup in firmware |
| **APP-01** | C Firmware Boot & Execution | `firmware/start.S` | `tb_cardioedge_firmware` | `compile_firmware_test.log` | C main executes, prints UART telemetry | Compilation succeeded; no log | **INCONCLUSIVE** | `sim_firmware.log` not found in repo |
| **APP-02** | Dataset Arrhythmia Eval | `cardioedge_test.c` | None | None | Multi-record dataset processing & confusion matrix | Not implemented in C test | **NOT TESTED** | `ecg_dataset.h` omitted from firmware source |

---

## 5. Detailed Audit of All 18 Original Regression Tests

Every check executed in [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv) and recorded in [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log) was audited:

```text
+----------------------------------------------------------------------------------------------------+
| 1. TEST 1: RESET ASSERTION AND DEASSERTION                                                         |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify system cold reset release and clean startup without unknown logic.
  DUT Interface       : Top reset input rst_n; AXI valid channels dut.s00_axi_* and dut.s01_axi_*.
  Input Stimulus      : Assert rst_n = 0 for 10 clock periods, then deassert to rst_n = 1.
  Expected Result     : rst_n == 1, critical AXI signals driven cleanly with zero X/Z states.
  Actual Comparison   : $isunknown(s00_axi_awvalid || s00_axi_arvalid || s01_axi_awvalid || s01_axi_arvalid)
  Actual Result in Log: [PASS] RESET (sim.log, lines 51-57).
  Coverage Gaps       : Checks only 4 top-level valid wires. Does not check internal peripheral reset states.
  False PASS Potential: Low for reset release; high if assumed to prove peripheral reset states.

+----------------------------------------------------------------------------------------------------+
| 2. TEST 2: VeeR STARTUP / INSTRUCTION FETCH                                                        |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify VeeR EL2 core releases from reset and initiates fetch at 0x0000_0000.
  DUT Interface       : Master S00 AR channel (dut.s00_axi_araddr, arvalid, arready).
  Input Stimulus      : Clock and reset release.
  Expected Result     : First fetch ARADDR == 32'h0000_0000 with ifu_fetch_count >= 1.
  Actual Comparison   : if (ifu_fetch_count > 0 && first_ifu_addr == 32'h00000000)
  Actual Result in Log: [PASS] VeeR STARTUP / INSTRUCTION FETCH (sim.log, lines 60-68). First ARADDR=0x0.
  Coverage Gaps       : Evaluates only the address of fetch #1. Does not check burst length, ID, or size.
  False PASS Potential: Low; core genuinely issued reset vector fetch.

+----------------------------------------------------------------------------------------------------+
| 3. TEST 3: IMEM INSTRUCTION MEMORY ACCESS (0x0000_0000 - 0x0000_FFFF)                             |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify autonomous instruction fetch sequence through interconnect slave M07.
  DUT Interface       : Interconnect slave M07 (dut.m07_axi_araddr, arvalid, arready, rdata, rresp).
  Input Stimulus      : Execution of boot program in IMEM.
  Expected Result     : >= 5 instruction memory accesses through M07 with RRESP=OKAY.
  Actual Comparison   : if (imem_access_count >= 5)
  Actual Result in Log: [PASS] IMEM ACCESS (sim.log, lines 70-85). 5 accesses observed.
  Coverage Gaps       : Check condition counts AR handshakes only; does not check RDATA or RRESP in the pass check.
  False PASS Potential: Moderate; would pass if 5 AR handshakes occurred even if RDATA was corrupted or SLVERR.

+----------------------------------------------------------------------------------------------------+
| 4. TEST 4: DMEM DATA MEMORY ACCESS (0x0001_0000 - 0x0001_FFFF)                                    |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU LSU can store to and load from DMEM via interconnect slave M08.
  DUT Interface       : Interconnect slave M08 (dut.m08_axi_*).
  Input Stimulus      : CPU executes `sw t0, 0(a0)` (0x5A) followed by `lw t1, 0(a0)`.
  Expected Result     : dmem_write_count >= 1, dmem_read_count >= 1, dut.u_dmem.mem[0] == 32'h0000005A.
  Actual Comparison   : if (dmem_write_count >= 1 && dmem_read_count >= 1 && dut.u_dmem.mem[0] == 32'h5A)
  Actual Result in Log: [PASS] DMEM WRITE, [PASS] DMEM READ (sim.log, lines 87-106). Stored=0x5a, Read=0x5a.
  Coverage Gaps       : Checks word offset 0 only. Unaligned, byte, and half-word transfers unverified.
  False PASS Potential: Low; memory write and read handshakes verified with exact data matching.

+----------------------------------------------------------------------------------------------------+
| 5. TEST 5: CPU INSTRUCTION EXECUTION (ALU, BRANCH, LOOP)                                          |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Validate core execution of arithmetic, conditional branching, and looping.
  DUT Interface       : VeeR execution pipeline; stores execution signatures into DMEM[1..3].
  Input Stimulus      : IMEM preloaded program: add, sub, slli, beq (taken), bne loop (5 iterations).
  Expected Result     : DMEM[1] == 30 (0x1E), DMEM[2] == 40 (0x28), DMEM[3] == 0 (0x00).
  Actual Comparison   : Direct value checks on dut.u_dmem.mem[1], dut.u_dmem.mem[2], dut.u_dmem.mem[3].
  Actual Result in Log: [PASS] CPU INSTRUCTION EXECUTION (sim.log, lines 109-160).
  Coverage Gaps       : Exercises only 6 instructions. Untested: RV32M, RV32C, CSRs, traps, untaken branches.
  False PASS Potential: Low; actual computed data values verified in SRAM.

+----------------------------------------------------------------------------------------------------+
| 6. TEST 6: UART PERIPHERAL ACCESS (0x4000_0000)                                                    |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU memory-mapped access to UART over interconnect slave M00.
  DUT Interface       : Interconnect M00; axi_uart_top register interface; uart_tx_o pin.
  Input Stimulus      : CPU writes 0x03 to UART LCR (0x4000_000C), reads back, stores in DMEM[4].
  Expected Result     : uart_access_count >= 1, readback == 0x03, uart_tx_o == 1'b1.
  Actual Comparison   : if (uart_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] UART ACCESS (sim.log, lines 163-179). DMEM[4]=0x03, TX idle=1.
  Coverage Gaps       : PASS criterion only checks transaction count! Never transmits a character, never
                        checks THR (0x00), never tests RX, baud divisor, or interrupts.
  False PASS Potential: HIGH; passes on any transaction to M00 even if data was wrong or UART was broken.

+----------------------------------------------------------------------------------------------------+
| 7. TEST 7: GPIO PERIPHERAL ACCESS (0x4000_2000)                                                    |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU configuration of GPIO direction and output data over M01.
  DUT Interface       : Interconnect M01; AXI4-Lite bridge; gpio_axi; gpio_io pins.
  Input Stimulus      : CPU writes DIR=0xFF (0x4000_2008), DATA_O=0xA5 (0x4000_2004), saves to DMEM[5].
  Expected Result     : gpio_access_count >= 1, DMEM[5] == 0xA5, gpio_io == 8'hA5.
  Actual Comparison   : if (gpio_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] GPIO ACCESS (sim.log, lines 181-204). DMEM[5]=0xa5, gpio_io=8'ha5.
  Coverage Gaps       : PASS criterion only checks transaction count! CPU never reads external input DATA_I.
                        Atomic set/clr/tgl, debounce, and PWM not tested by CPU.
  False PASS Potential: HIGH; passing status is decoupled from the actual readback comparison.

+----------------------------------------------------------------------------------------------------+
| 8. TEST 8: TIMER PERIPHERAL ACCESS (0x4000_4000)                                                   |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU configuration of TIMER LOAD and CTRL registers over M02.
  DUT Interface       : Interconnect M02; AXI4-Lite bridge; timer_axi.
  Input Stimulus      : CPU writes LOAD=5 (0x4000_4004), reads back to DMEM[6], writes CTRL=1 (enable).
  Expected Result     : timer_access_count >= 1, DMEM[6] == 5.
  Actual Comparison   : if (timer_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] TIMER ACCESS (sim.log, lines 205-221). LOAD readback=5.
  Coverage Gaps       : Only checks transaction count! Does not check counter decrement, timeout, reload,
                        prescaler, PWM output, or interrupt firing.
  False PASS Potential: HIGH; only verifies register presence, not timer functionality.

+----------------------------------------------------------------------------------------------------+
| 9. TEST 9: FIR FILTER ENGINE ACCESS (0x4000_C000)                                                  |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU enable of FIR engine via M03 and streaming input handshake.
  DUT Interface       : Interconnect M03; fir_top registers; fir_s_axis_* stream interface.
  Input Stimulus      : CPU writes CTRL=1, saves to DMEM[7]. TB drives impulse 0x0100 on fir_s_axis_tdata.
  Expected Result     : fir_access_count >= 1, tready handshake confirmed.
  Actual Comparison   : if (fir_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] FIR ACCESS (sim.log, lines 223-245). Impulse processed, tready confirmed.
  Coverage Gaps       : Does not program filter coefficients! Never inspects fir_m_axis_tdata output!
                        Filter mathematical response is completely unchecked.
  False PASS Potential: CRITICAL; passes purely because stream input was accepted, ignoring output data.

+----------------------------------------------------------------------------------------------------+
| 10. TEST 10: ADC CONTROLLER ACCESS (0x4000_E000)                                                   |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU enable of ADC scheduler via M04 and testbench sample injection.
  DUT Interface       : Interconnect M04; adc_controller; adc_sample_in, adc_sample_valid pins.
  Input Stimulus      : CPU writes CTRL=1, reads STATUS (empty flag), saves to DMEM[8]. TB injects sample 1024.
  Expected Result     : adc_access_count >= 1, STATUS bit 2 set (FIFO empty = 0x04).
  Actual Comparison   : if (adc_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] ADC ACCESS (sim.log, lines 247-263). STATUS readback = 0x00000004.
  Coverage Gaps       : CPU never reads SAMPLE_DATA or FIFO_DATA! FIFO pop, full, overrun, and IRQ unverified.
  False PASS Potential: HIGH; passing is gated solely on transaction count.

+----------------------------------------------------------------------------------------------------+
| 11. TEST 11: SPI CONTROLLER ACCESS (0x4001_0000)                                                   |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU access to SPI space over interconnect slave M05.
  DUT Interface       : Interconnect M05; axi_spi_top unmapped address space.
  Input Stimulus      : CPU writes 1 to offset 0x00, reads offset 0x04, stores into DMEM[9].
  Expected Result     : spi_access_count >= 1.
  Actual Comparison   : if (spi_access_count >= 1)
  Actual Result in Log: [PASS] SPI ACCESS (sim.log, lines 264-280). Readback = 0x61626364.
  Coverage Gaps       : CRITICAL DEFECT: Offsets 0x00 and 0x04 are unmapped in Xilinx-style SPI IP!
                        Readback 0x61626364 is the architectural dummy fallback! Zero real SPI registers
                        (CR, SR, DTR, DRR, SSR) or serial pins were exercised.
  False PASS Potential: 100% FALSE POSITIVE; passes because dummy fallback read completed.

+----------------------------------------------------------------------------------------------------+
| 12. TEST 12: QRS PEAK DETECTOR ACCESS (0x4001_2000)                                                |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify CPU enable of QRS accelerator via M06.
  DUT Interface       : Interconnect M06; qrs_axi4_wrapper.
  Input Stimulus      : CPU writes 1 to QRS_CONTROL (0x4001_2000), reads STATUS, stores in DMEM[10].
  Expected Result     : qrs_access_count >= 1, STATUS active bit set (0x01).
  Actual Comparison   : if (qrs_access_count >= 1)  <-- WEAK CHECK!
  Actual Result in Log: [PASS] QRS ACCESS (sim.log, lines 281-298). STATUS readback = 0x00000001.
  Coverage Gaps       : Evaluates transaction count only. No ECG samples fed through CPU MMIO.
  False PASS Potential: HIGH; passes on transaction count alone.

+----------------------------------------------------------------------------------------------------+
| 13. TEST 13: END-TO-END ECG DATA PATH (ADC -> FIR -> QRS DETECTOR)                                |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Claimed validation of combined ECG signal pipeline.
  DUT Interface       : Top ADC/FIR pins + hierarchical signals dut.u_qrs.ecg_sample_reg / ecg_valid_pulse.
  Input Stimulus      : 260 samples from ecg_input.txt (clinical R-peak at sample 220).
  Expected Result     : Samples injected == samples accepted across all blocks; >= 1 R-peak detected.
  Actual Comparison   : ecg_injected == adc_accepted && ecg_injected == fir_accepted && qrs_peak_count > 0.
  Actual Result in Log: [PASS] CASE 1: Known clinical R-peak (sample 220) detected! (sim.log, lines 300-416).
  Coverage Gaps       : CRITICAL FALSE ARCHITECTURE: ADC, FIR, and QRS are NOT connected in hardware!
                        TB forces internal signals of QRS with `force`! FIR output is never checked!
                        Only 1 peak detected; RR interval, BPM, and rhythm classification are unverified.
  False PASS Potential: CRITICAL FALSE POSITIVE; simulates an illusion of pipeline integration.

+----------------------------------------------------------------------------------------------------+
| 14. TEST 14: DUMMY SLAVES (M09 - M17 DECERR RESPONSE)                                              |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify unmapped/group dummy slave positions return DECERR without bus deadlock.
  DUT Interface       : Interconnect M09 (axi_dummy_slave).
  Input Stimulus      : CPU executes `sw zero, 0(s5)` and `lw zero, 0(s5)` targeting 0x4000_6000.
  Expected Result     : dummy_access_count >= 1, DECERR (2'b11) returned.
  Actual Comparison   : if (dummy_access_count >= 1)
  Actual Result in Log: [PASS] DUMMY SLAVES (sim.log, lines 418-425). Transaction accepted, DECERR returned.
  Coverage Gaps       : Only tests M09. Slaves M10 through M17 were never accessed.
  False PASS Potential: Low for M09, but leaves M10–M17 unverified.

+----------------------------------------------------------------------------------------------------+
| 15. TEST 15: INTERRUPT ARCHITECTURE & PIC ROUTING                                                  |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify wiring from peripheral IRQ lines to VeeR EL2 PIC inputs extintsrc_req[5:1].
  DUT Interface       : Interconnect IRQ wires -> dut.u_veer.extintsrc_req[5:1].
  Input Stimulus      : Static 4-state simulation comparison.
  Expected Result     : All 5 IRQ nets identity-match (===) PIC inputs.
  Actual Comparison   : Exact signal identity check (dut.u_veer.extintsrc_req[1] === uart_irq && ...)
  Actual Result in Log: [PASS] INTERRUPT ROUTING (sim.log, lines 427-438). 100% connectivity confirmed.
  Coverage Gaps       : Only checks that wires are connected while all IRQ signals are 0! Never asserts
                        an interrupt dynamically; CPU never runs an ISR.
  False PASS Potential: MODERATE; confirms schematic netlist connectivity, not functional interrupt behavior.

+----------------------------------------------------------------------------------------------------+
| 16. TEST 16: IFU / LSU AXI CONCURRENCY (S00 + S01)                                                 |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Verify concurrent instruction fetch (S00) and data access (S01) on interconnect.
  DUT Interface       : Interconnect master ports S00 and S01 arbiter.
  Input Stimulus      : CPU executes code while accessing memory and peripherals.
  Expected Result     : concurrent_traffic_detected || (ifu_fetch_count > 50 && dmem_write_count > 5).
  Actual Comparison   : Checks either simultaneous valid assertion OR cumulative transaction thresholds.
  Actual Result in Log: [PASS] IFU/LSU AXI CONCURRENCY (sim.log, lines 440-454). IFU=387, LSU=30.
  Coverage Gaps       : The `||` operator allows the test to pass on sequential counts alone even if no
                        true concurrency occurred. Master S02 is inactive.
  False PASS Potential: Moderate.

+----------------------------------------------------------------------------------------------------+
| 17. TEST 17: AXI 3x18 FABRIC STRESS & PROTOCOL INTEGRITY                                           |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Check that active AXI ready and valid lines do not contain X or Z values.
  DUT Interface       : Interconnect master/slave channel handshakes.
  Input Stimulus      : Normal simulation progression.
  Expected Result     : No X/Z on dut.s00_axi_arready, s01_axi_awready, m00_axi_arvalid, m07_axi_arvalid.
  Actual Comparison   : !$isunknown(dut.s00_axi_arready) && ...
  Actual Result in Log: [PASS] AXI 3x18 STRESS & INTEGRITY (sim.log, lines 456-466).
  Coverage Gaps       : Only samples 4 signals at a single point in time. No continuous SVA protocol checker.
  False PASS Potential: Moderate; spot check only.

+----------------------------------------------------------------------------------------------------+
| 18. TEST 18: FINAL SYSTEM REGRESSION CHECK                                                         |
+----------------------------------------------------------------------------------------------------+
  Purpose             : Check overall cumulative test error counter.
  DUT Interface       : Testbench error tracking variable error_count.
  Input Stimulus      : Completed execution of Tests 1–17.
  Expected Result     : error_count == 0.
  Actual Comparison   : if (error_count == 0) PASS; else FAIL;
  Actual Result in Log: [PASS] FINAL SYSTEM CHECK (sim.log, lines 468-489). Cumulative Errors = 0.
  Coverage Gaps       : Inherits all false-positive vulnerabilities from Tests 6 through 13.
  False PASS Potential: HIGH; only reports 0 errors because preceding weak checks failed to increment error_count.
+----------------------------------------------------------------------------------------------------+
```

---

## 6. Firmware and Application Test Audit

### A. Firmware Source & Implementation Analysis
- **Source Files**: [`firmware/start.S`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/start.S) (reset bootstrap), [`firmware/cardioedge_test.c`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/cardioedge_test.c) (bare-metal application), [`firmware/cardioedge.ld`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/cardioedge.ld) (linker script).
- **Execution Path**:
  - `_start` sets stack pointer to `0x0001_8000` and calls `main()`.
  - `main()` calls drivers for UART, GPIO, Timer, ADC, FIR, SPI, and QRS sequentially.
  - Driver status and verification strings are formatted via `uart_puts()` to transmit out of `UART_THR`.
  - Concludes with `ALL TESTS PASSED\nTEST COMPLETE\n` and traps in a `while(1) nop` loop.

### B. Application Verification Gaps & Deficiencies
1. **No Execution Log**:
   - Although compiled into `simv_firmware` ([`run/compile_firmware_test.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/compile_firmware_test.log), *Oct 9 12:44*), **no output log (`sim_firmware.log`) exists** in the repository. Its execution status is technically **INCONCLUSIVE**.
2. **QRS Unit Test Does Not Check Detector Results**:
   - In `test_qrs()` ([`cardioedge_test.c`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/cardioedge_test.c#L621-L653)):
     - Feeds only 32 samples from `clinical_ecg_qrs_vector`.
     - 32 samples is physically insufficient to detect an R-peak (the WTSEE filter latency is 76 samples, and `MIN_DIST` refractory period is 90 samples).
     - The code reads R-peak status with `uint32_t rpeak = qrs_read_rpeak(); (void)rpeak;` and **completely discards the result without checking it**!
     - It only verifies that the last written sample can be read back from `QRS_REG_ECG_INPUT`, then prints `PASS`.
3. **Hardware Clock Gates Force-Disabled in Firmware Testbench**:
   - In [`firmware/tb_cardioedge_firmware.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/tb_cardioedge_firmware.sv#L550-L557):
     ```systemverilog
     force dut.u_qrs.u_wtsee.cg0.en = 1'b0;
     force dut.u_qrs.u_wtsee.cg1.en = 1'b0;
     force dut.u_qrs.rpeak_q        = forced_rpeak;
     force dut.u_qrs.result_valid_q = forced_valid;
     force dut.u_qrs.rr_q           = forced_rr;
     force dut.u_qrs.bpm_q          = forced_bpm;
     force dut.u_qrs.rhythm_q       = forced_rhythm;
     ```
   - The testbench **completely shuts down the real WTSEE hardware detector** and overrides the status registers with fake signals driven by a testbench task (`trigger_hw_peak`).
4. **Dataset Arrhythmia Evaluation Missing**:
   - While [`firmware/prepare_ecg_dataset.py`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/prepare_ecg_dataset.py) synthesizes 4 records (`REC_NSR_01`, `REC_BRADY_02`, `REC_TACHY_03`, `REC_ARRHY_04`), **these records are not included or evaluated in `cardioedge_test.c`**.
   - No beat-level detection counting, no record-level classification, and no sensitivity/specificity evaluation exists.

---

## 7. Peripheral-by-Peripheral Coverage Findings

### 1. RISC-V Processor (VeeR EL2) & Memory (IMEM / DMEM)
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Reset vector fetch at `0x0000_0000`, linear instruction fetch through M07, single-word writes and reads to DMEM M08, basic RV32I arithmetic (`add`, `sub`, `slli`), conditional branch taken (`beq`), countdown loop (`bne`).
- **Untested**: RV32M (multiplication/division instructions), RV32C (compressed instructions), sub-word memory accesses (`sb`, `sh`, `lb`, `lh`, `lbu`, `lhu`), unaligned accesses, control and status registers (CSRs), machine-mode traps, illegal instruction exceptions, stack overflow, interrupts.

### 2. AXI4 Interconnect (3×18 Fabric) & Adapters
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Standalone interconnect testbench verified address routing and OKAY responses across all 18 slave positions (M00–M17) for Master S00. Dual-master activity (IFU on S00, LSU on S01) verified without deadlock. AXI 64-to-32 adapter write/read addressing verified. AXI4-to-AXI4-Lite bridge single-beat register writes/reads verified. M09 dummy slave returns DECERR (`2'b11`).
- **Untested**: Master S02 is inactive in SoC top. Multi-master arbitration under heavy contention (competing requests targeting the same slave port). Multi-beat burst transfers across the bridge. Dummy slaves M10–M17 unverified via CPU. Reset deassertion during outstanding bus transactions.

### 3. UART Peripheral
- **Status**: **MINIMALLY VERIFIED (Near Untested)**
- **Tested**: Read and write to Line Control Register (`UART_LCR`, `0x4000_000C`). TX pin idle level check (`uart_tx_o == 1`).
- **Untested**: Serial data transmission (`UART_THR`, `0x0000_0000`) at system level, serial data reception (`UART_RBR`, `uart_rx_i`), baud rate divisor generator (`UART_BAUD_DIV`), FIFO full/empty flags in `UART_LSR`, parity computation, receive line status interrupts, `uart_irq` transmission to PIC.

### 4. GPIO Peripheral
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Direction register configuration (`GPIO_DIR`), output register write/readback (`GPIO_DATA_O` = 0xA5), external output pin drive. Atomic set, clear, and toggle operations verified in bridged BFM testbench.
- **Untested**: CPU read of external input pin levels (`GPIO_DATA_I`). Input debouncing filters (`DEB_TH`, `DEB_EN`). Pin polarity and inversion (`INV_IN`, `INV_OUT`). Open-drain and pull-up/down logic. Integrated PWM engine (`PWM_CFG`, `PWM_DUTY`). Edge and level interrupt generation and status clearing (`INT_STS`).

### 5. 32-bit Timer Peripheral
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Register write and readback of `TIMER_LOAD` (0x4000_4004) and `TIMER_CTRL` (0x4000_4000). Timer countdown, expiration, and interrupt assertion verified in bridged BFM testbench.
- **Untested**: In CPU integration regression, counter decrement, reload, and expiration are never checked. Prescaler division timing (`TIMER_PRE`). PWM compare generation (`TIMER_CMP`, `timer_pwm_o`). External event capture (`TIMER_CAP`, `timer_capture_i`). Status clearing (`TIMER_INT_STS` W1C) via CPU.

### 6. FIR Filter Engine
- **Status**: **MINIMALLY VERIFIED**
- **Tested**: Control register enable (`FIR_CTRL`, `0x4000_C000`). AXI4-Stream slave ready/valid handshake on `fir_s_axis_tready` when an impulse is driven.
- **Untested**: Programming of the 32 filter tap coefficients (`COEFF[0..31]`). Coefficient latch strobe (`FIR_LOAD`). FIFO status flags (`input_fifo_full`, `output_fifo_empty`). **Filter output data (`fir_m_axis_tdata`) mathematical correctness is 100% unverified against any filter specification.**

### 7. ADC Acquisition Controller
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Control register enable (`ADC_CTRL`, `0x4000_E000`). Status register FIFO empty bit readback (`ADC_STATUS` = 0x04). In bridged BFM testbench: single-sample capture (`SAMPLE_DATA` = 0xA55), FIFO pop (`FIFO_DATA` = 0xA55), sample interrupt generation (`adc_irq_sample`).
- **Untested**: In CPU integration regression, CPU never reads `SAMPLE_DATA` or `FIFO_DATA`. Automated periodic sampling scheduler rate timing (250 Hz). 32-entry FIFO full flag and overrun detection (`adc_irq_overrun`). Back-to-back sample throughput.

### 8. SPI Master Controller
- **Status**: **NOT VERIFIED (False Positive in Regression)**
- **Tested**: Write and read to unmapped addresses `0x4001_0000` and `0x4001_0004`, returning default dummy token `0x61626364`.
- **Untested**: Control register (`SPI_CR`), Status register (`SPI_SR`), Soft reset (`SPI_SRR`), Transmit FIFO (`SPI_DTR`), Receive FIFO (`SPI_DRR`), Slave Select (`SPI_SSR`), Baud clock ratio (`SPI_RCLK`), Global interrupt enable (`SPI_GIER`), physical serial communication on `spi_clk_o`, `spi_mosi_o`, `spi_miso_i`, `spi_cs_n_o`.

### 9. WTSEE QRS Detection Accelerator
- **Status**: **PARTIALLY VERIFIED**
- **Tested**: Control register enable (`QRS_CONTROL`, `0x4001_2000`). Standalone core processes 2,200 samples from MIT-BIH Record 100 and identifies R-peaks. Single clinical R-peak detected at sample 220 in integration regression.
- **Untested**: In integration regression, samples are injected by testbench `force` rather than through the AXI bus or hardware pipeline. Processing of noisy, abnormal, or arrhythmic records. Beat-to-beat RR interval verification across successive beats. Heart rate (BPM) accuracy against clinical ground truth. Hardware rhythm classification (`rhythm_class`) accuracy.

---

## 8. False-Positive and Weak-Test Investigation

| Test Location | Suspected Weakness / False Positive | Concrete Evidence in Source or Log | Severity |
|---|---|---|:---:|
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L529-L537) (Test 6) | UART check passes purely on transaction count | Code checks `if (uart_access_count >= 1)` to display `[PASS] UART ACCESS`. Never writes to `UART_THR`, never checks serial output. | **HIGH** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L557-L572) (Test 7) | GPIO check passes purely on transaction count | Code checks `if (gpio_access_count >= 1)` to display `[PASS] GPIO ACCESS`. CPU never reads input pins or exercises atomic operations. | **HIGH** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L592-L599) (Test 8) | Timer check passes without checking counting | Code checks `if (timer_access_count >= 1)` to display `[PASS] TIMER ACCESS`. Counter decrement and expiration are never monitored. | **HIGH** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L619-L644) (Test 9) | FIR check passes without inspecting filter output | Code checks `if (fir_access_count >= 1)` to display `[PASS] FIR ACCESS`. `fir_m_axis_tdata` is never sampled or compared against any expected value. | **CRITICAL** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L664-L680) (Test 10) | ADC check passes without checking data readout | Code checks `if (adc_access_count >= 1)` to display `[PASS] ADC ACCESS`. CPU never reads `SAMPLE_DATA` or `FIFO_DATA`. | **HIGH** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L700-L707) (Test 11) | SPI check passes by reading an unmapped dummy address | In `axi_imem_slave.sv` lines 170-174, CPU accesses offsets 0x00 and 0x04. Returns default fallback token `0x61626364`. Real SPI registers are untouched. | **CRITICAL** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L764-L813) (Test 13) | End-to-end ECG pipeline is simulated via testbench forcing | In `tb_cardioedge_riscv_soc.sv` lines 771-778 and 803-810: TB uses `force dut.u_qrs.ecg_sample_reg = cur_ecg_sample; force dut.u_qrs.ecg_valid_pulse = 1'b1;`. No hardware pipeline connects ADC, FIR, and QRS in RTL! | **CRITICAL** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L886-L897) (Test 15) | Interrupt test passes on static 0-level wiring check | In `tb_cardioedge_riscv_soc.sv` lines 886-890: checks `extintsrc_req[1] === uart_irq` while all IRQ lines are 0. No interrupt ever pulses high. | **MODERATE** |
| [`tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L908-L916) (Test 16) | Concurrency check passes on sequential counts | In `tb_cardioedge_riscv_soc.sv` line 908: `concurrent_traffic_detected || (ifu_fetch_count > 50 && dmem_write_count > 5)`. The `||` allows passage without true concurrency. | **MODERATE** |
| [`firmware/tb_cardioedge_firmware.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/tb_cardioedge_firmware.sv#L550-L557) | Firmware testbench force-disables hardware QRS | In `tb_cardioedge_firmware.sv` lines 550-557: `force dut.u_qrs.u_wtsee.cg0.en = 0; force dut.u_qrs.rpeak_q = forced_rpeak;`. Disables real hardware and injects fake testbench results! | **CRITICAL** |
| [`firmware/cardioedge_test.c`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/cardioedge_test.c#L645-L646) | Firmware QRS test casts R-peak result to void | In `cardioedge_test.c` lines 645-646: `uint32_t rpeak = qrs_read_rpeak(); (void)rpeak;`. Never evaluates whether a peak was detected. | **HIGH** |
| [`tb_ecg_wtsee_optimized_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_ecg_wtsee_optimized_top.v#L280) | Standalone QRS detects false peaks on zero input | In `sim_qrs_standalone.log` lines 673-675: detects 22 R-peaks for 6 actual peaks. When input data is 0 after sample 2200, search-back repeatedly triggers forced false peaks. | **HIGH** |

---

## 9. Actual Code and Functional Coverage Availability

### A. Code Coverage Status
- **Status**: **NOT CONFIGURED / ZERO DATA AVAILABLE**
- **Evidence**:
  - Inspection of compilation command lines in [`run/compile.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/compile.log), [`run/compile_firmware_test.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/compile_firmware_test.log), and filelists shows that no `-cm` flags (such as `-cm line+cond+fsm+tgl+branch`) were passed to VCS.
  - Search for coverage directories (`*.vdb`) in the repository confirmed that **no Synopsys VCS coverage databases exist**.
  - Statement, branch, expression/condition, state machine (FSM), and toggle coverage have never been collected.

### B. Functional Coverage Status
- **Status**: **NOT IMPLEMENTED**
- **Evidence**:
  - Global grep across all testbenches in [`tb/`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/) and [`firmware/`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/) for SystemVerilog functional coverage keywords (`covergroup`, `coverpoint`, `cross`) returned zero instances.
  - No functional coverage models exist to track address space coverage, transaction combinations, FIFO boundary conditions, or clinical ECG rhythm scenarios.

### C. Recommended Method to Enable Coverage Safely (Post-Audit)
To collect full code and assertion coverage without altering design source code:
```bash
# Add -cm options to VCS compilation in a new build script:
vcs -full64 -sverilog -ntb_opts uvm -timescale=1ns/1ps \
    -cm line+cond+fsm+tgl+branch -cm_dir ./coverage_db.vdb \
    -f filelist_cardioedge_riscv_soc.f -l compile_cov.log

# Run simulation collecting coverage:
./simv -cm line+cond+fsm+tgl+branch -cm_dir ./coverage_db.vdb -no_save -l sim_cov.log

# Generate human-readable HTML coverage report using Synopsys Unified Report Generator:
urg -dir ./coverage_db.vdb -format both -report ./coverage_report
```

---

## 10. List of Features Proven PASS

The following features have incontrovertible, positive verification evidence in simulation logs with correct value checking:

1. **Cold Power-On Reset Deassertion**: Clean reset release without unknown states on primary AXI valid signals (`sim.log` lines 51–57).
2. **Initial Reset Vector Fetch**: VeeR EL2 core releases from reset and initiates instruction fetch at `0x0000_0000` (`sim.log` lines 60–68).
3. **Sequential IMEM Instruction Fetching**: Core executes sequential fetches across interconnect slave M07 (`sim.log` lines 70–85).
4. **DMEM SRAM 32-bit Write and Read**: Core writes token `0x0000005A` to `0x00010000` and reads it back with OKAY response (`sim.log` lines 87–106).
5. **Core ALU Arithmetic (`add`, `sub`, `slli`)**: Core calculates `10 + 20 = 30` (DMEM[1] = 0x1E) and `10 << 2 = 40` (DMEM[2] = 0x28) (`sim.log` lines 109–160).
6. **Core Conditional Branching (`beq` taken)**: Core evaluates equal condition (20 == 20) and branches over skipped store (`sim.log` lines 109–160).
7. **Core Software Loop Execution (`bne`)**: Core decrements counter from 5 to 0 and stores loop termination proof (DMEM[3] = 0x00) (`sim.log` lines 109–160).
8. **UART LCR Configuration Access**: Core configures Line Control Register with `0x03` (8N1) and confirms readback (`sim.log` lines 163–179).
9. **GPIO Direction & Pin Drive**: Core sets `DIR` = 0xFF, writes `DATA_O` = 0xA5, and physical pins drive `8'hA5` (`sim.log` lines 181–204).
10. **GPIO Atomic Set / Clear / Toggle Operations**: Verified in bridged testbench (`sim_fixed.log` lines 69–80).
11. **GPIO External Input Pin Sampling**: Verified in bridged testbench (`sim_fixed.log` lines 81–84).
12. **Timer Load & Enable Configuration**: Core writes `LOAD` = 5 and `CTRL` = 1, readback confirms 5 (`sim.log` lines 205–221).
13. **Timer Decrement, Expiration, and Interrupt**: Verified in bridged testbench (`sim_fixed.log` lines 87–105).
14. **FIR Engine Control Enable**: Core enables FIR via register `0x4000C000`, readback confirms 1 (`sim.log` lines 223–245).
15. **FIR AXI4-Stream Input Handshaking**: Stream slave accepts impulse sample with valid `tready` handshake (`sim.log` line 243).
16. **ADC Controller Enable & Status Read**: Core enables ADC, reads FIFO empty bit `0x04` in status register (`sim.log` lines 247–263).
17. **ADC Sample Capture & FIFO Pop**: Verified in bridged testbench (`sim_fixed.log` lines 29–34).
18. **ADC Sample Interrupt Assertion**: Verified in bridged testbench (`sim_fixed.log` lines 36–54).
19. **QRS Detector Control Enable**: Core enables QRS engine, status readback confirms active bit 1 (`sim.log` lines 281–298).
20. **Standalone QRS Peak Detection on Real ECG**: WTSEE engine detects clinical R-peak at sample 220 in MIT-BIH Record 100 (`sim_qrs_standalone.log` line 59).
21. **Dummy Slave DECERR Termination**: Watchdog region M09 returns `2'b11` (DECERR) without interconnect hang (`sim.log` lines 418–425).
22. **Interconnect 18-Slave Standalone Addressing**: Master S00 writes and reads all 18 slave positions M00–M17 (`sim_3x18.log` lines 25–63).

---

## 11. List of Partial, Failed, Untested, Missing, and Blocked Features

### A. Failed / Inconclusive Features
1. **SPI Controller Integration (M05)**: **FAILED / FALSE POSITIVE**. The integration test accesses unmapped addresses `0x00` and `0x04`, returning default dummy token `0x61626364`. No functional SPI registers or pins were verified.
2. **Firmware Simulation Execution**: **INCONCLUSIVE**. Executable `simv_firmware` was compiled on Oct 9, but no simulation transcript log (`sim_firmware.log`) exists in the repository.

### B. Partially Verified Features
1. **End-to-End ECG Data Path (Test 13)**: Only 260 samples tested. Bypassed AXI bus and bypassed nonexistent hardware pipeline by using testbench `force` on internal QRS registers. Filter output never checked.
2. **QRS Standalone Algorithm**: Processes 2,200 samples, but triggers 22 detections for 6 actual clinical peaks due to search-back false triggers on trailing zero-valued samples.
3. **IFU / LSU Concurrency (Test 16)**: Evaluated with an `||` condition that allows passage on sequential transaction counts alone.
4. **Dummy Slaves M10–M17**: Verified in standalone interconnect testbench, but never exercised by CPU in SoC integration regression.
5. **Interrupt Routing (Test 15)**: Wires are verified connected in simulation, but no interrupt was dynamically fired or serviced by the CPU.

### C. Untested Features
1. **UART Data Transmission (`THR`) and Serial Output (`uart_tx_o`)**.
2. **UART Serial Input Reception (`uart_rx_i`) and Read Buffer (`RBR`)**.
3. **UART Baud Rate Divisor Generator and Line Status Flags**.
4. **GPIO Debounce, Inversion, Open-Drain, and Pull-up/down Logic**.
5. **GPIO Integrated PWM Generators**.
6. **Timer Prescaler Frequency Division Timing**.
7. **Timer Compare PWM Output (`timer_pwm_o`) and External Capture (`timer_capture_i`)**.
8. **FIR Coefficient Programming (Taps 0..31) and Filter Tap Latching**.
9. **FIR Output Mathematical Response Correctness (`fir_m_axis_tdata`)**.
10. **ADC Automated 250 Hz Periodic Sampling Timing**.
11. **ADC Sample FIFO Full Flag and Overrun Error (`adc_irq_overrun`)**.
12. **Real SPI Master Control (`CR`), Status (`SR`), TX FIFO (`DTR`), and Serial Pins (`MOSI`, `MISO`, `SCK`, `CS`)**.
13. **QRS Hardware RR Interval and BPM Register Readout via CPU MMIO**.
14. **QRS Clinical Rhythm Classification (`rhythm_class`) against Arrhythmic ECG**.
15. **CPU Core Trap Vector Setup (`mtvec`) and Interrupt Service Routine (ISR) Context Switching**.
16. **RV32M Hardware Multiplication and Division Instructions**.
17. **RV32C Compressed Instructions**.
18. **Multi-Record Dataset Arrhythmia Classification in Firmware Application**.

### D. Missing / Blocked Features
1. **Hardware Pipeline Connecting ADC -> FIR -> QRS**: Does not exist in SoC RTL.
2. **Firmware Multi-Record Dataset Integration**: `ecg_dataset.h` was generated by script but never integrated into `cardioedge_test.c`.
3. **VCS Coverage Databases**: Zero code or functional coverage instrumentation exists.

---

## 12. Prioritized Missing-Test Plan

The following test additions are proposed in strict priority order. To preserve the frozen baseline, **do not modify `tb_cardioedge_riscv_soc.sv`**. All new tests should be implemented in dedicated, cleanly isolated verification suites.

### Priority 1: Critical Correctness (Processor, Memory, Real Data Output)

#### Test Plan Item P1-1: Real UART Character Transmission & Telemetry Test
- **Purpose**: Prove that VeeR CPU can write ASCII characters to `UART_THR` (`0x4000_0000`) and the UART transmitter produces valid bit-framed serial output on `uart_tx_o`.
- **Stimulus**: CPU firmware writes string `"CARDIOEDGE\n"` into `UART_THR`, polling `UART_LSR` bit 5 (`THRE`).
- **Expected Result**: Bit-accurate receiver model in testbench samples `uart_tx_o` at configured baud rate and reconstructs exact ASCII string `"CARDIOEDGE\n"`.
- **Interfaces**: LSU S01 -> Interconnect M00 -> `axi_uart_top` -> `uart_tx_o`.
- **Pass/Fail Criteria**: Fail if baud bit timing exceeds ±3% tolerance or any character mismatches.
- **Target Testbench**: Extend `firmware/tb_cardioedge_firmware.sv` or create dedicated `tb/tb_soc_uart_tx_verification.sv`.
- **Dependencies**: Functional UART driver; no RTL modifications required.

#### Test Plan Item P1-2: FIR Filter Numerical Output Verification Against Golden Reference
- **Purpose**: Verify that the 32-tap FIR filter mathematical datapath computes numerically correct filtered output samples.
- **Stimulus**: Program 16-tap bandpass filter coefficients into `FIR_COEFF(0..15)` (`0x4000_C010`+), latch via `FIR_LOAD`, stream 100 clinical ECG samples into `fir_s_axis_tdata`.
- **Expected Result**: Sample-by-sample output on `fir_m_axis_tdata` matches double-precision golden software model within ±1 LSB fixed-point quantization tolerance.
- **Interfaces**: LSU S01 -> Interconnect M03 (registers); external AXI4-Stream slave/master.
- **Pass/Fail Criteria**: Fail if any output sample deviates by > 1 LSB or stream backpressure stalls.
- **Target Testbench**: Execute standalone `tb/tb_fir_top.v` with log capture, then integrate into SoC level.
- **Dependencies**: Reference FIR model; no RTL modifications required.

#### Test Plan Item P1-3: Real SPI Controller Master Transfer Verification
- **Purpose**: Verify genuine register access and serial communication of `axi_spi_top` on M05, eliminating the current false-positive check.
- **Stimulus**: CPU resets SPI via `SPI_SRR` (`0x4001_0040`), configures `SPI_CR` (`0x4001_0060`) for master mode, enables slave select `SPI_SSR` (`0x4001_0070`), writes byte `0xA5` to `SPI_DTR` (`0x4001_0068`).
- **Expected Result**: Testbench SPI slave model receives byte `0xA5` over `spi_mosi_o` synchronized with `spi_clk_o` while `spi_cs_n_o` is asserted low.
- **Interfaces**: LSU S01 -> Interconnect M05 -> `axi_spi_top` -> external SPI bus pins.
- **Pass/Fail Criteria**: Fail if SPI pins remain static or data byte corrupted.
- **Target Testbench**: Dedicated testbench `tb/tb_soc_spi_verification.sv`.
- **Dependencies**: SPI slave BFM; no RTL modifications required.

---

### Priority 2: Peripheral Functional Completeness

#### Test Plan Item P2-1: Timer Countdown, Expiration, and Interrupt Verification
- **Purpose**: Validate that the Timer decrements at the programmed clock rate, triggers expiration interrupt, and reloads.
- **Stimulus**: CPU writes `TIMER_LOAD = 1000`, enables repeat mode in `TIMER_CTRL`, enables `TIMER_INT_EN`.
- **Expected Result**: `TIMER_VAL` decreases each clock cycle; `timer_irq` asserts after 1000 cycles; writing 1 to `TIMER_INT_STS` clears interrupt.
- **Interfaces**: LSU S01 -> Interconnect M02 -> `timer_axi` -> `timer_irq`.
- **Pass/Fail Criteria**: Fail if counter does not decrement or interrupt fails to fire/clear.
- **Target Testbench**: Dedicated test in `tb/tb_cardioedge_riscv_soc.sv` extension or `tb/tb_timer_axi.sv`.
- **Dependencies**: None; no RTL modifications required.

#### Test Plan Item P2-2: ADC FIFO Streaming & Overrun Test
- **Purpose**: Validate ADC 32-sample FIFO buffering, automated sample scheduler rate, and overrun error flag.
- **Stimulus**: Enable ADC scheduler, inject 35 consecutive samples at 250 Hz without CPU readout.
- **Expected Result**: First 32 samples buffered; FIFO full flag asserts; 33rd sample dropped; `adc_irq_overrun` asserts. CPU reads out 32 samples in correct first-in-first-out order.
- **Interfaces**: Top pins `adc_sample_*`, LSU S01 -> Interconnect M04 -> `adc_controller`.
- **Pass/Fail Criteria**: Fail if FIFO ordering corrupted or overrun fails to assert.
- **Target Testbench**: Run standalone `tb/ADC/adc_tb.sv` (incorporates `adc_fifo_test.sv`).
- **Dependencies**: None; no RTL modifications required.

#### Test Plan Item P2-3: Multi-Beat QRS RR Interval & Heart Rate (BPM) Verification
- **Purpose**: Verify hardware calculation of RR interval and BPM across multiple successive beats without testbench forcing.
- **Stimulus**: Stream 1,500 samples from MIT-BIH Record 100 (crossing beats at sample 220, 580, 940) via CPU MMIO writes to `QRS_REG_ECG_INPUT` (`0x4001_2008`).
- **Expected Result**: Core detects beats, calculates RR interval = 360 samples, BPM = 60, `result_valid` pulses high, and CPU reads these values over AXI M06.
- **Interfaces**: LSU S01 -> Interconnect M06 (`qrs_axi4_wrapper`).
- **Pass/Fail Criteria**: Fail if BPM != 60 ± 2 BPM or RR interval != 360 ± 4 samples.
- **Target Testbench**: Dedicated testbench `tb/tb_qrs_multibeat_verification.sv`.
- **Dependencies**: Remove testbench `force` statements; no RTL modifications required.

---

### Priority 3: Integration Robustness

#### Test Plan Item P3-1: AXI Multi-Master Heavy Arbitration & Contention Stress
- **Purpose**: Verify interconnect arbiter under competing simultaneous requests to the same slave port from IFU (S00) and LSU (S01).
- **Stimulus**: CPU executes tight loop in IMEM (M07) while simultaneously issuing back-to-back stores to DMEM (M08) and UART (M00).
- **Expected Result**: Interconnect grants access according to priority encoder without deadlock, starvation, data interleaving, or dropped beats.
- **Interfaces**: S00, S01, Interconnect, M00, M07, M08.
- **Pass/Fail Criteria**: Fail if simulation deadlocks or data write response corrupted.
- **Target Testbench**: Dedicated stress testbench `tb/tb_axi_interconnect_stress.sv`.
- **Dependencies**: None; no RTL modifications required.

#### Test Plan Item P3-2: Dynamic Interrupt Servicing & PIC Context Switching
- **Purpose**: Validate end-to-end interrupt flow: peripheral asserts IRQ -> PIC prioritizes -> VeeR core traps to ISR -> CPU clears peripheral IRQ -> CPU returns (`mret`).
- **Stimulus**: Configure Timer for 500-cycle periodic interrupt. CPU initializes `mtvec`, enables global interrupts (`mstatus.mie = 1`, `mie.meie = 1`), and executes background counting loop.
- **Expected Result**: Timer interrupt triggers trap; CPU jumps to ISR address; ISR reads `TIMER_INT_STS`, clears it, increments interrupt counter in DMEM, and executes `mret` back to main program.
- **Interfaces**: Timer M02 -> `timer_irq` -> VeeR PIC `extintsrc_req[3]` -> VeeR pipeline.
- **Pass/Fail Criteria**: Fail if CPU fails to vector to ISR or hangs in trap.
- **Target Testbench**: Firmware test with ISR support (`firmware/tb_cardioedge_firmware.sv`).
- **Dependencies**: Updated IMEM assembly or C startup with trap handler; no RTL modifications required.

---

### Priority 4: Application Validation

#### Test Plan Item P4-1: Multi-Record Clinical ECG Dataset Arrhythmia Evaluation
- **Purpose**: Evaluate the complete CARDIOEDGE SoC against standardized multi-record clinical ECG waveforms with known medical labels.
- **Stimulus**: Execute firmware that streams 4 synthesized records (`REC_NSR_01`, `REC_BRADY_02`, `REC_TACHY_03`, `REC_ARRHY_04`) from [`firmware/ecg_dataset.h`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/ecg_dataset.h) into QRS accelerator.
- **Expected Result**:
  - `REC_NSR_01` (Normal): RR = 360, BPM = 60, Rhythm Class = `2'b00` (NORMAL).
  - `REC_BRADY_02` (Bradycardia): RR = 480, BPM = 45, Rhythm Class = `2'b01` (ABNORMAL).
  - `REC_TACHY_03` (Tachycardia): RR = 180, BPM = 120, Rhythm Class = `2'b10` (ABNORMAL).
  - `REC_ARRHY_04` (Arrhythmia): Premature beats detected, Rhythm Class = `2'b10` / `2'b01`.
  - Firmware computes Confusion Matrix (TP, FP, TN, FN) and prints complete clinical summary out of UART.
- **Interfaces**: Full SoC (CPU, IMEM, DMEM, QRS M06, UART M00).
- **Pass/Fail Criteria**: Fail if classification accuracy < 95% on reference dataset.
- **Target Testbench**: `firmware/tb_cardioedge_firmware.sv` with real WTSEE hardware enabled (removing clock gate forces).
- **Dependencies**: Integrated firmware C application; no RTL modifications required.

---

## 13. Exact Evidence References to Source Files and Logs

| Evidence Item | Source File & Location | Log File & Location | Description / Excerpt |
|---|---|---|---|
| **18/18 Regression Pass Banner** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L964-L976) | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L486-L497) | `CARDIOEDGE RISC-V INTEGRATION: PASS. ALL 18 REGRESSION CHECKS PASSED WITH ZERO ERRORS. Simulation time: 73090000 ps. Wed Oct 7 14:32:59 2026.` |
| **Initial Fetch ARADDR = 0x0** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L396-L413) | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L60-L68) | `[IFU] ARADDR = 0x00000000 (Fetch #1). EXPECTED: Reset vector fetch ARADDR = 0x0000_0000. ACTUAL: First fetch ARADDR = 0x00000000.` |
| **ALU & Loop DMEM Results** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L489-L505) | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L156-L160) | `[ALU ADD/SUB & BEQ] ACTUAL: 0x0000001e. [ALU SLLI] ACTUAL: 0x00000028. [COUNTDOWN LOOP] ACTUAL: 0x00000000.` |
| **UART Weak Pass Check** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L529-L537) | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L175-L179) | `if (uart_access_count >= 1) begin ... [PASS] UART ACCESS end. Observed 3 UART register transactions over AXI M00.` |
| **SPI Unmapped Dummy Return** | [`rtl/riscv/axi_imem_slave.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/rtl/riscv/axi_imem_slave.sv#L170-L174) | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L276-L279) | `mem[49] = 32'h00482B83; // lw s7, 4(a6) (read SPI offset +4). Actual: 0x61626364. Offset 0x04 is unmapped dummy return.` |
| **QRS Forcing in Test 13** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L771-L778), L803-810 | [`run/sim.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim.log#L384-L416) | `force dut.u_qrs.ecg_sample_reg = cur_ecg_sample; force dut.u_qrs.ecg_valid_pulse = 1'b1; release dut.u_qrs.ecg_valid_pulse;` |
| **Clock Gate Forcing in FW TB** | [`firmware/tb_cardioedge_firmware.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/tb_cardioedge_firmware.sv#L550-L557) | None (`sim_firmware.log` absent) | `force dut.u_qrs.u_wtsee.cg0.en = 1'b0; force dut.u_qrs.u_wtsee.cg1.en = 1'b0; force dut.u_qrs.rpeak_q = forced_rpeak;` |
| **Firmware Void Cast of R-Peak**| [`firmware/cardioedge_test.c`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware/cardioedge_test.c#L645-L646) | None | `uint32_t rpeak = qrs_read_rpeak(); (void)rpeak; // Discards detector result` |
| **QRS Standalone False Detections** | [`tb/tb_ecg_wtsee_optimized_top.v`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_ecg_wtsee_optimized_top.v#L275-L280) | [`run/sim_qrs_standalone.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_qrs_standalone.log#L670-L687) | `Input Samples: 2200. Detected R-Peaks: 22. Valid Results: 21. Expected R-Peaks: 6. Excessive false search-back peaks on trailing zero data.` |
| **Interconnect 3x18 Standalone**| [`tb/tb_axi_interconnect_wrap_3x18.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_axi_interconnect_wrap_3x18.sv#L50-L200) | [`run/sim_3x18.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_3x18.log#L97-L101) | `SIMULATION COMPLETE. PASS: 58. FAIL: 0. Wed Oct 7 12:07:44 2026.` |
| **Bridged SoC Test (No CPU)** | [`tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv) | [`run/sim_fixed.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_fixed.log#L107-L115) | `ADC INTEGRATION RESULT: PASS. Line 1060. Simulation time: 3700000 ps. Tue Oct 6 14:16:26 2026.` |
| **Timeout Failure in Early Run** | [`tb/tb_cardioedge_riscv_soc.sv`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/tb/tb_cardioedge_riscv_soc.sv#L677) | [`run/sim_cardioedge_riscv.log`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/run/sim_cardioedge_riscv.log#L98-L105) | `[WATCHDOG TIMEOUT] Simulation exceeded maximum cycle limit. CARDIOEDGE RISC-V INTEGRATION: FAIL (TIMEOUT). Wed Oct 7 10:57:57 2026.` |

---

## 14. Recommended Next Steps

1. **Step 1: Execute Firmware Simulation & Capture Output Log**:
   - Run `./simv_firmware -no_save +HEX=../firmware/cardioedge_test.vhx -l sim_firmware.log` inside `run/` to resolve the current `INCONCLUSIVE` status of the compiled firmware executable.
2. **Step 2: Remove Testbench Forcing in Firmware Testbench**:
   - In `firmware/tb_cardioedge_firmware.sv`, delete the `force` statements on `cg0.en`, `cg1.en`, and `u_qrs.*_q` so that the real WTSEE hardware detector processes ECG samples fed by software.
3. **Step 3: Integrate Multi-Record Dataset into Firmware Application**:
   - Update `firmware/cardioedge_test.c` to include `ecg_dataset.h`, iterate over the 4 synthesized records, read `QRS_REG_RPEAK`, `QRS_REG_RR_INTERVAL`, `QRS_REG_BPM`, and `QRS_REG_RHYTHM_CLASS`, and print beat counts and classification outcomes over the UART console.
4. **Step 4: Implement Real Output Checking for FIR and SPI**:
   - Create directed testbenches verifying that `fir_m_axis_tdata` matches reference filter math and SPI `spi_mosi_o` transmits programmed data bytes.
5. **Step 5: Instrument Build Configuration for Unified Code & Functional Coverage**:
   - Add `-cm line+cond+fsm+tgl+branch` flags to VCS compile and simulation invocations to obtain authoritative code coverage metrics.

---

## 15. Initial and Final Git Status

### Initial Git Status (at audit start):
```text
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   rtl/Cores-VeeR-EL2 (modified content)

no changes added to commit (use "git add" and/or "git commit -a")
```

### Final Git Status (at audit completion):
```text
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
  (commit or discard the untracked or modified content in submodules)
	modified:   rtl/Cores-VeeR-EL2 (modified content)

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	verification/

no changes added to commit (use "git add" and/or "git commit -a")
```

---

## 16. Preservation and Non-Modification Statement

**Explicit Project Preservation Confirmation**:  
During this audit, **no existing project files were modified, overwritten, regenerated, cleaned, or deleted**.  
In particular:
- Western Digital VeeR EL2 RTL and its pre-existing submodule state were preserved untouched.
- `cardioedge_cpu_soc_top.sv` was preserved untouched.
- AXI 3×18 interconnect fabric, priority encoders, and arbiters were preserved untouched.
- AXI 64-to-32 adapters, AXI4-to-AXI4-Lite bridges, and dummy slaves were preserved untouched.
- IMEM and DMEM memory slaves were preserved untouched.
- UART, GPIO, Timer, FIR, ADC, SPI, and QRS peripheral RTL modules were preserved untouched.
- The authoritative integration testbench (`tb/tb_cardioedge_riscv_soc.sv`) was preserved untouched.
- The original regression filelist (`run/filelist_cardioedge_riscv_soc.f`) was preserved untouched.
- Existing firmware source files, binaries, and build scripts were preserved untouched.
- Existing simulation logs, executables, and documentation were preserved untouched.
- No destructive Git commands were run.
- The only file created was this audit document: [`verification/CARDIOEDGE_FEATURE_COVERAGE_AUDIT.md`](file:///home/student/Documents/HONOURS_CBP_CARDIOEDGE/verification/CARDIOEDGE_FEATURE_COVERAGE_AUDIT.md).
