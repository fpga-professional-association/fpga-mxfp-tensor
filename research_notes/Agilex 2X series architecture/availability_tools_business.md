# Agilex 2X (Agilex 27 / Agilex 25): availability, software support, business context

Scope note: material published up to 31 October 2026. The altera.com newsroom page and the BusinessWire original (20261028884986) returned HTTP 403 to fetch tools, so press release wording below comes from syndicated mirrors (Yahoo Finance, Rutland Herald/BusinessWire feed) and trade press that quoted it. Where a date is a vendor target rather than an achieved milestone it is marked [TARGET]. Where a claim is press inference rather than Altera wording it is marked [PRESS INFERENCE].

## Key question 1: Exact announced dates (software early access, engineering samples, production) for Agilex 27 and Agilex 25

### Takeaway
Altera gave only two dates, both for Agilex 27 and both targets: Quartus Prime early access "starting mid-November" (2026) and engineering sample silicon "in the second half of 2027". No production date was given for any Agilex 2X family, and no dates at all were given for Agilex 25, 23 or 22.

### Cited Findings
- Dateline of the launch release: "SAN JOSE, Calif.--(BUSINESS WIRE)--Oct 28, 2026". Headline: "Altera Announces Agilex 2X, a Complete FPGA & SoC Portfolio Built for the Future of Intelligent Systems" — [Rutland Herald (BusinessWire feed)](https://www.rutlandherald.com/news/business/altera-announces-agilex-2x-a-complete-fpga-soc-portfolio-built-for-the-future-of-intelligent/article_18933a1b-73fd-5fa0-9ace-6f88f32e553c.html); [Altera newsroom (403 to fetch)](https://www.altera.com/newsroom/agilex-2x)
- [TARGET] "Quartus Prime software support for Agilex 27 FPGAs will be available to early access customers starting in mid-November" and "engineering sample silicon for Agilex 27 FPGAs is expected in the second half of 2027" — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); [Yahoo Finance mirror of release](https://finance.yahoo.com/technology/ai/articles/altera-announces-agilex-2x-complete-150000633.html); [ENGtechnica](https://engtechnica.com/altera-introduces-agilex-2x-fpgas-for-ai-and-edge-systems/)
- "Agilex 27 FPGAs are the first family to launch within the Agilex 2X portfolio" — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- "Agilex 25/23/22 samples: Timeline not specified" and "Altera has not established equivalent detailed silicon delivery dates for the other three announced families" — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- No production date stated; "Production Timeline: Not specified" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- [PRESS INFERENCE] ServeTheHome's own estimate: "Production availability: Likely 2027-2028 timeframe" — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- QuartusIQ (the AI companion, not device support) was announced 21 October 2026 with availability "planned for October 28 with Quartus Prime Pro 26.3" — [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design); trade press on 28 October describes QuartusIQ as "available now" in Quartus Prime Pro Edition 26.3 — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant); [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)

### Inferences
- The one-year gap between tool access (Nov 2026) and silicon samples (H2 2027) matches Altera's usual pattern of releasing "advance" device support in Quartus well ahead of samples. It is not evidence of a slip, since no earlier date was ever public.
- Nothing in the coverage suggests Agilex 25 follows Agilex 27 closely. Read Agilex 25 as a roadmap placeholder for now.

### Gaps
- No production (volume) date for Agilex 27 was published by Altera. Any "2028" figure in circulation is press estimation.
- No sample or software date for Agilex 25, 23 or 22.
- I could not retrieve the verbatim press release (403s), so exact footnote wording around the dates is unverified beyond the mirror summaries.

## Key question 2: Which Quartus Prime Pro release first supports Agilex 27, and under what access program?

### Takeaway
Quartus Prime Pro Edition 26.3 is the release Altera shipped in the same announcement cycle (it carries QuartusIQ). Altera's own wording ties Agilex 27 support to "early access customers" from mid-November, which is after 26.3 shipped, so the first supporting bits are most plausibly an early-access build or patch on the 26.3 line. No program name or version suffix was published.

### Cited Findings
- "QuartusIQ, the company's AI development companion, is also available now through Quartus Prime Pro Edition 26.3" and "Software support is available now in Quartus Prime 26.3, but Agilex 27 engineering samples are expected in the second half of 2027" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- Contradicting nuance: the release itself says Agilex 27 support goes to "early access customers starting in mid-November", i.e. not generally available on 28 October — [Yahoo Finance mirror](https://finance.yahoo.com/technology/ai/articles/altera-announces-agilex-2x-complete-150000633.html); [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/) ("November 2026: Agilex 27 software early-access support expected")
- QuartusIQ availability was "planned for October 28 with Quartus Prime Pro 26.3" in the 21 October announcement — [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design)
- Latest publicly indexed Quartus Prime Pro release notes are 25.3 (29 Oct 2025) and 25.3.1 (5 Jan 2026); no 26.3 release notes surfaced in search, and no "Agilex 27" device-support entry was found in any indexed release note — [Quartus Prime Pro 25.3.1 release notes](https://docs.altera.com/r/docs/683706/25.3.1/quartus-prime-pro-edition-version-25.3.1-software-and-device-support-release-notes/quartus-prime-pro-edition-version-25.3.1-software-and-device-support-release-notes); [Quartus Prime Pro 25.3 "devices with advance device support"](https://www.intel.com/content/www/us/en/docs/programmable/683706/25-3/devices-with-advance-device-support.html)
- All four Agilex 2X families share "a common Quartus Prime development environment" — [inelectronics.co.uk](https://www.inelectronics.co.uk/altera-unveils-agilex-2x-fpga-portfolio/)

### Inferences
- Altera release notes carry a standing "devices with advance device support" section; Agilex 27 will most likely appear there first (either a 26.3.x update or 26.4), gated to early-access customers. This is inference from Altera's release-note structure, not a stated plan.
- The SiliconANGLE "available now in 26.3" line conflates QuartusIQ availability with Agilex 27 device support. Treat the vendor's "mid-November early access" as authoritative.

### Gaps
- No public name for the early access program, no sign-up page found, no NDA/eligibility detail.
- 26.3 release notes not retrievable/indexed as of 31 Oct 2026, so I cannot confirm whether 26.3 already contains Agilex 27 device files.

## Key question 3: What AI software stack is promised (FPGA AI Suite version, OpenVINO, tensor DSP compiler, INT8/FP8/MXFP)?

### Takeaway
The Agilex 2X announcement promised nothing specific about FPGA AI Suite, OpenVINO, or data types; the only architectural AI statement was "enhanced AI tensor DSP blocks". The AI software news in the cycle was QuartusIQ, an agentic design assistant, not an inference compiler. The latest FPGA AI Suite on record (26.1.1, April 2026) predates Agilex 2X and targets existing Agilex devices.

### Cited Findings
- Agilex 2X architecture list includes "Enhanced AI tensor DSP blocks for signal processing acceleration", plus "Arm cores and Nios V soft processors", "Adaptive Logic Module (ALM) modes", and HyperFlex fabric registers enabling retiming "without consuming logic resources" — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- Embedded.com explicitly found no FPGA AI Suite, OpenVINO, INT8/FP8/MXFP, or tensor-compiler detail in the announcement materials — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant); same absence noted by [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/) and [inelectronics.co.uk](https://www.inelectronics.co.uk/altera-unveils-agilex-2x-fpga-portfolio/)
- QuartusIQ: "AI Expert Companion for Quartus Prime", uses the open Model Context Protocol (MCP) to connect AI agents to Quartus and supported tools; supports "customer-selected frontier and open-weight models with deployment options in the cloud or on premises"; NVIDIA Nemotron open-weight models can run locally; "reusable Quartus Skills"; claims "up to 1.5X faster total design cycles" — [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design)
- QuartusIQ claims "up to 10× faster design creation" and "~1.5× overall design-cycle improvements, in some cases 2×" (internal benchmarks); "Trained on 20,000+ FPGA-specific documents"; Visual Studio Code integration via MCP connector; GitHub Copilot compatibility; can translate block diagrams/natural language into designs, run compilation/simulation, find bugs, close timing — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- QuartusIQ supports MCP and "bring-your-own-key" model setup — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- QuartusIQ is "Optimized for NVIDIA DGX Station (GB300 Grace Blackwell Ultra, 748 GB coherent memory)" for on-prem use; NVIDIA VP Chris Marriott: "Running this agentic AI locally on the DGX Station gives engineers the ultimate deskside supercomputer" — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm); [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design)
- Altera's Farhad Shafai on QuartusIQ: "Agentic AI brings expert guidance and workflow automation into the development environment" — [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design)
- FPGA AI Suite 26.1.1 (announced 30 April 2026) "introduces a spatial compiler that maps AI models directly onto Agilex FPGAs"; "supports Quartus Prime Pro Edition 26.1"; works with TensorFlow and PyTorch; vendor claims 3.09 million inferences/s, "28 times less" latency and "up to 40% less power" (basis not stated in the summary I could access) — [BusinessWire 30 Apr 2026 (403 to fetch; title and snippet only)](https://www.businesswire.com/news/home/20260430098695/en/Altera-Brings-Determinism-to-Physical-AI-Systems-with-Latest-Release-of-FPGA-AI-Suite); [aichiplink summary](https://aichiplink.com/blog/Altera-Unveils-Next-Gen-FPGA-AI-Suite-Empowering-Deterministic-Physical-AI_1195)
- FPGA AI Suite 25.3 was released alongside Quartus 25.3 (Oct 2025) "to accelerate the integration of AI models into an FPGA" — [HPCwire (Altera release, 1 Oct 2025)](https://www.hpcwire.com/off-the-wire/altera-expands-agilex-fpga-portfolio-and-streamlines-developer-experience/)
- For reference only (Agilex 5, not Agilex 2X): the existing Enhanced DSP with AI Tensor Block does 20 INT8 multiplies per block, "supports a block floating exponent", and the variable-precision DSP supports FP32, FP16, FP19 and BFLOAT16 — [Intel/Altera Agilex 5 device overview](https://www.intel.com/content/www/us/en/docs/programmable/762191/current/variable-precision-dsp-in.html)

### Inferences
- "Enhanced AI tensor DSP blocks" in Agilex 2X almost certainly builds on the Agilex 5 tensor block lineage (INT8 tensor mode plus block-floating exponent), which would make a shared-exponent/MX-style format a natural extension. Altera has not said so; treat any MXFP/FP8 claim as unconfirmed.
- QuartusIQ is the "software" half of Altera's launch messaging. I found no product branded "Altera Agilex AI"; the branded stacks remain FPGA AI Suite (inference) and QuartusIQ (design assistance).

### Gaps
- No FPGA AI Suite version with Agilex 2X device support announced. No OpenVINO statement in Agilex 2X coverage.
- No data-type list (INT8/FP8/MXFP) for the Agilex 2X tensor DSP in any public source.
- No product or page named "Altera Agilex AI" found; if the parent report has that name from another source, it needs its own citation.
- The BusinessWire FPGA AI Suite 26.1.1 release body was not retrievable (403); the 3.09M inferences/s and 28x/40% figures come from a secondary summary.

## Key question 4: Foundry/process node and the 1.8x performance-per-watt claim

### Takeaway
Altera did not disclose a foundry or node for Agilex 2X in any coverage reviewed. The 1.8x claim is a generation-over-generation perf/watt gain of Agilex 27 over Agilex 7, attributed to the third-generation HyperFlex fabric, and no methodology footnote was reproduced by any outlet.

### Cited Findings
- "Altera claims a 1.8X generation-over-generation performance-per-watt improvement over Agilex 7 for HyperFlex in Agilex 27"; no process node, foundry, HBM, or DSP counts provided — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- "3rd generation HyperFlex fabric with 1.8X generation-over-generation performance/watt improvements" — [Yahoo Finance mirror](https://finance.yahoo.com/technology/ai/articles/altera-announces-agilex-2x-complete-150000633.html); inelectronics phrases it as "up to 1.8 times the performance per watt" versus predecessor — [inelectronics.co.uk](https://www.inelectronics.co.uk/altera-unveils-agilex-2x-fpga-portfolio/)
- [PRESS INFERENCE] TechTimes characterizes the 1.8x as "internal benchmarks, not independently audited" — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Process node: "Not disclosed" per [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/), [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm), [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- Pre-announcement context (earlier CEO Sandra Rivera interview): next-generation products "will be on a new process node", Intel 18A looked "really appealing"; Agilex 5 is on Intel 7; Altera historically built Cyclone and others at TSMC; TSMC described as "a critical partner with 2040 commitments" — [eeNews Europe, Rivera interview](https://www.eenewseurope.com/en/ceo-interview-sandra-rivera-of-altera-on-the-move-to-intel-18a)
- Agilex 7 M-Series (the comparison baseline generation) uses Intel 7 and integrates HBM — [Altera Agilex 7 M-Series page](https://www.altera.com/products/fpga/agilex-7/m-series)
- Fabric details tied to the claim: 3rd-gen HyperFlex registers "distributed throughout the routing fabric", Quartus can "re-time and pipeline designs through those registers without consuming logic resources"; HyperFlow is a "full-chip distributed data network" moving data at "multi-terabit-per-second rates throughout the FPGA" on a dedicated network separate from programmable fabric — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)

### Inferences
- The Rivera 18A comment is from before the Silver Lake close and before Hussain became CEO; it should not be read as confirmation of the Agilex 2X node. The H2 2027 sample date is consistent with either an Intel advanced node or a TSMC N3-class node; there is no public evidence either way.
- Because the baseline is Agilex 7 (Intel 7, launched 2019-2022), a 1.8x perf/watt figure spanning roughly two process generations is modest and probably refers to fabric (HyperFlex) performance at iso-power rather than DSP or SerDes throughput.

### Gaps
- Foundry and node: not disclosed.
- No footnote text for the 1.8x claim (which Agilex 7 device, which benchmark suite, which Quartus version). The press release mirrors did not reproduce footnotes.

## Key question 5: Development kits, reference designs, pricing and tier positioning

### Takeaway
No Agilex 27 or Agilex 25 development kit, reference design, or price was announced. Positioning is tiered: Agilex 27 high-performance, Agilex 25 mid-range, Agilex 23 value with SoC options, Agilex 22 value FPGA-only.

### Cited Findings
- "No ... dev kit pricing" and no DSP counts in the announcement — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); "No development kit details", "No pricing information" — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/); "Pricing: Not disclosed" — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Tier positioning: "Agilex 27 (high-performance), Agilex 25 (mid-range), Agilex 22 (FPGA-only value), and Agilex 23 (SoC-capable value)" — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- Agilex 27 target applications: "Digital AI infrastructure, terabit networking, 6G and satellite networks, and aerospace and defense"; Agilex 25: "4K/8K video processing, drones, low-latency sensors", with "high-performance fabric and embedded compute", "optimized I/O, transceivers and peripherals" — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant); [ENGtechnica](https://engtechnica.com/altera-introduces-agilex-2x-fpgas-for-ai-and-edge-systems/)
- Agilex 23: "robotics, industrial automation and automotive systems" with functional safety; Agilex 22: "board control, motor control, security and interface bridging" — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- Agilex 27 feature list: transceivers up to 256 Gbps; hardened 800GbE and 1.6TbE; PCIe 6.0 and 7.0; DDR5, LPDDR4, LPDDR5X, LPDDR6 memory controllers; UCIe; crypto acceleration; Arm Cortex-A720 and Cortex-A520 cores — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); MIPI also listed — [inelectronics.co.uk](https://www.inelectronics.co.uk/altera-unveils-agilex-2x-fpga-portfolio/)
- Security across the portfolio: Secure Device Manager root of trust, MACsec, PCIe IDE, inline memory encryption, post-quantum-cryptography-ready secure boot and attestation — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant); [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- Existing ecosystem scale (from Oct 2025 cycle): "Over 300 registered partners" in the Altera Solution Acceleration Partner (ASAP) Program — [HPCwire (Altera release, 1 Oct 2025)](https://www.hpcwire.com/off-the-wire/altera-expands-agilex-fpga-portfolio-and-streamlines-developer-experience/)

### Inferences
- Agilex 27 listing Arm Cortex-A720/A520 cores implies SoC (HPS) variants of Agilex 27 exist on the roadmap, even though Altera did not use "M-series" or "SoC" naming for it. ServeTheHome's "Agilex 22 FPGA-only, Agilex 23 adds SoC" wording suggests Altera will keep separate FPGA/SoC ordering codes rather than a universal SoC.
- With samples in H2 2027, a dev kit is unlikely before 2028 if Altera follows its Agilex 3 pattern (software Q1 2025, dev kits and production mid-2025).

### Gaps
- No HBM / M-series statement for Agilex 27 in any source; whether an HBM variant exists is unknown.
- No dev kit names, part numbers, or prices.
- No logic-element counts or device table for Agilex 27 or 25 were published.

## Key question 6: Competitive positioning versus AMD Versal / Spartan UltraScale+ and Lattice

### Takeaway
Altera made no direct named comparison to AMD or Lattice in the Agilex 2X announcement; its competitive framing was architectural ("data movement is the biggest problem") and tooling (agentic AI in Quartus). Press drew the AMD/Lattice comparisons.

### Cited Findings
- CEO Raghib Hussain: "Compute is one part, but data movement is the biggest problem to be solved" — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm); [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- Hussain, launch release: Agilex 2X "delivers the performance and density the most complex Digital AI and aerospace and defense systems demand" while scaling to edge requirements; "Digital AI and Physical AI are expanding the opportunity for programmable logic" (Raghib Hussain, President and CEO) — [Yahoo Finance mirror](https://finance.yahoo.com/technology/ai/articles/altera-announces-agilex-2x-complete-150000633.html); [ENGtechnica](https://engtechnica.com/altera-introduces-agilex-2x-fpgas-for-ai-and-edge-systems/)
- Lux Joshi, Senior Director of Product Management: "Intelligence is reshaping a lot of what's happening in the electronics industry" — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- "No direct AMD/Lattice comparisons" in the announcement — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); "No competitive positioning statements" — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- [PRESS INFERENCE] TechTimes frames AMD/Xilinx as the primary competitor and notes Lattice announced an MCP-based "Lattice Prompt" tool in September 2026, so QuartusIQ is not alone in agentic FPGA tooling; it also likens HyperFlow to NVIDIA's NVLink conceptually — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- [PRESS INFERENCE] SiliconANGLE's John Furrier: "customer results in sustained throughput, latency and total system cost will be more telling" than launch claims — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- Prior Altera competitive benchmarks (older, not from this cycle): Agilex 3 "up to 62% faster core performance (29% faster geomean)" than competing devices — [Altera community blog](https://community.altera.com/blog/fpga-blog/agilex%E2%84%A2-3-fpgas-and-socs-deliver-up-to-62-faster-core-performance-than-competing/250057); Agilex 3 vs Lattice Certus-N2 head-to-head on 10 OpenCores designs — [Altera doc](https://docs.altera.com/v/u/docs/r289791/agilextm-3-vs.-certus-n2-devices-head-to-head-benchmarking-on-10-opencores-designs); Agilex 5 LE "can implement 34% more logic than Lattice's Avant system logic cell" — [Altera white paper](https://docs.altera.com/v/u/docs/833305/comparing-the-real-world-capacity-of-agilextm-5-fpgas-white-paper)

### Inferences
- Altera is positioning Agilex 27 against AMD Versal Premium (PCIe 6/7, 1.6TbE, UCIe are the same checklist AMD uses for Versal Premium Gen 2) without saying so. No Versal comparison data exists yet because there is no Agilex 27 silicon.
- Agilex 22/23 land in the Spartan UltraScale+ / Lattice Certus-N2 and Avant zone; the Agilex 3 benchmarks above are the template Altera will likely reuse.

### Gaps
- No analyst notes from Moor Insights, SemiAnalysis, TechInsights or Forbes on Agilex 2X surfaced in search by 31 Oct 2026. An unattributed analyst line ("2027 or 2028 timeframe when actual deployments happen") appeared only in a search summary without a resolvable source, so I did not cite it.
- No EE Times, The Register, HPCwire or EE Journal coverage of the 28 Oct announcement was found in search.

## Supporting context: post-Intel independence, leadership, strategy, and the rest of the Agilex roadmap

### Takeaway
Altera closed the Silver Lake majority sale in September 2025 (announced April 2025; Silver Lake 51%, Intel 49%, $8.75B valuation), confidentially filed for an IPO on 15 September 2026, and is led by CEO Raghib Hussain. The company declared the whole Agilex 3/5/7 portfolio in production in October 2025; the October 2026 cycle added no new Agilex 3/5/7 milestones in the coverage reviewed.

### Cited Findings
- Silver Lake completed acquisition of a 51% stake, Intel retaining 49%, "reestablishing Altera as the world's largest independent, pure-play FPGA solutions provider" — [Silver Lake / Altera close announcement (Sept 2025)](https://www.silverlake.com/altera-closes-silver-lake-investment-to-become-worlds-largest-pure-play-fpga-solutions-provider/); [Edge AI and Vision Alliance repost](https://www.edge-ai-vision.com/2025/09/altera-closes-silver-lake-investment-to-become-worlds-largest-pure-play-fpga-solutions-provider/)
- Deal terms: Silver Lake paid $4.46 billion for 51% at an $8.75 billion valuation; Intel bought Altera for about $16.7 billion in 2015 — [The Star (Reuters)](https://www.thestar.com.my/tech/tech-news/2026/09/11/exclusive-silver-lake-intel-backed-altera-prepares-ipo-that-could-raise-over-2-billion-as-early-as-2026-sources-say); [Converge Digest](https://convergedigest.com/intel-sells-51-of-altera-to-silver-lake-for-8-75b-appoints-new-ceo/)
- 15 Sept 2026: Altera's parent "confidentially submitted a draft registration statement on Form S-1 with the Securities and Exchange Commission"; "The number of shares to be offered and the price range for the proposed offering have not yet been determined"; boilerplate: "Altera is the largest pure-play FPGA provider with a full-spectrum portfolio serving applications ranging from data centers and communications networks to critical embedded systems" — [HPCwire (Altera release)](https://www.hpcwire.com/off-the-wire/altera-announces-confidential-submission-of-draft-registration-statement/)
- Reuters-sourced: IPO "could raise more than $2 billion as early as 2026"; Barclays, Citi, JPMorgan and Morgan Stanley as underwriters; FY2024 revenue about $1.54 billion, growth over 20% year on year — [The Star (Reuters), 11 Sept 2026](https://www.thestar.com.my/tech/tech-news/2026/09/11/exclusive-silver-lake-intel-backed-altera-prepares-ipo-that-could-raise-over-2-billion-as-early-as-2026-sources-say); [The Star, 15 Sept 2026](https://www.thestar.com.my/tech/tech-news/2026/09/15/silver-lake-intel-backed-altera-confidentially-files-for-us-ipo)
- CEO Raghib Hussain (July 2026): revenue grew more than 20% in the prior year, expects mid-20% growth for 2026 and a doubling of operating income — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); Hussain on theCUBE (June 2026): "AI is going to force a redesign of every equipment out there" — same source
- Silver Lake stated it will support Altera's expansion into industrial automation, robotics, aerospace, defense, telecommunications, data centers and edge AI — [Silver Lake announcement](https://www.silverlake.com/altera-closes-silver-lake-investment-to-become-worlds-largest-pure-play-fpga-solutions-provider/)
- "Full-stack" wording: Altera describes "a comprehensive, full-stack FPGA portfolio featuring industry-leading fabric, efficient performance, and easy-to-use, scalable software" and a portfolio including "software tools, IP, and design services aimed at building full-stack FPGA solutions" — [Pulse 2.0](https://pulse2.com/altera-partnering-with-silver-lake-to-become-leading-independent-fpga-provider); [Edge AI and Vision Alliance](https://www.edge-ai-vision.com/2025/09/altera-closes-silver-lake-investment-to-become-worlds-largest-pure-play-fpga-solutions-provider/)
- Agilex 3/5/7 status (1 Oct 2025 release): "production availability of all Agilex FPGAs device families, including Agilex 5 and Agilex 3 SoC FPGAs"; Agilex 5 D-Series density up to 2.5X with up to 1.6 million LEs; DDR5 to 5,600 MT/s and LPDDR5 to 5,500 MT/s (25% up); PQC secure boot on all Agilex 5 D-Series; Quartus Prime 25.3 with Visual Designer Studio ("5 days to 2 hours" design start), 6% faster compiles vs 25.1.1, 27% compile reduction since Agilex 7 production, 6% fewer ALMs — [HPCwire (Altera release)](https://www.hpcwire.com/off-the-wire/altera-expands-agilex-fpga-portfolio-and-streamlines-developer-experience/); [Embedded Computing Design](https://embeddedcomputing.com/technology/processing/semiconductor-ip/alteras-agilex-fpga-portfolio-now-in-full-production-with-major-performance-upgrades)
- Agilex 3 earlier timeline (for pattern): software support Q1 2025, dev kits and production shipments mid-2025 — [Hackster](https://www.hackster.io/news/altera-announces-aligex-3-agilex-5-e-volume-availability-max-10-io-expansion-at-embedded-world-133150a4555b)
- NVIDIA is the only named partner in the Agilex 2X / QuartusIQ cycle (Nemotron models, DGX Station optimization) — [TechIntelPro](https://techintelpro.com/news/ai/agentic-ai/altera-launches-quartusiq-ai-companion-for-fpga-design); [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- An Altera community blog post exists titled "Altera extends Agilex, MAX 10 and Cyclone V lifecycles through 2045 for long-l[ifecycle]..." (title only seen in search; body not fetched) — [Altera community blog](https://community.altera.com/blog/fpga-blog/altera-extends-agilex%C2%AE-max%C2%AE-10-and-cyclone%C2%AE-v-lifecycles-through-2045-for-long-l/351568)

### Inferences
- Announcing a 2027-silicon roadmap six weeks after a confidential S-1 reads as roadmap signaling to IPO investors as much as to customers; the "complete portfolio" framing (four families, one toolchain) supports the "full-stack" pitch in the S-1 boilerplate.
- Any reference to Sandra Rivera as CEO is stale: by the Agilex 2X launch the CEO is Raghib Hussain (named when the Silver Lake deal was announced). Rivera's 18A remarks predate him.

### Gaps
- No Agilex 3, 5 or 7 product news in the 21-31 Oct 2026 cycle was found; "full production" claims date from 1 Oct 2025.
- No customer or ecosystem partner quotes (beyond NVIDIA) for Agilex 2X located.
- No public S-1 as of 31 Oct 2026, so no audited financials.
