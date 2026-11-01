# Technical Implementation and Benchmark Specification
## FPGA-Optimized Quantization for a 1B–3B LLM on Existing Agilex 5 DSP Hardware

**Specification ID:** AGX5-MXQ-001  
**Revision:** 1.0  
**Date:** 2026-10-31  
**Status:** Engineering implementation baseline; no FPGA timing, utilization, or model-quality outcomes are claimed  
**Primary device:** Agilex 5 E-Series `A5EC065BB32AE4S` (same device studied in *Jack of All Scales*)  
**Tool baseline:** Quartus Prime Pro 25.3, as used in the paper; also record results with the currently installed supported Quartus release.  
**Reference model:** `Qwen/Qwen2.5-1.5B-Instruct`, **1.54B parameters**, Apache-2.0.  
**Alternative replication:** `Qwen/Qwen3-1.7B` (Apache-2.0) after the 1.5B baseline is completed.  
**Workload:** Inference-oriented quantization. No claim that the complete 1.5B decoder will run efficiently on the target FPGA until all non-GEMM operations, DRAM interfaces, and runtime are implemented.

> **Primary deliverable:** one reproducible research pipeline producing four quantized checkpoints, exact software arithmetic oracles, Quartus-compatible matrix/dot-product RTL/IP builds, quality assessments and sustained-throughput measurements. This project is **not** a claim that Altera FPGA AI Suite natively loads these custom checkpoints.

---

## 1. Objective, hypotheses and scope

### 1.1 Objective

Determine which representation yields the best **model-quality / model-size / sustained FPGA throughput / DSP-efficiency** combination for a 1B–3B decoder-only LLM when mapped onto **existing, unmodified** Agilex 5 DSP blocks.

The primary question is **not** which representation provides the largest nominal TOPS. It is whether the memory savings from four-bit storage outweigh quantizer/dequantizer overhead, reduced model quality and DSP underutilization when running real model matrices.

### 1.2 Hypotheses

- **H1 (native baseline):** INT8-BFP mapped to the Agilex 5 tensor engine is the lowest-risk reference, with strong quality but larger weights.
- **H2 (MXFP4):** E2M1 values can be mapped *exactly* to signed five-bit integers and run within signed-eight-bit DSP lanes. Arithmetic is exact within each 32-element scaled dot product before floating-point rounding.
- **H3 (custom INT4):** custom INT4-BFP reduces decode hardware relative to MXFP4, but may lose accuracy on blocks with outliers due to its single shared exponent and uniformly spaced mantissas.
- **H4 (mixed precision):** a per-layer W4/W8 allocation based on measured sensitivity can recover much of the INT8 quality while staying close to INT4 storage.
- **H5 (implementation):** tensor fixed-point mode plus a single scale operation at the 32-element group boundary may outperform a tensor floating-point cascade in some kernels, but it must be *measured* because the latter benefits from hardened FP32 logic.

### 1.3 Deliverable levels

**Required:** pure PyTorch quantizers and exact goldens; all four model-quality runs; standalone FPGA dot32 and tiled GEMM with post-fit reports; model-derived weight vectors executed through the RTL simulator or FPGA.

**Stretch:** hardware on an Agilex 5 board with DDR/LPDDR and wall-plug power; one fully executed transformer MLP or attention projection; complete token decoding only if a suitable FPGA runtime is available.

**Explicitly excluded from initial claims:** native MXFP4 arithmetic in existing silicon, ASIC DSP modifications from the paper, full model hosting without a runtime, and FP12AGX checkpoint compatibility without conformance tests.

---

## 2. Authoritative source-derived architecture

The uploaded research paper (*Jack of All Scales*, arXiv:2607.13898v1) characterizes 32-element MXFP dot products on Agilex 5 and publishes code at `https://github.com/boutros-lab/fpga-mxfp`.

The demonstrated **existing-silicon** E2M1 tensor implementation uses four Agilex 5 DSP blocks and 198 ALMs to produce **two dot32 results** per instance at 458 MHz; the paper's preferred redesigned DSP instead produces two dot32 results with two modified DSPs, but **that DSP is not commercially available**. The paper reports fully mapped simulated benchmark results as well as theoretical device extrapolations; do not substitute hypothetical proposed DSP results for a real Quartus build.

The Agilex 5 variable-precision DSP hardware implements two dot10 signed INT8 lanes, sharing the activation vector. It has separate ping-pong weight buffers for each output column and supports **tensor fixed-point**, **tensor floating-point**, and **tensor accumulation** modes. Fixed-point mode provides a 32-bit output/cascade; floating-point mode applies shared exponents and provides FP32 output/cascade. The documented side-feed preload takes 12 cycles and can overlap computation using the other bank. Verify the exact registered handoff in simulation; the vendor's timing diagram specifies switching after preload completes.

Altera FPGA AI Suite describes `FP12AGX` as `INT8-BFP` with an **eight-bit two's-complement mantissa and five-bit block exponent**, and recommends this precision for Agilex 5. Its definition also involves the architectural parameter `c_vector`. **The custom INT8-BFP format defined below imitates the width, but is not asserted to be bit-compatible** with the FPGA AI Suite's internal convention or exponent selection.

**Primary official documentation:**

1. Agilex 5 DSP user guide: `https://docs.altera.com/r/docs/813968/25.1/variable-precision-dsp-blocks-user-guide-agilextm-5-fpgas-and-socs/tensor-fixed-point-mode`
2. Tensor floating-point mode: `https://docs.altera.com/r/docs/813968/25.1/variable-precision-dsp-blocks-user-guide-agilextm-5-fpgas-and-socs/tensor-floating-point-mode`
3. Side preload: `https://docs.altera.com/r/docs/813968/25.1/variable-precision-dsp-blocks-user-guide-agilextm-5-fpgas-and-socs/side-input-feed-preloading-method`
4. BFP notation: `https://docs.altera.com/r/docs/863373/2026.1.1/fpga-ai-suite-handbook/block-floating-point-bfp`
5. Paper and source RTL: `https://arxiv.org/abs/2607.13898` and `https://github.com/boutros-lab/fpga-mxfp`
6. OCP MX format v1.0: obtain the authoritative public specification through Open Compute Project; reference table includes 32-element E2M1 and E8M0 scale.

---

## 3. Four precise candidate formats

**Notation:** `K=32` elements in each quantization group. `q` denotes a signed integer operand presented to the DSP. For all BFP formats, the represented value is `q × 2^e`. For MXFP4 the represented value is `q × 2^(e-1)`, since `q` is twice the E2M1 value. No learned non-power-of-two scales are allowed in the fast-path hardware baseline.

| Configuration | Weights | Activations | Shared scale | Stored weight bits/element (ideal) | DSP operand(s) | Qualification |
|---|---|---|---|---:|---|---|
| **C0 INT8-BFP** | Signed INT8, `[-127,127]` | Signed INT8 | One signed 5-bit power-of-two exponent / 32 weights and separately / 32 activations | `8 + 5/32 = 8.15625` | 8 × 8 | **Custom reference**, FP12AGX-inspired |
| **C1 MXFP4 E2M1** | Standard E2M1 4-bit | Standard E2M1 4-bit | E8M0 / 32 weights and / 32 activations | `4 + 8/32 = 4.25` | 5 × 5, sign-extended to 8 | OCP element and scale encoding |
| **C2 INT4-BFP** | Signed INT4, `[-7,7]`, -8 reserved | Signed INT8, `[-127,127]` | Signed 5-bit power-of-two / 32 | `4 + 5/32 = 4.15625` | 4 × 8 | Custom **W4A8**, deliberately not W4A4 |
| **C3 Mixed INT4/INT8-BFP** | Selected layers INT4 or INT8 | Signed INT8 throughout quantized linear layers | Signed 5-bit exponent / 32, per selected precision | Depends on allocation | 4 × 8 or 8 × 8 | Custom W4/W8-A8; assign precision per module, not per token |

**Fairness caveat:** This is a comparison of four practical *configurations*, not a controlled experiment with identical activation widths. C1 is W4A4; C2 and C3 use W4A8, and C0 uses W8A8. Therefore include separate **C1a W4A8 MXFP4-weights ablation** and **C2a W4A4 INT4-BFP ablation** to disentangle the effect of activation precision from the weight format. All four primary configurations must use the same model, sequence selection and evaluation code.

### 3.1 Custom BFP numeric contract

For each group of 32 finite values `x`, choose an exponent:

`e = clamp(ceil(log2(max(abs(x))/Qmax)), -16, +15)`; `e=0` if the group is all zeros.

`q_i = clip(roundTiesToEven(x_i / 2^e), -Qmax, +Qmax)`.

- INT8-BFP: `Qmax=127`; int8 `-128` is unused in initial experiments.
- INT4-BFP: `Qmax=7`; signed four-bit `-8` is unused.
- Exponent packing: signed five-bit two's complement (`e & 0x1F`), one exponent per 32-element group. Decode exponent via sign-extension. This is **project-specific**, not an interoperable FP12AGX file format.
- At runtime the activation exponent is recalculated **per token / activation vector / 32-element K group** unless a specified static activation method is selected.
- Overflow saturates; all rounding is round-to-nearest, ties-to-even. PTQ sensitivity tracking must record clipping counts separately from quantization error.

Exponent range is a deliberate design parameter. A power-of-two exponent outside `[-16,+15]` is clamped and the values are saturated; if this becomes common in real model weights or activations, revise the custom format explicitly (for example, use a signed 8-bit exponent) and account for the added bits. The initial baseline must not silently widen it.

### 3.2 MXFP4 E2M1 numeric contract

OCP E2M1 positive magnitudes: `{0, 0.5, 1, 1.5, 2, 3, 4, 6}`; the sign bit produces negative counterparts. Thus the exact signed-integer decode is:

`q=2×E2M1_value ∈ {0, ±1, ±2, ±3, ±4, ±6, ±8, ±12}`.

MXFP4 requires `K=32`, and scale **E8M0** is an unsigned eight-bit code `X`. Normal scales are `2^(X-127)` for `X in [0,254]`; `X=255` is reserved for NaN. In the reference quantizer, `e = X-127` and `e` may be `-127 ... +127`. The block scale is selected with an amax-safe rule `ceil(log2(max_abs/6))`, clamped to this range, then values are rounded to the nearest E2M1 code, with ties resolved toward the encoding with low mantissa bit zero. This is one explicit converter design: test it against independent OCP conformance vectors and alternative scale-selection strategies before claiming converter interoperability.

For non-finite input tensors, **fail closed** in the initial build. Subsequent work must specify handling of NaNs, negative zero, over-range inputs and reserved scale codes. Exported weights must never contain `E8M0=0xFF` in the normal finite pathway.

### 3.3 Zero, bias and partial high precision

- Padded K lanes must use zero codes and must not alter a group's original scale.
- Do **not** quantize an entire output row with one scale if the format calls for one scale per group of 32.
- Keep layer-normalization / RMSNorm, softmax, rotary embedding, nonlinear activation and all KV-cache handling in the **software model's baseline higher precision** at first. Hardware support for those elements is a separate deliverable.
- Keep embedding weights, final LM head and output biases in BF16/FP16 initially; then add sensitivity-based optional quantization for these modules, with storage separately accounted.
- Weights are stored as `[output_channel, K]`; each output channel has its own sequence of 32-element scales. Activations have separate 32-element K scales **per token**. Scale factors must never be shared across different output-channel weights by accident.

---

## 4. Exact arithmetic and accumulator requirements

For a single K=32 group, compute:

`S_g = Σ_{i=0}^{31} q_w[g,i] × q_a[g,i]` with a **signed integer exact sum**, and then apply:

`Y_g = S_g × 2^(e_w[g] + e_a[g] - f_w - f_a)`.

Where `f=1` for MXFP4 (because `q = 2 × E2M1`) and `f=0` for BFP integer operands. For multiple K groups, `Y = Σ_g Y_g`, with each `Y_g` independently scaled. **Never add integer partial sums from different scale groups unless their exponents are first aligned.**

| Operand pair | Largest product magnitude | Maximum dot32 absolute sum | Minimum signed width |
|---|---:|---:|---:|
| W8×A8 | 127×127 = 16,129 | 516,128 | 20 bits |
| MXFP4 q×q | 12×12 = 144 | 4,608 | 14 bits |
| W4×A8 | 7×127 = 889 | 28,448 | 16 bits |
| W4×A4 | 7×7 = 49 | 1,568 | 12 bits |

The Agilex 5 tensor fixed-point mode provides a 32-bit result and cascade, so these **one-group** sums fit without overflow. Across multiple K groups, scale before intergroup summation. For the final FP32 output, define and test a specific rounding strategy; results need not be bit-identical to BF16 baseline model outputs or a different FP32 accumulation order.

**Golden outputs required:** (1) int64 partial group sums exact; (2) float64 scaled sum mathematical oracle; (3) bit-level FP32 group-wise scaled and accumulated software model reflecting FPGA rounding; (4) BF16/FP32 original-model output for quality measurement. Label each reference distinctly.

---

## 5. PyTorch software implementation

The accompanying starter module `python/agilex_quant.py` implements and unit-tests:

- `quant_bfp(x, width=4|8, group=32)` — signed shared-exponent integer quantization;
- `quant_mxfp4(x, group=32)` — E2M1 bit encoding and E8M0 scale selection;
- `QTensor.dequant()` — reference reconstruction;
- `integer_dot_group(a,b)` — integer dot-group exact oracle plus exponent;
- `reference_dot(a,b)` — float64 group-scaled oracle;
- `fake_quant(x, fmt)` — STE fake quantizer for early QAT;
- `pack_nibbles()` / `unpack_nibbles()` — low-nibble-first packed weight storage;
- `pack_signed_exponent5()` and `pack_mxfp4_scale()` — scale serialization.

**Important scale:** the reference code is an **algorithmic prototype** designed for vectors, layers and chunked checkpoints. It is not memory-optimal for quantizing 1.54B parameters in a single call. Large weights must be processed layer-by-layer or in configurable 1–16M-element chunks, with a production exporter streaming packed bytes to disk. The STE is a minimal surrogate: implement clipping-aware STE and saturation gradient behavior before final QAT experiments.

### 5.1 Integration design

Implement a `QuantizedLinearEmulator(nn.Module)` that retains a BF16 or FP32 master weight, wraps each selected `nn.Linear`, and provides:

- `weight_fmt`: `int8_bfp | mxfp4 | int4_bfp`;
- `activation_fmt`: `int8_bfp | mxfp4 | int4_bfp`;
- `group_size`: fixed at 32 for main comparison;
- `act_scale_mode`: `dynamic_per_token` (default), `static_calibrated` (ablation);
- `mode`: `observer | fake_quant | packed_reference`;
- per-module numerical and clipping statistics.

In `fake_quant`, run:

```python
w_hat = fake_quant(weight, weight_fmt, group=32)
a_hat = fake_quant(input, activation_fmt, group=32)
y = torch.nn.functional.linear(a_hat, w_hat, bias)
```

This gives **numerically quantized inputs into a normal GPU/CPU GEMM**, so it is suitable for quality assessment and QAT but **does not estimate FPGA latency**. In `packed_reference`, calculate actual group-aligned integer dot products and post-scaling for selected small tensor test cases; full-model bit-exact execution can be optimized later.

### 5.2 Model selection and setup

Primary `Qwen/Qwen2.5-1.5B-Instruct` from `https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct`; pin a specific model revision SHA, tokenizer SHA, Transformers version, PyTorch version, and output model configuration. This model has ~1.54B parameters and is a sensible initial reproducible target.

Initial quantized modules are the projection and MLP `Linear` modules within transformer blocks: Q, K, V, O, gate, up and down projections (actual names discovered from the pinned model). Do not quantize RoPE, activation, RMSNorm, residual additions or cache operations in stage one. Keep embeddings and the LM head out of the initial comparison, and account for them in actual model size.

### 5.3 Calibration (PTQ)

1. Fix deterministic seeds (`0, 1, 2` for calibration sensitivity repetitions), tokenizer settings, max length, and model revision.
2. Create a stratified calibration dataset from licensed, reproducible text with code, prose, numerical, and dialogue samples. Exclude all evaluation texts and near duplicates.
3. **Default calibration budget:** 512 sequences × 1,024 tokens (~524k tokens); **ablation:** 128 and 2,048 sequences to determine data sensitivity.
4. Attach activation observers to candidate `Linear` inputs to record max abs, per-group exponent histograms, quantization MSE, clipping rate, outliers, and output-channel-specific sensitivity.
5. For C0/C2/C3, perform weight per-output-row/per-32 scale selection. For C1, use MXFP4 E2M1+E8M0 rules exactly.
6. Run no-training PTQ for each candidate; save checkpoint manifest, all scale arrays, code histograms, calibration metrics and logits from a fixed probe set.
7. As ablations test dynamic activation quantization (per token and 32-element K group) against static/calibrated activation scales. Dynamic quantization requires hardware logic or preprocessing; include that cost in real throughput.

**Optimization options:** compare plain amax-safe scaling with quantization-error-optimized scale search. An alternative scale must still be representable by the specified power-of-two exponent. AWQ/GPTQ may inform sensitivity or equivalent weight transforms, but **do not introduce arbitrary per-channel floating scales into the FPGA fast path** without explicitly implementing the needed additional arithmetic.

### 5.4 Mixed-precision assignment

For each quantizable layer `l`, measure `ΔL_l = loss(model with only l at W4) - loss(BF16)` on the fixed calibration/validation slices. Also measure output cosine similarity and layer output NMSE. Build a table `{name, parameters, ΔL_l, W4 bytes, W8 bytes, estimated FPGA cycles}`.

Choose W8 for the most sensitive layers subject to budget. Initial W8 budgets: **5%, 10%, 20%, and 40% of eligible linear-layer parameters**. Assign precision at whole-layer granularity first to avoid excessive reconfiguration/control. If adjacent modules have different widths, use the same eight-bit DSP data path and load four-bit weights after local unpack/sign-extend. Quantize activations to INT8 at all quantized linear layers.

Proposed deterministic baseline allocator: rank layers by `ΔL_l / additional_weight_byte_l` and promote to W8 until the byte budget is exhausted; compare with greedy iterative reevaluation and ILP/knapsack if needed. Re-measure interactions because isolated-layer sensitivities are not additive.

### 5.5 Quantization-aware fine-tuning (QAT)

If a four-bit PTQ model fails quality thresholds, enable QAT using fake-quantized weights and activations, maintaining higher-precision master weights. Use a frozen calibration exponent initially, then allow carefully controlled dynamic exponent selection for training forward passes. Start with 5M training tokens; extend to 10M–20M if validation improves without overfitting. Compare:

- full-rank QAT where compute permits;
- LoRA/PEFT adaptation to a fake-quantized forward path, with adapters **fused into the final model before re-quantization and export**;
- short distillation against frozen BF16 teacher logits, mixing cross entropy and KL divergence.

Example starting hyperparameters (must be tuned, not claims of optimality): AdamW, learning rate `1e-5` full-parameter or `1e-4` LoRA, warmup 2%, gradient clipping 1.0, mixed BF16 training master weights, and checkpoint every 1M tokens. Track the **same** held-out data and never select on the final test set. QAT clipping-aware gradients must match the selected quantizer's saturation policy; the supplied STE merely demonstrates the integration pattern.

### 5.6 Export and binary format

Define a `model.fpgaq` artifact made of a JSON or CBOR manifest and separate binary weight/scale blobs. Manifest must include format version, SHA256 of base model/config/tokenizer, module ordering, quantization formats, group size, logical/padded matrix shapes, exponent width/bias, sign convention, byte order, nibble order, scales offset, weights offset, and per-layer CRC or SHA256.

- MXFP4 and INT4-BFP: **low nibble stores the first K element**; high nibble stores the next element. K is padded to multiple of 32 with zero codes.
- INT4-BFP negative values use signed four-bit two's complement; MXFP4 uses E2M1 sign/exponent/mantissa codes and must **not** be decoded as int4 two's complement.
- INT8-BFP: signed int8 bytes; scales are packed or stored unpacked for first-phase convenience, but both *actual bytes* and *theoretical minimum* must be reported.
- INT4/INT8-BFP scale: one signed five-bit exponent/group; initial exporter may place in one byte, but label this as **8-bit practical scale storage** when calculating actual size.
- MXFP4 scale: one E8M0 byte/group; `0xFF` reserved.
- Padded weights, unquantized parameters, biases, embeddings, tokenizer and metadata are counted in actual on-disk checkpoint size.

**Storage sanity for 1.54B wholly quantized parameters (ideal, no packing/padding/kept-precision overhead):** BF16 3.080 GB; INT8-BFP 1.570 GB; MXFP4 0.818 GB; INT4-BFP 0.800 GB (decimal GB). Actual exported model size will be larger, particularly when some layers stay BF16.

---

## 6. FPGA RTL design requirements

Create a layerable, synthesizable SystemVerilog codebase with vendor-specific DSP instances isolated behind wrappers. Avoid assuming an inferred `*` or `for` loop automatically maps to tensor mode; *verify DSP use in the post-map technology view and fitter reports*.

### 6.1 Modules and interfaces

| Module | Purpose | Essential contract |
|---|---|---|
| `mxq_e2m1_to_s5.sv` | Four-bit E2M1 to signed five-bit `q=2P` | Combinational, all 16 codes, negative zero policy documented |
| `mxq_int4_to_s8.sv` | Sign extend custom INT4 to signed eight-bit | Use signed two's complement (special `-8` invalid in symmetric profile) |
| `mxq_bfp_scale_decode.sv` | Decode signed 5-bit BFP exponent / E8M0 scale | Preserve exponent semantics; trap reserved MX NaN scale |
| `mxq_qdot10_ref.sv` | **Soft RTL golden** two dot10 integer sums | Exact signed integer multiplication; not accepted as proof of tensor DSP inference |
| `mxq_agx5_tensor_fxp_wrapper.sv` | Native AI Optimized DSP **tensor fixed-point IP** | Two dot10 outputs, integer cascade, control and preload; explicit generated IP stub |
| `mxq_agx5_tensor_fp_wrapper.sv` | Tensor floating-point IP | Correct shared exponent mapping, FP32 outputs, cascades |
| `mxq_dot32.sv` | Four dot10 stages for 32-element groups | Lane mapping 10+10+10+2, unused lanes zero-filled, independent two-column results |
| `mxq_weight_pingpong.sv` | Weight preload controller | Support data-feed and side-feed modes; no read/write collision |
| `mxq_scale_apply.sv` | Signed int sum times power-of-two, FP32 output | **One scale per 32-element K group**, clipping/underflow/rounding specified |
| `mxq_gemm_pe.sv` | Two-output-channel processing element | Share activation vector, independent weight scales per output |
| `mxq_gemm_tile.sv` | Parameterized PE tile and FIFOs | M/N/K tile widths, valid/ready, performance counters |
| `mxq_axi_dma.sv` | Optional external memory source/sink | Functional only after target board/controller is chosen |
| `mxq_perf_counters.sv` | Cycle statistics | active multiply cycles, preload, stalls, bytes, tiles, errors |

**Externally observable `dot32` transaction:** `clk`, reset, `valid_i`, mode, packed 32-element activation/weight data or predecoded eight-bit lanes, one scale for activation and one for each of two output-channel weight groups, `ready_o`, `valid_o`, two signed partial sums (debug), two FP32 outputs, and exception flags. Use synchronous reset and registered valid alignment; report exact latency in cycles.

### 6.2 DSP mapping variants

- **V0:** reproduce author's E2M1 paper tensor floating-point design as faithfully as possible, with 32-element groups and two output columns. Record Git commit and Quartus version.
- **V1:** tensor fixed-point mode, exact signed decoded operands, four DSPs for two dot32 outputs (the paper's resource expectation), 32-bit cascades, and **one FP32 rescale per 32-value dot**.
- **V2:** as V1 but use fabric to combine the four 10-element partials instead of in-DSP cascade, for a controlled Fmax/ALM tradeoff.
- **V3:** INT8-BFP native tensor fixed-point mode with W8A8, group 32 and per-group scaling.
- **V4:** INT4-BFP weights unpack/sign-extend into same INT8 tensor lanes, activations INT8; no assertion of multiplier-count improvement.
- **V5:** mixed precision, alternate W4 and W8 per layer **without recompiling the fabric**. Compare the cost of universal decode logic against separate-specialized bitstreams as an ablation.
- **V6:** signed six-way 9×9 DSP multiply-adder baseline for irregular kernels, if an appropriate native DSP IP configuration is supported on the exact device.

Vendor tensor IP instances must be generated from a pinned Quartus installation; check generated IP parameters and licenses into an appropriate reproduction manifest. Do not invent exact `altera_*` primitive port names. The attached combinational decoder/golden RTL is vendor independent and *not* the tensor IP wrapper.

### 6.3 Hard requirements and functional checks

- Signed arithmetic correct for all lanes and all two's-complement negative values in supported ranges.
- The two output columns share activations but **never share the wrong weight-group exponent**.
- Exactly 32 logical elements per MXFP4 group; for 10+10+10+2 partition, 8 padded lanes must contribute zero.
- Integer partial sums must match PyTorch bit-for-bit for 10- and 32-element groups.
- Add FPGA FP32 scale and accumulation comparison against a cycle-accurate soft reference; distinguish any permitted rounding differences from arithmetic bugs.
- Dynamic activation scaling must be either **measured as part of hardware** or explicitly excluded from fixed-weight microbenchmark throughput and reported as preprocessing overhead.
- Side-feed mode must observe vendor's load/start/ready timing; allow continued computation only on the non-loading bank.
- Time-critical paths must contain pipeline registers. Output valid/ready must tolerate backpressure and bubble injection without duplicating or losing results.
- Flag and halt on invalid `0xFF` E8M0 scales in the normal finite profile, exponent overrange, malformed packed stream and CRC failure.

### 6.4 Verification plan

1. **Formal/structural:** SV assertions for valid alignment, no dropped transactions, accumulator reset, channel independence, ping-pong exclusivity; lint and CDC checks.
2. **Unit test:** all 16 MXFP4 codes, all BFP mantissa extremes, all-zero blocks, both signed zero encodings, powers-of-two scale extremes, exponent saturation and quantizer midpoint ties.
3. **Directed dot product:** cancellation, all maximal values, mixed signs, one nonzero lane, every K position, 10+10+10+2 tail, independent weights across columns.
4. **Random:** at least 100,000 dot32 vectors / format, with reproducible random seeds; compare integer results exactly.
5. **Matrix:** 128 randomized GEMM shapes/tile boundaries, including M or N=1, K not multiple of 32 (padding), odd output counts and bank transitions.
6. **Stress:** at least 10 million consecutive valid cycles at functional RTL simulation level *or* equivalent FPGA continuous streaming, with backpressure/preload changes; count errors and dropped outputs.
7. **Model-derived:** 1,000 input/weight block pairs from each of five sensitive real model layers, plus end-to-end output sample from at least one linear layer.

---

## 7. Quartus build, constraints and experiment matrix

### 7.1 Tool reproducibility

Save `quartus_sh --version`, `quartus_sta --version` (if available), device part number, exact `qsf`/`sdc` content, IP generator version, source commit, git diff status, host RAM/CPU, operating system and seed. Preserve post-synthesis, fitted and final timing reports for every experiment.

Use the **exact target `A5EC065BB32AE4S`** for the primary comparison. Add a second device only as a separate reported target, never silently mix resources or Fmax across device parts.

All modes must use consistent latency accounting and I/O register boundaries. Use fixed timing constraints, e.g. 350/400/450/500 MHz target sweeps (periods approximately 2.857/2.5/2.222/2.0 ns). Avoid comparing one variant as a purely combinational block against another with extra uncounted pipeline stages. Register input/output and report pipeline latency separately.

A minimal build-command pattern (once the Quartus project has been generated) is:

```bash
quartus_sh --version
quartus_sh --flow compile agilex_mxfp -c agilex_mxfp
```

Create one revision per mode/format or generate a project per configuration; set fitter seed (e.g. seeds 1, 2, 3) through the standard `.qsf` assignment. Use the built-in Quartus Timing Analyzer and Fitter resource reports for metrics. A production automation script should parse generated reports in a **version-validated** way; do not assume report labels or exact XML keys are stable across Quartus releases.

### 7.2 Benchmark sweep

| Dimension | Values |
|---|---|
| Modes | V0–V6 as relevant |
| Formats | C0, C1, C2, C3; plus ablations C1a/C2a |
| K | 32, 128, 512, 2048, 4096 |
| GEMM M | 1, 8, 32, 128 |
| GEMM N | 2, 32, 128, 512 |
| Weight reload | data feed vs side feed |
| Buffering | 1 vs 2 vs 4 or more weight/activation tiles |
| Clock request | 350, 400, 450, 500 MHz |
| Fitter seeds | 1, 2, 3 (at minimum) |
| Dataset | synthetic random, hard corner cases, actual Qwen model matrices |

Run a **small qualification subset** first before committing hundreds of compilations. Do not build the full Cartesian product: select a manageable design-of-experiments sample, then zoom into Pareto-front configurations.

### 7.3 Compile metrics

Capture exact **ALMs, DSP blocks, M20Ks, MLAB, registers, RAM bits, routing congestion, failed timing paths, Fmax**, total/peak power estimate if the power analyzer is configured, and total compilation duration. Distinguish ALM usage for the arithmetic core versus decoders, exponent handling, FIFOs and bus wrappers.

No power number can be labeled **measured watts** without an on-board physical measurement. Treat vendor power analyzer as **estimated** and document inputs/toggle activity.

### 7.4 Runtime metrics

- Dot32/s (one dot32 = **64 operations**, 32 multiplies plus 32 adds by common ML counting convention).
- `GOPS = dot32_per_second × 64 / 1e9`.
- Sustained **GOPS / DSP**, **GOPS / 1k ALMs**, and **GOPS/W** if power measured.
- Dot-output latency in clock cycles and nanoseconds; steady-state initiation interval; startup/reload latency.
- Peak sustained and 95th-percentile useful-cycle utilization; weights loaded per second; activations/weights bytes/s.
- Arithmetic intensity for the executed tile; effective `bytes/weight`, counted scale traffic and buffer padding.
- GEMM throughput measured from a common transaction interval including mandatory preload and scale conversion.
- If end-to-end decoding is implemented, prefill tokens/s and batch-one decode tokens/s at context lengths 128, 512, and 2048, with separately measured FPGA, host preprocessing, PCIe/DDR and cache costs.

**Compute-utilization caution:** nominal 20 INT8 multiplies per DSP per clock is not the same as 20 useful multiplies per clock for K=32 because of the 10+10+10+2 mapping. Count only useful logical operations as achieved work. Batch and K tiling affect how much amortization is possible.

### 7.5 Expected performance reporting

For each variant, produce:

```csv
run_id,git_sha,device,quartus_version,format,k,m,n,mode,seed,target_mhz,fmax_mhz,alms,dsps,m20k,mlab,latency_cycles,ii_cycles,load_cycles,active_cycles,stall_cycles,dot32_count,bytes_weights,bytes_acts,gops_sustained,gops_per_dsp,timing_met,correctness_pass
```

Provide a compiler-independent software baseline on the same GEMM shapes, but **do not compare FPGA absolute throughput against GPU BF16 GEMM as evidence of a quantization speedup without controlling arithmetic precision and memory cost**.

---

## 8. Model-quality benchmarking

### 8.1 Reference and evaluations

1. Run unquantized BF16 baseline with frozen model SHA/tokenizer/settings on the same inference framework and hardware.
2. Run each PTQ model C0–C3, plus essential activation-width ablations, using full software fake-quant inference.
3. Optionally run QAT on the best two four-bit configurations and repeat the same fixed tests.
4. Use **WikiText-2 perplexity** with predetermined tokenization/sliding-window details; include a second held-out domain dataset and a distribution-shift sample.
5. Use `lm-evaluation-harness` with a pinned commit, exact task names/versions and few-shot settings: HellaSwag, PIQA, ARC-Easy/Challenge, and (optionally) GSM8K for a more challenging accuracy check. The harness's current CLI has `lm-eval run --model hf ...`; ensure the custom fake-quant model can be loaded, not just the original base checkpoint.
6. Measure output-logit KL divergence, top-1 token agreement against BF16, per-layer output NMSE, weight quantization MSE, clipping rate, and observed scale range.
7. Evaluate temperature=0 deterministic generation on at least 200 held-out prompts with context lengths 128/512/2048, reporting exact-match task performance where applicable. Use frozen prompt templates and sampling settings.

### 8.2 Quality gates (engineering targets, not prior results)

| Metric | Gate for initial promotion | Notes |
|---|---|---|
| WikiText-2 perplexity | ≤ 5% relative increase or ≤ +0.5 absolute, whichever is **less permissive** | Threshold adjustable after baseline established |
| HellaSwag, PIQA, ARC-Easy | ≤ 2 percentage-point drop on each | Report bootstrap confidence intervals |
| Representative task success | ≤ 2 pp drop, or user-specific threshold | Predefine before final evaluation |
| Numerics | No NaNs/Inf on finite inputs; no unexplained RTL mismatch | Non-negotiable |
| Packing/export | 100% verified round-trip on model tensors | Non-negotiable |
| FPGA bit-exact integer dot | 100% on validation vectors | Non-negotiable |

Require **quality + fit + sustained-performance** together to declare a winner. If no four-bit candidate meets quality, select INT8-BFP or mixed precision and report that outcome rather than relaxing the numerical fidelity claim.

---

## 9. Comparison framework and decision rules

All results must include these competing baselines:

- **B0:** BF16 pretrained software inference, model-quality reference, no FPGA.
- **B1:** author's published existing-Agilex-5 E2M1 tensor-mode RTL, reproduced on the specified device/version; this is the FPGA reference for MXFP4.
- **B2:** Altera FP12AGX/AI Suite pipeline, if a **numerically compatible supported model** can be built; explicitly mark this as a tool-stack baseline, **not** an identical implementation of project C0.
- **B3:** simple 8-bit signed matrix dot mapped to Agilex 5 DSP tensor IP; independent of quantization checkpoint pipeline.

For the four candidate formats compute a Pareto frontier over *(accuracy loss, exported bytes, sustained GOPS, watts, DSPs, ALMs)*. Rank using feasibility gates first rather than collapsing incompatible objectives into a single ungrounded weighted score.

Suggested winner priority:

1. Meet non-negotiable correctness and all declared quality gates.
2. Meet target device memory/DSP/ALM limits and timing closure across three seeds.
3. Maximize **sustained useful GEMM GOPS/W** at a fixed, realistic tiling workload.
4. At equivalent compute efficiency and accuracy, select the smaller checkpoint and easier runtime.
5. Demonstrate same format and exporter operation on a second 1B–3B LLM before declaring generality.

---

## 10. Execution milestones and acceptance criteria

### M0: locked environment and baseline

**Deliver:** model revision/sha, manifest, calibration/eval datasets, tool versions, BF16 quality baseline, author's RTL repository commit and build instructions. **Accept:** reproducible twice with identical seeds and dataset hashes.

### M1: quantizers and conformance

**Deliver:** signed INT8/INT4 BFP, OCP E2M1/E8M0, fake quant, 4-bit packing, unpacking, group-scale reference. **Accept:** all codebook and tie cases tested; software integer dot exact; randomized tests ≥100k/group; three repeatable model exports.

### M2: PTQ model-quality matrix

**Deliver:** C0–C3 checkpoints, ablations, sensitivity map, actual sizes, evaluation metrics. **Accept:** no uncontrolled test-set tuning; independent evaluation; all run configurations archived.

### M3: Quartus arithmetic microbenchmarks

**Deliver:** V0–V5 RTL/IP wrappers and projects, functional simulation, 3-seed fitter/time reports. **Accept:** exact dot results, reproducible scripts, clearly sourced real DSP utilization, Fmax and ALMs.

### M4: real weight and GEMM replay

**Deliver:** actual Qwen weight/activation matrices replayed through RTL/FPGA and post-fit sustained-throughput reports, including preload and scale conversion. **Accept:** no correctness mismatch; throughput includes all mandatory transfer and reload cycles.

### M5: optimize/iterate/QAT

**Deliver:** clip-aware QAT or mixed-precision refinement, rerun frozen quality suite, update Pareto frontier. **Accept:** pick winning configuration or document none passes the declared gates.

### M6 (optional): deployment prototype

**Deliver:** one full linear/MLP layer integrated with board memory and runtime, board-measured watts, host-vs-FPGA timing, documented accuracy agreement. **Accept:** end-to-end layer outputs numerically verified and complete runtime overhead included.

---

## 11. Project file tree and reproducibility contract

```text
agilex_quant_benchmark/
├── README.md
├── AGX5_MXQ_SPEC.md
├── configs/
│   ├── model.yaml
│   ├── quant_c0_int8_bfp.yaml
│   ├── quant_c1_mxfp4.yaml
│   ├── quant_c2_int4_bfp.yaml
│   └── quant_c3_mixed.yaml
├── python/
│   ├── agilex_quant.py        # supplied in starter
│   ├── model_wrappers.py      # implement
│   ├── calibrate.py           # implement
│   ├── sensitivity.py         # implement
│   ├── qat_train.py           # implement
│   ├── export_checkpoint.py  # implement
│   └── evaluate.py           # implement
├── tests/
│   ├── test_quant.py          # supplied in starter
│   ├── test_dot_vectors.py    # implement
│   ├── test_gemm.py           # implement
│   ├── test_serialization.py  # implement
│   └── golden_vectors/       # generate deterministic files
├── rtl/
│   ├── mxq_e2m1_to_s5.sv     # supplied in starter
│   ├── mxq_qdot10_ref.sv      # supplied in starter
│   ├── mxq_dot32.sv          # implement
│   ├── mxq_agx5_tensor_{fxp,fp}_wrapper.sv # generated IP wrapper
│   ├── mxq_scale_apply.sv    # implement
│   ├── mxq_gemm_pe.sv        # implement
│   └── ...
├── quartus/
│   ├── agilex_mxfp.qpf/.qsf/.sdc # implement
│   ├── ip/                  # generated per pinned tool
│   └── scripts/             # seed sweeps and report extraction
├── results/
│   ├── quality/
│   ├── resource_reports/
│   ├── waveforms/
│   ├── throughput/
│   └── pareto.csv
└── manifests/
    ├── model_sha.json
    ├── datasets_sha.json
    └── toolchain.json
```

**No hidden assumptions:** record file SHA, pinned software versions and hardware part in all reports; all RTL or FPGA speedups must be reproduced from the archive. If parts of the toolchain are offline/air-gapped, vendor IP, PyTorch wheels, model weights and datasets must be transferred using an approved internal method and hashed at both ends.

**Recommended next action:** implement `model_wrappers.py` and `export_checkpoint.py`, prove quantized Qwen 1.5B quality first, then compare `V0` vs `V1` and `V4` on exactly the same sampled 32-element vectors. Stop or refactor before scaling the systolic array if model accuracy is unacceptable or tensor DSP inference does not work as expected.

---

## 12. References and methodological caveats

1. Mekhemer et al., *Jack of All Scales: A Versatile FPGA Tensor Block for MXFP Precisions*, arXiv:2607.13898 (2026): `https://arxiv.org/abs/2607.13898`.
2. Authors' RTL/benchmarks: `https://github.com/boutros-lab/fpga-mxfp`.
3. Altera, *Agilex 5 Variable Precision DSP Blocks User Guide* (25.1): `https://docs.altera.com/r/docs/813968/current`.
4. Altera, *FPGA AI Suite Handbook*, BFP numeric precision (2026.1.1): `https://docs.altera.com/r/docs/863373/2026.1.1/fpga-ai-suite-handbook/block-floating-point-bfp`.
5. OCP, *Microscaling Formats (MX) Specification*, v1.0: official spec and FP4/E8M0 codebook; use primary OCP spec as conformance authority.
6. Qwen, 1.5B model card and Apache 2.0 license: `https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct` and `https://qwen.ai/blog?id=qwen2.5-llm`.
7. EleutherAI, *lm-evaluation-harness*: `https://github.com/EleutherAI/lm-evaluation-harness`.
8. Lin et al., *Activation-aware Weight Quantization (AWQ)* implementation: `https://github.com/mit-han-lab/llm-awq`.

**Source boundary:** Hardware mode availability and the existing MXFP4 dot32 reference are verified from vendor documentation and the uploaded paper. Custom signed-five-bit BFP exponent encoding, scale-selection rules, precision allocations, QAT settings, benchmark thresholds, new RTL modules and projected optimization benefits are **design proposals defined by this specification**, not published Altera capabilities or measured results.
