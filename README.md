# CARDIOEDGE

### RISC-V Based ECG Processing SoC with AXI-Based RTL Integration

CARDIOEDGE is an RTL-level hardware design project for a RISC-V based ECG acquisition and processing system. The project integrates multiple ECG-processing and communication IPs through an AXI-based interconnect to create a modular SoC architecture for real-time cardiac signal processing.

The current work focuses on:

* RTL IP integration
* AXI4 / AXI4-Lite interfacing
* AXI interconnect integration
* ECG signal-processing hardware
* Peripheral integration
* Interface adaptation using wrappers
* RTL simulation and verification using Synopsys VCS

---

# 1. Project Overview

CARDIOEDGE is designed as a modular hardware platform in which ECG data can be acquired, filtered, processed, and analyzed using dedicated hardware accelerators.

The current integrated subsystem contains:

```text
                         +------------------+
                         |    AXI Master    |
                         |   / SoC Master   |
                         +---------+--------+
                                   |
                                   v
                         +-------------------+
                         |  AXI 3 × 14       |
                         |   Interconnect    |
                         +---------+---------+
                                   |
             +----------+----------+----------+----------+
             |          |          |          |          |
             v          v          v          v          v
           UART        QRS        SPI        FIR        ADC
             |          |          |          |          |
             |          |          |          |          |
             +----------+----------+----------+----------+
                                   |
                            ECG Processing
```

The current top-level integration uses five active peripheral connections:

```text
M00 → UART
M01 → QRS
M02 → SPI
M03 → FIR
M04 → ADC
```

The remaining interconnect slots are currently unused.

---

# 2. Current Project Status

The project is currently in the **RTL integration and verification stage**.

## Completed / Verified

* [x] AXI interconnect evaluated
* [x] AXI 3 × 14 interconnect wrapper integrated
* [x] AXI arbitration and priority logic integrated
* [x] UART integrated
* [x] UART AXI interface tested
* [x] FFT IP integrated/tested during subsystem development
* [x] FIR integrated
* [x] FIR AXI register interface verified
* [x] FIR streaming datapath verified
* [x] QRS integrated
* [x] QRS register interface verified
* [x] SPI integrated
* [x] SPI AXI interface verified
* [x] ADC integrated into the current top-level subsystem
* [x] Peripheral-specific integration testbenches developed
* [x] Multi-peripheral AXI integration testbench developed
* [x] AXI4-to-AXI4-Lite wrapper approach established
* [x] Synopsys VCS simulation environment established

## Current / Remaining Work

* [ ] Complete ADC-level verification/regression
* [ ] Complete final subsystem regression
* [ ] Integrate remaining system-level components
* [ ] Integrate VeeR RISC-V processor
* [ ] Finalize processor-to-interconnect integration
* [ ] Complete top-level SoC integration
* [ ] Perform complete end-to-end ECG processing verification

---

# 3. Current Top-Level Architecture

The current top-level integration is based on the RTL module:

```text
soc_uart_qrs_spi_fir_adc_top
```

The current architecture is:

```text
                         AXI Master
                             |
                             |
                             v
                   +---------------------+
                   | AXI 3 × 14          |
                   | Interconnect        |
                   |                     |
                   | 32-bit AXI          |
                   +----------+----------+
                              |
       +----------+-----------+-----------+----------+
       |          |           |           |          |
       v          v           v           v          v
      M00        M01         M02         M03        M04
       |          |           |           |          |
       v          v           v           v          v
     UART        QRS         SPI         FIR        ADC
```

The active master-to-slave connections are:

```text
M00 → UART
M01 → QRS
M02 → SPI
M03 → FIR
M04 → ADC
```

Interconnect slots M05 through M13 are currently unused.

---

# 4. Current Memory Map

The memory map below is taken from the **current top-level RTL implementation**.

The current active peripheral address regions are:

| Interconnect Master | Peripheral |  Base Address |               Address Range | Size |
| ------------------- | ---------- | ------------: | --------------------------: | ---: |
| M00                 | UART       | `0x4000_0000` | `0x4000_0000 – 0x4000_0FFF` | 4 KB |
| M01                 | QRS        | `0x4000_1000` | `0x4000_1000 – 0x4000_1FFF` | 4 KB |
| M02                 | SPI        | `0x4000_2000` | `0x4000_2000 – 0x4000_2FFF` | 4 KB |
| M03                 | FIR        | `0x4000_3000` | `0x4000_3000 – 0x4000_3FFF` | 4 KB |
| M04                 | ADC        | `0x4000_4000` | `0x4000_4000 – 0x4000_4FFF` | 4 KB |
| M05                 | Unused     |             — |                           — |    — |
| M06                 | Unused     |             — |                           — |    — |
| M07                 | Unused     |             — |                           — |    — |
| M08                 | Unused     |             — |                           — |    — |
| M09                 | Unused     |             — |                           — |    — |
| M10                 | Unused     |             — |                           — |    — |
| M11                 | Unused     |             — |                           — |    — |
| M12                 | Unused     |             — |                           — |    — |
| M13                 | Unused     |             — |                           — |    — |

### Address Layout

```text
0x4000_0000 ──────────────────────
             UART
             4 KB
0x4000_0FFF ──────────────────────

0x4000_1000 ──────────────────────
             QRS
             4 KB
0x4000_1FFF ──────────────────────

0x4000_2000 ──────────────────────
             SPI
             4 KB
0x4000_2FFF ──────────────────────

0x4000_3000 ──────────────────────
             FIR
             4 KB
0x4000_3FFF ──────────────────────

0x4000_4000 ──────────────────────
             ADC
             4 KB
0x4000_4FFF ──────────────────────

             M05–M13
             Currently unused
```

There are no overlapping active address regions in the current peripheral map.

---

# 5. Current AXI Configuration

The current top-level AXI configuration uses:

| Parameter         | Current Value |
| ----------------- | ------------: |
| AXI Data Width    |       32 bits |
| AXI Address Width |       32 bits |
| AXI Write Strobe  |        4 bits |
| AXI ID Width      |        8 bits |
| Interconnect      |    AXI 3 × 14 |

Therefore, the current integrated subsystem should be described as a:

```text
32-bit AXI data path
32-bit AXI address path
4-bit write strobe
8-bit AXI ID
```

The earlier concept of a 64-bit AXI system is **not the current top-level implementation** and should not be represented as the current project status.

---

# 6. AXI 3 × 14 Interconnect

The project uses a reusable AXI interconnect supporting:

```text
3 Masters
14 Slaves
```

Conceptually:

```text
                 +------------------+
M00 ------------>|                  |
M01 ------------>| AXI Interconnect|----> S00
M02 ------------>|      3 × 14      |----> S01
                 |                  |----> S02
                 |                  |       ...
                 |                  |----> S13
                 +------------------+
```

The reusable interconnect contains supporting arbitration and priority logic.

Typical infrastructure includes:

```text
rtl/interconnect/
├── axi_interconnect.v
├── axi_interconnect_wrap_3x14.v
├── arbiter.v
└── priority_encoder.v
```

For the current CardioEdge subsystem, only the required peripheral slots are enabled.

```text
M00 → UART
M01 → QRS
M02 → SPI
M03 → FIR
M04 → ADC
```

M05–M13 remain unused.

---

# 7. AXI4 and AXI4-Lite Integration

The integrated peripherals do not all use identical AXI interfaces.

Some peripherals use AXI4, while others use AXI4-Lite-style register interfaces.

Instead of modifying the original IP whenever possible, CARDIOEDGE uses interface wrappers.

```text
                  AXI Interconnect
                        |
                        | AXI4
                        v
                +---------------+
                | AXI Wrapper   |
                |               |
                | Interface     |
                | Adaptation    |
                +-------+-------+
                        |
                        | AXI4-Lite / Native AXI
                        v
                  Peripheral IP
```

This approach provides:

* IP reuse
* Reduced modification of original RTL
* Easier debugging
* Independent peripheral verification
* AXI protocol adaptation
* Cleaner subsystem integration

---

# 8. UART

UART provides serial communication and can also be used for system-level debugging and status reporting.

The integration is:

```text
AXI
 |
 v
UART Register Interface
 |
 +---- TX
 |
 +---- RX
```

The UART occupies:

```text
Base Address : 0x4000_0000
Size         : 4 KB
```

The top-level integration maps the UART system address into the UART's local register address space.

### Status

**UART integration and verification completed.**

UART has been exercised through dedicated and subsystem-level testbenches.

---

# 9. QRS Accelerator

The QRS accelerator is responsible for ECG QRS/beat detection and associated cardiac measurements.

The intended processing structure is:

```text
Filtered ECG
     |
     v
 Derivative
     |
     v
 Squaring
     |
     v
 Moving Integration
     |
     v
 Threshold Detection
     |
     v
 QRS / R-Peak Detection
     |
     +----------+----------+
     |          |          |
     v          v          v
    BPM     RR Interval  Rhythm
```

The QRS peripheral occupies:

```text
Base Address : 0x4000_1000
Size         : 4 KB
```

### QRS Register Map

| Offset | Register     |
| -----: | ------------ |
| `0x00` | CONTROL      |
| `0x04` | STATUS       |
| `0x08` | ECG_INPUT    |
| `0x0C` | RPEAK        |
| `0x10` | RR_INTERVAL  |
| `0x14` | BPM          |
| `0x18` | RHYTHM_CLASS |

Therefore:

```text
CONTROL      = 0x4000_1000
STATUS       = 0x4000_1004
ECG_INPUT    = 0x4000_1008
RPEAK        = 0x4000_100C
RR_INTERVAL  = 0x4000_1010
BPM          = 0x4000_1014
RHYTHM_CLASS = 0x4000_1018
```

### Status

**QRS integration and verification completed at the current RTL subsystem level.**

---

# 10. SPI

SPI provides serial peripheral communication.

The integrated structure is:

```text
AXI Register Interface
        |
        v
   SPI Controller
        |
   +----+----+----+----+
   |    |    |    |
 MOSI MISO SCLK  CS
```

The SPI peripheral occupies:

```text
Base Address : 0x4000_2000
Size         : 4 KB
```

The top-level integration passes the required local address bits to the SPI AXI interface.

### Status

**SPI integration and verification completed.**

Dedicated SPI integration tests were used to verify register access and SPI functionality.

---

# 11. FIR Filter

The FIR block provides hardware-based ECG signal conditioning.

The intended ECG processing path is:

```text
ADC
 |
 v
ECG Samples
 |
 v
+----------------+
|      FIR       |
| Digital Filter |
+-------+--------+
        |
        v
     QRS Path
```

The FIR peripheral occupies:

```text
Base Address : 0x4000_3000
Size         : 4 KB
```

The system-level address is converted into the local FIR register address using the FIR base address.

```text
FIR Local Address =
    AXI Address - 0x4000_3000
```

### Verification

The FIR integration has been tested through:

* AXI register access
* FIR enable operation
* Streaming input
* Filtered output
* Expected-versus-actual sample comparison

### Status

**FIR integration and verification completed.**

---

# 12. ADC

The ADC block provides the ECG sample acquisition interface.

The current ADC configuration in the integrated top-level design is:

| Parameter   |   Value |
| ----------- | ------: |
| Resolution  | 12 bits |
| Channels    |       1 |
| FIFO Depth  |      32 |
| Clock       |  50 MHz |
| Sample Rate |  250 Hz |
| FIFO        | Enabled |
| Interrupt   | Enabled |

The ADC occupies:

```text
Base Address : 0x4000_4000
Size         : 4 KB
```

The ADC is connected through an AXI4-Lite-compatible register interface.

The additional AXI4 signals that are not required by the native ADC interface are left unused through the integration wrapper.

### Intended data path

```text
ADC
 |
 v
ADC FIFO
 |
 v
ECG Sample
 |
 v
FIR
 |
 v
QRS
```

### Status

**ADC is now integrated into the current top-level subsystem.**

Further verification and complete end-to-end testing remain part of the current development work.

---

# 13. ECG Processing Pipeline

The intended CARDIOEDGE signal-processing path is:

```text
              ECG Signal
                  |
                  v
             +---------+
             |   ADC   |
             +----+----+
                  |
                  v
             +---------+
             | ADC FIFO|
             +----+----+
                  |
                  v
             +---------+
             |   FIR   |
             +----+----+
                  |
                  v
             +---------+
             |   QRS   |
             +----+----+
                  |
        +---------+---------+
        |         |         |
        v         v         v
       BPM       RR      Rhythm /
              Interval   Classification
```

This represents the intended hardware processing chain.

The current top-level RTL has the individual ADC, FIR, and QRS blocks integrated through their respective interfaces; complete end-to-end streaming verification is still part of the remaining work.

---

# 14. FFT

FFT hardware was also evaluated and integrated during the development of the CARDIOEDGE subsystem.

The FFT provides hardware acceleration for frequency-domain signal processing.

Typical processing flow:

```text
Input Samples
     |
     v
+-----------+
|    FFT    |
+-----+-----+
      |
      v
Frequency-Domain Data
```

FFT-related integration and testing were performed during the project development.

The current `soc_uart_qrs_spi_fir_adc_top` address map described in this README is specifically the **UART/QRS/SPI/FIR/ADC top-level integration** and does not assign an FFT address window.

---

# 15. Verification Strategy

Verification is performed incrementally.

```text
Individual IP Verification
          |
          v
AXI Interface Verification
          |
          v
Peripheral + Interconnect
          |
          v
Multi-IP Integration
          |
          v
Processor Integration
          |
          v
Complete SoC Verification
```

This approach allows interface and functional issues to be isolated before complete SoC integration.

---

# 16. Current Verification Environment

The primary RTL simulation environment uses:

### HDL

* Verilog
* SystemVerilog

### Simulation

* Synopsys VCS

### Debugging

* Verdi
* Simulation logs
* RTL waveforms

The testbenches exercise:

* AXI writes
* AXI reads
* Register configuration
* Peripheral enable/disable
* Streaming data
* Expected-versus-actual data comparison
* Integrated peripheral access

---

# 17. Integration Test Status

| IP / Component            | Current Status                      |
| ------------------------- | ----------------------------------- |
| AXI Interconnect          | ✅ Integrated                        |
| AXI 3 × 14 Wrapper        | ✅ Integrated                        |
| Arbitration Logic         | ✅ Integrated                        |
| Priority Encoder          | ✅ Integrated                        |
| UART                      | ✅ Integrated / Verified             |
| FFT                       | ✅ Tested during development         |
| FIR                       | ✅ Integrated / Verified             |
| QRS                       | ✅ Integrated / Verified             |
| SPI                       | ✅ Integrated / Verified             |
| ADC                       | ✅ Integrated / Verification ongoing |
| M05–M13                   | ⏸ Unused                            |
| VeeR EL2                  | 🔄 Future integration stage         |
| Complete SoC              | 🔄 In progress                      |
| End-to-End ECG Regression | ⏳ Pending                           |

---

# 18. Repository Structure

The repository contains the RTL, testbenches, integration files, and supporting project material.

A representative structure is:

```text
HONOURS_CBP_CARDIOEDGE/
│
├── rtl/
│   ├── interconnect/
│   │   ├── axi_interconnect.v
│   │   ├── axi_interconnect_wrap_3x14.v
│   │   ├── arbiter.v
│   │   └── priority_encoder.v
│   │
│   ├── uart/
│   ├── qrs/
│   ├── spi/
│   ├── fir/
│   ├── adc/
│   └── fft/
│
├── tb/
│   ├── UART testbenches
│   ├── QRS testbenches
│   ├── SPI testbenches
│   ├── FIR testbenches
│   ├── ADC testbenches
│   └── integration testbenches
│
├── scripts/
│
├── doc/
│
└── README.md
```

The repository structure may change as the SoC integration progresses.

---

# 19. Design Approach

CARDIOEDGE follows several design principles.

### 1. Reuse Existing IP

Original IP implementations are preserved wherever possible.

### 2. Wrapper-Based Integration

Interface mismatches are handled using wrappers rather than unnecessarily modifying the original peripheral RTL.

### 3. Incremental Verification

Each peripheral is verified individually before being integrated into the larger subsystem.

### 4. Non-Overlapping Address Map

Every active peripheral receives its own 4 KB address window.

```text
UART → 0x4000_0000
QRS  → 0x4000_1000
SPI  → 0x4000_2000
FIR  → 0x4000_3000
ADC  → 0x4000_4000
```

### 5. Modular Architecture

The AXI interconnect and peripheral interfaces are designed to allow additional IPs to be added later.

---

# 20. Current System Address Map Summary

For quick reference:

```text
+----------------------+----------------------+
| Peripheral           | Base Address         |
+----------------------+----------------------+
| UART                 | 0x4000_0000          |
| QRS                  | 0x4000_1000          |
| SPI                  | 0x4000_2000          |
| FIR                  | 0x4000_3000          |
| ADC                  | 0x4000_4000          |
+----------------------+----------------------+
| M05–M13              | Unused               |
+----------------------+----------------------+
```

Each active peripheral receives a 4 KB window.

---

# 21. Current Development Architecture

The current integrated subsystem can be summarized as:

```text
                         32-bit AXI
                             |
                             v
                  +---------------------+
                  | AXI 3 × 14          |
                  | Interconnect        |
                  +----------+----------+
                             |
       +----------+----------+----------+----------+
       |          |          |          |          |
       v          v          v          v          v
      UART       QRS        SPI        FIR        ADC
       |          |          |          |          |
       |          |          |          +----------+
       |          |          |                     |
       |          |          +                     v
       |          |                              ECG
       |          |                            Processing
       |          |
       |          +------------------------------+
       |                                         |
       +-----------------------------------------+
```

The architecture is being progressively extended toward the final RISC-V based SoC.

---

# 22. Future Integration

The next major stages are:

### VeeR RISC-V Integration

Integrate the VeeR processor and connect its instruction/data interfaces to the AXI fabric.

```text
             +-----------+
             |  VeeR EL2 |
             +-----+-----+
                   |
                   v
             AXI Interconnect
```

### Additional System Components

Additional system-level components can be connected to the currently unused interconnect slots as the architecture develops.

### End-to-End ECG Verification

The final verification objective is:

```text
ECG Input
   |
   v
 ADC
   |
   v
 FIR
   |
   v
 QRS
   |
   +----> R-Peak
   |
   +----> RR Interval
   |
   +----> BPM
   |
   +----> Rhythm Classification
```

---

# 23. Project Scope

CARDIOEDGE is currently focused on **RTL-level SoC architecture, IP integration, AXI interfacing, and simulation-based verification**.

The project combines:

```text
RISC-V
   +
AXI Interconnect
   +
ECG Acquisition
   +
Digital Filtering
   +
QRS Detection
   +
Peripheral Communication
   +
RTL Verification
```

The project does not claim to be a clinically certified medical device. The current work is focused on digital hardware implementation and verification.

---

# 24. Tools and Technologies

### Hardware Description Languages

* Verilog
* SystemVerilog

### SoC / Bus Architecture

* RISC-V
* AXI4
* AXI4-Lite
* AXI Interconnect

### Verification

* Synopsys VCS
* Verdi
* SystemVerilog Testbenches

### ECG Processing

* ADC acquisition
* FIR filtering
* QRS detection
* BPM calculation
* RR interval calculation
* Rhythm classification

### Communication

* UART
* SPI

---

# 25. Project Progress

```text
AXI Infrastructure
      |
      v
   COMPLETE
      |
      v
UART ──────── COMPLETE
QRS  ──────── COMPLETE
SPI  ──────── COMPLETE
FIR  ──────── COMPLETE
ADC  ──────── INTEGRATED / VERIFYING
      |
      v
Subsystem Regression
      |
      v
VeeR Integration
      |
      v
Complete SoC
      |
      v
End-to-End Verification
```

---

# 26. Current Status

**CARDIOEDGE is currently in the RTL integration and verification phase.**

The current top-level subsystem successfully brings together:

```text
UART
QRS
SPI
FIR
ADC
```

through a reusable **AXI 3 × 14 interconnect**.

The active memory map is:

```text
0x4000_0000 → UART
0x4000_1000 → QRS
0x4000_2000 → SPI
0x4000_3000 → FIR
0x4000_4000 → ADC
```

The current system interface is **32-bit AXI**, with a 32-bit address bus and 4-bit write strobe.

The next major stage is to complete the remaining verification and extend the subsystem toward the final **RISC-V based CARDIOEDGE SoC**.

---

## Author

**Yashwanth Chakravarthy**

**Project:** CARDIOEDGE
**Type:** Honours / Capstone Hardware Design Project
**Domain:** RISC-V SoC / AXI / RTL / ECG Signal Processing
**Implementation:** Verilog / SystemVerilog
**Simulation:** Synopsys VCS / Verdi

---
