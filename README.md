# CardioEdge — AXI4 RISC-V Healthcare SoC

CardioEdge is an RTL-level System-on-Chip integration project for real-time ECG acquisition and cardiac signal processing. The design combines a **RISC-V VeeR EL2 processor**, an **AXI4 interconnect**, dedicated ECG/QRS processing hardware, and multiple AXI-connected peripheral IPs.

The current repository focuses on **RTL integration and simulation verification**. It is not a tape-out implementation.

---

## Project Overview

The SoC is organized around a shared AXI4 infrastructure. Peripheral IPs that expose AXI4-Lite interfaces are connected through an **AXI4-to-AXI4-Lite bridge**, allowing the same system-level AXI4 fabric to access both AXI4 and AXI4-Lite devices.

### Current Functional Blocks

- **RISC-V VeeR EL2** — processor subsystem, included as a Git submodule
- **AXI4 Interconnect** — multi-master / multi-slave address-based routing
- **UART** — serial communication
- **QRS Detector** — ECG QRS / R-peak detection hardware
- **SPI** — serial peripheral interface
- **FIR** — programmable FIR filtering with AXI4-Stream datapath
- **ADC** — sample acquisition, scheduling and FIFO support
- **GPIO** — memory-mapped GPIO peripheral
- **Timer** — timer, capture/measurement, PWM and interrupt support
- **AXI4 → AXI4-Lite Bridge** — connects AXI4 interconnect paths to AXI4-Lite peripherals

---

## High-Level Architecture

```text
                         +-------------------------+
                         |     RISC-V VeeR EL2     |
                         |      Processor Core     |
                         +------------+------------+
                                      |
                                      | AXI4
                                      v
                    +--------------------------------------+
                    |          AXI4 Interconnect           |
                    |     Address Decode / Arbitration     |
                    |          3-master × 14-slave         |
                    +----+-----+-----+-----+-----+-----+---+
                         |     |     |     |     |     |
                       UART   QRS   SPI   FIR   ADC  GPIO
                                                   |
                                                   +---- Timer
```

The current integrated top-level RTL is:

```text
rtl/soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv
```

It exposes the system AXI interface together with the external UART, SPI, FIR stream, ADC, GPIO and Timer interfaces.

---

## AXI Interconnect

The project uses:

```text
rtl/interconnect/axi_interconnect.v
rtl/interconnect/axi_interconnect_wrap_3x14.v
```

The wrapper provides a **3-master × 14-slave AXI4 fabric**.

The interconnect architecture intentionally contains more slave positions than the currently populated peripheral set so unused positions can remain available for future IP integration.

The interconnect contains supporting arbitration and address-routing logic:

```text
rtl/interconnect/arbiter.v
rtl/interconnect/priority_encoder.v
```

---

## AXI4 → AXI4-Lite Bridge

The common bridge is:

```text
rtl/common/axi4_to_axi4lite_bridge.sv
```

It provides the protocol boundary between the system AXI4 fabric and AXI4-Lite peripherals such as GPIO and Timer.

### Bridge Characteristics

- Single-beat AXI4 transactions
- One outstanding transaction per bridge
- Independent AXI4 AW and W channel capture
- AXI ID preservation for B/R responses
- AXI4 USER fields terminated at the bridge boundary
- WLAST not required downstream
- AXI4-Lite write/read handshaking preserved
- Suitable for register-mapped peripheral access

This keeps the system-side transport AXI4-based while reusing AXI4-Lite peripherals without modifying their internal register interfaces.

---

## Current Peripheral Integration

| IP | Function | Interface | Status |
|---|---|---|---|
| UART | Serial communication | AXI4-Lite | Integrated |
| QRS | ECG QRS / R-peak detection | AXI4 | Integrated |
| SPI | Serial peripheral communication | AXI4-Lite | Integrated |
| FIR | Digital filtering | AXI4-Lite + AXI4-Stream | Integrated |
| ADC | ECG sample acquisition | AXI4-Lite | Integrated |
| GPIO | General-purpose digital I/O | AXI4-Lite | Integrated |
| Timer | Timer / capture / PWM / IRQ | AXI4-Lite | Integrated |

---

## ECG / QRS Processing

The QRS subsystem is implemented as dedicated RTL for hardware ECG processing.

The processing chain contains blocks for:

- Baseline filtering
- First-difference processing
- Moving-window sums
- Non-linear processing
- Shannon-energy related processing
- Peak detection
- Search-back processing
- RR classification
- AXI4 register/control access

Important QRS files include:

```text
rtl/QRS/ecg_wtsee_v6_top.v
rtl/QRS/qrs_axi4_wrapper.v
rtl/QRS/baseline_filter.v
rtl/QRS/first_difference.v
rtl/QRS/moving_sum12.v
rtl/QRS/moving_sum20.v
rtl/QRS/schmitt_peak_detector.v
rtl/QRS/search_back.v
rtl/QRS/rr_classifier.v
```

The verification environment includes ECG stimulus data and checks for R-peak detection.

---

## FIR Processing Path

The FIR subsystem supports register-based configuration together with an AXI4-Stream datapath.

```text
                 AXI4-Lite
                    |
                    v
             +-------------+
             | FIR Control |
             +------+------+
                    |
                    v
AXI4-Stream  --> +--------+ --> AXI4-Stream
                 | FIR DSP|
                 +--------+
```

Relevant RTL:

```text
rtl/FIR/fir_top.v
rtl/FIR/fir_dsp.v
rtl/FIR/fir_axi_lite.v
rtl/FIR/axis_fifo.v
```

---

## ADC Subsystem

The ADC block contains:

- ADC control
- Register interface
- Sampling scheduler
- Sample acquisition
- FIFO buffering
- AXI4-Lite slave interface

Relevant RTL:

```text
rtl/ADC/adc_controller.sv
rtl/ADC/adc_registers.sv
rtl/ADC/adc_axi_lite_slave.sv
rtl/ADC/adc_sampling_scheduler.sv
rtl/ADC/adc_sample_acquisition.sv
rtl/ADC/adc_fifo.sv
```

The integrated ADC exposes sample and overrun interrupt outputs.

---

## GPIO and Timer

GPIO and Timer are integrated as AXI4-Lite peripherals behind the common AXI4 → AXI4-Lite bridge.

### GPIO

Relevant RTL:

```text
rtl/gpio/gpio_axi.sv
rtl/gpio/gpio_regs.sv
rtl/gpio/gpio_bit.sv
rtl/gpio/gpio_wrapper.sv
```

The GPIO subsystem supports memory-mapped register access, bidirectional GPIO pins and interrupt generation.

### Timer

The Timer subsystem supports:

- Timer operation
- External measurement/capture
- PWM output
- Trigger output
- Interrupt generation

Relevant RTL is under:

```text
rtl/timer/
```

---

## RISC-V Processor

The repository includes the **VeeR EL2 RISC-V core** as a Git submodule:

```text
rtl/Cores-VeeR-EL2
```

Upstream project:

```text
https://github.com/chipsalliance/Cores-VeeR-EL2.git
```

The current SoC integration is being built around the existing AXI system infrastructure so that the working peripheral RTL and verification environments remain reusable.

---

## Address Map

The authoritative project address allocation is maintained in:

```text
doc/addressmapping.ods
```

The checked-in address-map document should be treated as the **final source of truth** for peripheral base addresses and ranges.

Historical simulation notes and older README versions should not be used as the source of truth when they differ from the current mapping.

---

## Repository Structure

```text
HONOURS_CBP_CARDIOEDGE/
├── doc/
│   ├── addressmapping.ods
│   ├── CardioEdge_AXI4_Specification_v2.docx
│   ├── Combined_SoC_Features_DataPath_ControlPath.pdf
│   ├── AES register set.pdf
│   └── qrs/
│       ├── ARCHITECTURE.md
│       ├── OPTIMIZATIONS.md
│       └── JOURNAL_VALIDATION_PLAN.md
│
├── rtl/
│   ├── ADC/
│   ├── Cores-VeeR-EL2/          # Git submodule
│   ├── FIR/
│   ├── QRS/
│   ├── common/
│   ├── gpio/
│   ├── interconnect/
│   ├── spi/
│   ├── timer/
│   ├── uart/
│   └── soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv
│
├── run/
│   └── filelist_uart_qrs_spi_fir_adc_gpio_timer_integration_BRIDGED.f
│
├── scripts/
│   └── axi_interconnect_wrap.py
│
└── tb/
    ├── ADC/
    ├── tb_axi_interconnect_wrap_3x14.sv
    ├── tb_gpio_axi.sv
    ├── tb_timer_axi.sv
    ├── tb_fir_top.v
    ├── qrs_axi4_wrapper_tb.sv
    ├── tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv
    ├── uart_standalone_tb.sv
    └── axi_bfm_tasks.sv
```

---

## Verification

Verification is primarily performed using **Synopsys VCS** with SystemVerilog testbenches and AXI bus-functional models.

### Verification Layers

1. Standalone IP verification
2. AXI protocol and register-access verification
3. Peripheral integration verification
4. Top-level SoC integration verification

The repository contains testbenches for:

- UART
- QRS
- FIR
- ADC
- GPIO
- Timer
- AXI interconnect
- AES-related verification
- Full UART/QRS/SPI/FIR/ADC/GPIO/Timer integration

Primary integration file list:

```text
run/filelist_uart_qrs_spi_fir_adc_gpio_timer_integration_BRIDGED.f
```



For waveform/debug analysis, the design can be compiled with VCS debug options and opened in **Synopsys Verdi**.

---

## Verification Status

| Block | RTL | Standalone | Integration |
|---|:---:|:---:|:---:|
| UART | ✅ | ✅ | ✅ |
| QRS | ✅ | ✅ | ✅ |
| SPI | ✅ | — | ✅ |
| FIR | ✅ | ✅ | ✅ |
| ADC | ✅ | ✅ | ✅ |
| GPIO | ✅ | ✅ | ✅ |
| Timer | ✅ | ✅ | ✅ |
| AXI Interconnect | ✅ | ✅ | ✅ |
| AXI4 → AXI4-Lite Bridge | ✅ | ✅ | ✅ |
| VeeR EL2 | Submodule | Core project | Processor-side integration in progress |

Verification is an ongoing RTL development process, so individual register-level and top-level tests may continue to evolve during the processor-side SoC integration.

---

## Design Goals

- Hardware acceleration for ECG/QRS processing
- RISC-V based SoC integration
- Reusable AXI-based IP architecture
- AXI4 system transport with AXI4-Lite peripheral compatibility
- Modular peripheral integration
- Simulation-driven RTL verification
- Clean separation between processing datapaths and control/register interfaces
- Extensible address-space and interconnect architecture

---

## Tools

- **SystemVerilog / Verilog**
- **Synopsys VCS**
- **Synopsys Verdi** (optional)
- **Linux**
- **Git / GitHub**

---

## Project Status

**Current stage: RTL SoC integration and verification**

The repository currently contains the integrated peripheral subsystem, AXI4 infrastructure, AXI4-Lite bridge, verification environments, documentation, and the VeeR EL2 processor as a Git submodule.

The current development focus is connecting the processor-side AXI master path and completing system-level validation while preserving the already working peripheral integrations.

---

## Repository

[HONOURS_CBP_CARDIOEDGE](https://github.com/Yashwanth20050906/HONOURS_CBP_CARDIOEDGE)
