# Agilex 2X (Agilex 27 / Agilex 25): AI inference implications and low-precision format support

Scope note: material published up to 31 October 2026. The Agilex 2X portfolio was announced on 28 October 2026. Three categories are kept apart throughout: (a) what Altera has published, (b) what press and analysts wrote (mostly paraphrase of the press release and a short slide deck), (c) my own arithmetic, which is always labelled as such.

Headline finding up front: as of 31 October 2026 there is no public Altera document that states the Agilex 27 tensor DSP's element formats, dot-product length, accumulator width, or any TOPS figure. Every published reference to the block is a single generic phrase ("enhanced AI tensor DSP blocks to accelerate compute in signal processing applications" or close variants). Nothing published mentions FP8, FP4, MXFP, microscaling, or a shared-exponent mode for Agilex 2X. Engineering samples are not due until the second half of 2027, and the device overview / DSP user guide that would normally carry these numbers has not appeared on docs.altera.com in a form I could retrieve.

Access caveat: altera.com (newsroom, product page), docs.altera.com direct links, businesswire.com, morningstar.com, intel.com docs redirects and allaboutcircuits.com all refused or 404'd to the fetcher. Findings about the Altera text therefore rest on trade press that quotes the press release, plus search-engine snippets of the Altera pages. I flag that where it matters.

---

## Key question 1: Does any Altera document state Agilex 27 tensor DSP support for FP8 (E4M3/E5M2), FP4, MXFP, or shared-exponent block floating point?

### Takeaway
No. Nothing published by Altera or quoted by the press through 31 October 2026 names any numeric format for the Agilex 27 tensor DSP. The only descriptive language is "enhanced AI tensor DSP blocks" for "signal processing applications." There is no FP8, FP4, MXFP, microscaling, or shared-exponent claim to quote, positive or negative.

### Cited Findings
- The Agilex 2X portfolio was announced 28 October 2026 with four families: Agilex 27 (bandwidth-intensive infrastructure), Agilex 25 (embedded processing and high-speed sensing), Agilex 23 (industrial automation and robotics), Agilex 22 (I/O-centric control) — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); [Embedded Computing Design](https://embeddedcomputing.com/technology/ai-machine-learning/altera-combines-scalable-fpga-hardware-with-ai-assisted-development)
- The only tensor-DSP language in the announcement coverage: the devices have "enhanced AI tensor DSP blocks to accelerate compute in signal processing applications" — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant). ENGtechnica's version: "It includes AI tensor DSP blocks for signal processing" — [ENGtechnica](https://engtechnica.com/altera-introduces-agilex-2x-fpgas-for-ai-and-edge-systems/). SiliconANGLE: "AI-oriented tensor DSP blocks" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/). Thai coverage (translated): "AI tensor DSP block that helps accelerate signal processing work" — [TechTalkThai](https://www.techtalkthai.com/altera-launches-agilex-2x-fpga-soc-portfolio-agilex-27/)
- The press release text, as carried by a wire re-publisher: "Agilex 27 FPGAs build on the architecture leadership of the prior generation Agilex 7 FPGAs with the 3rd generation HyperFlex fabric" — [Rutland Herald (Business Wire copy)](https://www.rutlandherald.com/news/business/altera-announces-agilex-2x-a-complete-fpga-soc-portfolio-built-for-the-future-of-intelligent/article_18933a1b-73fd-5fa0-9ace-6f88f32e553c.html)
- ServeTheHome, which reproduced Altera's four launch slides (target markets; architecture with HyperFlex and connectivity labels; portfolio tiers; QuartusIQ), reports no DSP, tensor, TOPS or precision detail from any slide; the only compute-related claim is "a 1.8X generation-over-generation performance-per-watt improvement over Agilex 7 for HyperFlex in Agilex 27" — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- Converge Digest states outright that "Altera has not announced specific Agilex 27 customer deployments or independently verified application benchmarks for these workloads" — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- Search results point to an Altera product page for the portfolio but it returned 403 to the fetcher — [Altera Agilex 2X portfolio page](https://www.altera.com/products/fpga/agilex-2x-portfolio); the newsroom item likewise — [Altera newsroom](https://www.altera.com/newsroom/agilex-2x)

### Inferences
- The phrase "to accelerate compute in signal processing applications" is a notably narrow framing for a tensor block. Altera's Agilex 5 tensor-block marketing led with AI inference TOPS; here the AI pitch for Agilex 27 is carried by HyperFlow (data movement), 1.6TbE, PCIe 7.0 and the "Digital AI infrastructure" use case rather than by MAC density. That reads as an infrastructure/networking positioning, with the tensor DSP described as a secondary feature. This is my reading of the emphasis, not something Altera said.
- Because the Agilex 5 block already has a block-floating-point mode (8-bit shared exponent per 10-element vector), it would be surprising if the "enhanced" successor dropped it; but there is no published statement either way, and nothing to indicate OCP-style k=32 blocks, E8M0 scales, or FP8/FP4 elements. Treat any such claim as speculation until Altera publishes the DSP user guide.

### Gaps
- No Agilex 27 device overview, DSP user guide, or architecture white paper could be located on docs.altera.com (the four docs.altera.com short links returned by search all 404'd). The Agilex 27 / Agilex 2X tensor DSP format list is simply not public.
- Quartus Prime Pro 26.3 reportedly includes Agilex 27 device support; a Quartus-level inspection of the DSP IP parameters (e.g. in the IP Catalog or the device handbook shipped with 26.3) might reveal the tensor modes, but that is not published material and was outside what I could reach here. Early-access customers are reported to receive software support "in November" (see KQ3), so public docs may appear after the 31 October cutoff.

---

## Key question 2: Dot-product length, columns per DSP, INT8 TOPS per device, and whether the TOPS math reproduces published numbers

### Takeaway
For Agilex 27 none of these numbers exist publicly, so there is nothing to reproduce. The TOPS methodology is well established on the predecessor blocks (DSPs x MACs/clk x 2 x f), and I show the implied clock on Agilex 5 and Stratix 10 NX to give the report writer a template for when Agilex 27 numbers arrive.

### Cited Findings
Agilex 27 specifics:
- No DSP count, logic-element count, dot-product width, or TOPS figure for any Agilex 27 or Agilex 25 device appears in the launch coverage; multiple outlets explicitly note the absence — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/); [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Process node is not disclosed in any coverage; an earlier eeNews Europe CEO interview discussed Altera's move to Intel 18A for future products but does not tie it to Agilex 27 — [eeNews Europe](https://www.eenewseurope.com/en/ceo-interview-sandra-rivera-of-altera-on-the-move-to-intel-18a/)

Baseline for the methodology (Agilex 5):
- Agilex 5 DSP in fixed-point tensor mode "implements int8 dot products and accumulates results in int32," as two 10-lane dot products sharing a broadcast input vector; block floating-point tensor mode "uses an 8-bit shared exponent per 10-element vector operand and accumulates results in fp32" — [arXiv 2607.13898, Jack of All Scales](https://arxiv.org/html/2607.13898)
- Altera's own phrasing: in tensor mode a single DSP performs a convolution using "two independent sets of 10 coefficients on streamed data composed of ten 8-bit fixed- or floating-point values, enabling up to 20 parallel multiplications per clock cycle per DSP"; the architecture brief claims "up to 25X peak theoretical TOPS improvement in a single DSP block's INT8" — [Altera Agilex 5 enhanced DSP architecture brief (PDF)](https://cdrdv2-public.intel.com/776602/agilex-5-fpgas-enhanced-dsp-with-ai-tensor-block-architecture-brief.pdf) (figures from search-engine snippet; the PDF timed out on fetch)
- A5E065A: 846 variable-precision DSP blocks and 25.99 peak INT8 TOPS, per Altera's E-Series product table as surfaced in search — [Agilex 5 device overview (Intel docs mirror)](https://www.intel.com/content/www/us/en/docs/programmable/762191/current/fpgas-and-socs-summary-of-features.html) (page redirected to a 404 on fetch; figure is from the search snippet). Note: the assignment brief states 22 INT8 TOPS for A5E065; both numbers are consistent with 846 DSPs at different assumed clocks (see Inferences).

Baseline (Stratix 10 NX):
- "The AI Tensor Block's architecture contains three dot-product units, each of which has ten multipliers and ten accumulators for a total of 30 multipliers and 30 accumulators within each block"; base precisions INT8 and INT4 "along with shared exponent to support Block FP16 and block FP12 numerics"; device rated at 143 INT8 TOPS / 286 INT4 TOPS — [docs.altera.com Stratix 10 NX material via search](https://docs.altera.com/v/u/vuRNmNci66pfc_1eQlNd~A); [Altera Stratix 10 NX page](https://www.altera.com/products/fpga/stratix/10/nx)
- 3,960 tensor blocks per device; two HBM2 stacks at 256 GB/s each (512 GB/s per package); Intel projected ResNet-50 at 500 MHz with 75% tensor utilisation — [The Next Platform](https://www.nextplatform.com/2020/11/11/hbm2-tensor-units-key-to-intels-new-ai-centric-fpga/)

Baseline (Agilex 7):
- AGI 027 (I-Series): 8,528 variable precision DSP blocks, 17,056 18x19 multipliers — [Agilex 7 I-Series Development Kit User Guide](https://www.intel.com/content/www/us/en/docs/programmable/683288/current/i-series-fpga.html)
- Agilex 7 DSP operational modes listed in the user guide: 18x18/18x19 independent multiplier; 27x27; "8 x 8 (Unsigned) or 9 x 9 (Signed) Sum of 4 Mode"; 18x19 summed with 36-bit input; systolic FIR; FP32 and FP16 floating point. No tensor, shared-exponent, bfloat16 or INT8 dot-product mode is listed — [Agilex 7 Variable Precision DSP Blocks User Guide](https://docs.altera.com/r/docs/683037/current)
- EEJournal's early Agilex article gives AGX027 as having "34,112 INT9 operators" (i.e. 4 per DSP) — [EEJournal](https://www.eejournal.com/article/inside-intel-agilex-fpgas/)

### Inferences (my arithmetic, clearly not Altera's)
- Methodology: peak TOPS = DSP count x MACs per DSP per clock x 2 ops per MAC x clock.
- Agilex 5 A5E065A: 846 x 20 x 2 = 33,840 INT8 ops/clk. The 25.99 TOPS figure implies 768 MHz; the 22 TOPS figure in the brief implies 650 MHz. Both are plausible Agilex 5 DSP Fmax points for different speed grades, so the two published-looking figures most likely differ by speed grade rather than by methodology.
- Stratix 10 NX: 3,960 x 30 x 2 = 237,600 INT8 ops/clk; 143 TOPS implies about 602 MHz. INT4 doubles to 286 TOPS at the same clock, matching the published pair.
- Agilex 7 AGI027: 8,528 x 4 (INT9 sum-of-4) x 2 = 68,224 ops/clk. At a hypothetical 600 MHz that is about 41 TOPS INT9-equivalent for the largest Agilex 7, which is why Altera's Agilex 5 brief could claim ~25X per-DSP INT8 gain (20 MACs vs 4, plus clock) even though per-device density only closed partially. Useful context for judging whatever Agilex 27 figure appears: a 1.8X perf/W claim against Agilex 7 says nothing about tensor MAC density, since Agilex 7 has no tensor mode.
- If (speculatively) Agilex 27 kept the Agilex 5 block (20 INT8 MAC/clk) and had an Agilex-7-class DSP count (~8,500), peak would be ~8,500 x 40 x f; at 700 MHz that is ~240 INT8 TOPS. I include this only to bound expectations; Altera has published no such number and the actual block may differ.

### Gaps
- No Agilex 27/25 DSP count, tensor-mode width, accumulator width, or TOPS figure is public. Nothing to reproduce.
- The A5E065 22 vs 25.99 TOPS discrepancy could not be resolved against the primary table because docs.altera.com and intel.com both blocked the fetch; the 25.99 figure is from a search snippet attributed to the Altera E-Series product table.

---

## Key question 3: What inference software and model support has Altera announced for Agilex 2X?

### Takeaway
Only Quartus Prime Pro 26.3 device support and the QuartusIQ design assistant were announced for Agilex 27. FPGA AI Suite 26.3 shipped on GitHub the next day (29 October 2026) with no visible Agilex 2X mention, and I found no LLM, transformer, OpenVINO or model-zoo claim tied to Agilex 2X anywhere.

### Cited Findings
- "Quartus Prime software support for Agilex 27 FPGAs is available now in Quartus Prime version 26.3"; QuartusIQ "is also available for download now as part of Quartus Prime Pro Edition 26.3"; engineering samples "expected in the second half of 2027" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); [Rutland Herald press-release copy](https://www.rutlandherald.com/news/business/altera-announces-agilex-2x-a-complete-fpga-soc-portfolio-built-for-the-future-of-intelligent/article_18933a1b-73fd-5fa0-9ace-6f88f32e553c.html)
- "Agilex 27 software support is expected to reach early-access customers in November" — [All About Circuits](https://www.allaboutcircuits.com/news/altera-unveils-a-new-agilex-fpga-portfolio-and-agentic-ai-developer-tool) (search snippet; page returned 403)
- QuartusIQ: "combines smarter design guidance, specialized chat interaction, agentic design flows, and timing-closure assistance," trained on "more than 20,000 documents," integrates with Visual Studio via an MCP connector, supports "frontier models or open-weight models, including Nvidia's Nemotron model"; Altera's internal benchmark claims "up to 10× faster design creation" and 1.5X (some cases 2X) faster design cycle — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant); [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- FPGA AI Suite 26.3 release published 29 October 2026 on GitHub: "Example designs and supporting content for FPGA AI Suite 26.3. Please refer to the FPGA AI Suite Handbook for more information." No device list visible in the release body — [altera-fpga/agilex-ed-ai-suite rel-26.3](https://github.com/altera-fpga/agilex-ed-ai-suite/releases/tag/rel-26.3)
- FPGA AI Suite supported families (as of the 2025-era handbook): Agilex 5, Agilex 7, Arria 10, Cyclone 10 GX, Stratix 10, with Agilex 3 added; version 2025.3 requires OpenVINO 2024.6 LTS — [FPGA AI Suite Handbook (Intel docs)](https://www.intel.com/content/www/us/en/docs/programmable/863373); [Supported FPGA families](https://www.intel.com/content/www/us/en/docs/programmable/768970/2024-3/supported-fpga-families.html)
- FPGA AI Suite 2025.3 new features (search snippet): availability from the Quartus Prime installer, model update in DDR-free mode, "production-quality mixed precision support" — [FPGA AI Suite 2025.3 release notes](https://www.intel.com/content/www/us/en/docs/programmable/772497/2025-3/new-features-and-enhancements.html) (page redirected to 404 on fetch)
- FPGA AI Suite 2026.1.1 (announced 30 April 2026): "new compiler technology that uses spatial mapping of AI models"; works with PyTorch and TensorFlow plus OpenVINO model optimisation; new hostless JTAG-attach example for the Agilex 3 C-Series kit; "Agilex 3 delivers up to 2.8 peak INT8 TOPS"; license-free operation for up to 100,000 consecutive inferences — [AIChipLink summary](https://aichiplink.com/blog/Altera-Unveils-Next-Gen-FPGA-AI-Suite-Empowering-Deterministic-Physical-AI_1195) (search snippet; page 403 on fetch)

### Inferences
- With silicon a year away, FPGA AI Suite support for Agilex 2X would normally arrive alongside or after engineering samples; its absence from the 26.3 release is expected rather than telling. But it also means Altera has made no claim about what models (CNN, ViT, LLM) the Agilex 27 tensor DSP is meant to serve.
- The Agilex 2X "AI" story at launch is tool-side (QuartusIQ, an agentic assistant for RTL/timing work) and interconnect-side (HyperFlow), not an inference-accelerator story. For an LLM-on-FPGA reader, that is the main takeaway: no toolchain or model-support commitment exists yet.

### Gaps
- Could not read the FPGA AI Suite 26.3 handbook or release notes (docs.altera.com short links 404). Whether 26.3 lists Agilex 27 as a target device is unknown; the GitHub release body does not mention it.
- No published statement about transformer/attention or LLM layer support on any Altera device was retrieved in this pass (the 2026.1.1 "spatial compiler" item does not list model classes in the snippet available).

---

## Key question 4: AI density per DSP and per device versus Agilex 5 and AMD Versal AI Edge Gen 2

### Takeaway
A direct Agilex 27 comparison is impossible without a published tensor-mode width or DSP count. The established reference points are: Agilex 5 at 20 INT8 MAC/clk per DSP (A5E065A: 846 DSPs, ~22 to 26 TOPS), Stratix 10 NX at 30 MAC/clk per block (143 TOPS), Agilex 7 at 4 INT9 MAC/clk per DSP with no tensor mode, and Versal AI Edge Gen 2 at 512 INT8 MAC/clk per AIE-ML v2 tile (2VE3858: 184 dense INT8 TOPS, 369 TFLOPS in MX6).

### Cited Findings
- Versal AI Edge Gen 2 per-tile multiplies per cycle, AIE-ML (Gen 1) vs AIE-ML v2 (Gen 2): INT8 256 vs 512; BFLOAT16 128 vs 256; FP8 N/A vs 512; FP16 N/A vs 256; MX6 N/A vs 1024; MX9 N/A vs 512. Footnote: "MX6 and MX9 datatypes defined in https://arxiv.org/pdf/2302.08007, reference to Table II" — [AMD Hot Chips 2024 slides, p.8 (PDF)](https://www.hc2024.hotchips.org/assets/program/conference/day2/21_HC2024.AMD.KnoppChu.final.pdf)
- Device TOPS (highest speed grade), 2VE3858 / 2VE3558 / 2VE3358: MX6 369 / 246 / 61 TFLOPS; INT8 sparse 369 / 246 / 61 TOPS; INT8 dense 184 / 123 / 31 TOPS; FP8/MX9 184 / 123 / 31 TFLOPS; FP16/BF16 92 / 61 / 15 TFLOPS; INT16 dense 46 / 31 / 8 TOPS — [AMD Hot Chips 2024 slides, p.7 (PDF)](https://www.hc2024.hotchips.org/assets/program/conference/day2/21_HC2024.AMD.KnoppChu.final.pdf)
- 2VE3858 has 144 AIE-ML v2 tiles and 543,104 LUTs — [CNX Software on VEK385](https://www.cnx-software.com/2026/02/23/amd-vek385-versal-ai-edge-gen-2-fpga-evaluation-kit-plugs-directly-into-a-pcie-gen5-gen4-slot/)
- AMD's "up to 3X TOPs/Watt" claim is MX6 on Gen 2 versus INT8 on Gen 1, based on pre-silicon estimates at "1 GHz Fmax, 0.7V AIE operating voltage, 85C junction temperature, typical process, 60% vector load" (endnotes VER-023/025/026); accuracy claims: MX6 evaluated as drop-in for 25 of 44 FP32 models, MX9 for 35 of 44 (VER-69/70) — [AMD Hot Chips 2024 slides, pp.25-26 (PDF)](https://www.hc2024.hotchips.org/assets/program/conference/day2/21_HC2024.AMD.KnoppChu.final.pdf)
- Agilex 5 tensor mode: 20 INT8 multiplies per clock per DSP (two 10-element dot products), INT32 accumulate; BFP mode 8-bit shared exponent per 10-element vector, FP32 accumulate — [arXiv 2607.13898](https://arxiv.org/html/2607.13898); [Altera Agilex 5 DSP architecture brief](https://cdrdv2-public.intel.com/776602/agilex-5-fpgas-enhanced-dsp-with-ai-tensor-block-architecture-brief.pdf)
- Agilex 5 MXFP mapping results (baseline, unmodified device): tensor mode can implement MXFP4 (E2M1) and MXFP6 (E2M3) at 12.4 TFLOPS peak each, "but cannot be used for MXFP6 (E3M2) or any MXFP8 precision" because the converted fixed-point values exceed 8 bits; E3M2 via packed DSP reaches 6.5 TFLOPS and E4M3 3.4 TFLOPS. The proposed modified block supports MXFP4, both MXFP6 and E4M3 MXFP8 at +36% DSP tile area (1.8% of die), for a 4.2X average systolic-array throughput gain (9.1X on E3M2, 2.4X on E2M1) — [arXiv 2607.13898](https://arxiv.org/html/2607.13898)
- Stratix 10 NX: 30 INT8 multipliers per tensor block, 3,960 blocks, 143 INT8 / 286 INT4 TOPS — [docs.altera.com (Stratix 10 NX)](https://docs.altera.com/v/u/vuRNmNci66pfc_1eQlNd~A); [The Next Platform](https://www.nextplatform.com/2020/11/11/hbm2-tensor-units-key-to-intels-new-ai-centric-fpga/)
- Agilex 7 AGI027: 8,528 DSPs, 4 INT9 multipliers per DSP in sum-of-4 mode, no tensor mode — [Agilex 7 DSP user guide](https://docs.altera.com/r/docs/683037/current); [I-Series dev kit guide](https://www.intel.com/content/www/us/en/docs/programmable/683288/current/i-series-fpga.html)
- Agilex 3 (smallest current family): "up to 2.8 peak INT8 TOPS" — [AIChipLink on FPGA AI Suite 2026.1.1](https://aichiplink.com/blog/Altera-Unveils-Next-Gen-FPGA-AI-Suite-Empowering-Deterministic-Physical-AI_1195)

### Inferences (my arithmetic)
- Per-block INT8 MAC/clk: Agilex 7 DSP 4 (INT9); Agilex 5 DSP 20; Stratix 10 NX tensor block 30; Versal AIE-ML v2 tile 512 (MX6: 1024). A Versal tile is of course a far larger structure than an FPGA DSP, so per-block numbers are not like-for-like; the per-device numbers are the fair comparison.
- Versal 2VE3858 check: 144 tiles x 512 x 2 = 147,456 INT8 ops/clk; 184 TOPS implies ~1.25 GHz, and MX6 144 x 1024 x 2 = 294,912 ops/clk gives 369 TFLOPS at the same ~1.25 GHz. The published table is internally consistent with one clock, which is the kind of consistency check to apply to Agilex 27 figures when they appear.
- Density gap today: the largest Agilex 5 (~22 to 26 INT8 TOPS) is roughly 7X to 8X below 2VE3858 dense INT8, and roughly 14X below its MX6 figure. For Agilex 27 to be competitive for inference it would need a substantially wider tensor block, a much higher DSP count, or both; Altera has published nothing to indicate which, if either.
- AMD's MX6/MX9 are the Microsoft "shared microexponents" formats (arXiv 2302.08007), not OCP MX v1.0 formats; the AMD slide footnote is explicit about the source. So "Versal Gen 2 supports MX" should not be read as OCP MXFP4/MXFP8 support.

### Gaps
- No Agilex 27 or Agilex 25 DSP count, tensor width, or TOPS; no per-device comparison possible.
- No published Agilex 5 BFP-mode TOPS/TFLOPS table was retrieved (the device overview summary-of-features page was not fetchable).

---

## Key question 5: Memory bandwidth relevant to LLM weight streaming (DDR5 / LPDDR5X / LPDDR6, HBM plans)

### Takeaway
Altera lists DDR5, LPDDR4, LPDDR5X and LPDDR6 memory controllers for Agilex 27 and says "high memory bandwidth," but publishes no data rates, channel counts or GB/s. No HBM is mentioned for Agilex 2X. A "410 GB/s per HBM stack, 1.6X" figure that surfaced in search is an Agilex 7 M-Series specification and should not be attributed to Agilex 27.

### Cited Findings
- Agilex 27 "has memory controllers for DDR5, LPDDR4, LPDDR5X, and LPDDR6"; HyperFlow is "a new full-chip distributed data network that...can move data at multi-terabit-per-second rates throughout the FPGA" on a dedicated network separate from the programmable fabric — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- Press-release language: Agilex 27 targets applications needing "high-performance fabric, high capacities, high memory bandwidth, and next-generation connectivity for datapath processing, beamforming and RF processing" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- Embedded.com paraphrases Altera as saying Agilex 27 delivers "2× to 4× the bandwidth in an equivalently-sized device compared to a prior generation" (the referent, HyperFlow vs memory vs transceiver, is not clear in the article) — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- Memory interface list including MIPI: "DDR5, LPDDR5X and LPDDR6, MIPI C-PHY 2.1 and D-PHY 3.0" — [TechTalkThai](https://www.techtalkthai.com/altera-launches-agilex-2x-fpga-soc-portfolio-agilex-27/)
- Connectivity: transceivers up to 256 Gbps, hardened 800GbE and 1.6TbE, PCIe 6.0 and 7.0 — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- HBM: Converge Digest notes HBM is "Not mentioned" in the Agilex 27 material — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/). The "410 GBps memory bandwidth per HBM2E stack" and "820 GBps total aggregate" figures belong to Agilex 7 M-Series — [Agilex 7 device overview, HBM2E section](https://www.intel.com/content/www/us/en/docs/programmable/683458/current/heterogeneous-3d-stacked-hbm2e-dram.html)
- Agilex 5 external memory (for scale): the device overview lists DDR5 and LPDDR5 support; specific max rates were not retrievable here — [Agilex 5 device overview](https://docs.altera.com/r/docs/762191/current/agilex-5-fpgas-and-socs-device-overview)

### Inferences (my arithmetic, for a reader sizing LLM decode)
- LPDDR6 is the one genuinely new item. JEDEC LPDDR6 starts around 10.667 Gbps per pin on 24-bit channels; a single 2x12-bit LPDDR6 channel at that rate is roughly 32 GB/s, so a hypothetical 8-channel configuration lands near 256 GB/s. That is my calculation from the JEDEC spec basics, not an Altera figure, and Altera has not published channel counts.
- For LLM decode, which is weight-bandwidth-bound, no-HBM plus unspecified LPDDR6/DDR5 width means Agilex 27 as announced cannot be evaluated against GPU-class (multi-TB/s) or even Versal-class HBM parts. HyperFlow's multi-Tb/s claim is on-chip movement and does not substitute for external weight bandwidth.

### Gaps
- No data rates (Mbps per pin), channel counts, or aggregate GB/s for any Agilex 27 or Agilex 25 memory interface are public.
- No HBM roadmap statement for Agilex 2X was found, positive or negative, beyond the absence noted by press.

---

## Key question 6: What the OCP Microscaling (MX) specification requires of a dot-product unit, and whether anything published suggests Agilex 27 maps to it natively

### Takeaway
OCP MX v1.0 fixes block size k=32 and an E8M0 (power-of-two) shared scale for every concrete format (MXFP8 E4M3/E5M2, MXFP6 E3M2/E2M3, MXFP4 E2M1, MXINT8); an implementation may support any subset but must honour those parameters per supported format. Nothing published about Agilex 27 mentions MX, FP8, FP4 or k=32 blocks; the only FPGA-side MX work on an Altera block is the academic Agilex 5 study, whose authors needed a hardware modification to cover MXFP8 and E3M2.

### Cited Findings
- OCP MX v1.0 (Sep 2023), concrete formats table: MXFP8 (FP8 E5M2 or E4M3, 8-bit elements), MXFP6 (FP6 E3M2 or E2M3, 6-bit), MXFP4 (FP4 E2M1, 4-bit), MXINT8 (INT8); all with "Scaling Block Size (k) 32" and "Scale Data Type E8M0, Scale Bits (w) 8" — [OCP MX Specification v1.0 (PDF)](https://opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
- Compliance: "it is not required for all the concrete MX-compliant formats to be supported. An implementation may choose to support any subset of the formats. Different encodings (e.g., E5M2 and E4M3 for MXFP8) are considered different formats. For each supported format, an implementation must support the parameters listed in Table 1." — [OCP MX Specification v1.0 (PDF)](https://opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
- Semantics: "If X = NaN, then vi = NaN for 1 <= i <= k regardless of Pi"; otherwise vi = X*Pi, with values beyond Float32 range "implementation-defined"; memory layout of the block "is not prescribed" and the scale may be stored contiguously or separately — [OCP MX Specification v1.0 (PDF)](https://opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
- Element rules: FP8 must follow the OCP FP8 spec (E4M3 max 448, no Inf; E5M2 max 57,344, has Inf) and support SAT and OVF conversion modes; FP6 and FP4 have no Inf/NaN encodings, must support subnormals and roundTiesToEven, and must saturate on overflow — [OCP MX Specification v1.0 (PDF)](https://opencompute.org/documents/ocp-microscaling-formats-mx-v1-0-spec-final-pdf)
- Dot product of two MX blocks as summarised by the Agilex 5 study: "a·b = 2^(Xa+Xb-254) * sum(Pa,i x Pb,i)" over k=32 elements sharing "a single unsigned E8M0 scale factor" — [arXiv 2607.13898](https://arxiv.org/html/2607.13898)
- A revised OCP MicroXcaling specification v1.1.0 was posted in October 2026 — [OCP MicroXcaling Spec v1.1.0 (PDF)](https://www.opencompute.org/wp-content/uploads/2026/10/OCP_MicroXcaling_Spec_v1.1.0.pdf) (not read; contents unverified in this pass)
- On the Agilex 5 block, MXFP8 and MXFP6 E3M2 cannot use tensor mode because converting elements to fixed point for the shared-exponent datapath requires "fixed-point values that are wider than 8 bits"; the paper calls itself "the first DSP-block microarchitecture study targeting MXFP formats" — [arXiv 2607.13898](https://arxiv.org/html/2607.13898)
- GPU context from the same paper: NVIDIA Blackwell "natively supports fp4 and fp6 operations in its fifth-generation tensor cores"; Stratix 10 NX was the first commercial FPGA with DL-optimised tensor blocks (int8/int4) — [arXiv 2607.13898](https://arxiv.org/html/2607.13898)
- AMD Versal Gen 2's MX6/MX9 are defined by the Microsoft shared-microexponent paper (arXiv 2302.08007, Table II), not by OCP MX v1.0 — [AMD Hot Chips 2024 slides (PDF)](https://www.hc2024.hotchips.org/assets/program/conference/day2/21_HC2024.AMD.KnoppChu.final.pdf)

### Inferences
- What a native OCP-MX dot-product unit needs, read off the spec: (1) element multipliers for the chosen element type(s), including FP8 E4M3/E5M2 specials if MXFP8 is claimed; (2) a k=32 reduction (or a shorter dot product whose partial sums are combined before the scale is applied, since the scale is constant across the block); (3) a product-of-scales step that is a pure exponent add (E8M0 + E8M0 - 254), i.e. a shift, not a multiply; (4) an accumulator wide enough that the implementation-defined internal precision does not visibly diverge from reference, with FP32 the de facto norm. The spec does not mandate internal precision or operation order.
- The Agilex 5 block's 10-element shared-exponent dot product is structurally close to this (shared 8-bit exponent, FP32 accumulate), which is why the arXiv authors could map MXFP4 and E2M3 onto it. The mismatches are block length (10 vs 32) and element width (its shared-exponent lanes take 8-bit fixed-point mantissas, so FP8 elements with their own exponents do not fit). An Agilex 27 block that fixed those two things would be a natural "enhancement," but there is no published evidence Altera did so.
- Nothing published suggests Agilex 27 maps to OCP MX natively. The honest statement for the report is: unknown, with no positive signal.

### Gaps
- The OCP MX v1.0 Section 6 text on the dot-product definition and internal-precision latitude was not extracted verbatim here (only Sections 5.1 to 5.3 were); the formula above is the arXiv paper's restatement.
- OCP MX v1.1.0 (Oct 2026) was not read; any changes to block size or scale type are unverified.
- AMD GPU MXFP4 support (CDNA 4 / MI355X) was not researched in this pass; only the NVIDIA Blackwell statement from the arXiv paper is cited.

---

## Summary table of what is and is not published for Agilex 27 (31 Oct 2026)

| Item | Status | Source class |
|---|---|---|
| Tensor DSP exists | Yes, "enhanced AI tensor DSP blocks ... signal processing applications" | Altera via press |
| Element formats (INT8/INT4/FP8/FP4/FP16/BF16) | Not published | — |
| Shared-exponent / BFP / MX mode | Not published | — |
| Dot-product length, columns, accumulator | Not published | — |
| INT8 TOPS per device, DSP count, LE count | Not published | — |
| 1.8X perf/W vs Agilex 7 (HyperFlex) | Published | Altera via press |
| HyperFlow multi-Tb/s on-chip network | Published, no numbers | Altera via press |
| Memory controllers DDR5 / LPDDR4 / LPDDR5X / LPDDR6 | Published, no rates | Altera via press |
| HBM | Not mentioned | press notes absence |
| Transceivers 256 Gbps, 800GbE/1.6TbE, PCIe 6.0/7.0 | Published | Altera via press |
| Quartus Prime Pro 26.3 support, QuartusIQ | Published | Altera via press |
| FPGA AI Suite / OpenVINO / LLM / transformer for Agilex 2X | Not published | — |
| Engineering samples | 2H 2027 | Altera via press |
| Process node | Not published | — |
