# CARDIOEDGE — Firmware Architecture & Laboratory Verification Guide

**Project Root**: `/home/student/Documents/HONOURS_CBP_CARDIOEDGE`  
**Firmware Directory**: `/home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware`  
**Target Processor**: Western Digital VeeR EL2 Core (RV32IMC)  
**Interconnect Fabric**: Shared Group 3×18 AXI4 Interconnect  
**RTL Baseline**: Frozen & Verified (18/18 Tests Pass, 0 Failures)

---

## 1. System Architecture Overview

```text
               start.S + cardioedge_test.c
                            │
                            ▼
           riscv64-unknown-elf-gcc (-march=rv32imc -mabi=ilp32)
                            │
                            ▼
                   cardioedge_test.elf
                            │
             ┌──────────────┼──────────────┐
             ▼              ▼              ▼
     cardioedge_test.bin  (.hex)  cardioedge_test.vhx (Verilog HEX)
                                           │
                                           ▼ ($readmemh backdoor)
                               tb_cardioedge_firmware.sv
                                           │
                                           ▼
                                 EXISTING IMEM (M07)
                                           │
                                           ▼
                                   VeeR EL2 (RV32IMC)
                                           │
                                           ▼ (LSU AXI 64->32)
                                 AXI 3×18 Fabric
                                           │
       ┌──────────┬──────────┬─────────────┼──────────┬──────────┬──────────┐
       ▼          ▼          ▼             ▼          ▼          ▼          ▼
     UART       GPIO       TIMER          FIR        ADC        SPI        QRS
    (0x4000)   (0x4002)   (0x4004)      (0x400C)   (0x400E)   (0x4010)   (0x4012)
```

---

## 2. Memory & Peripheral Register Map

### A. Memory Regions

| Region | Port | Base Address | Top Address | Size | Function |
|---|---|---|---|---|---|
| **IMEM** | M07 | `0x0000_0000` | `0x0000_FFFF` | 64 KiB | Instruction SRAM (Reset Vector: `0x0000_0000`) |
| **DMEM** | M08 | `0x0001_0000` | `0x0001_FFFF` | 64 KiB | Data SRAM (`.data`, `.bss`, Stack: `0x0001_8000`) |

### B. Peripheral Register Map (Verified Against RTL)

| Peripheral | Base Address | Register Offset | Name | Type | Access | Description |
|---|---|---|---|---|---|---|
| **UART** | `0x4000_0000` | `+0x00` | `UART_THR` / `RBR` | WO / RO | 32-bit (byte 0) | TX Data / RX Data (DLAB=0) |
| | | `+0x04` | `UART_IER` | RW | 32-bit | Interrupt Enable Register |
| | | `+0x08` | `UART_BAUD_DIV` | WO | 32-bit | Baud Divisor (DLAB=1) |
| | | `+0x0C` | `UART_LCR` | RW | 32-bit | Line Control (`0x03` = 8N1) |
| | | `+0x14` | `UART_LSR` | RO | 32-bit | Line Status (`[5]` = THRE empty) |
| **GPIO** | `0x4000_2000` | `+0x00` | `GPIO_DATA_I` | RO | 32-bit (`[7:0]`) | Input pin levels (debounced) |
| | | `+0x04` | `GPIO_DATA_O` | RW | 32-bit (`[7:0]`) | Output pin levels |
| | | `+0x08` | `GPIO_DIR` | RW | 32-bit (`[7:0]`) | Pin direction (`1` = Output, `0` = Input) |
| | | `+0x20` | `GPIO_SET_O` | WO | 32-bit (`[7:0]`) | Atomic bit set for `DATA_O` |
| | | `+0x24` | `GPIO_CLR_O` | WO | 32-bit (`[7:0]`) | Atomic bit clear for `DATA_O` |
| | | `+0x28` | `GPIO_TGL_O` | WO | 32-bit (`[7:0]`) | Atomic bit toggle for `DATA_O` |
| **TIMER** | `0x4000_4000` | `+0x00` | `TIMER_CTRL` | RW | 32-bit | Control (`[0]`: En, `[1]`: Mode, `[2]`: Pre) |
| | | `+0x04` | `TIMER_LOAD` | RW | 32-bit | Counter load value (forces reload) |
| | | `+0x08` | `TIMER_VAL` | RO | 32-bit | Current counter value |
| | | `+0x10` | `TIMER_INT_EN` | RW | 32-bit | Interrupt enable (`[0]`: Expire IRQ) |
| | | `+0x14` | `TIMER_INT_STS`| R/W1C| 32-bit | Sticky interrupt status |
| **FIR** | `0x4000_C000` | `+0x00` | `FIR_CTRL` | RW | 32-bit (`[0]`) | FIR filter engine enable |
| | | `+0x04` | `FIR_LOAD` | WO | 32-bit (`[0]`) | Latch coefficients to active register bank |
| | | `+0x08` | `FIR_STATUS` | RO | 32-bit | FIFO status flags |
| | | `+0x10+n*4`| `FIR_COEFF(n)`| RW | 32-bit (`[15:0]`)| Filter tap `n` coefficient (`n = 0..31`) |
| **ADC** | `0x4000_E000` | `+0x00` | `ADC_CTRL` | RW | 32-bit | Control (`[0]`: En, `[1]`: Start sample) |
| | | `+0x04` | `ADC_STATUS` | RO/W1C | 32-bit | Status (`[2]`: FIFO empty flag = `0x04`) |
| | | `+0x08` | `ADC_SAMPLE_DATA`| RO | 32-bit (`[11:0]`)| Latest 12-bit acquired sample |
| | | `+0x0C` | `ADC_FIFO_DATA` | RO | 32-bit (`[11:0]`)| FIFO sample (reading pops FIFO) |
| **SPI** | `0x4001_0000` | `+0x1C` | `SPI_GIER` | RW | 32-bit | Global Interrupt Enable |
| | | `+0x40` | `SPI_SRR` | WO | 32-bit | Soft reset register (write `0x0A`) |
| | | `+0x60` | `SPI_CR` | RW | 32-bit | Control register (Reset: `0x00000180`) |
| | | `+0x64` | `SPI_SR` | RO | 32-bit | Status register (Reset: `0x000000A5`) |
| | | `+0x68` | `SPI_DTR` | WO | 32-bit (`[7:0]`) | TX Data Register (push into FIFO) |
| | | `+0x70` | `SPI_SSR` | RW | 32-bit | Slave Select Register (Reset: `0xFFFFFFFF`) |
| | | `+0x04` | *Unmapped* | RO | 32-bit | Architectural default return (`0x61626364`) |
| **QRS** | `0x4001_2000` | `+0x00` | `QRS_CONTROL` | RW | 32-bit (`[0]`) | QRS WTSEE engine enable |
| | | `+0x04` | `QRS_STATUS` | RO | 32-bit | Status (`[0]`: active, `[1]`: result valid) |
| | | `+0x08` | `QRS_ECG_INPUT`| RW | 32-bit (`[15:0]`)| **Signed 16-bit ECG sample input (auto valid pulse)** |
| | | `+0x0C` | `QRS_RPEAK` | RO | 32-bit (`[0]`) | R-peak detection indicator pulse |
| | | `+0x10` | `QRS_RR_INTERVAL`| RO | 32-bit (`[15:0]`)| RR interval duration in clock counts |
| | | `+0x14` | `QRS_BPM` | RO | 32-bit (`[15:0]`)| Heart rate (Beats Per Minute) |
| | | `+0x18` | `QRS_RHYTHM` | RO | 32-bit (`[1:0]`)| Rhythm classification (Normal, etc.) |

---

## 3. Known Hardware Constraints & Boundaries

1. **FIR Filter Datapath**:
   - Software configures FIR engine enable (`0x4000C000`), latches coefficients (`0x4000C004`), and reads status (`0x4000C008`).
   - The actual streaming ECG sample datapath is **purely AXI4-Stream** (`fir_s_axis_*` and `fir_m_axis_*`) connected at the hardware top level. There is **no** software memory-mapped FIFO write register for feeding samples into FIR via CPU MMIO. Software does not fake this path.
2. **QRS Peak Detector Streaming**:
   - The QRS wrapper provides a direct memory-mapped register at `0x40012008` (`QRS_REG_ECG_INPUT`). Writing a signed 16-bit sample when `QRS_CONTROL[0] == 1` generates a hardware `ecg_valid` strobe into the WTSEE QRS core. Software exercises this real path using clinical ECG samples from `tb/ecg_input.txt`.
3. **IMEM Hardware Loader**:
   - `axi_imem_slave.sv` has a hardcoded initialization block in RTL and was left **100% untouched** per the frozen baseline rule.
   - Dynamic simulation loading is accomplished via the new testbench (`tb_cardioedge_firmware.sv`), which performs a non-invasive `$readmemh` into `dut.u_imem.mem` during the initial block.

---

## 4. Software Build Instructions

### Prerequisites
A 32-bit capable RISC-V GCC toolchain is required:
- `riscv64-unknown-elf-gcc` (multi-lib) or `riscv32-unknown-elf-gcc`
- Target flags **must** specify: `-march=rv32imc -mabi=ilp32`

### Build via Makefile
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware

# Compile ELF, generate HEX, VHX, BIN, and disassembly:
make

# Individual targets:
make hex          # Intel HEX (cardioedge_test.hex)
make vhx          # Verilog HEX for $readmemh (cardioedge_test.vhx)
make bin          # Flat Binary (cardioedge_test.bin)
make disassemble  # Assembly dump (cardioedge_test.dump)
make size         # Memory footprint report
make clean        # Clean build artifacts
```

### Build via Helper Script
```bash
cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE/firmware
./generate_hex.sh
```

---

## 5. Expected Console Output on UART

When the firmware runs on the SoC, `tb_cardioedge_firmware.sv` intercepts the UART transmitter and displays the following live verification trace:

```text
CARDIOEDGE C TEST
=================

CPU STARTED

UART TEST
  PASS: UART configured 8N1, TX holding empty confirmed
GPIO TEST
  PASS: GPIO DIR=0xFF, DATA_O write/readback verified
TIMER TEST
  PASS: TIMER LOAD=100 and CTRL enable/start verified
ADC TEST
  PASS: ADC scheduler enabled, STATUS empty flag=0x04 confirmed
FIR TEST
  PASS: FIR enable=1, Tap0=0x0100 latched, AXI-Stream ready
SPI TEST
  PASS: SPI CR/SR verified, unmapped response 0x61626364 verified
QRS TEST
  PASS: QRS enabled, 32 clinical ECG samples streamed to 0x40012008

ALL TESTS PASSED
TEST COMPLETE
```

---

## 6. Tomorrow's Laboratory Procedure (Step-by-Step)

Follow these 16 steps in the lab to compile the firmware and verify execution in VCS:

```text
 1. Enter CARDIOEDGE project root:
    cd /home/student/Documents/HONOURS_CBP_CARDIOEDGE

 2. Source the lab environment / load RISC-V module:
    module load riscv-toolchain   # (or laboratory equivalent)

 3. Verify compiler availability:
    which riscv64-unknown-elf-gcc
    riscv64-unknown-elf-gcc --version

 4. Verify objcopy availability:
    which riscv64-unknown-elf-objcopy

 5. Enter firmware directory:
    cd firmware

 6. Build cardioedge_test.elf:
    make

 7. Generate flat binary:
    make bin

 8. Generate Intel HEX:
    make hex

 9. Generate Verilog HEX:
    make vhx

10. Verify that cardioedge_test.vhx exists:
    ls -lh cardioedge_test.vhx

11. Navigate to the simulation run directory:
    cd ../run

12. Setup Synopsys VCS environment:
    export VCS_HOME=/home/student/snps_tools_target/vcs/U-2023.03
    export PATH=$VCS_HOME/bin:$PATH
    export SNPSLMD_LICENSE_FILE=27021@14.139.1.126

13. Compile the NEW firmware testbench with existing SoC RTL:
    vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
        -f ../firmware/filelist_cardioedge_firmware.f -l compile_firmware.log

14. Execute the simulation (loads cardioedge_test.vhx automatically):
    ./simv -no_save +HEX=../firmware/cardioedge_test.vhx -l sim_firmware.log

15. Observe live UART execution trace on console:
    Verify that all 7 peripheral tests report PASS.

16. Record verification results and log files for final report.
```
