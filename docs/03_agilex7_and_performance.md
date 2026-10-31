# Can this extend to Agilex 7, and what performance can we get?

Short answer: the paper's proposed block cannot be used on Agilex 7 because it is an ASIC
proposal, not something you can configure, and Agilex 7 has no tensor mode at all to stand in
for it. But the characterization half of the paper transfers directly, and the bigger Agilex 7
parts give 3x to 6x the raw throughput of the paper's Agilex 5 even without a tensor mode.
The M-series with HBM2e is the only Altera part where MXFP4 LLM inference makes sense.

## What the Agilex 7 DSP block actually has

From the Agilex 7 Variable Precision DSP Blocks User Guide (683037) and the F/I/M-series
product tables (2025.09.30):

- Fixed point: two independent 18x19, one 27x27, 18x19 sum of two, 36x18, 8x8 unsigned or
  9x9 signed sum of four, systolic FIR modes.
- Floating point: fp32 multiply, add, multiply-add, multiply-accumulate, vector one and two;
  fp16 sum of two (with fp32 add or accumulate), fp16 vector one, two, three. fp16 modes
  accept IEEE half, "extended" fp16, and bfloat16.
- No int8 dot-10 tensor mode. That mode exists in Stratix 10 NX, Agilex 5, and Agilex 3 only.
- Datasheet fmax for 18x19 fixed point: 900 MHz (-1V), 771 MHz (-2V), 676 MHz (-3). Floating
  point modes are lower and I did not get a verified table; the paper's fp16 vector designs
  ran at 446 to 460 MHz on Agilex 5 -4, and Agilex 7 -2 should be somewhat higher.

| Device | ALMs | DSP blocks | 18x19 mults | Notes |
|---|---|---|---|---|
| Agilex 5 A5E065 (paper) | 222,400 | 846 | 1,692 | has tensor mode |
| Agilex 3 A3CY100 (ours) | ~34K | 138 | 276 | has tensor mode, -7 speed grade |
| Agilex 7 AGF027 | 912,800 | 8,528 | 17,056 | F-series, no HBM |
| Agilex 7 AGM039 | 1,305,600 | 12,300 | 24,600 | M-series, 32 GB HBM2e at 820 GB/s, DDR5 |

So Agilex 7 has 10x to 15x the DSP count and 4x to 6x the ALMs of the paper's part, but each
DSP block can only do 2 MACs (fp16 vector) or 4 MACs (9x9 sum-of-4) or up to 10 effective
packed MACs per cycle for MXFP4, versus 20 for the Agilex 5 tensor mode and 32 for the paper's
proposed block.

## Three ways to run MXFP on Agilex 7, and one new one

1. Packed 18x19 multipliers (paper's approach for E3M2/E4M3/E5M2). Works unchanged on
   Agilex 7. ALM bound: 3,590 ALMs per 5 MXFP4 dot-32 units, so AGM039 fills its ALMs after
   using only 47% of the DSPs.
2. fp16 vector mode. Works unchanged. 2 MACs per DSP, format independent, tiny ALM cost.
   22 TFLOPS peak on AGM039 for every format. Boring but reliable, and it uses the DSPs the
   packed approach leaves idle.
3. Optimized soft logic. Works but fmax collapses when the device fills.
4. New: pre-aligned fixed point into the 9x9 sum-of-4 mode. The paper pre-aligns E2M1 to 5-bit
   and E2M3 to 7-bit signed fixed point before the tensor block. Those widths also fit the
   Agilex 7 9x9 signed sum-of-four mode, which sums four products with no alignment needed
   because the operands were pre-aligned. One DSP block becomes a dot-4; eight blocks plus a
   seven-adder soft tree and one fixed-to-fp32 converter make a dot-32. My estimate is about
   260 ALMs per dot-32 unit against 718 for packing. This is the same insight as the paper's
   Section III-D, applied to a mode the paper did not consider. It has to be measured.

For E3M2 (10-bit pre-aligned) and MXFP8 (19 and 34 bits) the 9x9 mode does not fit, and the
18x19 sum-of-two gives only 2 MACs per block, so for those formats Agilex 7 stays with packing
plus fp16 vector mode.

## Peak throughput estimates

From `scripts/perf_model.py`, using the paper's measured per-unit costs. "Peak at unit fmax" is
the paper's optimistic method. "Peak at 450 MHz" assumes the full device closes at 450 MHz,
which is a guess informed by the paper's Agilex 5 arrays closing at about 400 MHz and Agilex 7
-2 being a faster fabric. Full output is in `perf_model_output.txt`.

| Format | A5E065 best today (paper) | A5E065 with proposed DSP (paper) | AGF027 best, 450 MHz | AGM039 best, 450 MHz |
|---|---|---|---|---|
| E2M1 (MXFP4) | 12.4 tensor | 24.8 | 36.6 packed, or 51 mixed (est.) | 52.3 packed, or 74 mixed (est.) |
| E2M3 (MXFP6) | 12.4 tensor | 16.5 | 26.8 packed, 30.7 sum-of-4 (est.) | 38.3 packed, 44.3 sum-of-4 (est.) |
| E3M2 (MXFP6) | 6.5 packed | 16.5 | 18.9 packed | 27.1 packed |
| E4M3 (MXFP8) | 3.4 packed | 12.4 | 15.4 fp16 vector | 22.1 fp16 vector |
| E5M2 (MXFP8) | 2.1 packed | 12.4 (bigger block) | 15.4 fp16 vector | 22.1 fp16 vector |

Units are TFLOPS. "Mixed" is the two-approach fill where one approach consumes the ALMs and
another consumes the leftover DSPs. The soft-logic half of a mix will not hold 450 MHz on a full
device, so treat the mixed numbers as upper bounds and the single-approach numbers as the
planning figures.

What I would actually plan on: 30 to 45 TFLOPS sustained MXFP4 on AGM039 after control,
memory, and attention logic take their share. Around 15 to 20 TFLOPS for MXFP8 E4M3.

## Does the paper's proposed DSP matter for Agilex 7?

Only as an argument to Altera. If a future Agilex 7-class part shipped the iteration 4 block,
AGM039 would have 12,300 x 32 MACs per cycle at 458 MHz, about 360 TFLOPS MXFP4 peak. That is
15x what you can get from the same die today. It is the clearest quantitative case the paper
did not make: the die area is 1.8% and the payoff on a big part is an order of magnitude.

## Agilex 3 (what we own)

The A3CY100 has the Agilex 5 style tensor block, so everything in the paper's tensor mode path
runs on it. At 138 DSPs it is a verification vehicle, not a performance one: about 1.3 TFLOPS
MXFP4 peak at an assumed 300 MHz. It is still the only place we can measure MXFP4 on real
silicon without buying a board.

## Comparison to the MI355X

One MI355X does 10.1 PFLOPS dense MXFP4 with 8 TB/s of HBM3E. One AGM039 at 40 TFLOPS and
820 GB/s is 0.4% of the compute and 10% of the bandwidth. The FPGA case is not throughput. It
is deterministic latency, custom formats (NVFP4, mixed W4A8, odd block sizes) without waiting
for a GPU generation, tight coupling to IO (sensor front ends, network), and power envelopes
under 100 W. For raw tokens per dollar the MI355X wins by two orders of magnitude.

## Sources

- Agilex 7 DSP user guide 683037: https://docs.altera.com/r/docs/683037/current
- Agilex 7 F-series product table: https://cdrdv2-public.intel.com/690880/agilex-7-fpgas-and-socs-f-series-product-table.pdf
- Agilex 7 I-series product table: https://cdrdv2-public.intel.com/732806/agilex-7-fpgas-and-socs-i-series-product-table.pdf
- Agilex 7 M-series product table: https://cdrdv2-public.intel.com/721636/agilex-7-fpgas-and-socs-m-series-product-table.pdf
- Agilex 7 HBM2e, 820 GB/s: https://intel.com/content/www/us/en/docs/programmable/683458/current/heterogeneous-3d-stacked-hbm2e-dram.html
- Agilex 5 E-series product table: https://cdrdv2-public.intel.com/743772/agilex-5-fpgas-and-socs-e-series-product-table.pdf
- Agilex 3 AI tensor block and A3CY100 resources: https://www.intel.com/content/www/us/en/docs/programmable/817231/current/fpgas-and-socs-summary-of-features.html
- MI355X specs: https://www.amd.com/en/products/accelerators/instinct/mi350/mi355x.html
