# CardioEdge — AXI4 RISC-V SoC Hardware Project

> **CardioEdge** is a RISC-V-based real-time ECG acquisition and processing SoC project.  
> The project is being developed as a synthesizable RTL system with AXI-based memory-mapped peripherals, hardware signal-processing blocks, verification environments, and a VeeR EL2 processor integration path.

---

## 1. Project Overview

CardioEdge is designed around a **VeeR EL2 RISC-V processor complex** and a memory-mapped AXI fabric. The application architecture targets:

- ECG sample acquisition
- Digital ECG signal conditioning
- FIR filtering
- QRS/heartbeat detection
- Heart-rate and RR-interval calculation
- Arrhythmia indication
- UART-based reporting/debug
- SPI-based peripheral communication

The frozen CardioEdge AXI4 specification defines a **64-bit AXI4 system**, 32-bit addressing, separate VeeR IFU/LSU master interfaces, and nine memory-mapped CardioEdge slave targets.

### Target architectural fabric

```text
                    +----------------------+
                    |      VeeR EL2       |
                    |                      |
                    | IFU AXI4  | LSU AXI4|
                    +------+-----+----+-----+
                           |          |
                           +----+-----+
                                |
                                v
                    +----------------------+
                    |    AXI4 Interconnect |
                    |                      |
                    |   Target: 2 x 9      |
                    |   64-bit AXI4        |
                    +----------+-----------+
                               |
       +----------+------------+------------+------------+
       |          |            |            |            |
      IMEM      DMEM         UART         Timer        GPIO
       |          |            |            |            |
       +----------+------------+------------+------------+
                               |
                    +----------+----------+
                    |                     |
                   ADC                   FIR
                                         |
                                         v
                                  FIR-QRS FIFO
                                         |
                                         v
                                        QRS
                                         |
                                         v
                              BPM / RR / Arrhythmia
```

---

## 2. Current Repository Snapshot

This README describes the uploaded repository archive:

`HONOURS_CBP_CARDIOEDGE-main`

The archive contains RTL, testbenches, documentation, scripts, and simulator-generated files.

### Main source areas

```text
proj-dir/
├── rtl/
│   ├── interconnect/
│   ├── uart/
│   ├── aes_axi_slave/
│   └── verilog_aes/
├── tb/
├── scripts/
├── doc/
├── aes256_axi/
└── run/
```

The uploaded archive contains **442 archived entries**, including source files, documentation, simulation output, and generated VCS/Verdi artifacts.

---

## 3. Repository Structure

### `rtl/interconnect/`

Contains the AXI interconnect infrastructure.

```text
rtl/interconnect/
├── arbiter.v
├── priority_encoder.v
├── axi_interconnect.v
└── axi_interconnect_wrap_3x14.v
```

#### `axi_interconnect.v`

Generic AXI4 interconnect implementation.

Current source defaults include:

- `DATA_WIDTH = 32`
- `ADDR_WIDTH = 32`
- `STRB_WIDTH = DATA_WIDTH/8`
- `ID_WIDTH = 8`
- Configurable number of AXI slave-side inputs
- Configurable number of AXI master-side outputs
- Configurable address regions
- Optional ID forwarding
- Read/write connection configuration

The source is parameterized and can therefore be configured for a wider data path without changing the original source file.

#### `axi_interconnect_wrap_3x14.v`

Generated/configured wrapper providing:

- **3 AXI master-side inputs**
- **14 AXI slave/IP-side outputs**
- Parameterized data/address/ID widths
- Individual address parameters for the 14 output slots

The current wrapper is being retained as reusable infrastructure for multiple projects.

Current project direction:

```text
M0 = VeeR IFU
M1 = VeeR LSU
M2 = Reserved/Dummy/Future Master

S0-S8  = CardioEdge / project IP slots
S9-S13 = Future / additional project IP slots
```

> The **frozen CardioEdge application specification itself defines 2 masters × 9 slaves**. The 3×14 wrapper is being retained as a reusable/common interconnect infrastructure for the wider honours project work.

---

## 4. UART RTL

The UART source is located at:

```text
rtl/uart/
├── axi_uart_top.v
├── axi_internal_fifo.v
├── uart_controller.v
├── uart_parity_bit_compute.v
├── uart_receiver.v
├── uart_transmitter.v
└── include/
    ├── axi_uart.vh
    └── axi_uart_defines.vh
```

### UART architecture

```text
AXI UART top
     |
     +-- AXI register interface
     |
     +-- UART controller
            |
            +-- TX FIFO
            +-- RX FIFO
            +-- transmitter
            +-- receiver
            +-- parity logic
```

The supplied UART IP is an **AXI4-Lite UART**.

The current UART definition specifies:

```text
AXI data width : 32 bits
AXI address    : 5 bits
AXI ID width   : 12 bits
FIFO depth     : 32
UART data      : 8 bits
```

The UART's internal 8-bit TX/RX datapath is intentional and does not need to be converted to 64 bits.

### Integration strategy

The original UART source is intended to remain unchanged.

A dedicated wrapper is planned between the CardioEdge AXI4 fabric and the existing UART:

```text
64-bit AXI4
     |
     v
+----------------------+
| uart_axi4_wrapper    |
|                      |
| AXI4 -> AXI4-Lite    |
| 64-bit -> 32-bit     |
+----------+-----------+
           |
           v
     Original UART
```

This preserves the original UART IP while allowing it to participate in the final CardioEdge architecture.

---

## 5. AES-256 RTL

AES sources are present in both:

```text
rtl/aes_axi_slave/
rtl/verilog_aes/
```

and also under the standalone:

```text
aes256_axi/
```

directory.

### AES AXI slave

```text
rtl/aes_axi_slave/aes_axi_slave.sv
```

The supplied AES AXI slave currently uses a **32-bit AXI register interface**.

The register map documented in the source is:

| Offset | Register | Description |
|---:|---|---|
| `0x00` | CONTROL/STATUS | START, DECRYPT, DONE, BUSY |
| `0x04` | KEY0 | Key bits `[31:0]` |
| `0x08` | KEY1 | Key bits `[63:32]` |
| `0x0C` | KEY2 | Key bits `[95:64]` |
| `0x10` | KEY3 | Key bits `[127:96]` |
| `0x14` | KEY4 | Key bits `[159:128]` |
| `0x18` | KEY5 | Key bits `[191:160]` |
| `0x1C` | KEY6 | Key bits `[223:192]` |
| `0x20` | KEY7 | Key bits `[255:224]` |
| `0x24` | DATA_IN0 | Input bits `[31:0]` |
| `0x28` | DATA_IN1 | Input bits `[63:32]` |
| `0x2C` | DATA_IN2 | Input bits `[95:64]` |
| `0x30` | DATA_IN3 | Input bits `[127:96]` |
| `0x34` | DATA_OUT0 | Output bits `[31:0]` |
| `0x38` | DATA_OUT1 | Output bits `[63:32]` |
| `0x3C` | DATA_OUT2 | Output bits `[95:64]` |
| `0x40` | DATA_OUT3 | Output bits `[127:96]` |

The AES core itself is implemented in:

```text
rtl/verilog_aes/
├── aes_cipher_top.v
├── aes_inv_cipher_top.v
├── aes_inv_sbox.v
├── aes_key_expand_256.v
├── aes_rcon.v
└── aes_sbox.v
```

---

## 6. CardioEdge AXI4 Specification

The repository contains:

```text
doc/CardioEdge_AXI4_Specification_v2.docx
```

The specification identifies the following frozen system-level requirements.

### AXI configuration

| Parameter | Specification |
|---|---|
| Protocol | AXI4 |
| Data width | **64 bits** |
| Address width | **32 bits** |
| Write strobes | **8 bits** |
| Clock | **50 MHz** |
| Reset | Active-low synchronous `rst_n` |
| Masters | VeeR IFU + VeeR LSU |
| Memory-mapped slaves | 9 |
| Register width | 32-bit registers transported over 64-bit AXI4 |
| FIR-QRS FIFO | Dedicated streaming path, not AXI mapped |

### CardioEdge memory map

| Slave | Block | Address range |
|---|---|---|
| S0 | Instruction Memory | `0x0000_0000 – 0x0000_FFFF` |
| S1 | Data Memory | `0x0001_0000 – 0x0001_FFFF` |
| S2 | UART | `0x1000_0000 – 0x1000_00FF` |
| S3 | Timer | `0x1000_0100 – 0x1000_01FF` |
| S4 | GPIO | `0x1000_0200 – 0x1000_02FF` |
| S5 | ADC Interface | `0x1000_0300 – 0x1000_03FF` |
| S6 | FIR | `0x1000_0400 – 0x1000_04FF` |
| S7 | QRS | `0x1000_0500 – 0x1000_05FF` |
| S8 | SPI2 | `0x1000_0600 – 0x1000_06FF` |

The dedicated FIR-to-QRS FIFO is not memory mapped.

---

## 7. ECG Processing Architecture

The intended application data path is:

```text
ADC
 |
 v
ADC FIFO
 |
 v
VeeR firmware
 |
 | AXI4 write
 v
FIR input
 |
 v
31-tap FIR
 |
 v
FIR-QRS FIFO
 |
 v
QRS Accelerator
 |
 +--> Heart Rate / BPM
 +--> RR Interval
 +--> Beat Detected
 +--> Arrhythmia Flag
```

The specification defines:

- 12-bit ECG acquisition
- Fixed 250 Hz sample rate
- 32-entry ADC acquisition FIFO
- 31-tap signed fixed-point FIR
- 40-bit FIR accumulation
- Optional 50 Hz / 60 Hz notch coefficient banks
- 32 × 16-bit FIR-to-QRS FIFO
- QRS derivative, squaring, integration, thresholding and refractory processing
- Heart-rate calculation
- RR-interval calculation
- Arrhythmia indication based on RR deviation
- Flat interrupt fan-in

---

## 8. Interrupt Architecture

The specification uses a flat interrupt OR rather than a programmable interrupt controller.

Conceptually:

```text
irq_timer
irq_adc_sample
irq_adc_overrun
irq_qrs_beat
irq_qrs_arrhythmia
       |
       v
   +-------+
   |   OR  |
   +---+---+
       |
       v
      irq_i
       |
       v
    VeeR EL2
```

No separate programmable interrupt controller is part of the frozen CardioEdge architecture.

---

## 9. Verification

### Interconnect testbench

```text
tb/tb_axi_interconnect_wrap_3x14.sv
```

The current testbench is configured for:

```text
3 masters × 14 slaves
DATA_WIDTH = 32
ID_WIDTH   = 8
```

It uses inline responder logic and does not require external AXI VIP.

The current testbench models 16 MB windows using base addresses of the form:

```text
slave N -> N << 24
```

This is the **current generic interconnect test configuration**, not the final CardioEdge memory map.

### UART standalone testbench

```text
tb/uart_standalone_tb.sv
```

The UART testbench exercises AXI UART register accesses and includes timeout/handshake checking.

The supplied testbench comments indicate that the UART implementation expects specific handshake behavior, including keeping the read request asserted while waiting for the response.

### AES testbench

```text
tb/aes_axi_slave_tb.sv
```

Tests the AES AXI slave through its 32-bit register interface.

### AES top-level testbench

```text
tb/aes_test_bench_top.v
```

---

## 10. Simulation / Tooling

The repository contains evidence of **Synopsys VCS** usage.

The interconnect testbench identifies:

```text
Tool: Synopsys VCS
Language: SystemVerilog
UVM: Not required for the inline interconnect testbench
```

The repository also contains generated VCS/Verdi artifacts under `run/`.

### Typical VCS command

A representative command documented by the repository's compile log is:

```bash
vcs -full64 -sverilog -ntb_opts uvm \
    -debug_access+all -kdb \
    -f filelist.f \
    -l compile.log
```

> The archived `compile.log` records a failure because `filelist.f` was not found in that particular invocation. Therefore, this README does **not** claim that the complete repository currently builds successfully from a clean checkout.

---

## 11. Current Development Status

### Present in the repository

- [x] AXI interconnect RTL
- [x] 3×14 AXI interconnect wrapper
- [x] Arbitration/priority support
- [x] AXI UART IP
- [x] UART TX/RX/FIFO/parity RTL
- [x] AES-256 RTL
- [x] AES AXI slave
- [x] AES standalone verification
- [x] UART standalone verification
- [x] Interconnect verification environment
- [x] CardioEdge AXI4 specification
- [x] Supporting scripts
- [ ] Final VeeR EL2 integration
- [ ] Final 64-bit CardioEdge interconnect configuration
- [ ] UART AXI4 compatibility wrapper
- [ ] AES AXI compatibility wrapper
- [ ] Remaining CardioEdge peripheral IPs
- [ ] Final CardioEdge top-level SoC
- [ ] Complete end-to-end firmware/software integration
- [ ] Complete SoC regression

---

## 12. Wrapper-Based Integration Strategy

A key project design rule is:

> **Original IP files should remain unchanged. Interface adaptation should be performed in dedicated wrapper modules.**

This allows each supplied IP to remain independently testable while providing a consistent system-level AXI interface.

### Planned integration structure

```text
VeeR EL2
   |
   v
[VeeR AXI Wrapper]
   |
   v
Common AXI4 Interconnect
   |
   +--> [IMEM Wrapper] --> Existing IMEM
   |
   +--> [DMEM Wrapper] --> Existing DMEM
   |
   +--> [UART Wrapper] --> Existing AXI UART
   |
   +--> [Timer Wrapper] --> Existing Timer
   |
   +--> [GPIO Wrapper] --> Existing GPIO
   |
   +--> [ADC Wrapper] --> Existing ADC
   |
   +--> [FIR Wrapper] --> Existing FIR
   |
   +--> [QRS Wrapper] --> Existing QRS
   |
   +--> [SPI2 Wrapper] --> Existing SPI
   |
   +--> Future / Dummy slots
```

The wrapper strategy also supports the wider **3-master × 14-slot reusable interconnect infrastructure** being developed for the honours project.

---

## 13. Width-Checking Rule

Before integrating any IP, its bus interface must be checked.

The target CardioEdge system is:

```text
AXI protocol : AXI4
AXI data     : 64 bits
AXI address  : 32 bits
WSTRB        : 8 bits
```

Peripheral registers remain 32 bits.

Therefore, a peripheral can internally remain 32-bit or 8-bit while its system wrapper exposes the required 64-bit AXI4 interface.

Example:

```text
64-bit AXI4
     |
     v
+--------------------+
| Peripheral Wrapper |
|                    |
| 64-bit bus         |
| 32-bit registers   |
+---------+----------+
          |
          v
Original IP
```

---

## 14. Addressing and Register Adaptation

CardioEdge architectural registers are 32 bits even though the AXI data bus is 64 bits.

For a register read:

```text
RDATA[31:0]  = register value
RDATA[63:32] = 0
```

For a register write:

```text
WDATA[31:0]  = register value
WSTRB        = applicable lower byte lanes
```

The upper half of the 64-bit AXI data bus is ignored by 32-bit architectural peripherals unless a peripheral-specific rule says otherwise.

---

## 15. Current Integration Roadmap

### Phase 1 — Existing IP verification

1. Verify each IP independently.
2. Confirm AXI protocol behavior.
3. Confirm register maps.
4. Confirm data widths.
5. Confirm reset behavior.

### Phase 2 — Wrapper creation

Create dedicated wrappers where interfaces differ:

```text
VeeR AXI wrapper
UART AXI4 wrapper
AES AXI wrapper
...
```

Original IP sources remain unchanged.

### Phase 3 — Interconnect integration

Connect:

```text
VeeR / master wrapper
        |
        v
3 × 14 reusable AXI infrastructure
        |
        +--> S2 UART
        +--> other peripherals
```

### Phase 4 — Peripheral integration

Integrate peripherals one at a time and verify each address window independently.

### Phase 5 — Processor integration

Connect the verified AXI fabric to the VeeR EL2 IFU and LSU interfaces.

### Phase 6 — Full SoC verification

Verify:

- instruction fetch
- data memory
- peripheral reads/writes
- interrupts
- ADC acquisition
- FIR processing
- QRS processing
- UART reporting
- SPI2 reporting
- end-to-end ECG processing

---

## 16. Repository Timeline

The following dates/times are based on the **ZIP archive file timestamps**, not Git commit history. The archive does not contain a repository-wide Git history, so these timestamps should be treated as file/archive metadata.

### Interconnect development

| Component | Archived timestamp |
|---|---|
| `arbiter.v` | 2026-08-29 13:54:32 |
| `axi_interconnect.v` | 2026-08-29 13:54:32 |
| `priority_encoder.v` | 2026-08-29 13:54:34 |
| `axi_interconnect_wrap_3x14.v` | 2026-08-29 16:02:42 |
| `tb_axi_interconnect_wrap_3x14.sv` | 2026-08-29 16:02:42 |
| `compile.log` | 2026-08-29 16:11:00 |
| `axi_interconnect_wrap.py` | 2026-08-29 13:54:38 |

### UART source

The UART IP files carry an older source timestamp:

```text
2023-05-29 16:48:32
```

This includes:

- `axi_uart_top.v`
- `axi_internal_fifo.v`
- `uart_controller.v`
- `uart_parity_bit_compute.v`
- `uart_receiver.v`
- `uart_transmitter.v`
- `axi_uart.vh`
- `axi_uart_defines.vh`

This indicates that the UART IP is an existing imported IP block rather than a newly written CardioEdge block.

### AES/CardioEdge development

The archived AES/CardioEdge files have timestamps on:

```text
2026-09-19
```

Examples include:

| Component | Archived timestamp |
|---|---|
| AES AXI slave | 2026-09-19 11:41:58 |
| AES key expansion | 2026-09-19 11:38:12 |
| AES S-box | 2026-09-19 11:36:50 |
| AES RCON | 2026-09-19 11:37:34 |
| AES cipher top | 2026-09-19 13:34:20 |
| AES inverse cipher top | 2026-09-19 13:50:16 |
| AES inverse S-box | 2026-09-19 13:46:58 |
| AES AXI testbench | 2026-09-19 13:38:52 |
| AES testbench top | 2026-09-19 12:30:00 |
| UART standalone testbench | 2026-09-19 12:04:08 |

These timestamps describe the packaged files only; they are **not proof of individual Git commits or authorship events**.

---

## 17. Important Compatibility Notes

### AXI4 vs AXI4-Lite

The final CardioEdge specification requires **AXI4**, not AXI4-Lite.

Some currently supplied IPs use 32-bit AXI4-Lite interfaces.

They should therefore be integrated through wrappers rather than by modifying the original IP.

### Current interconnect defaults

The generic interconnect source currently defaults to:

```text
DATA_WIDTH = 32
ID_WIDTH   = 8
```

The final CardioEdge architecture requires:

```text
DATA_WIDTH = 64
ID handling = preserved
```

The integration layer is responsible for resolving this interface difference while keeping the original source files intact.

### Address-window granularity

The current generic interconnect wrapper uses 24-bit address-region defaults, corresponding to large 16 MB windows.

The frozen CardioEdge map uses much smaller peripheral windows, including 256-byte UART/Timer/GPIO/etc. regions.

Therefore, the final CardioEdge address configuration must be handled deliberately rather than assuming the generic wrapper defaults are the final memory map.

---

## 18. Third-Party Source and Licensing

The interconnect source contains an MIT-style copyright/license notice attributed to **Alex Forencich**.

The UART source contains its own upstream project copyright/authorship information.

These notices should be preserved when redistributing the corresponding source files.

The uploaded archive does not contain a repository-wide `LICENSE` file. Before publishing the complete repository publicly, the project should add an appropriate top-level license and retain all required third-party notices.

---

## 19. Design Principles

The project follows these integration principles:

1. **Do not modify original IP unnecessarily.**
2. **Use wrappers for interface adaptation.**
3. **Verify bus width before integrating every IP.**
4. **Keep peripheral register semantics at 32 bits.**
5. **Use 64-bit AXI4 at the final CardioEdge system boundary.**
6. **Preserve AXI transaction IDs where required.**
7. **Keep FIR-to-QRS streaming separate from the memory-mapped AXI fabric.**
8. **Do not silently change the frozen CardioEdge address map.**
9. **Verify every IP independently before system integration.**
10. **Keep generated simulator artifacts out of source control where possible.**

---

## 20. Recommended Git Repository Cleanup

The uploaded archive contains large generated simulation directories, including VCS/Verdi artifacts.

For a clean GitHub repository, consider excluding generated files such as:

```text
run/
*.daidir/
csrc/
simv
simv.daidir/
*.vpd
*.fsdb
*.log
```

A suitable `.gitignore` should be added before the first public push.

Keep source RTL, testbenches, scripts, documentation, specifications, and required reference files under version control.

---

## 21. Getting Started

### Clone

```bash
git clone <your-repository-url>
cd HONOURS_CBP_CARDIOEDGE
```

### Inspect the RTL

```bash
find rtl -type f
```

### Inspect testbenches

```bash
find tb -type f
```

### Compile with VCS

Use the project-specific file list and VCS configuration after creating/validating the appropriate `filelist.f`.

A typical VCS/SystemVerilog invocation is:

```bash
vcs -full64 -sverilog \
    -ntb_opts uvm \
    -debug_access+all \
    -kdb \
    -f filelist.f \
    -l compile.log
```

### Run simulation

The exact simulation command depends on the selected testbench and VCS setup.

For example, after a successful VCS build:

```bash
./simv
```

---

## 22. Project Scope

### In scope

- RTL design
- AXI4 interconnect
- VeeR EL2 integration
- Memory-mapped peripherals
- ECG acquisition
- FIR filtering
- QRS detection
- Heart-rate calculation
- RR interval calculation
- Arrhythmia indication
- UART/SPI reporting
- Simulation and verification
- Firmware integration
- Synthesis-oriented RTL

### Explicitly outside the frozen CardioEdge scope

The specification explicitly excludes:

- APB interconnect
- APB bridges
- AXI4-to-APB bridges
- DMA
- Second processor
- Programmable interrupt controller
- Cache
- MMU
- OLED/BLE protocols
- Additional application accelerators
- Physical ADC hardware dependencies
- Physical SPI endpoint dependencies

---

## 23. Final Target

The final CardioEdge system is intended to converge on:

```text
                    +------------------+
                    |     VeeR EL2     |
                    |                  |
                    | IFU       LSU    |
                    +---+-------+------+
                        |       |
                        | AXI4  |
                        | 64b   |
                        v       v
                  +---------------+
                  | AXI4 FABRIC   |
                  |               |
                  | 2 Master      |
                  | 9 Slave       |
                  | 64-bit        |
                  +-------+-------+
                          |
       +---------+--------+--------+---------+
       |         |        |        |         |
      IMEM      DMEM     UART     Timer     GPIO

                          +---------+
                          |   ADC   |
                          +----+----+
                               |
                         ADC acquisition
                               |
                               v
                              FIR
                               |
                         FIR-QRS FIFO
                               |
                               v
                              QRS
                               |
                   +-----------+-----------+
                   |           |           |
                  BPM      RR Interval   Alert
```

The reusable development infrastructure may retain the **3×14 AXI wrapper** so that additional project IPs and a future/dummy third master can be accommodated without changing the original interconnect source.

---

## 24. Status

**Project stage: Active RTL integration and verification**

Current focus:

```text
[✓] Existing interconnect examined
[✓] Existing UART examined
[✓] Existing AES AXI slave examined
[✓] CardioEdge AXI4 specification available
[✓] Wrapper-based integration strategy defined
[ ] UART AXI4 wrapper
[ ] Final width adaptation
[ ] Final address-map configuration
[ ] VeeR AXI integration
[ ] Complete peripheral integration
[ ] Full SoC top
[ ] End-to-end verification
```

---

## 25. Authors / Project

**Project:** CardioEdge  
**Type:** Honours / Capstone Hardware Design Project  
**Domain:** RISC-V SoC / AXI4 / RTL / ECG Signal Processing  
**Implementation:** Verilog / SystemVerilog  
**Primary simulation environment:** Synopsys VCS / Verdi  
**Target architecture:** VeeR EL2 + AXI4 memory-mapped SoC

---

> **Note:** This README was generated from the contents and metadata of the uploaded project archive. Where the repository's current RTL configuration differs from the frozen CardioEdge AXI4 specification, the distinction is explicitly stated rather than silently treating the current RTL as the final architecture.
