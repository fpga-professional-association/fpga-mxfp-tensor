# Results: AGX5-MXQ-001 quantization benchmark (spec in `quant/AGX5_MXQ_SPEC.md`)

Date: 2026-10-31. Code: `quant/`. Everything here is measured by the scripts in that directory;
hardware rows are from the AXC3000 (Agilex 3 A3CY100) and Quartus 26.1 fits.

## M1: quantizers and conformance (done)

`quant/tests`: 7 tests pass. All 16 E2M1 codes, tie-to-even cases, exponent clamps and
saturation, 100,000 random dot32 vectors per format against an int64 oracle, maximum sum widths
from the spec's table (516,128 / 28,448 / 4,608), nibble and scale packing round trips, and
`.fpgaq` export round trips on synthetic and real model tensors.

RTL (`quant/rtl/mxq_decoders.sv`, Icarus): E2M1 decoder 16/16, INT4 sign-extend 16/16, scale
decode 288/288, soft dot10 golden 2,000/2,000, int32-to-fp32 rescale 2,015/2,015 including
overflow, flush, carry-out and tie cases.

## M2: PTQ model-quality matrix (done, one model)

Qwen2.5-1.5B-Instruct, 196 block linears (1,310M parameters) quantized, embeddings / lm_head /
norms kept bf16. WikiText-2 test, 65,536 tokens, seqlen 1,024. Dynamic per-token activation
scales. KL and top-1 agreement against bf16 on the first 8,184 tokens. RTX 5070.

| Config | Weights | Activations | Bits/weight | Perplexity | vs bf16 | KL to bf16 | Top-1 agree | Gate (+0.5 abs) |
|---|---|---|---|---|---|---|---|---|
| B0 | bf16 | bf16 | 16.00 | 10.891 | - | - | - | - |
| C0 | INT8-BFP | INT8-BFP | 8.16 | 10.914 | +0.2% | 0.004 | 0.966 | pass |
| X5 | INT5-BFP | INT8-BFP | 5.16 | 11.577 | +6.3% | 0.067 | 0.875 | fail (+0.69) |
| C3 40% W8 | mixed INT4/INT8-BFP | INT8-BFP | 5.76 | 11.710 | +7.5% | 0.098 | 0.850 | fail |
| C3 20% W8 | mixed | INT8-BFP | 4.96 | 12.202 | +12.0% | 0.138 | 0.828 | fail |
| C1a | MXFP4 | INT8-BFP | 4.25 | 12.392 | +13.8% | 0.150 | 0.816 | fail |
| C3 10% W8 | mixed | INT8-BFP | 4.56 | 12.691 | +16.5% | 0.175 | 0.811 | fail |
| C3 5% W8 | mixed | INT8-BFP | 4.36 | 13.112 | +20.4% | 0.204 | 0.790 | fail |
| C2 | INT4-BFP | INT8-BFP | 4.16 | 14.440 | +32.6% | 0.292 | 0.748 | fail |
| C1 | MXFP4 | MXFP4 | 4.25 | 16.313 | +49.8% | 0.432 | 0.698 | fail |
| C2a | INT4-BFP | INT4-BFP | 4.16 | 26.175 | +140% | 0.901 | 0.581 | fail |

Bits/weight count the spec's theoretical scale bits (5-bit BFP exponent, 8-bit E8M0 per 32).
Activation clip rate was 1.9e-4 for every INT8-activation config, 1.0e-2 for C1 and 3.6e-3 for C2a.

Reading of the hypotheses in spec section 1.2:

- H1 holds. INT8-BFP is lossless to within noise (+0.2%, 0.004 KL) and is the only config that
  passes the gate. This is the W8A8 the AI Suite's FP12AGX convention points at.
- H2 holds as arithmetic (M1 and the silicon runs) but MXFP4 x MXFP4 (C1, W4A4) is the second
  worst row at +50%. The activation side, not the weight side, does the damage: the same
  weights with INT8 activations (C1a) are at +14%.
- H3 is answered in the direction the 0.5B pilot predicted. INT4-BFP weights lose to MXFP4
  weights at equal activation width (C2 14.44 vs C1a 12.39) and at equal storage. The per-element
  exponent is worth about 2 perplexity points on this model. The decoder it needs costs no area on
  the tensor block (see `06`).
- H4 holds partially. Mixed W4/W8 at 20% W8 (4.96 b/w) lands at 12.20, essentially the MXFP4 W4A8
  number at 17% more storage; at 40% W8 (5.76 b/w) it reaches 11.71. The sensitivity-ranked
  allocation works, but it does not beat the simplest alternative: INT5-BFP at a flat 5.16 b/w
  gives 11.58, better than any mixed allocation below 5.76 b/w. On the Agilex tensor block,
  INT5 operands cost exactly what MXFP4 operands cost (the paper's pre-aligned E2M1 is a 5-bit
  integer), so INT5-BFP W5A8 is the best accuracy per stored bit of anything measured here.
- H5 (fixed-point tensor mode) is a hardware question, below.

What the spec's gates say: no 4-bit weight format meets the +0.5 perplexity gate by PTQ alone on
this model. Per spec section 8.2 the selection would be INT8-BFP, or INT5-BFP / mixed if the gate
is relaxed to +1.0. QAT (M5) is the route to a 4-bit pass and has not been run.

Caveats: one model, one text, perplexity and KL only; the lm-evaluation-harness tasks and the
second-domain set in spec 8.1 are not run; no calibration data was used (scales are amax-based
per the spec's power-of-two rule), so AWQ/GPTQ-style scale search could close some of the gap.

## M3: Quartus microbenchmarks and silicon

| Variant | Device | ALMs / DSPs / fmax | Silicon (AXC3000, 240 MHz) |
|---|---|---|---|
| V0 paper E2M1 tensor-FP (`mxfp_dot`) | A5E065 | 207 / 4 / 458 | 64/64 bit-exact (E2M1 and E2M3) |
| V0 paper E2M1 | A3CY100 | 199 / 4 / 343 | same |
| V3/V4 raw int8 lanes tensor-FP (`bfp_dot`) | A5E065 | 243 / 4 / 458 | 64/64 bit-exact W8A8-BFP and W4A8-BFP |
| V3/V4 | A3CY100 | 244 / 4 / 343 | same |
| V1 tensor fixed-point + fabric rescale (`fxp_dot`) | A5E065 | 701 / 4 / 324 | - |
| V1 | A3CY100 | 703 / 4 / 254 | 64/64 bit-exact for W8A8-BFP, W4A8-BFP and MXFP4 (host-decoded lanes), latency 13 |

V1 answers spec H5 in the negative on this block. The fixed-point tensor cascade itself is one
cycle faster than the floating-point cascade (10 vs 11 cycles to the int32 sums), but doing the
shared-exponent bookkeeping and the int32-to-fp32 conversion in the fabric costs 3.5x the ALMs of
the paper's unit (703 vs 199 on Agilex 3, 701 vs 207 on Agilex 5), loses 26% to 30% of the
standalone fmax (254 vs 343 MHz; 324 vs 458 MHz) with the converter already pipelined to three
stages, and adds two cycles of latency (13 vs 11). The DSP count is identical. The tensor-FP
mode does that work inside the block for free, so for one dot-32 per group V1 has no advantage.
Where V1 could still matter is the spec's V2 idea: keeping several groups' int32 sums in the
fabric and applying one scale per output row, which the FP mode cannot do; that is unmeasured.

Debug record, kept because it is the kind of thing the next person will hit: the first three V1
builds failed on the board for two reasons of mine, not the silicon's. The unit delayed load_en
by an extra PIPE stage internally while the harness already delays it, so the DSP latched its
weight banks one cycle late (one bank got the first activation vector; the raw-sum trace showed
exactly the sum of a0 times a_k), and the fabric exponent capture then used a copy of load_en
delayed once more than the exponent. The raw-int32 debug mode (`MODE` bit 8) made both visible in
one trace each. An earlier draft of this document reported a column-mapping difference between
fixed-point and floating-point modes; there is none.

Not yet run from spec section 7: fitter seeds 1/2/3, the 350/400/450/500 MHz clock sweep, V2,
V5 and V6, and the K/M/N GEMM tile matrix. Standalone unit fmax on Agilex 3 is pinned by the
DSP's restricted fmax (343 MHz tensor modes) regardless of clock request.

## Export (spec 5.6)

`.fpgaq` artifacts for Qwen2.5-0.5B, round trip verified exact for every sampled module:

| Format | Quantized weights | Scales (1 byte/group) | Theoretical min | Kept bf16 | Total |
|---|---|---|---|---|---|
| INT4-BFP | 178.9 MB | 11.2 MB | 185.9 MB | 272.4 MB | 462.5 MB |
| MXFP4 | 178.9 MB | 11.2 MB | 190.1 MB | 272.4 MB | 462.5 MB |
| INT8-BFP | 357.8 MB | 11.2 MB | 364.8 MB | 272.4 MB | 641.4 MB |

The kept-bf16 tensors (tied embeddings, norms) are 59% of the 4-bit file on a 0.5B model, which
is the spec's point about reporting actual bytes, not ideal bits.

## Open items

M4 (real weight replay through the FPGA), M5 (QAT), M6 (board with external memory), the
lm-eval tasks, the seed and clock sweeps, and the second model (Qwen3-1.7B).
