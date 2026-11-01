# fpga-mxfp-tensor

Reproduction and extension of the paper

> Marwan Mekhemer, Ahmed Elsousy, Balaji Venkatesh, Raphael Rowley, Vaughn Betz, Nachiket Kapre
> and Andrew Boutros. "Jack of All Scales: A Versatile FPGA Tensor Block for MXFP Precisions."
> arXiv:2607.13898 [cs.AR], 15 July 2026. https://arxiv.org/abs/2607.13898

by the University of Waterloo and the University of Toronto. The authors' RTL, scripts and ASIC
reports are their work, released under the MIT license at
https://github.com/boutros-lab/fpga-mxfp and included here unmodified as a git submodule. All
measurements in this repository that use their designs are measurements of their designs.

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
| `docs/07_external_quantization_formats.md` | Supplied note on Agilex-specific quantization formats, with our PTQ pilot and decoder-cost results. |
| `docs/08_quant_benchmark_results.md` | Results of the AGX5-MXQ-001 benchmark spec: M1 conformance, M2 quality matrix on Qwen2.5-1.5B, M3 silicon variants, exports. |
| `quant/` | Implementation of the AGX5-MXQ-001 spec: quantizers, oracles, model wrapper, sensitivity allocator, evaluation, exporter, decoder RTL and goldens. |
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
  the same 4 DSPs and clock; the MXFP4 decoder costs no area.
- PTQ on Qwen2.5-1.5B-Instruct (spec AGX5-MXQ-001): only INT8-BFP W8A8 passes the +0.5 perplexity
  gate; MXFP4 weights beat INT4-BFP weights at equal storage (12.39 vs 14.44 with INT8 activations);
  INT5-BFP W5A8 (11.58 at 5.16 b/w) is the best accuracy per stored bit, and it uses the same DSP
  lanes as MXFP4. W4A4 of any kind is poor (16.3 MXFP4, 26.2 INT4-BFP).
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

## Citation and attribution

If you use anything from this repository, cite the paper first:

```bibtex
@article{mekhemer2026jackofallscales,
  title   = {Jack of All Scales: A Versatile {FPGA} Tensor Block for {MXFP} Precisions},
  author  = {Mekhemer, Marwan and Elsousy, Ahmed and Venkatesh, Balaji and Rowley, Raphael and
             Betz, Vaughn and Kapre, Nachiket and Boutros, Andrew},
  journal = {arXiv preprint arXiv:2607.13898},
  year    = {2026},
  month   = jul,
  url     = {https://arxiv.org/abs/2607.13898}
}
```

The authors' code: boutros-lab/fpga-mxfp, MIT license, vendored at `upstream/fpga-mxfp`. The
dot-product units, systolic arrays and proposed DSP block RTL measured here are theirs.

What is ours: the Agilex 3 retarget scripts, the AXC3000 board harness and shell, the golden
model and System Console driver, the decoder-free `bfp_dot.sv` variant, the throughput and
LLM-fit model, the PTQ format comparison, and the documents in `docs/` and `reports/`. Two
documents in `docs/` (`05` and `07`) reproduce analyses produced by other tools and say so at
the top. Device figures come from Altera's published product tables and user guides, linked
where used.

`paper/` holds the arXiv v1 PDF for convenience. The copyright is the authors'; refer to the
arXiv record for the license the authors chose.
