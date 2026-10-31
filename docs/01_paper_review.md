# Review: "Jack of All Scales: A Versatile FPGA Tensor Block for MXFP Precisions"

Mekhemer, Elsousy, Venkatesh, Rowley, Betz, Kapre, Boutros. University of Waterloo and
University of Toronto. arXiv 2607.13898v1, 15 July 2026. Code: github.com/boutros-lab/fpga-mxfp
(MIT), vendored here under `upstream/fpga-mxfp`.

## What the paper does

Three things, in order.

1. Characterizes five ways to build a 32-element MXFP dot product (fp32 output) on an Agilex 5
   A5E065 with Quartus 25.3: the Imperial soft-logic baseline from Samson et al. (FPL 2024),
   a pipelined version of it, packed 18x18 fixed-point multipliers, the fp16 vector mode, and
   the DSP's floating-point tensor mode. All five MXFP sub-formats (E5M2, E4M3, E3M2, E2M3,
   E2M1) are covered.
2. Proposes modifications to the tensor mode of the Agilex 5 DSP so that it natively accepts
   MXFP inputs. Four design iterations are costed in ASAP7 standard cells (Genus + Innovus via
   HAMMER) plus COFFE for the routing interfaces. The preferred design (iteration 4) is a 36%
   larger DSP tile, roughly 1.8% of die area, and supports dot-16 E2M1, dot-12 E2M3/E3M2, and
   dot-8 E4M3. E5M2 is dropped.
3. Builds systolic arrays for all formats using the real Agilex 5 DSP as a pin-compatible
   stand-in for the proposed block, so Quartus can place and route the array and report
   realistic fmax and utilization. Claims 9.1x to 15.3x for formats that previously could not
   use the tensor mode, 1.3x to 2.4x for E2M1/E2M3, 4.2x average.

## Key numbers (Table I and Table V, A5E065, k = 32)

| Format | Best today (approach, ALMs, DSPs, D, TFLOPS peak) | With proposed DSP (ALMs, DSPs, D, TFLOPS) |
|---|---|---|
| E5M2 | packed, 10,421, 16, 3, 2.1 | 210, 4, 2, 12.4 (needs the bigger iteration 2/3.3 block) |
| E4M3 | packed, 4,841, 16, 2, 3.4 | 210, 4, 2, 12.4 |
| E3M2 | packed, 4,153, 16, 3, 6.5 | 96, 3, 2, 16.5 |
| E2M3 | tensor, 420, 4, 2, 12.4 | 96, 3, 2, 16.5 |
| E2M1 | tensor, 198, 4, 2, 12.4 | 39, 2, 2, 24.8 |

I rebuilt the "fill the device" peak calculation in `scripts/perf_model.py` from the per-unit
costs and get the same numbers to the decimal, which confirms the device has 846 DSP blocks
and 222,400 ALMs and that the method is just units x D x 64 FLOP x fmax.

## Why the tensor mode fails for wide-exponent formats

This is the core insight and it is simple. The Agilex 5 tensor mode is an int8 dot-10 with a
shared 8-bit exponent per vector. It sums products without per-element alignment. The only
way to feed it MXFP is to pre-align each element to signed fixed point using its own exponent.
A 2-bit exponent gives at most 2 positions of shift, so E2M1 becomes 5 bits and E2M3 becomes
7 bits, both inside the 8-bit lane. E3M2 needs 10 bits, E4M3 19 bits, E5M2 34 bits. Those do
not fit, so you fall back to packing unsigned significands into 18x18 multipliers and doing
alignment, two's complement, and reduction in soft logic, which is where the ALMs go.

## What I think is strong

- The characterization is the useful part for anyone shipping on today's silicon. The
  decision table (tensor for E2M1/E2M3, packed for the rest, fp16 vector when you are ALM
  starved) is actionable and the code to reproduce it is public.
- The pin-compatible stand-in trick is clever. The proposed block keeps the 104-in, 64-out,
  64-chain interface, so the real DSP can stand in for placement and routing while the new
  internals are verified by RTL simulation. This gives the systolic array numbers far more
  credibility than an area-only ASIC study would.
- The design space exploration is honest about MXFP8. E5M2 needs a 67-bit CSA tree and they
  show exactly what it costs and then drop it. Iteration 4's dot-8 baseline is a sensible
  observation that dot-10 wastes lanes for k = 16 and k = 32.
- Area overhead is bounded conservatively. The baseline block only models the tensor mode,
  so the 36% is an overestimate relative to a full commercial block.

## What I think is weak or missing

- Peak TFLOPS assume single-instance fmax across a full device, and the authors say so. The
  soft-logic approaches degrade most, so the real gap between tensor and packed is wider than
  Table V suggests. The systolic array study (Section V) partly fixes this. Only the largest
  arrays are quoted at "around 400 MHz".
- No accuracy evaluation at all. The paper assumes MXFP accuracy from Rouhani et al. and never
  runs a model through the hardware. For an inference story, bit-exactness against the OCP MX
  reference (or against a GPU MXFP4 kernel) matters and is not shown.
- The proposed block is MXFP x MXFP, same format on both operands. Real inference deployments
  today are mostly weight-only MXFP4 with fp8 or bf16 activations (for example the AMD
  "w-mxfp4-a-fp8" gpt-oss checkpoints). A mixed-format lane (E4M3 activations x E2M1 weights)
  is a small change to their native-input design and is not discussed.
- NVFP4 (E4M3 scale per 16, fp32 tensor scale) is mentioned as future work. It is the format
  Blackwell actually runs, and it only changes the scale datapath, so it is cheap to add.
- ASAP7 is a predictive academic PDK and Agilex 5 is Intel 7. Absolute area is not comparable;
  only the ratio is meaningful, and even the ratio depends on how much of the real block was
  left out of the baseline.
- The pre-aligned fixed-point trick is only applied to the tensor mode. It also makes the
  DSP's sum-of-N fixed-point modes usable for E2M1/E2M3 (sum-of-six 9x9 on Agilex 5,
  sum-of-four 9x9 on Agilex 7). That does not matter on Agilex 5 because the tensor mode is
  denser, but it matters a lot on Agilex 7, which has no tensor mode. See
  `03_agilex7_and_performance.md`.
- The device is small. 846 DSP blocks is a mid-range Agilex 5. Absolute numbers (12 to 25
  TFLOPS) are tiny next to a GPU, and the paper does not place them in that context.
- Quartus 25.3 only. No check of whether the stand-in trick survives a tool version change.

## Implications

For Altera: the paper is a well-argued request for an MXFP-native tensor mode in the next DSP
generation. The 1.8% die cost for a 4x throughput gain on the formats the industry is
standardizing on is an easy sell, and the authors are the right people to be making it
(Betz wrote COFFE, Boutros wrote the FPL 2018 DSP enhancement paper that Stratix 10 NX
followed).

For anyone building MXFP inference on current Agilex parts: use the tensor mode for MXFP4 and
E2M3, do not bother with E5M2, and treat E4M3 as the format where the hardware fights you.
On Agilex 7 there is no tensor mode at all and the strategy changes completely.

For the OCP MX ecosystem: it is one more datapoint that MXFP4/MXFP6 map cleanly onto 8-bit
integer machinery after pre-alignment, while MXFP8 does not. That is also why GPU vendors
treat fp8 and fp4 as different hardware paths.
