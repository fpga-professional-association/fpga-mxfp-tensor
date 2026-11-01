# External note: an Agilex-specific quantization format (W4A8-BFP, INT4-BFP)

Provenance: supplied by the user on 2026-10-31, produced by a separate research tool. Reproduced
with image links and citation chips stripped; wording otherwise unchanged. Our notes and the
experiments we derived from it are at the end.

---

Yes. In fact, Altera already uses FPGA-specific quantization formats that are different from the
formats optimized for NVIDIA and AMD GPUs. We could go further and develop a custom quantization
scheme specifically for Agilex DSP architectures.

The most interesting opportunity is to combine 4-bit weight storage with the native INT8 tensor
execution hardware on Agilex 5, avoiding much of the hardware required for general floating-point
arithmetic.

## 1. The optimal quantization format depends on the FPGA

Altera's FPGA AI Suite documentation confirms the following preferred formats:

| FPGA | Preferred compute format | Hardware |
|---|---|---|
| Agilex 5 | INT8-BFP | 20 INT8 multiplications/DSP |
| Agilex 7 | INT9-BFP | 4 INT9 multiplications/DSP |
| Agilex 27 | INT8 tensor candidate | 32 INT8 multiplications/DSP |
| Agilex 25 | Not yet verified | Detailed DSP specifications needed |

Here, BFP means block floating point: multiple numbers have integer mantissas and share an
exponent. Altera calls its native AI Suite formats FP12AGX for Agilex 5 and FP13AGX for Agilex 7.
These are software-defined numerical representations targeting the architecture, not
conventional IEEE FP12 or FP13. This is highly relevant because the best quantization format for
a GPU isn't necessarily the fastest format for an FPGA.

## 2. Proposed Agilex-specific format: W4A8-BFP

Weight storage: two 4-bit weights per byte plus block scale metadata. A small FPGA unpacking and
decoding circuit converts weights into signed INT8 operands. INT8 activations are block-scaled
values. The native Agilex tensor DSP computes INT8 x INT8, accumulates, and the scales are
applied afterwards. The concept is to store weights compactly while performing arithmetic in the
exact fixed-point format the DSP already accelerates.

For example, MXFP4 E2M1 values can be converted exactly to signed five-bit integers by
multiplying their represented values by two. Those integers can be sign-extended into the
eight-bit DSP inputs without losing precision: MXFP4 weights -> INT5 -> INT8 DSP. No
floating-point multiplier is needed for the individual four-bit elements.

Important distinction: this doesn't double the DSP arithmetic throughput. Agilex 5 still executes
its existing INT8 operations. The benefit is reduced weight storage and potentially lower memory
traffic, with relatively inexpensive decoding logic.

## 3. Formats to benchmark on Agilex 5

| Format | Stored bits per weight | DSP input width | Main advantage |
|---|---|---|---|
| INT8-BFP | ~8.16 | 8 | Altera's established native format |
| MXFP4 E2M1 | 4.25 | 5, expanded to 8 | Standardized; strong dynamic range |
| Custom INT4-BFP | ~4.16 | 4, expanded to 8 | Very simple decoder and arithmetic |

Storage figures assume 32-element groups, five-bit shared exponents for the BFP formats, and
eight-bit shared exponents for MXFP4; they exclude tensor metadata and unquantized layers.

Why INT4-BFP could be attractive: a group of signed four-bit integers shares one power-of-two
scale, w_i = 2^ew q_w,i and a_i = 2^ea q_a,i, so sum_i w_i a_i = 2^(ew+ea) sum_i q_w,i q_a,i.
The whole inner dot product is ordinary integer arithmetic with the exponent applied after
accumulation. Compared with MXFP4: simpler decoding and no per-element exponent operations;
potentially worse accuracy when values inside one block span a large dynamic range. The central
research question: can we quantize or fine-tune a model so the loss of precision from
shared-exponent INT4 is small enough to justify simpler FPGA hardware?

## 4. Quantization block sizes matched to the DSP

OCP MXFP4 uses a fixed group size of 32. Agilex 5 calculates two 10-element dot products per DSP.
A custom scheme could experiment with 10-, 20-, 40- or 80-element groups. Distinguish the
quantization group size (how many values share a scale) from the hardware execution tile (how
many values the DSP calculates at once); they need not be identical. Benchmark 32-element groups
mapped onto 10-element tiles against choosing a multiple of 10 as the group size. For Agilex 27,
the 16-element dot-product geometry makes 32-element blocks a natural match.

## 5. Quantizing an existing LLM

Start with a pretrained BF16 model (Llama 3.1 8B, Qwen3 8B): (1) BF16 baseline on perplexity and
task evals; (2) PTQ of linear-layer weights to MXFP4, INT4-BFP or INT8-BFP, with INT8 activation
calibration; (3) keep normalization, softmax and selected attention or output layers at higher
precision, profile which layers can be reduced; (4) QAT if necessary, simulating the FPGA's exact
integer ranges, scale selection, rounding and saturation; (5) export an FPGA-native checkpoint
with packed 4-bit weights, shared exponent tables, DSP-friendly tiles and metadata; (6) validate
hardware against a software model with precisely the same quantization and accumulator behavior.
Tools: AMD Quark (MXFP4/6, MXINT8, AWQ, GPTQ) for the MXFP4 baseline; Brevitas for custom
simulated quantizers and QAT; Altera FPGA AI Suite for its block floating-point calibration as a
reference.

## 6. Fitting an 8B model

Idealized weight storage for 8B parameters: BF16 16 GB, INT8-BFP ~8.2 GB, MXFP4 ~4.25 GB, custom
INT4-BFP ~4.2 GB. Real checkpoints keep some tensors at higher precision. Four-bit options help
Agilex 5 fit weights in external memory and reduce the bandwidth Agilex 7 M-Series needs to stream
them; on Agilex 27 they raise compute utilization when weights are reused. Aggressive quantization
does not solve attention, KV-cache bandwidth, unsupported operators or weight loading cost.

## 7. Recommended experiment

Quantize the same 1B to 3B LLM into four formats (INT8-BFP, MXFP4 E2M1, custom INT4-BFP, mixed
INT4/INT8-BFP) and benchmark real GEMM kernels on Agilex 5: accuracy, weight storage, ALMs, DSPs,
Fmax, sustained GEMM throughput, external-memory bandwidth, performance per watt. The result to
look for: whether a QAT-trained INT4-BFP model can match MXFP4 accuracy while using less
conversion logic and delivering higher sustained FPGA throughput.

---

## Our notes

- The paper already does the "MXFP4 -> INT5 -> INT8 DSP" step. Its `mxfp_dot.sv` converts each
  E2M1 code to a signed integer (value x 2) and subtracts M from the shared exponent before the
  tensor block. So the W4A8-BFP datapath and the paper's E2M1 datapath are the same hardware;
  the difference is only the decoder and the format of what sits in memory.
- INT4-BFP and INT8-BFP operands are plain sign-extended int8 lanes to the tensor block. They
  need no decoder at all. We test both on silicon with one bitstream: `agilex3/board/rtl/bfp_dot.sv`
  is the paper's cascade with the MXFP decoder removed, and `mx_golden.py --bfp 4` / `--bfp 8`
  generate INT4-BFP x INT8-BFP and INT8-BFP x INT8-BFP vectors with exact fp32 expectations.
  Results in `06_agilex3_results.md`.
- The accuracy question (INT4-BFP vs MXFP4 at group 32, and INT4-BFP at group 10/20/32/40) is a
  software experiment. `scripts/quant_formats.py` fake-quantizes a small LLM's linear weights to
  each format and measures perplexity on the same text. The analysis's "central research
  question" is answered to first order by that script, without QAT.
- The throughput claim is right and worth restating: none of this changes DSP throughput on
  Agilex 3/5. Every format runs at 20 MACs per DSP per cycle. The wins are memory footprint,
  bandwidth, and decoder ALMs.
- FP12AGX/FP13AGX names and the "Altera preferred format" table are the note's; we have not
  verified them against FPGA AI Suite documentation yet.
