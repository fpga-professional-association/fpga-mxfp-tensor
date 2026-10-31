# Plan: reproduce the paper, then improve on it

Status legend: [ ] not started, [~] in progress, [x] done. Keep this file current.

## What we have on this machine

| Item | Status | Notes |
|---|---|---|
| Quartus Prime Pro 26.1 (and 2026.1.1) | have | C:\altera_pro\26.1. Agilex 3, 5, 7 device support installed. Paper used 25.3. |
| Agilex 3 board, Arrow AXC3000 (A3CY100BM16AE7S) | have | 138 DSP blocks with the same AI tensor block as Agilex 5. Our only MXFP-capable silicon. |
| Agilex 5 / Agilex 7 hardware | none | Agilex 5 E-series dev kit is the cheapest path to match the paper on silicon. |
| Questa / ModelSim | not installed | Upstream sim scripts are Questa-based and the Agilex tensor DSP sim model is a Mentor library. Install Questa Intel FPGA Starter Edition (free). |
| Icarus Verilog | have (miniforge) | Can simulate the pure-RTL proposed block but not Altera DSP primitives or the FloPoCo VHDL. |
| WSL2 Ubuntu 24.04 | have | Needed for HAMMER, OpenROAD, COFFE, Verilator. |
| Cadence Genus / Innovus | none | Paper's ASIC flow. We substitute OpenROAD-flow-scripts with the public ASAP7 platform. |
| RAM | 32 GB | Upstream says `make -j4` needs more than 40 GB. Use `-j2`. |
| GitHub | tcovert2015/fpga-mxfp-tensor (private) | This repo. Upstream is a submodule. |

## Phase 0: scaffolding (this session)

- [x] Directory, git, GitHub remote, paper moved, upstream vendored as submodule.
- [x] Paper review (`01_paper_review.md`).
- [x] Peak-throughput and LLM-fit model (`scripts/perf_model.py`) that reproduces Table V.
- [x] Agilex 2X deep research: `reports/Agilex 2X series architecture.md` (notes in `research_notes/`).
- [ ] Install Questa Intel FPGA Starter Edition 26.1 and point `MODELSIM` env at it.
- [ ] `sudo apt install verilator` in WSL. Try Verilator on `aitb_asic/rtl` (SystemVerilog) with
      the FloPoCo VHDL blocks replaced by SV equivalents (see Phase 3).

## Phase 1: reproduce the characterization (Table I, Fig. 3) on Agilex 5

Target A5EC065BB32AE4S, same part as the paper, Quartus 26.1 instead of 25.3.

1. [~] Run `characterization/Makefile` with `-j2`. Done for the tensor-mode designs (E2M1, E2M3)
       on A5EC065BB32AE4S via `agilex3/char/run_aitb.sh`: 207/4/458 and 417/4/458 vs the paper's
       198/4/458 and 420/4/458. Soft-logic baselines and the packed/fp16 runs on Agilex 5 remain.
       Original step: run `characterization/Makefile` with `-j2` and whatever the Makefile expects for the
       Quartus path. Fix Windows path issues or run under WSL with the Linux Quartus if easier.
2. [ ] Compare `base.csv`, `base_opt.csv`, `packed_base.csv`, `fp16_base.csv`, `aitb_base.csv`
       to Table I. Expect ALM counts within a few percent and fmax within 5 to 10% (26.1 vs 25.3).
       Record deltas in `results/characterization_26.1.md`.
3. [ ] `make sim-all` with Questa to confirm functional equivalence across approaches.
4. [ ] Re-run `scripts/perf_model.py` with our measured per-unit costs instead of the paper's.

Exit criterion: our own Table I and Fig. 3, with differences explained.

## Phase 2: reproduce on silicon we own (Agilex 3 AXC3000)

The paper never runs on a board. We can, for the formats the baseline tensor mode supports.

1. [x] Retarget `characterization/ai_tensor_block` (E2M1, E2M3) and `packed_multiplier` (E3M2,
       E4M3) to A3CY100BM16AE7S. All 12 DSP-based designs fit within 3% of the paper's ALMs; see
       `06_agilex3_results.md`. Check that the Agilex 3 tensor DSP IP has the same ports
       (104 in, 64 out, 64 chain) as Agilex 5. Our earlier CoreDLA project in
       `D:\altera_demo\agilex_mlperf_demo` already has the board constraints and a JTAG host path.
2. [ ] Scale `systolic_array/rtl/sys_array_aitb.sv` down (N = 2..6) to fit 138 DSPs and ~34K ALMs.
3. [x] JTAG Avalon harness (`agilex3/board`), exact MX golden model, System Console driver.
4. [x] E2M1 bit-exact on silicon, 64/64 vectors, 240.1 MHz measured, latency 11 cycles.
       Tensor-mode restricted fmax on the -7 part is 342.94 MHz.
5. [x] Device-fill peak at 343 MHz: 1.49 TFLOPS MXFP4. One unit measured at 30.7 GFLOPS.
6. [ ] E2M3 on silicon (build in progress).
7. [ ] Register the harness RAM reads (it uses 19K ALMs as flops today) and sweep the DUT PLL
       to find the real on-silicon fmax of the dot unit.

Exit criterion: an MXFP4 systolic array running on the AXC3000 with a measured tok/s-style
number for a toy matmul and a bit-exact check against the MX reference.

## Phase 3: reproduce the DSP block study (Table IV) with open tools

1. [ ] Simulate `aitb_asic` designs (baseline `aitb`, iterations 1 to 4) with Questa using the
       upstream `make sim` and `make sim_all_mxfp`. Confirm pass.
2. [ ] Replace the four FloPoCo VHDL normalizers and `ieee_fp32_add.vhdl` with SystemVerilog so
       the design simulates in Verilator and synthesizes in Yosys/OpenROAD without mixed-language
       support. Check equivalence by co-simulation against the VHDL versions in Questa.
3. [ ] Port the HAMMER YAMLs to OpenROAD-flow-scripts (ORFS) on the ASAP7 platform in WSL.
       Target the same 2 ns clock and 1.5x cell-area floorplan utilization.
4. [ ] Produce our own Table IV. Expect different absolute areas (Genus/Innovus vs Yosys/
       OpenROAD) but the same ordering and similar ratios. Report both.
5. [ ] COFFE for interface area: optional. The interface area is identical for every iteration
       except 4 (72 vs 80 input pins), so a re-run only matters if we change pin counts.

Exit criterion: an independently produced area ratio for iteration 4 vs baseline. If it lands
between 1.25x and 1.5x, the paper's 1.36x is credible.

## Phase 4: reproduce the systolic array study (Fig. 6)

1. [ ] Run `systolic_array/summarize_systolic_array_sweep.py` on Quartus 26.1 (4 hours upstream).
2. [ ] Compare the N sweep and the "largest array that fits" throughput to Fig. 6.
3. [ ] Confirm the ~400 MHz full-device fmax claim and the 22 to 32% soft logic use.

## Phase 5: improvements (our contribution)

Ordered by value divided by effort. Each gets its own `docs/exp_*.md` with hypothesis, method,
result.

1. [ ] Mixed-format lanes: E4M3 activations x E2M1 weights (W4A8), and E4M3 x E2M3 (W6A8).
       Change only the input preparation and multiplier shapes (4x2 and 4x4 significands) in
       the native-input design. Area delta should be small. This is the format real inference
       deployments use (AMD and NVIDIA both ship weight-only MXFP4 with fp8 activations).
2. [ ] NVFP4 scale path: E4M3 block scale per 16 elements plus a per-tensor fp32 scale.
       Only the shared-exponent handling changes. Cheap and makes the block useful for
       Blackwell-format checkpoints.
3. [ ] Agilex 7 strategy without a tensor mode: pre-align to fixed point in soft logic, then use
       the Agilex 7 "9x9 signed sum-of-4" DSP mode for dot-4 per block with zero post-multiply
       alignment. Build the dot-32 unit, measure ALMs and fmax on AGF027 or AGM039 in Quartus.
       The model in `scripts/perf_model.py` predicts this beats packing on DSP efficiency by 4x
       to 5x per ALM, but the ALM estimate (about 260) is a guess until measured.
       See `03_agilex7_and_performance.md`.
4. [ ] Packed accumulation: pre-aligned signed values packed into 18x19 lanes with guard bits so
       that DSP outputs can be summed as packed words across the dot product, deferring lane
       extraction to the end. Removes most of the per-product soft logic that makes the paper's
       packed approach ALM-bound. Validate overflow margins for k = 32.
5. [ ] Accuracy: run a real MXFP4 model (gpt-oss-20b has native MXFP4 expert weights) through a
       bit-accurate Python model of each datapath (tensor mode pre-alignment, proposed block,
       sum-of-4 variant) and report perplexity deltas against the MX reference implementation.
       None of the datapaths should change results if they are exact, so this is a correctness
       check more than an accuracy study, but it is the check the paper skipped.
6. [ ] Frequency-aware peak numbers: re-derive Fig. 3 using fmax measured at 25%, 50%, 75%, 95%
       device fill instead of the single-instance fmax. This is the paper's acknowledged
       weakness and fixing it is mostly compute time.
7. [ ] Full-device inference engine on AGM039 (if we get access): HBM2e weight streaming, a
       matmul engine built from item 3, and an attention path. Target gpt-oss-20b decode.
       See `04_mxfp4_model_fit.md` for why this is the only Agilex part where LLM inference is
       more than a toy.

## Tooling notes

- Paper tcl scripts hardcode `A5EC065BB32AE4S` and Quartus `25.3` (26 occurrences). Add a
  `PART` and `QUARTUS_VER` override before running sweeps.
- Upstream README says `make -j4` needs more than 40 GB RAM. We have 32 GB. Use `-j2`.
- The `characterization/ai_tensor_block/ip/ai_tensor_slice/sim/mentor` directory ships the
  Agilex tensor DSP simulation library for Questa only. There is no open-source model of the
  tensor DSP, so any Verilator path can only cover the proposed block RTL, not the real IP.
