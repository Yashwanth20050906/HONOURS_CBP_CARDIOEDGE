# AXI 3×14 Interconnect

## Overview

This project implements and verifies a **3-Master × 14-Slave AXI interconnect** intended for integration into a larger RISC-V/SoC design.

The interconnect allows three AXI masters to communicate with fourteen different AXI slave/peripheral interfaces through address-based routing and arbitration.

The project is currently in the **initial RTL implementation and functional verification stage**.

---

## Current Progress

### Completed

- [x] 3 × 14 AXI interconnect RTL structure
- [x] Top-level AXI interconnect wrapper
- [x] AXI interconnect logic
- [x] Arbitration logic
- [x] Priority encoder
- [x] Initial SystemVerilog testbench
- [x] Clock and reset generation in testbench
- [x] Basic AXI master stimulus
- [x] Basic AXI slave response modeling
- [x] Initial VCS simulation setup
- [x] Initial Verdi waveform setup

### In Progress

- [ ] Complete functional verification
- [ ] Verify all master-to-slave combinations
- [ ] Verify simultaneous master accesses
- [ ] Verify arbitration behavior
- [ ] Verify back-to-back transactions
- [ ] Improve self-checking and coverage
- [ ] Analyze and fix any RTL issues found during simulation
- [ ] Finalize waveform-based debugging

---

## Project Structure

```text
cardio_edge-project/
│
├── rtl/
│   └── interconnect/
│       ├── axi_interconnect_wrap_3x14.v
│       ├── axi_interconnect.v
│       ├── arbiter.v
│       └── priority_encoder.v
│
├── tb/
│   └── tb_axi_interconnect_wrap_3x14.sv
│
├── run/
│   └── filelist.f
│
├── scripts/
│   └── axi_interconnect_wrap.py
│
└── README.md
