# External deep-research note: improving MXFP4 acceleration on Agilex 5, 7, 25 and 27

Provenance: supplied by the user on 2026-10-31, produced by a separate research tool from the
paper, Altera DSP documentation, the Agilex 2X announcement (28 October 2026), and the authors'
repository. Reproduced here with image links and citation chips stripped; wording otherwise
unchanged. Claims about Agilex 25 and 27 have not been independently verified in this repo yet;
see "Our notes" at the end.

---

## Executive findings

My most important finding is that the newly announced Agilex 27 already implements one of the
paper's most valuable proposed architectural improvements: longer tensor dot products.

The paper proposes increasing the number of MXFP4 operations per DSP block. Agilex 27's
second-generation tensor DSP has two 16-element dot-product columns, rather than the two
10-element columns in Agilex 5.

This is a significant development because the OCP MXFP4 format naturally operates on groups
of 32 elements.

| | Agilex 5 | Agilex 27 |
|---|---|---|
| INT8 tensor lanes per DSP | 10 x 2 | 16 x 2 |
| Published INT8 TOPS (largest device) | 22 (A5E065) | 1,211 (A27F180) |

The Agilex 27 figures are published hardware specifications, not measured MXFP4 inference results.

There are four important conclusions:

1. Agilex 5 has several unexplored optimization opportunities, particularly replacing repeated
   floating-point conversion with exact narrow-integer accumulation, improving weight reuse, and
   exploiting other existing DSP modes.
2. Agilex 7 should not simply reuse the Agilex 5 implementation. It lacks that generation's
   20-multiplier tensor DSP. Its four-way 9x9 multiply-add architecture suggests a different
   approach.
3. Agilex 25 is a future midrange platform, but its detailed DSP resource counts and
   configurations are not yet publicly established. Any concrete MXFP4 performance estimate
   would be speculative.
4. Agilex 27 is especially promising because the new DSP, M80K memory, HyperFlow network, and
   faster memory interfaces address multiple bottlenecks from the paper simultaneously.

The distinction is that these are architectural opportunities, not yet validated speedups.
Only the Agilex 5 results in the uploaded paper are directly benchmarked.

## 1. What the paper leaves available for optimization

The paper studies four methods on the Agilex 5 A5EC065BB32AE4S, using Quartus Prime Pro 25.3.
Its results on existing silicon are:

| Implementation | MXFP4 E2M1 | MXFP6 E2M3 | MXFP8 E4M3 |
|---|---|---|---|
| Optimized soft logic | Supported | Supported | Supported |
| Packed fixed-point DSP | Supported | Supported | Supported |
| FP16 DSP arithmetic | Supported | Supported | Supported |
| AI tensor DSP | Best | Best | Not supported |

For MXFP4, the published tensor-mode implementation uses four DSP blocks to produce two
32-element dot products, at 458 MHz, requiring 198 ALMs in its surrounding implementation.

This means the researchers have already demonstrated efficient MXFP4 use of existing Agilex 5
tensor hardware. However, their primary contribution is redesigning the DSP block itself,
rather than fully optimizing the surrounding memory system, scheduling, numeric conversion, or
complete inference workload.

### The most relevant hardware comparison

| Feature | Agilex 5 | Agilex 7 | Agilex 25 | Agilex 27 |
|---|---|---|---|---|
| AI tensor dot-product mode | Two dot-10 | No comparable hard tensor mode | Details pending | Two dot-16 |
| 9x9 multipliers per DSP | 6 | 4 | Not disclosed | 6 |
| FP16 multipliers per DSP | 2 | 2 | Not disclosed | 4 |
| FP32 multipliers per DSP | 1 | 1 | Not disclosed | 2 |
| MXFP4 approach | Tensor INT8 | Fixed DSP or soft logic | To be determined | Tensor INT8 candidate |
| HBM / in-package memory | No HBM in E/D devices | M-Series HBM2E | Not disclosed | M-Series planned |

The Agilex 27 information is from Altera's October 2026 device overview and architecture white
paper, which document its second-generation tensor DSP and multipliers per block.

## 2. A particularly valuable optimization: exact MXFP4 integer arithmetic

MXFP4 E2M1 has only 16 possible bit encodings. Its representable finite positive magnitudes are
0, 0.5, 1, 1.5, 2, 3, 4, 6. Multiplying these values by two converts every one of them into an
exact signed integer, q_i = 2 P_i, in the range -12..12, which fits in five signed bits.

Consequently, a complete 32-element MXFP4 dot product can be computed as

    a . b = 2^(Xa + Xb - 256) * sum_{i=0..31} q_a,i * q_b,i

where Xa and Xb are the encoded shared E8M0 scale exponents. This is the mathematical basis
of the paper's five-bit conversion. The useful extension is to optimize the entire 32-element
accumulation around that representation.

### A 14-bit integer accumulator is sufficient

Each integer product has magnitude at most 12 x 12 = 144. For 32 elements, 32 x 144 = 4608.
A signed 14-bit accumulator can therefore hold any exact sum for one MXFP4 block without
overflowing.

Candidate exact-integer MXFP4 datapath: 32 MXFP4 values per operand, stored as 4-bit E2M1
plus 8-bit shared exponent; small E2M1-to-signed-5-bit decoders (exact, no rounding); signed
integer dot-product units (tensor DSP, fixed-point DSP or ALMs); exact 14-bit reduction for
32 elements; apply shared scale and convert to FP32; then accumulate across separately scaled
blocks.

Proposed experiment: compare the paper's FP32 tensor-mode cascade with a design that keeps the
four partial sums in exact integer arithmetic, performs a single reduction, and applies the
shared exponent once per block. Potential advantages include smaller external reduction logic,
fewer floating-point operations and deterministic accumulation inside each MXFP4 block.

There is an important tradeoff: the existing Agilex 5 tensor floating-point mode already
provides hardened FP32 conversion and accumulation. Moving some of that work into the ALMs
might reduce efficiency. This is a candidate to benchmark, not an assumed improvement. Correct
E8M0 special-value handling, final FP32 rounding, and accumulation across multiple 32-element
groups with different scales must be preserved.

## 3. Improvements to pursue on existing Agilex 5

| Opportunity | Hardware change | Expected benefit | Priority |
|---|---|---|---|
| Exact INT32 tensor accumulation | DSP operating mode and scale logic | Lower arithmetic overhead | Very high |
| Better ping-pong weight scheduling | Controller and buffering | Higher sustained DSP utilization | Very high |
| Larger GEMM tiles with shared activations | Processing-element architecture | More output per memory read | Very high |
| Six-way 9x9 DSP accumulation | Alternative mapping | Efficient smaller/irregular kernels | Medium |
| Compressed weights and decoder placement | Memory and register architecture | Reduced memory traffic and routing | High |

### A. Compare tensor fixed-point mode directly against the paper's floating-point tensor mode

Agilex 5 has two distinct tensor modes. Tensor floating-point computes signed 8x8 dot products,
applies shared exponents, and supports FP32 accumulation. Tensor fixed-point computes signed
8x8 dot products and produces an INT32 accumulated result. Because the decoded MXFP4 operands
are exact signed five-bit integers, the fixed-point mode is a natural fit.

| Variant | Implementation |
|---|---|
| A | Paper's existing tensor floating-point implementation |
| B | Tensor fixed-point with INT32 cascade and one scale conversion |
| C | Tensor fixed-point with partial results combined in fabric, followed by conversion |

Variant B's DSP-internal 32-bit accumulator is already far wider than the required 14 bits for
one group. The challenge is converting the final integer result into FP32 and applying the
power-of-two scale without a large, slow, or badly rounded soft-logic path. Hypothesis:
Variant B may improve resource efficiency, particularly if multiple consecutive MXFP4 groups
can be processed while reducing conversion overhead; relative performance is unknown until
place-and-route.

### B. Optimize the weight preload mechanism

The Agilex 5 tensor block contains two weight-buffer banks per output column. Data input feed
reloads rapidly but stalls computation; side input feed reloads the inactive bank over 12
cycles while the active bank continues computing. For transformer inference, a weight-stationary
architecture with ping-pong scheduling needs each weight tile to provide at least 12 cycles of
useful work to hide the reload. For workloads with little weight reuse the data feed might win
despite the stall. Worth measuring: a tensor engine with excellent arithmetic density can still
spend much of its time loading coefficients.

### C. Exploit the six 9x9 multipliers

The Agilex 5 fixed-point DSP has a sum-of-six 9x9 mode. With pre-aligned five-bit values, six
DSP blocks per dot-32 (with some unused positions). Unlikely to beat the tensor mode on a large
GEMM, but possibly better for irregular workloads where preloading, two-column broadcasting or
cascades are inconvenient, and a useful comparison for custom ALM arithmetic.

### D. Make the shared-operand broadcast a first-class architectural constraint

The two dot-product columns share the input vector but use independently loaded weight
buffers. The efficient tile produces at least two output channels from the same activation
data. Test C = A x B with K grouped into 32-element blocks, N tiled to the two columns, and M
increased to reuse each weight tile across more activation rows. The paper does not sweep
batch size, memory bandwidth, and preload efficiency.

### E. Agilex 5 D-Series may matter more than the paper's E-Series device

The D-Series family plan includes an A5D160 with up to 9,936 DSP blocks and a vendor-listed
peak of 152.62 INT8 TOPS, plus faster external memory. Benchmark the same RTL on E-Series,
D-Series, and the largest suitable Agilex 7, keeping workload and arithmetic identical.

## 4. Applying the paper to Agilex 7

The Agilex 7 DSP supports four independent 9x9 multipliers, two 18x19 or one 27x27, plus
FP16, BF16, FP19 and FP32, but no dual-column INT8 tensor block. A basic design uses four 9x9
multipliers per DSP: 8 DSP blocks per dot-32, then an integer reduction and one shared-scale
conversion.

| Approach | Likely advantage | Tradeoff |
|---|---|---|
| 9x9 DSP arrays | High, predictable clock | Lower density than Agilex 5 tensor |
| ALM-based 4-bit lookup-product units | Only 16x16 operand pairs; tiny exact Boolean network | Routing and reduction-tree cost |
| Packed wide DSP multiplication | Share one operand across several products | Product extraction and sign handling |

For Agilex 7 the ALM-versus-DSP crossover point is especially interesting. The product of two
E2M1 encodings can be an exact minimized Boolean network feeding a deeply pipelined compressor
tree.

Agilex 7 M-Series: 32 GB HBM2E, 820 GB/s. Could hold AMD's 5.83 GB Llama 3.1 8B MXFP4
checkpoint; ideal batch-one weight-streaming ceiling 820/5.83 = about 141 tokens/s. A bandwidth
ceiling only. Recommendation: HBM-fed pipelined MXFP4 GEMM, comparing four-way 9x9 against an
optimized all-ALM implementation.

## 5. Agilex 25: announced 28 October 2026, not enough DSP information yet

Midrange target (video, drones, low-latency sensing). No verified public DSP resource table,
precision-mode description, or MXFP4 performance specification. Do not assign an invented TOPS
estimate or assume it inherits Agilex 27's dual-dot16 architecture. Treat as a future deployment
target.

## 6. Agilex 27: the strongest architectural match

First Agilex 2X family. Software support to early-access customers mid-November 2026;
engineering samples second half of 2027. The new DSP exposes two 16-element INT8 dot-product
engines.

| Architecture | DSPs for two dot-32 MXFP4 results |
|---|---|
| Agilex 5, paper's existing tensor mapping | 4 |
| Agilex 5, paper's proposed redesigned DSP | 2 |
| Agilex 27, if INT8 and accumulation modes map appropriately | 2 |

Potentially 2x DSP efficiency for the dot-32 primitive, but not proven native OCP MXFP4
support. Validation needed: input encoding, INT8-to-FP32 conversion path, shared scales,
cascades, and compiler access to the primitive modes.

Preliminary product table (hardware specifications, not MXFP4 results):

| Device | Tensor DSPs | INT8 TOPS | On-chip memory | Peak external bandwidth |
|---|---|---|---|---|
| A27F008 | 1,096 | 63 | 103 Mb | 115 GB/s |
| A27F027 | 3,284 | 189 | 299 Mb | 269 GB/s |
| A27F054 | 6,648 | 382 | 606 Mb | 547 GB/s |
| A27F140 | 16,632 | 957 | 1,516 Mb | 1,230 GB/s |
| A27F180 | 21,048 | 1,211 | 1,918 Mb | 1,230 GB/s |

A27F180 has about 240 MB of raw on-chip memory, a theoretical 451 million MXFP4 weights if
nearly all block memory held weights. M80K memories and the hardened HyperFlow data network
suggest a memory-stationary partition: M80K/M20K as tiled buffers, HyperFlow and DMA for
transport, DSPs for compute. Evaluate memory-stationary versus weight-stationary rather than
assuming the paper's systolic structure is optimal.

## 7. The real bottleneck: compute versus memory reuse

MXFP4 weight = 0.53125 bytes. Without reuse, arithmetic intensity is about 3.76 ops/byte. For
A27F180, 1,211 TOPS / 1.23 TB/s = 985 ops/byte, so reaching peak needs each weight reused
about 262 times after fetch. Large GEMM batches exploit the hardware; batch-one decode does not.
Illustrative ceilings (vendor peak bandwidth / 5.83 GB checkpoint): A27F008 20, A27F027 46,
A27F054 94, Agilex 7 M-Series 141, A27F180 211 tok/s. Ideal, not achieved.

## 8. Research roadmap and expected value

| Benchmark | Platform | Question | Success criterion |
|---|---|---|---|
| Exact INT32 MXFP4 dot32 | Agilex 5 | Can fixed tensor mode beat floating tensor mode? | ALMs/DSP, Fmax, correct rounding |
| Weight-preload stress test | Agilex 5 | How much compute is lost to reloads? | Sustained vs peak dot products/s |
| Four-way 9x9 vs LUT arithmetic | Agilex 7 | Optimal five-bit multiplication mapping? | Ops per DSP/ALM and watt |
| HBM-fed MXFP4 GEMM | Agilex 7 M | Does bandwidth change the winner? | Sustained GEMM throughput |
| Dual-dot16 MXFP4 | Agilex 27 | Does native tensor remove the paper's inefficiency? | DSP count, precision, post-fit speed |
| HyperFlow tiled GEMM | Agilex 27 | Can the memory network sustain DSP utilization? | End-to-end bandwidth and throughput |

Golden reference: all 16 MXFP4 encodings, all permitted scale cases, rounding, cancellation;
compare exact block sums and FP32 results, since FP32 summation order changes rounding.

Priority ranking: (1) MXFP4 INT32 tensor mode on Agilex 5; (2) weight reuse and preload
scheduling; (3) Agilex 7 HBM-backed GEMM; (4) Agilex 27 dual-dot16 mapping; (5) custom
LUT-based five-bit arithmetic.

Paper limitations the benchmarks should address: device-level peak extrapolations assume no
frequency degradation; the enhanced DSP was not fabricated (ASAP7 estimate, proxy placement);
the chosen design drops E5M2 and changes legacy dot-10 behavior; no model accuracy or
end-to-end inference on published MXFP4 checkpoints.

Overall recommendation: near term, Agilex 5 for arithmetic optimization and Agilex 7 M-Series
as the memory-bandwidth reference; forward-looking, Agilex 27. Most consequential next
experiment: take the authors' Agilex 5 E2M1 dot32, add an exact INT32 tensor-mode variant, and
compare under identical standalone and memory-fed GEMM workloads.

Primary sources cited by the note: the authors' repository (github.com/boutros-lab/fpga-mxfp),
Agilex 5 DSP user guide 813968 (tensor fixed-point mode), Agilex 7 device overview 683458,
and the Altera Agilex 2X announcement (altera.com/newsroom/agilex-2x).

---

## Our notes on this analysis

- It agrees with `03_agilex7_and_performance.md` on the Agilex 7 approach (pre-aligned 5-bit
  values into the 9x9 sum-of-4 mode) and on the M-series bandwidth ceiling. Its 141 tok/s for
  Llama 3.1 8B uses peak bandwidth and AMD's 5.83 GB checkpoint; ours uses 70% of peak and
  4.3 GB of pure MXFP4 weights and lands at about 120. Same ballpark.
- The "exact INT32 tensor fixed-point mode" experiment (Variant B) is cheap and we can run it on
  our Agilex 3 board, which has the same tensor block with both fixed-point and floating-point
  tensor modes. Added to the plan as the first Agilex 3 experiment after the baseline port.
- The Agilex 25/27 claims (dual dot-16, M80K, HyperFlow, product table) need checking against
  the Altera documents once we have them. Nothing in this repo depends on them yet.
- The Agilex 5 D-series A5D160 point is a good one: the same RTL on 9,936 DSP blocks would put
  the paper's existing tensor-mode E2M1 design near 145 TFLOPS peak at 458 MHz, with no DSP
  redesign at all.
