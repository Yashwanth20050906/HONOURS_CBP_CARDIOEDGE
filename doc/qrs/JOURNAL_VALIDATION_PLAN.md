# Validation plan

Compare baseline and optimized RTL using the same MIT-BIH records and the same
clock/library/PDK constraints.

Report:
- TP, FP, FN
- Sensitivity
- Positive Predictivity
- F1
- DER
- R-peak position error
- LUT, FF, DSP, BRAM
- ASIC cell area / gate equivalents
- critical path / Fmax
- dynamic, leakage and total power
- energy/sample
- energy/beat
- PDP, ADP, EDP

Recommended ablation:
V0 baseline
V1 + lifting DWT
V2 + bit-width optimization
V3 + operand isolation / clock-enable
V4 + selective pipelining
V5 + retiming
V6 final combined
