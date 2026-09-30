# Applied optimizations

1. Lifting-style DWT datapath:
   even/odd split, predict/update, soft thresholding, shift-add arithmetic.

2. Retiming-ready:
   explicit pipeline boundaries are included. Final retiming must be performed
   by synthesis after the real target library is loaded.

3. Critical-path-only pipelining:
   pipeline registers are placed after SEE and PEE accumulation boundaries.

4. Operand isolation:
   inactive arithmetic operands are driven to zero; all sequential stages use
   explicit valid/enable behavior.

5. Clock-gating friendly RTL:
   state updates occur only when stage valid is asserted. In ASIC synthesis,
   map these enables to proper integrated clock-gating cells; do not build
   `clk & enable` manually.

6. Bit-width optimization:
   norm1 12-bit, Shannon 12-bit, SEE accumulator 18-bit, norm2 10-bit,
   square 20-bit, PEE accumulator 26-bit.

Extra:
- no divider in normalization,
- direct Shannon ROM,
- no /33 or /43 divisions,
- circular storage,
- RR-domain classification.

IMPORTANT:
The included lifting block is a hardware-oriented lifting approximation.
It is not claimed to be an exact mathematical Sym5 lifting factorization.
For an exact-Sym5 publication claim, replace that block with a formally
verified Sym5 lifting factorization or convolutional Sym5 core.
