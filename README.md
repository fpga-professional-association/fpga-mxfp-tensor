# fpga-mxfp-tensor

Reproduction and extension of "Jack of All Scales: A Versatile FPGA Tensor Block for MXFP
Precisions" (Mekhemer et al., Waterloo/Toronto, arXiv 2607.13898, July 2026).

The paper characterizes five ways to compute 32-element MXFP dot products on an Altera Agilex 5
and proposes a modified DSP tensor mode that natively handles MXFP4, MXFP6, and MXFP8 E4M3 for a
36% larger DSP tile (about 1.8% of die area), giving 4.2x average throughput. We vendor the
authors' MIT-licensed code, reproduce their results on Quartus 26.1, run the tensor-mode path on
an Agilex 3 board we own, and extend the work toward Agilex 7 and MXFP4 LLM inference.

## Layout

| Path | What |
|---|---|
| `paper/` | The PDF and its extracted text. |
| `docs/01_paper_review.md` | What the paper does, what holds up, what is missing, implications. |
| `docs/02_reproduction_plan.md` | Phased plan with status checkboxes. Phase 0 done. |
| `docs/03_agilex7_and_performance.md` | Why Agilex 7 has no tensor mode, what you can get instead, TFLOPS estimates per device. |
| `docs/04_mxfp4_model_fit.md` | Which models fit in MXFP4 on which Agilex part, and estimated decode rates. |
| `docs/05_external_analysis_agilex_2x.md` | A separately produced deep-research note on Agilex 5/7/25/27 supplied by the user, with our verification notes. |
| `docs/06_agilex3_results.md` | Measured results: the paper's designs on Agilex 3 silicon (AXC3000), plus the Agilex 5 reproduction under Quartus 26.1. |
| `docs/perf_model_output.txt` | Output of the model below at the time of writing. |
| `reports/Agilex 2X series architecture.md` | Deep-research report on Altera's Agilex 2X (27 and 25) from the 28 Oct 2026 launch documents. |
| `agilex3/char/` | Scripts that retarget the paper's characterization designs to any part; results CSVs. |
| `agilex3/board/` | AXC3000 bitstream: Platform Designer shell, JTAG test harness, golden model, System Console driver, measured results. |
| `scripts/perf_model.py` | Peak-throughput and LLM-fit calculator. Reproduces Table V of the paper exactly. |
| `upstream/fpga-mxfp` | Submodule: github.com/boutros-lab/fpga-mxfp (authors' RTL, scripts, ASIC reports). |

## Headline findings so far

- Measured on silicon: the paper's E2M1 and E2M3 tensor-mode dot products are bit-exact on an
  Agilex 3 A3CY100 (64/64 vectors each, 240 MHz, 11-cycle latency). The paper itself never ran on hardware.
- All 12 of the paper's DSP-based designs fit Agilex 3 within 3% of the paper's Agilex 5 ALM
  counts; the Agilex 5 numbers reproduce under Quartus 26.1.
- Block floating point without a decoder (W4A8-BFP, INT8-BFP) is also bit-exact on the board at
  the same 4 DSPs and clock; the MXFP4 decoder costs no area. PTQ on Qwen2.5-0.5B says INT4-BFP
  loses to MXFP4 at equal storage (21.8 vs 17.9 perplexity) and INT5-BFP (15.6) is the sweet spot.
- Agilex 27 (announced 28 Oct 2026) has a second-generation tensor block with two 16-element
  columns (32 INT8 multipliers), but Altera publishes no FP8, FP4 or MXFP support for it.

- The paper's peak numbers reproduce from first principles: 846 DSP blocks x 20 MACs x 458 MHz.
- Agilex 7 has no tensor mode. The proposed block cannot be used there, but the big Agilex 7
  parts still reach an estimated 35 to 50 TFLOPS MXFP4 with packing, and the Agilex 7 9x9
  sum-of-4 DSP mode with pre-aligned inputs looks like a better fit than packing (to be measured).
- Agilex 3 has the same tensor block as Agilex 5, so our AXC3000 board can run the baseline
  tensor-mode designs on real silicon, which the paper never did.
- For LLM inference the Agilex 7 M-series (32 GB HBM2e, 820 GB/s) is the only candidate.
  gpt-oss-20b in native MXFP4 fits with room to spare at an estimated 200+ tok/s batch-1 decode.
  gpt-oss-120b does not fit in one or two devices without DDR5 behind the HBM.
- Real checkpoints are weight-only MXFP4 with fp8 or bf16 activations. A mixed-format lane
  (E4M3 x E2M1) is the most valuable change to the paper's block and is first in our plan.

## Getting started

```
git clone --recurse-submodules https://github.com/fpga-professional-association/fpga-mxfp-tensor
python scripts/perf_model.py
```

Quartus Prime Pro 26.1 is at `C:\altera_pro\26.1`. Questa Intel FPGA Starter Edition is needed
for the upstream simulations and is not yet installed. See the plan for the rest.
