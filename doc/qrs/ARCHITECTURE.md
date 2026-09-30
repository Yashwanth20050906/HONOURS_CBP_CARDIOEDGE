# WTSEE ECG Arrhythmia Detector Microarchitecture Specification

## 1. Overview
The Wavelet-Transform-based Shannon Energy Envelope (WTSEE) ECG detector is an ultra-low-power biomedical ASIC tailored for implantable loop recorders, smart wearables, and ambulatory ECG patches. 

This document details the exact microarchitectural pipeline stages, register boundaries, arithmetic bit-widths, and clock domain definitions.

---

## 2. Pipeline Stages & Datapath Details

### Stage 1: Noise Filtering & Smoothing (`baseline_filter.v`)
- **Input**: 16-bit signed Q1.15 raw ECG sample ($f_s = 250 - 360\text{ Hz}$).
- **Operation**: 3-tap moving average filter:
  $$y[n] = \frac{x[n] + 2x[n-1] + x[n-2]}{4}$$
- **Hardware Realization**: Shift-and-add arithmetic without multipliers.
- **Latency**: 1 clock cycle.

### Stage 2: First-Order Derivative (`first_difference.v`)
- **Operation**: First difference:
  $$d[n] = y[n] - y[n-1]$$
- **Output Width**: 17 bits signed.
- **Function**: Suppresses baseline drift and accentuates high-frequency QRS rising/falling slopes.

### Stage 3: Power-of-2 Barrel-Shift AGC Normalizer (`pow2_normalizer.v`)
- **Input**: 17-bit derivative.
- **Envelope Tracking**: Dynamic peak magnitude tracker (`max_mag`) with 64-sample decay window.
- **Shift Logic**: Computes leading-one count $k = \text{CLZ}(\text{max\_mag})$. Scales sample by $2^k$.
- **Output**: 12-bit unsigned normalized magnitude $[0, 4095]$.
- **Hardware Advantage**: Completely eliminates 24-bit non-restoring divider logic.

### Stage 4: Shannon Energy Envelope (`shannon_lut12.v` & `moving_sum12.v`)
- **Shannon Non-linear Mapping**: 
  $$E_{\text{SEE}}[n] = -x[n] \cdot \ln(x[n])$$
  Implemented as a $4096 \times 12$-bit dual-port synchronous ROM.
- **Sliding Window Accumulation**: 33-point moving sum ($W = 33$ samples $\approx 91\text{ ms}$ at $360\text{ Hz}$):
  $$\text{SEE}[n] = \sum_{k=0}^{32} E_{\text{SEE}}[n-k]$$
- **Accumulator Bit-width**: 18-bit unsigned accumulator.

### Stage 5: Retiming Boundary 1 (`see_pipe`)
- Isolates the Shannon transformation and moving sum accumulation from the subsequent power envelope datapath, closing timing with zero combinational paths crossing the boundary.

### Stage 6: Power Energy Envelope (`moving_sum20.v` & `square10.v`)
- **Second Derivative & Normalizer**: 13-bit second difference followed by 10-bit power-of-2 normalizer.
- **Operand-Isolated Squarer**: Computes $P[n] = (x_{\text{norm2}}[n])^2$ ($10 \times 10 \rightarrow 20\text{ bits}$).
  - *Operand Isolation*: Zeroes inputs when `in_valid = 0`, eliminating dynamic switching and internal glitch power.
- **Sliding Window Accumulation**: 43-point moving sum ($W = 43$ samples $\approx 120\text{ ms}$ at $360\text{ Hz}$).
- **Accumulator Bit-width**: 26-bit unsigned accumulator.

### Stage 7: Retiming Boundary 2 (`pee_pipe`)
- Registers the accumulated PEE output prior to the decision logic.

### Stage 8: Dual-Threshold Adaptive Schmitt Trigger (`schmitt_peak_detector.v`)
- **Dynamic Threshold Adaptation**:
  $$\text{th}_1 = \frac{3}{4} \times \text{Peak}_{\text{avg}} \qquad \text{th}_2 = \frac{1}{2} \times \text{Peak}_{\text{avg}}$$
- **Hysteresis State Machine**:
  - Transitions to *State High* when $\text{PEE}[n] > \text{th}_1$.
  - Resets to *State Low* when $\text{PEE}[n] < \text{th}_2$.
- Eliminates double-counting caused by notched R-waves or biphasic QRS complexes.

### Stage 9: Missed-Beat Search-Back Rescue (`search_back.v`)
- Tracks running average RR interval ($\text{RR}_{\text{avg}}$).
- If no peak occurs within $1.5 \times \text{RR}_{\text{avg}}$, a lower threshold $\text{th}_{\text{rescue}} = 0.5 \times \text{th}_1$ is applied to the buffered history window.
- Recovers missed beats during premature ventricular beats or sudden amplitude dips.

### Stage 10: Real-Time Arrhythmia Classifier (`rr_classifier.v`)
- Measures inter-beat interval in clock ticks / sampling samples.
- Calculates Heart Rate:
  $$\text{BPM} = \frac{60 \times f_s}{\text{RR}}$$
- Diagnostic Class Output:
  - `2'b00`: **Normal Sinus Rhythm** ($60 \le \text{BPM} \le 100$)
  - `2'b01`: **Bradycardia** ($\text{BPM} < 60$)
  - `2'b10`: **Tachycardia / Premature Ventricular Contraction** ($\text{BPM} > 100$)
  - `2'b11`: **Arrhythmic Episode / Asystole**

---

## 3. Integrated Clock Gating (ICG) Architecture

Three modular clock domains are implemented via `icg_generic.v`:

1. `gclk_in`: Gated by `ecg_valid`. Drives front-end filter and derivative stages.
2. `gclk_core`: Gated by pipeline valid signal. Drives SEE, PEE, and Squarer datapaths.
3. `gclk_rr`: Gated by peak detection events. Updates RR buffer, heart rate calculation, and classifier state.

This achieves $>70\%$ dynamic power reduction by keeping unused blocks dormant between ECG sampling cycles.
