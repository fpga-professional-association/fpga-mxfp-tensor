# Can we fit a model using MXFP4 for inference?

Yes on Agilex 7 M-series, for models up to roughly 25B parameters (or MoE models up to about
60 GB of weights with DDR5 behind the HBM). No on Agilex 5 or Agilex 3 in any meaningful way.
And the format question is more subtle than "MXFP4 is what the MI355X uses".

## The format question first

The paper's hardware computes MXFP x MXFP dot products with the same format on both sides,
per the OCP MX spec. That is what the MI355X and Blackwell matrix cores support too. But the
checkpoints people actually ship are mostly weight-only:

- gpt-oss-20b and gpt-oss-120b: expert weights in MXFP4 (4.25 bits per parameter), everything
  else bf16, activations bf16 or fp8 depending on the kernel. AMD's recipe for MI355X is
  "w-mxfp4-a-fp8", which you already looked at for the airgap bundle.
- NVFP4 (Blackwell): E2M1 elements, E4M3 scale per 16, fp32 per-tensor scale. Not MX
  compliant, so the paper's block cannot consume it without the scale-path change in Phase 5.

So an FPGA engine that only does MXFP4 x MXFP4 would have to quantize activations to MXFP4 on
the fly, which costs accuracy that the GPU recipes avoid. The mixed-lane variant (E4M3
activations x E2M1 weights) in the plan is the one that matches real checkpoints. It is also
the more hardware-friendly one: the activation side stays at 8 bits and only the weights get
the 2x2 significand multipliers.

## Memory is the constraint, not compute

Batch-1 decode reads every active weight once per token. The FPGA has far more compute than
it can feed.

| Device memory | Capacity | Peak BW | Assumed usable |
|---|---|---|---|
| Agilex 7 AGM039 HBM2e | 32 GB | 820 GB/s | 70% |
| plus 2 channels DDR5-5600 | +64 GB | ~90 GB/s | 75% |
| Agilex 5 E065 dev kit LPDDR5 | board dependent, ~8 GB | ~50 GB/s | 70% |
| Agilex 3 AXC3000 HyperRAM | 16 MB | 0.34 GB/s | 77% (we measured this) |
| MI355X HBM3E (reference) | 288 GB | 8 TB/s | 80% |

Model sizes at 4.25 bits per parameter, with published checkpoint sizes used where known:

| Model | Weights | Active per token | Fits 1x AGM039? | Est. batch-1 decode on AGM039 |
|---|---|---|---|---|
| gpt-oss-20b | 13.7 GB | 2.2 GB | yes | ~260 tok/s |
| Qwen3-30B-A3B | 16.2 GB | 2.0 GB | yes | ~285 tok/s |
| Llama-3.1-8B | 4.3 GB | 4.9 GB | yes | ~120 tok/s |
| Qwen3-32B dense | 17.4 GB | 20 GB | yes | ~30 tok/s |
| Llama-3.3-70B | 37.5 GB | 43 GB | no (2 devices: ~25 tok/s) | |
| gpt-oss-120b | 65.3 GB | 3.1 GB | no (HBM + DDR5: ~20 to 50 tok/s) | |

These come from `scripts/perf_model.py`. The decode rates divide usable bandwidth by active
bytes per token, with 15% added for the bf16 attention and embedding weights and KV traffic.
They are upper bounds that assume a weight-streaming engine that keeps HBM busy, which is the
hard engineering problem, not the arithmetic.

Two observations from the table:

- MoE models are the sweet spot. gpt-oss-20b and Qwen3-30B-A3B have 3 to 4B active parameters,
  so a single AGM039 could in principle decode them at a couple of hundred tokens per second.
  That is competitive with a mid-range GPU for single-stream latency, and it comes from 820 GB/s
  of HBM2e that the FPGA otherwise has no AI use for.
- gpt-oss-120b does not fit in 32 GB and does not fit in two devices either (65.3 GB vs 64 GB).
  The workable layout is attention, routers, and embeddings in HBM with the 128 experts in
  DDR5. The 22 tok/s in the model output assumes everything streams from DDR5, which is too
  pessimistic; with only the four active experts (about 1.9 GB) coming from DDR5 at ~68 GB/s
  usable and the rest from HBM, around 30 to 35 tok/s is a better estimate. Either way it is
  a demo, not a serving node.

## Compute check

Decode: gpt-oss-20b at 260 tok/s is 2 x 3.6e9 x 260 = 1.9 TFLOPS. Any of the Agilex 7
approaches covers that 10x over, so the matmul engine can be small and most of the fabric goes
to attention, the MoE router, and the memory system.

Prefill: compute bound. A 1,000-token prompt on gpt-oss-20b is 7.2 TFLOP. At 30 TFLOPS
sustained that is 0.25 s; at the 6 TFLOPS an fp16-vector-only engine might sustain, 1.2 s.
This is where the dot-product density from the paper (or from our sum-of-4 idea) matters.
Decode does not care.

## On-chip memory for the paper's style of engine

The systolic arrays in the paper preload one operand into the DSP's ping-pong register banks
and stream the other. For an LLM the preloaded operand is weights and the streamed one is
activations. AGM039 has about 1,305,600 ALMs worth of MLAB plus the M20K array, on the order
of 20 to 30 MB total on-chip SRAM. That is enough for a KV cache of a few thousand tokens for
an 8B model and for double-buffering weight tiles from HBM, but not for keeping any layer
resident. The engine is a streaming engine by necessity.

## Agilex 5 and Agilex 3

Agilex 5 E065 has no HBM. Dev kits carry LPDDR5 in the tens of GB/s. Llama-3.1-8B in MXFP4
fits in 8 GB but decodes at single-digit tokens per second. Models under 1B (speech, small
vision-language, a draft model for speculative decoding on the GPU box) are the realistic
targets. Agilex 3 on the AXC3000 has 16 MB of HyperRAM at 0.34 GB/s. Nothing LLM-shaped fits;
it is for verifying the datapath, which is still worth doing.

## Where this connects to your MI355X work

The 8x MI355X node runs gpt-oss-120b at 5 to 10 PFLOPS per GPU with weights in MXFP4 and
activations in fp8. An AGM039 cannot serve alongside it on throughput. Three places an FPGA
would earn its slot:

1. A speculative-decoding draft model (gpt-oss-20b or smaller) with deterministic sub-millisecond
   per-token latency, feeding the GPUs.
2. Pre- and post-processing that touches the same MXFP4 tensors (quantization, scale
   calibration, format conversion to NVFP4 or back) in the network path, where the FPGA already
   sits.
3. Air-gapped or power-limited deployments where a 75 to 150 W card running a 20B MoE at
   100+ tok/s is the whole product.

## Bottom line

MXFP4 is a good fit for the FPGA because, after pre-alignment, it is int8 arithmetic that the
existing tensor blocks already do, and because 4.25 bits per weight is what makes a 20B model
fit in 32 GB of HBM2e. The paper's block would make the compute side 4x denser, but the
compute side was never the limit for decode. Buy the M-series for the memory, build the
mixed-format dot product for the checkpoints people actually ship, and expect a couple of
hundred tokens per second on a 20B MoE as the realistic ceiling.
