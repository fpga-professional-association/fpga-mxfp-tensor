# Results: the paper's designs on Agilex 3 silicon (Arrow AXC3000)

Date: 2026-10-31. Tools: Quartus Prime Pro 26.1.0 build 110, System Console 26.1. Board: Arrow
AXC3000, Agilex 3 A3CY100BM16AE7S (speed grade 7, 138 DSP blocks, 34,000 ALMs), USB Blaster III.
Everything below marked "measured" was read back from the board over JTAG; the raw records are in
`agilex3/board/results/`. "Fit" numbers come from Quartus reports in `agilex3/char/`.

## Headline

The paper's tensor-mode MXFP4 dot product runs on Agilex 3 silicon unmodified and is bit-exact
against an exact OCP-MX golden model: 64 of 64 random 32-element E2M1 vector pairs, two dot
products per vector, at a measured 240.1 MHz, with the 11-cycle latency the paper states. The
paper never ran on hardware; this is the first silicon confirmation of its Section III-D mapping.

| Measured on AXC3000 | Value |
|---|---|
| Format | MXFP4 E2M1, k = 32, two dot products per cycle (both DSP columns) |
| Vectors checked | 64, all bit-exact against `mx_golden.py` (fp32 output) |
| DUT clock | 240.1 MHz (on-chip free-running counter against host wall clock) |
| Latency valid_in to result | 11 cycles (per-cycle trace), matches the paper's RTL |
| DSP blocks for the dot unit | 4 (same as the paper) |
| Throughput of one unit | 2 x 32 x 2 x 240e6 = 30.7 GFLOPS |
| Device fill at the standalone unit fmax (343 MHz, 34 units) | 1.49 TFLOPS peak |
| E2M3 (MXFP6) | 64/64 bit-exact, 240.1 MHz, latency 11, same harness with M = 3 |
| W4A8-BFP (INT4-BFP weights x INT8-BFP activations, no decoder) | 64/64 bit-exact, 240 MHz, latency 11 |
| W8A8-BFP (INT8-BFP x INT8-BFP, Altera's native format) | 64/64 bit-exact, 240 MHz, latency 11 |
| Tensor fixed-point mode + fabric rescale (spec V1, `fxp_dot`) | 64/64 bit-exact for W8A8, W4A8 and MXFP4 lanes, latency 13; 3.5x the ALMs of the paper's unit, see `08` |

## What it took to make it run

Two things the paper does not say, found with a per-cycle trace of the DSP outputs:

1. The paper's `mxfp_dot.sv` pipelines the data and shared exponent by `PIPE` stages but passes
   `load_en` and `valid_in` straight through. Their testbench uses `PIPE = 0`, their synthesis
   runs use `PIPE = 1`. With `PIPE = 1` the DSP sees the controls one cycle before the data. The
   harness delays the controls by `PIPE` to compensate (MODE bit 1).
2. The tensor block's data-feed preload needs `load_en` high for two consecutive cycles. The
   vector presented in the second high cycle becomes the column-2 weights and the vector in the
   first low cycle becomes the column-1 weights. This is exactly what the paper's testbench does
   and the paper does not describe it. One high cycle does not work.

Protocol variants tried on silicon with the same bitstream (MODE register):

| MODE | load_en cycles | controls aligned to data | first-cycle data | columns swapped | Result |
|---|---|---|---|---|---|
| 3 | 2 | yes | column-2 weights | no | 64/64 bit-exact, latency 11 |
| 7 | 2 | yes | zeros (paper TB) | no | 64/64 bit-exact, latency 11 |
| 1 | 2 | no | column-2 weights | no | 0/64, expected values absent from trace |
| 2 | 1 | yes | n/a | no | 0/64, expected values absent from trace |
| 0 | 1 | no | n/a | no | 0/64 |
| 11 | 2 | yes | column-2 weights | yes | 0/64 |

A third issue was mine: the harness's activation write decode covered only half the slot range,
which made the first 32 streamed vectors zeros with a shared exponent of 0. The paper's RTL
computes `shared_exponent - M` on 8 bits, so exponent 0 wraps to 0xFF and the DSP produces NaN.
That is worth knowing for anyone feeding real data: a shared exponent below M is not handled.

## Characterization of all the paper's DSP-based designs on Agilex 3 (fit, Quartus 26.1)

Same RTL, same 1 ns target SDC, device changed to A3CY100BM16AE7S. Paper numbers are Agilex 5
A5EC065BB32AE4S with Quartus 25.3 (Table I).

| Format | Approach | Agilex 3 ALMs / DSPs / MHz | Paper Agilex 5 ALMs / DSPs / MHz | ALM delta |
|---|---|---|---|---|
| E2M1 | tensor mode | 199 / 4 / 343 | 198 / 4 / 458 | +0.5% |
| E2M3 | tensor mode | 416 / 4 / 343 | 420 / 4 / 458 | -1.0% |
| E2M1 | fp16 vector | 227 / 16 / 321 | 224 / 16 / 460 | +1.3% |
| E2M3 | fp16 vector | 373 / 16 / 321 | 368 / 16 / 446 | +1.4% |
| E3M2 | fp16 vector | 382 / 16 / 321 | 381 / 16 / 455 | +0.3% |
| E4M3 | fp16 vector | 680 / 16 / 321 | 660 / 16 / 455 | +3.0% |
| E5M2 | fp16 vector | 320 / 16 / 321 | 319 / 16 / 460 | +0.3% |
| E2M1 | packed DSP | 3,577 / 16 / 353 | 3,590 / 16 / 740 | -0.4% |
| E2M3 | packed DSP | 1,955 / 16 / 353 | 1,962 / 16 / 850 | -0.4% |
| E3M2 | packed DSP | 4,167 / 16 / 353 | 4,153 / 16 / 654 | +0.3% |
| E4M3 | packed DSP | 4,819 / 16 / 353 | 4,841 / 16 / 581 | -0.5% |
| E5M2 | packed DSP | 10,453 / 16 / 353 | 10,421 / 16 / 525 | +0.3% |

Observations:

- ALM counts transfer within 3%. Agilex 3 and Agilex 5 share the fabric and DSP architecture, so
  the paper's resource conclusions hold on the cheaper part.
- The fmax columns are speed-grade limits, not logic limits. Every tensor-mode design stops at
  342.94 MHz, every fp16 design at 321.23 MHz and every packed design at 352.98 MHz on this -7
  part. Those are the DSP block's restricted fmax values for each mode. The paper's "packed runs
  at 740 MHz" headroom does not exist on Agilex 3; the three approaches are within 10% of each
  other in clock, so the tensor mode's 5x to 10x density advantage per DSP becomes a direct
  throughput advantage.
- Peak device fill for MXFP4 on the A3CY100 at the restricted fmax: tensor 34 units x 128 FLOP x
  343 MHz = 1.49 TFLOPS; packed is ALM-bound at 9 units x 320 FLOP x 353 MHz = 1.0 TFLOPS; fp16
  vector 8 units x 64 FLOP x 321 MHz = 0.16 TFLOPS.

## Reproduction of the paper's Agilex 5 numbers under Quartus 26.1 (fit)

Same part as the paper, newer Quartus.

| Format | Approach | Quartus 26.1 | Paper (Quartus 25.3) |
|---|---|---|---|
| E2M1 | tensor mode | 207 / 4 / 457.67 MHz | 198 / 4 / 458 MHz |
| E2M3 | tensor mode | 417 / 4 / 457.67 MHz | 420 / 4 / 458 MHz |

Table I reproduces. The fmax is the Agilex 5 tensor block's restricted fmax, as the paper's
identical 458 MHz across formats already suggested.

## Harness notes

- `agilex3/board/rtl/mxfp_harness.sv`: Avalon-MM register file, 64 activation slots, two weight
  slots, result RAM, 192-cycle output trace, MODE knobs. The trace and slot RAMs were inferred as
  registers (19,197 ALMs, 56% of the device) because of the combinational read muxes. Harmless
  for the measurement, but register the reads before scaling the harness up.
- `agilex3/board/qsys/mx_shell.tcl`: Platform Designer shell. IOPLL from the 25 MHz board clock
  (100 MHz system, DUT clock as argument), JTAG-to-Avalon master, clock-crossing bridge, reset
  bridges. The PLL reference domain must be declared asynchronous to the output clocks in the
  SDC or STA reports a false setup violation from the PLL control register into the reset.
- `agilex3/board/host/mx_golden.py` generates vectors and exact fp32 expectations with Fraction
  arithmetic; `run_test.tcl` drives the board from System Console and writes a JSON record.
- Programming needs the JTAG clock at 6 MHz on this board (errata found in the earlier CoreDLA
  project).

## E2M3 on silicon

Same harness rebuilt with `M = 3` (`agilex3/board/results/e2m3_240/`), timing clean at 240 MHz
after declaring the PLL reference domain asynchronous (setup slack +0.006 ns on the DUT clock).
Measured: 64/64 E2M3 vector pairs bit-exact in MODE 3 and MODE 7, 240.1 MHz, latency 11 cycles,
4 DSP blocks. Records: `results/e2m3_mode3.json`, `results/e2m3_mode7.json`.

Both formats the paper maps to the tensor mode are therefore confirmed on silicon. E3M2 and
MXFP8 cannot use this path, exactly as the paper argues, because their pre-aligned values exceed
the 8-bit lane.

## Block floating point without a decoder (W4A8-BFP and INT8-BFP) on silicon

From the quantization note (`07_external_quantization_formats.md`): INT4-BFP and INT8-BFP operands
are plain sign-extended int8 lanes to the tensor block, so `bfp_dot.sv` is the paper's cascade
with the MXFP decoder removed, and one bitstream (`DUT_KIND = 1`, `results/bfp_240/`) covers both.
Timing clean at 240 MHz (setup slack +0.056 ns).

| Measured on AXC3000 | Weights | Activations | Vectors bit-exact | Clock | Latency |
|---|---|---|---|---|---|
| W4A8-BFP | signed 4-bit, shared E8M0 per 32 | signed 8-bit, shared E8M0 per 32 | 64 / 64 | 240.0 MHz | 11 |
| W8A8-BFP | signed 8-bit, shared E8M0 per 32 | signed 8-bit, shared E8M0 per 32 | 64 / 64 | 240.1 MHz | 11 |

Records: `results/w4a8_bfp_mode3.json`, `results/w8a8_bfp_mode3.json`. Golden: `mx_golden.py --bfp 4`
and `--bfp 8` (exact integer dot product scaled by the two shared exponents, one fp32 rounding).

Decoder cost, standalone fits of the dot unit (same SDC):

| Unit | Agilex 3 ALMs / DSPs / MHz | Agilex 5 ALMs / DSPs / MHz |
|---|---|---|
| paper `mxfp_dot` E2M1 (MXFP4 decoder in) | 199 / 4 / 343 | 207 / 4 / 458 |
| paper `mxfp_dot` E2M3 | 416 / 4 / 343 | 417 / 4 / 458 |
| `bfp_dot` raw int8 lanes (no decoder) | 244 / 4 / 343 | 243 / 4 / 458 |

The decoder-free unit is not smaller. The MXFP4 path pipelines 4-bit elements and widens to 8-bit
lanes at the DSP input; the raw path pipelines 8-bit lanes through every stage. The E2M1 decoder is
a few LUTs per element. So on the tensor block the choice between MXFP4, INT4-BFP and INT8-BFP is a
memory-format and accuracy choice (see the PTQ table in `07`), not an arithmetic or area one: all
three run at 4 DSPs per two dot-32 and the same clock.
