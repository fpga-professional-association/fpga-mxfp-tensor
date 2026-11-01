# AGX5-MXQ-001: FPGA-optimized quantization benchmark (implementation)

Implementation of the specification in `AGX5_MXQ_SPEC.md` (supplied 2026-10-31). Status per
milestone is below; measured numbers live in `results/` and are summarized in the main repo's
`docs/08_quant_benchmark_results.md` once produced.

Primary device per the spec is Agilex 5 A5EC065BB32AE4S (Quartus fits). Silicon runs use the
Agilex 3 A3CY100 on the Arrow AXC3000 we own and are reported as a separate target.

## Layout

| Path | What |
|---|---|
| `python/agilex_quant.py` | Quantizers (INT8-BFP, INT4-BFP, INT5-BFP, MXFP4 E2M1+E8M0) with the spec's exact numeric contracts, int64/float64/fp32 oracles, nibble and scale packing. |
| `python/model_wrappers.py` | `QuantizedLinearEmulator`: per-token dynamic activation quantization, cached weight quantization, mixed per-layer formats. |
| `python/sensitivity.py` | Per-layer delta-loss map and the W8 budget allocator (delta loss per extra byte). |
| `python/evaluate.py` | M2 matrix: B0, C0, C1, C1a, C2, C2a, X5, C3 at 5/10/20/40% W8. Perplexity, KL vs bf16, top-1 agreement, activation clip rate, manifest with SHAs. |
| `python/export_checkpoint.py` | `.fpgaq` exporter (manifest + packed blobs) and round-trip verifier. |
| `tests/test_quant.py`, `tests/test_serialization.py` | M1 conformance: all 16 E2M1 codes, tie cases, exponent clamps, 100k random dot32 per format vs int64 oracle, packing round trips. |
| `rtl/mxq_decoders.sv` | `mxq_e2m1_to_s5`, `mxq_int4_to_s8`, `mxq_bfp_scale_decode`, `mxq_qdot10_ref`, `mxq_scale_apply` (int32 x 2^e to fp32, RNE). |
| `tests/gen_rtl_vectors.py`, `tests/tb_mxq_decoders.sv`, `tests/run_sim.sh` | Golden vectors and Icarus testbench for the RTL modules. |
| `configs/` | model.yaml and quant_c0..c3 (+ablations). |
| `../agilex3/board/rtl/fxp_dot.sv` | Spec V1: tensor fixed-point mode, int32 cascade, one fabric fp32 rescale per group (`mxq_scale_apply`). |
| `../agilex3/board/rtl/bfp_dot.sv` | V3/V4: raw int8 lanes into the tensor floating-point block (INT8-BFP, INT4-BFP sign-extended). |
| `../agilex3/board/rtl/mxfp_harness.sv` | DUT_KIND 0 = paper's V0, 1 = bfp_dot, 2 = fxp_dot. |

## How to run

```
.venv/Scripts/python -m pytest quant/tests -q                       # M1 conformance
.venv/Scripts/python quant/tests/gen_rtl_vectors.py                 # RTL goldens
bash quant/tests/run_sim.sh                                          # Icarus (WSL): decoders vs goldens
.venv/Scripts/python quant/python/evaluate.py --model Qwen/Qwen2.5-1.5B-Instruct --tokens 65536
.venv/Scripts/python quant/python/export_checkpoint.py --model Qwen/Qwen2.5-0.5B --fmt int4_bfp --out quant/results/export_qwen05b_int4_bfp
```

Board (AXC3000): set `DUT_KIND` in `agilex3/board/syn/top.qsf`, `bash agilex3/board/build.sh`, then
`MX_DATA=data_w4a8_bfp.tcl MX_RESULT=... system-console --script=run_test.tcl` from `agilex3/board/host`.
Golden data: `mx_golden.py --bfp 4|8` (C2/C0 operands), `--mxfp4_lanes` (C1 with host-side E2M1 decode),
`--e 2 --m 1` (paper's own decoder path).

## Milestone status

| Milestone | Status |
|---|---|
| M0 locked environment | Model revision SHA, library versions and eval-text SHA written to `manifests/model_sha.json` by evaluate.py. Quartus 26.1.0 b110 (spec asked for 25.3; recorded). |
| M1 quantizers and conformance | Done: 7 tests pass (16 codes, ties, clamps, 100k dot32 x 3 formats exact, packing, export round trip). |
| M2 PTQ quality matrix | Running on Qwen2.5-1.5B-Instruct, WikiText-2, 65,536 tokens. Pilot on Qwen2.5-0.5B in `docs/07`. |
| M3 Quartus arithmetic microbenchmarks | V0 (paper), V3/V4 (`bfp_dot`) and V1 (`fxp_dot`) built; V0/V3/V4 bit-exact on silicon; V1 in test. Seeds and the 350/400/450/500 MHz sweep not yet run. V2, V5, V6 not started. |
| M4 real weight replay | Not started. The harness takes 64 vectors per run; replaying model matrices needs the GEMM tile. |
| M5 QAT / mixed precision | C3 allocation by sensitivity is in M2; QAT not started. |
| M6 deployment prototype | Not started. |

## Deviations from the spec, stated

- Quartus 26.1 instead of 25.3 (installed version); Agilex 5 numbers are fits only, silicon is Agilex 3.
- Weight exponents in `fxp_dot` are captured in fabric at preload time, since the fixed-point tensor
  mode has no shared-exponent port. The paper's V0 relies on the DSP doing this internally.
- Scales are stored one byte per group in the exporter (the spec's "8-bit practical scale storage");
  the theoretical minimum is reported alongside.
- KL and top-1 agreement are computed on the first 8 eval chunks (8,184 tokens), not all 64, to keep
  the bf16 reference logits in host memory.
