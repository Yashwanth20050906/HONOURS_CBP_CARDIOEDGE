# CardioEdge — Honours CBP SoC

An AXI4-based System-on-Chip designed for real-time ECG signal processing and cardiac beat detection. The design integrates multiple peripherals over a shared AXI4 interconnect and is verified using Synopsys VCS.

---

## Overview

CardioEdge is an RTL SoC built as part of an Honours project. It implements an ECG acquisition and QRS detection pipeline entirely in hardware, alongside a suite of general-purpose peripherals accessible via an AXI4 bus fabric.

The full integrated top-level is `soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv`, which wraps a 3-master × 14-slave AXI interconnect.

---

## Architecture

```
                        ┌─────────────────────────────────┐
                        │   AXI4 Interconnect (3×14)      │
                        │   axi_interconnect_wrap_3x14.v  │
                        └────────────┬────────────────────┘
                                     │
      ┌──────────┬────────┬──────────┼──────────┬────────┬──────────┐
      │          │        │          │          │        │          │
   UART(M00)  QRS(M01)  SPI(M02)  FIR(M03)  ADC(M04) GPIO(M05) Timer(M06)
```

The single AXI4 slave port (`s00`) is bridged to AXI4-Lite for each peripheral using a common `axi4_to_axi4lite_bridge.sv`.

---

## RTL Structure

```
rtl/
├── soc_uart_qrs_spi_fir_adc_gpio_timer_top_BRIDGED.sv   ← integrated top
├── interconnect/
│   ├── axi_interconnect.v          ← AXI4 crossbar
│   ├── axi_interconnect_wrap_3x14.v
│   ├── arbiter.v
│   └── priority_encoder.v
├── common/
│   ├── axi4_to_axi4lite_bridge.sv  ← AXI4 → AXI4-Lite bridge
│   └── axi4lite_slave_adapter.sv   ← AXI4-Lite → register bus
├── uart/                           ← AXI UART (TX/RX FIFOs, parity)
├── QRS/                            ← Pan-Tompkins-style QRS detector
│   ├── ecg_wtsee_v6_top.v          ← top-level ECG algorithm
│   ├── baseline_filter.v
│   ├── first_difference.v
│   ├── moving_sum12/20.v
│   ├── shannon_lut12.v
│   ├── schmitt_peak_detector.v
│   ├── search_back.v
│   └── qrs_axi4_wrapper.v          ← AXI4 register wrapper
├── spi/                            ← AXI-Lite SPI master
├── FIR/                            ← AXI4-Stream FIR filter (DSP slices)
│   ├── fir_top.v
│   ├── fir_dsp.v
│   ├── fir_axi_lite.v
│   └── axis_fifo.v
├── ADC/                            ← ADC sampling controller
│   ├── adc_controller.sv
│   ├── adc_registers.sv
│   ├── adc_axi_lite_slave.sv
│   ├── adc_sampling_scheduler.sv
│   ├── adc_sample_acquisition.sv
│   └── adc_fifo.sv
├── gpio/                           ← 8-bit bidirectional GPIO (Gemini IP)
│   ├── gpio_axi.sv
│   ├── gpio_regs.sv
│   ├── gpio_bit.sv
│   └── gpio_wrapper.sv
└── timer/                          ← Timer/PWM/capture (Gemini IP)
    ├── timer_axi.sv
    ├── timer_core.sv
    └── timer_regs.sv
```

---

## Peripheral Memory Map

| Peripheral | Address Range         | Interface  |
|------------|-----------------------|------------|
| UART       | `0x4000_0000`         | AXI4-Lite  |
| QRS        | `0x4000_1000`–`1FFF`  | AXI4       |
| SPI        | `0x4000_2000`         | AXI4-Lite  |
| FIR        | `0x4000_3000`         | AXI4-Lite + AXI4-Stream |
| ADC        | `0x4000_4000`         | AXI4-Lite  |
| GPIO       | `0x4000_5000`         | AXI4-Lite  |
| Timer      | `0x4000_6000`         | AXI4-Lite  |

---

## Top-Level Port Summary

| Signal Group | Direction | Description |
|---|---|---|
| `clk`, `rst` | in | System clock and synchronous reset |
| `s00_axi_*` | in/out | AXI4 slave port (from master/testbench) |
| `uart_rx_i` / `uart_tx_o` | in/out | UART serial lines |
| `spi_clk_o`, `spi_cs_n_o`, `spi_mosi_o`, `spi_miso_i` | in/out | SPI bus |
| `fir_s_axis_*` / `fir_m_axis_*` | in/out | AXI4-Stream FIR data path |
| `adc_sample_in[11:0]`, `adc_sample_valid` | in | ADC raw sample input |
| `adc_irq_sample`, `adc_irq_overrun` | out | ADC interrupt lines |
| `gpio_io[7:0]` | inout | Bidirectional GPIO pad |
| `gpio_irq` | out | GPIO interrupt |
| `timer_ext_meas_i`, `timer_capture_i` | in | Timer external inputs |
| `timer_pwm_o`, `timer_trigger_o`, `timer_irq` | out | Timer outputs |

---

## Testbenches

```
tb/
├── tb_soc_uart_qrs_spi_fir_adc_gpio_timer_top.sv  ← full integration TB (primary)
├── tb_gpio_axi.sv                                  ← GPIO standalone
├── tb_timer_axi.sv                                 ← Timer standalone
├── tb_fir_top.v                                    ← FIR standalone
├── qrs_axi4_wrapper_tb.sv                          ← QRS wrapper
├── adc_tb.sv                                       ← ADC standalone
├── axi_bfm_tasks.sv                                ← AXI BFM helper tasks
└── ecg_input.txt                                   ← ECG sample stimulus file
```

---

## Simulation

Simulations use **Synopsys VCS**. File lists are in `run/`.

### Full integration (primary)
```bash
cd run
vcs -full64 -sverilog -f filelist_uart_qrs_spi_fir_adc_gpio_timer_integration_BRIDGED.f \
    -o simv -l compile.log
./simv
```

### GPIO standalone
```bash
vcs -full64 -sverilog -f gpio_standalone.f -o simv_gpio
./simv_gpio
```

### Timer standalone
```bash
vcs -full64 -sverilog -f timer_standalone.f -o simv_timer
./simv_timer
```

Waveform debugging is supported via **Synopsys Verdi** (`-verdi` flag or open the generated `.vcd`/`fsdb` from `run/`).

---

## Documentation

```
doc/
├── CardioEdge_AXI4_Specification_v2.docx   ← full register-level AXI spec
├── qrs/
│   ├── ARCHITECTURE.md                     ← QRS algorithm architecture
│   ├── OPTIMIZATIONS.md                    ← implementation optimisations
│   └── JOURNAL_VALIDATION_PLAN.md          ← validation methodology
└── aes.pdf / AES register set.pdf          ← AES IP reference (legacy)
```

---

## Dependencies

- **Synopsys VCS** — simulation and elaboration
- **Synopsys Verdi** — waveform viewing (optional)
- SystemVerilog-2012 compatible simulator (for `.sv` files)

---

## Project Status

| Block       | RTL | Standalone TB | Integration TB |
|-------------|-----|--------------|----------------|
| UART        | ✅  | ✅            | ✅              |
| QRS         | ✅  | ✅            | ✅              |
| SPI         | ✅  | —             | ✅              |
| FIR         | ✅  | ✅            | ✅              |
| ADC         | ✅  | ✅            | ✅              |
| GPIO        | ✅  | ✅            | ✅              |
| Timer       | ✅  | ✅            | ✅              |
| Interconnect| ✅  | ✅            | ✅              |
