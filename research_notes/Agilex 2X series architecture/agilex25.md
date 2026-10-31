# Altera Agilex 25 FPGA family (Agilex 2X portfolio)

Scope note: everything below is limited to material published on or before 31 October 2026. Sources are tagged [vendor spec], [vendor marketing], [press], or [observation] where the distinction matters. Where no number is published, the gap is stated rather than estimated.

Primary sources located and read in full:
- Altera press release, 28 Oct 2026: https://www.altera.com/newsroom/agilex-2x
- Altera Agilex 2X portfolio page: https://www.altera.com/products/fpga/agilex-2x-portfolio
- Agilex 2X FPGA and SoC Portfolio Brief, PB-1025-1.0, docs.altera.com metadata date 2026-10-26 (landing: https://docs.altera.com/v/u/docs/r133175/agilex-2x-fpga-and-soc-portfolio-brief ; PDF: https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- Agilex 27 FPGA and SoC Product Brief, PB-1026-1.0, dated 2026-10-29 (landing: https://docs.altera.com/v/u/docs/r594095/agilex-27-fpga-and-soc-product-brief ; PDF: https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content)
- Agilex 27 FPGA and SoC Product Table, version 2026.10.28, marked "Preliminarily and Subject to Change" (PDF: https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- Agilex 27 white paper WP-01358-1.0, "Engineered for Throughput: How Agilex 27 FPGAs Sustain System Performance in the Age of Exponential Data Growth" (PDF: https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- Agilex 5 D-Series Product Table, version 2026.08.07 (PDF: https://docs.altera.com/api/khub/documents/u3IUzUncU9s_fK0pS0LseA/content), used only for the positioning comparison

## Key question 1: What has Altera published about Agilex 25 resources (LEs, DSPs, memory, transceivers)? Is there a product table?

### Takeaway
Nothing quantitative. As of 31 Oct 2026 Altera has published no Agilex 25 product table, product brief, device overview, or any resource number (LEs, DSP count, memory bits, transceiver count or speed). The only Agilex 25 content is three to four sentences of positioning text repeated across the press release, the portfolio web page, and the portfolio brief. There is no Agilex 25 product page; the URL pattern that works for other families returns a 404 and the portfolio page routes Agilex 25 to "Contact Sales".

### Cited Findings
- Press release, full Agilex 25 text: "Agilex 25 FPGAs deliver a high-performance fabric and embedded compute with optimized I/O, transceivers and peripherals for applications like 4K/8K video processing, drones and low-latency sensors." That is the only Agilex 25 sentence in the release. [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Portfolio page, full Agilex 25 text: "Built for mid-range systems, Agilex 25 FPGAs and SoCs combine high-performance programmable fabric embedded compute with an optimized mix of logic, memory, transceivers, and I/O to deliver high performance and power efficiency for applications such as 4K/8K video, drones, and low-latency sensing." The Agilex 25 card links to "Contact Sales >" whereas the Agilex 27 card links to "Learn More >". [vendor marketing] — [Altera Agilex 2X portfolio page](https://www.altera.com/products/fpga/agilex-2x-portfolio)
- Portfolio brief (PB-1025-1.0) table row for Agilex 25: "Designed for: Mid-range FPGA and SoC family balancing high-performance fabric with power efficiency, connectivity, and integration. Key capabilities: High-performance fabric with an optimized mix of logic, memory, transceivers, I/O, and peripherals. Application fit: 4K/8K video processing, drones, and low-latency sensing." The brief carries the caveat "Capabilities and availability vary by family and series." No numbers appear anywhere in the two-page brief. [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- The URL https://www.altera.com/products/fpga/agilex/agilex-25 returns an Altera "404 Error Page" (checked in a browser on 31 Oct 2026). [observation] — [Altera 404](https://www.altera.com/products/fpga/agilex/agilex-25)
- A dump of the docs.altera.com document catalog (24,665 entries via https://docs.altera.com/api/khub/documents, retrieved 31 Oct 2026) contains exactly seven documents whose title or filename matches Agilex 2X/27/25/23/22, and all seven are Agilex 27 or portfolio-level: Agilex 27 White Paper; Agilex 27 FPGA and SoC Product Brief; Agilex 27 Product Table; Agilex 2X FPGA and SoC Portfolio Brief; three Agilex 27 solution briefs (deterministic Physical AI systems; deterministic RF and photonic signal processing; Giga-MIMO 6G radio units). Zero documents mention Agilex 25, 23, or 22 in the title. [observation] — [docs.altera.com catalog API](https://docs.altera.com/api/khub/documents)
- By contrast Agilex 27 does have a published product table: 14 product lines A27F008 through A27F180, 0.866M to 17.6M LEs, 274,190 to 5,683,872 ALMs, M20K blocks 2,040 to 42,096, M80K blocks 806 to 14,032, total block memory 103 to 1,918 Mb, AI Tensor DSP blocks 1,096 to 21,048, INT8 TOPS 63 to 1,211, GT 256 Gbps channels 0 to 32, GX 128 Gbps channels 16 to 176. Marked "Preliminarily and Subject to Change", version 2026.10.28. [vendor spec, preliminary] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- Agilex 27 product brief, "Learn More" list, points to an Agilex 27 Device Overview, product page, Product Table and Architecture White Paper, and says "For Memory (M-Series) or Direct RF (RF-Series) specifications, contact Sales for advance details." No equivalent list exists for Agilex 25. [vendor spec] — [Agilex 27 Product Brief PDF](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content)
- Trade press uniformly reports no Agilex 25 specifications. ServeTheHome (Patrick Kennedy, 28 Oct 2026) identifies Agilex 25 only as "mid-range" between Agilex 27 and the value Agilex 22/23. [press] — [ServeTheHome](https://www.servethehome.com/?p=106363)
- Converge Digest (Jim Carroll, 29 Oct 2026): Agilex 25 "targets embedded processing and high-speed sensing"; the article notes DSP, memory, process node and packaging data "are not disclosed in this roadmap announcement." [press] — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- TechTimes (Mark Rutherford, 29 Oct 2026): Agilex 25 "targets high-resolution video processing, drone systems, and low-latency sensor applications"; Agilex 25/23/22 timelines "not specified". [press] — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Embedded.com paraphrases Altera as positioning Agilex 25 for applications "that need a high-performance fabric and also a greater emphasis on embedded compute, but don't need the highest levels of bandwidth." [press] — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)

### Inferences
- The portfolio page and brief both call Agilex 25 "FPGAs and SoCs", so SoC (HPS) variants are planned, but the processor type is not stated for Agilex 25 (Agilex 27's dual Cortex-A720 plus dual Cortex-A520 is specified only for Agilex 27).
- "Optimized mix of logic, memory, transceivers, and I/O" and "don't need the highest levels of bandwidth" imply fewer and/or slower transceivers than Agilex 27, but no figure is published, and inferring one from Agilex 27's table would be speculation.
- The Agilex 27 pattern (brief, device overview, product table, white paper all published in launch week) suggests Agilex 25 documents will appear when that family formally launches, which has not happened.

### Gaps
- No LE, ALM, DSP, M20K/M80K, MLAB, transceiver, I/O, PLL, or external memory controller counts for Agilex 25 are published anywhere, vendor or press.
- No Agilex 25 ordering part number prefix (by analogy A27Fxxx) is published.
- No Agilex 25 product page, product brief, device overview, product table, or white paper exists on altera.com or docs.altera.com as of 31 Oct 2026.
- The embedded.com article could not be fetched directly in full; the quote above comes from a fetch summary and should be verified against the article before being quoted in a final report.

## Key question 2: Which DSP architecture does Agilex 25 use, and is any INT8 TOPS or AI figure published?

### Takeaway
Altera has not specified the Agilex 25 DSP block. The portfolio-level documents say "enhanced AI tensor DSP blocks" are part of the Agilex 2X architecture across families, and the Agilex 27 documents name that block the "2nd-Generation AI Tensor DSP Block" with 32 INT8 or 32 block FP16 multipliers per block. Whether Agilex 25 gets the same second-generation block, a derivative, or the Agilex 5 first-generation tensor block is not stated. No Agilex 25 TOPS figure exists.

### Cited Findings
- Press release, portfolio-wide statement: "Enhanced AI tensor DSP blocks accelerate compute in signal processing applications, the latest Arm cores accelerate embedded processing, high-bandwidth connectivity support mainstream and next-generation standards, and end-to-end security protects data and system integrity." This paragraph describes Agilex 2X as a whole, not any one family. [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Portfolio brief, portfolio-wide statement: "Agilex 2X families advance Altera's programmable architecture with 3rd-Gen HyperFlex fabric, ALM innovations, enhanced AI tensor DSP blocks, and architectural optimizations designed to sustain performance and efficiency as designs become more demanding." The brief's "Programmable Architecture Leadership" graphic lists "AI Tensor DSP Blocks: For compute and signal processing" as a shared pillar. It also carries "Capabilities and availability vary by family and series." [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- Agilex 27 product brief, Product Highlights: "2nd-Generation AI Tensor DSP Blocks"; product family table: "Peak DSP TOPS (INT8): Up to 1,211". This is explicitly Agilex 27. [vendor spec] — [Agilex 27 Product Brief PDF](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content)
- Agilex 27 white paper, DSP section: "The Agilex 27 devices' variable DSP blocks provide classic signal processing and AI-oriented compute in one programmable architecture. It supports fixed-point, floating-point, and complex modes, tensor and vector modes, and multiple precision formats." And: "New tensor modes provide 32 INT8 or 32 Block FP16 multipliers per DSP block, and new INT18 and INT32 modes remove the soft logic that complex integer arithmetic previously required. Overall, compute density per DSP block rises 2 to 4 times." [vendor spec] — [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- Agilex 27 white paper, Table 4 (multipliers per DSP block, Agilex 7 vs Agilex 27): INT8 scalar 4 vs 8 (2x); INT8 tensor n/a vs 32 (new); Block FP16 tensor n/a vs 32 (new); Bfloat16 2 vs 4 (2x); FP19 (TF32) 2 vs 3 (1.5x); CINT16 "0.5 + soft logic" vs 2 (4x); INT18 2 vs 4 (2x); CINT18 "0.5 + soft logic" vs 1 (2x); INT32 n/a vs 1 (new); FP16 2 vs 4 (2x); FP32 1 vs 2 (2x). Note the comparison baseline is Agilex 7, not Agilex 5. [vendor spec] — [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- Agilex 27 product table: each AI Tensor DSP block is counted as 4 "18x19 Multipliers" (e.g. A27F180: 21,048 blocks, 84,192 multipliers), and INT8 TOPS works out to roughly 57.5 GOPS per block (A27F180: 1,211 TOPS). The table also lists a "Total Processing Performance (TPP)" metric (A27F180: 16,155) without defining it. [vendor spec, preliminary] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- For comparison, the Agilex 5 D-series product table (version 2026.08.07) calls its block "Variable-precision digital signal processing (DSP) blocks AI-capable", 2 multipliers of 18x19 per block, peak INT8 45.22 to 152.62 TOPS across A5D 051 to A5D 160. [vendor spec] — [Agilex 5 D-Series Product Table PDF](https://docs.altera.com/api/khub/documents/u3IUzUncU9s_fK0pS0LseA/content)
- The Agilex 5 tensor block (first generation) generates "the sum of twenty 8x8-bit multiplications within one DSP/tensor block" in INT8 tensor mode, per Intel's architecture brief. [vendor spec] — [Agilex 5 Enhanced DSP with AI Tensor Block architecture brief](https://cdrdv2-public.intel.com/776602/agilex-5-fpgas-enhanced-dsp-with-ai-tensor-block-architecture-brief.pdf)
- The Agilex 27 white paper contains no mention of Agilex 25, 23, or 22 at all (full-text search of the 16-page PDF). [observation] — [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)

### Inferences
- The most defensible reading is that "enhanced AI tensor DSP blocks" across Agilex 2X refers to the same second-generation block family documented for Agilex 27, since the portfolio brief uses the same adjective ("enhanced") for the portfolio that the Agilex 27 brief pairs with "2nd-Generation". But Altera has not said so for Agilex 25, and the brief's "vary by family and series" caveat leaves room for a reduced-mode or different-ratio block in the mid-range part. Treat "Agilex 25 uses the Gen-2 tensor DSP" as likely but unconfirmed.
- If Agilex 25 does share the Agilex 27 block, a per-block INT8 rate near the Agilex 27 figure would follow, but device-level TOPS depends on block count and fabric clock, neither of which is published for Agilex 25. No Agilex 25 TOPS should be quoted.

### Gaps
- Agilex 25 DSP block type: not published.
- Agilex 25 INT8 TOPS, block count, supported precisions (including whether Block FP16 tensor mode is present): not published.
- No DSP user guide exists yet for any Agilex 2X family; the only DSP detail is in the Agilex 27 white paper (Table 4) and the Agilex 27 product table.
- Whether "Block FP16" in the Agilex 27 white paper corresponds to an OCP MX-style shared-exponent format or an Altera-specific block floating point is not defined in the sources found.

## Key question 3: Memory (M20K/M80K), HyperFlow NoC, process node, packaging, external memory, power, HPS/SoC options for Agilex 25

### Takeaway
None of these are published for Agilex 25. M80K and HyperFlow are documented only for Agilex 27. The portfolio-level text promises "hardened memory controllers", "Embedded Arm SoC processing", and hardened PCIe/Ethernet/MIPI across the portfolio without saying which family gets what. Process node and packaging are not disclosed for any Agilex 2X family, including Agilex 27.

### Cited Findings
- Portfolio brief, portfolio-wide: "Embedded Arm SoC processing, hardened memory controllers, high-speed and broad I/O voltage standards, plus hardened PCIe, Ethernet, and MIPI place common system functions where they add the most value". Also: "Arm cores across SoC families, Nios V embedded soft processors, common security framework, PQC secure boot and functional-safety capabilities where supported". [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- Press release, portfolio-wide: "The portfolio also shares common security and embedded software foundations, including Arm-based hard processors and Nios V soft processors, post-quantum-cryptography-ready secure boot, and shared functional-safety practices." [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Press release attributes HyperFlow specifically to Agilex 27: "Agilex 27 FPGAs feature a new full-chip, distributed HyperFlow data network, delivering multi terabit-per-second data movement throughout the FPGA without consuming soft logic resources or introducing routing congestion." The portfolio page likewise: "Combining the 3rd-generation HyperFlex fabric architecture with the HyperFlow data network, Agilex 27 is designed to drive and sustain throughput". Neither document attaches HyperFlow to Agilex 25. [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x); [Altera portfolio page](https://www.altera.com/products/fpga/agilex-2x-portfolio)
- The portfolio brief's list of portfolio-wide architecture features ("3rd-Gen HyperFlex fabric, ALM innovations, enhanced AI tensor DSP blocks, and architectural optimizations") does not include HyperFlow or M80K. [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- Agilex 27 white paper on M80K: "Agilex 27 devices retains the proven M20K embedded memory block and adds a new M80K embedded memory block, a new block with four times the capacity of M20K". And: "M80K adds 80-bit width and 4x depth at common widths". HyperFlow is "comprised of hardened network-on-chip (NoC) subsystems with dedicated data movers" and runs "through the M20K/M80K memory column, so memory attaches to the network directly." [vendor spec] — [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- Agilex 27 product table HyperFlow row, "B'width Fabic (Slice) Tb/s": 6.80 (A27F008 to A27F018), 11.89 (A27F027/031), 15.29 (A27F045/054), 13.59 (12.44) for A27F070 and larger. [vendor spec, preliminary] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- Agilex 27 external memory (not Agilex 25): "DDR5 and LPDDR4/5X/6 with IME memory controllers" and "Memory in Package options"; white paper: "DDR5 and LPDDR5/5X memory controllers with LPDDR6 on select devices". Product table: smaller devices (A27F008 to A27F031) list "DDR5, LPDDR4, LPDDR5/5X"; A27F045 and up list "DDR5, LPDDR5/5X, LPDDR6". [vendor spec] — [Agilex 27 Product Brief PDF](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content); [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- Agilex 27 HPS (not Agilex 25): "Dual Arm Cortex-A720 and Dual Arm Cortex-A520 with peripherals"; product table: "up to 2.3GHz with 64KB I/D L1 cache, 256K L2 cache, and up to 2MB L3 shared cache"; white paper: Armv9.2, A720 "targeted for up to 2.5 GHz", A520 "targeted for up to 1.85" GHz. The two Altera documents disagree on the A720 ceiling (2.3 GHz in the product table vs 2.5 GHz in the white paper). [vendor spec] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content); [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- Process node: the Agilex 27 white paper, product brief, product table, portfolio brief, press release and portfolio page contain no foundry name and no node designation (full-text searches for "nm", "foundry", "18A", "Intel 3", "TSMC" return nothing). Trade press (ServeTheHome, Converge Digest, TechTimes, SiliconANGLE) likewise report no node. [observation] — [Agilex 27 White Paper PDF](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content); [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- For reference, Agilex 5 is described by Altera as "Built with Intel 7 technology and second-generation Hyperflex FPGA architecture". [vendor spec] — [Agilex 5 Device Overview](https://docs.altera.com/r/docs/762191/current/agilex-5-fpgas-and-socs-device-overview)
- Power: the only quantified power claim is Agilex 27's "1.8X gen-over-gen performance/watt improvements" versus Agilex 7 (white paper: ">1.8X performance-per-watt advantage versus Agilex 7"). TechTimes notes these are "Altera's own internal figures". No Agilex 25 power or performance/watt figure exists. [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x); [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Packaging: the Agilex 27 product table has a "Package Code (Balls)" section (page 4) but no Agilex 25 package data exists. The white paper mentions "UCIe for chiplets and memory in-package" for Agilex 27 only. [vendor spec] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)

### Inferences
- 3rd-generation HyperFlex is the one architectural feature Altera attributes to the whole portfolio in writing, so Agilex 25 almost certainly has it. M80K and HyperFlow are attributed only to Agilex 27; assuming them for Agilex 25 would go beyond the published record.
- "FPGAs and SoCs" for Agilex 25 plus "Arm cores across SoC families" implies an Arm HPS option. Whether it is the A720/A520 cluster or a smaller core (Agilex 5 uses Cortex-A76/A55, Agilex 3 Cortex-A55) is not stated.
- Agilex 25's stated video, drone and sensing focus plus the portfolio-wide "hardened ... MIPI" line suggests MIPI C-PHY/D-PHY will be present, but this is not stated for Agilex 25.

### Gaps
- Agilex 25 M80K presence, HyperFlow presence and bandwidth, process node, package list, external memory standards, power targets, HPS core type and count: all unpublished.
- Process node and foundry are unpublished for the entire Agilex 2X portfolio, Agilex 27 included.

## Key question 4: Timeline (software early access, engineering samples, production)

### Takeaway
Altera has published no dates of any kind for Agilex 25. The only dated milestones belong to Agilex 27 (Quartus Prime early access mid-November 2026, engineering sample silicon H2 2027) and to QuartusIQ (available now in Quartus Prime 26.3). No production date is given for any Agilex 2X family.

### Cited Findings
- Press release, Availability section (verbatim): "Quartus Prime software support for Agilex 27 FPGAs will be available to early access customers starting in mid-November. Engineering sample silicon for Agilex 27 FPGAs is expected in the second half of 2027. QuartusIQ, the AI expert companion for Quartus Prime software, is now available for download as part of Quartus Prime version 26.3. QuartusIQ can be used across Altera's FPGA portfolio supported within Quartus Prime Pro edition software." No other family is mentioned in this section. [vendor spec] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Press release: Agilex 2X is announced "with Agilex 27 as its first family"; "Agilex 27 FPGAs are the first family to launch within the Agilex 2X portfolio". [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Portfolio brief caveat: "Capabilities and availability vary by family and series." [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- TechTimes: "Agilex 25, 23, 22 timelines: Not specified." [press] — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- Converge Digest: "No production timelines ... are mentioned." [press] — [Converge Digest](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- ServeTheHome: QuartusIQ availability "current quarter (Q4 2026)"; Agilex 27 engineering samples H2 2027. [press] — [ServeTheHome](https://www.servethehome.com/?p=106363)
- Document dates on docs.altera.com: Portfolio Brief metadata date 2026-10-26 (version 1.0); Agilex 27 Product Brief 2026-10-29 (version 1.0); Agilex 27 Product Table "Version 2026.10.28". [observation] — [Portfolio Brief landing](https://docs.altera.com/v/u/docs/r133175/agilex-2x-fpga-and-soc-portfolio-brief); [Agilex 27 Brief landing](https://docs.altera.com/v/u/docs/r594095/agilex-27-fpga-and-soc-product-brief)

### Inferences
- Because Agilex 27 is explicitly "first" and its own silicon is not expected until H2 2027, Agilex 25 silicon is presumably later than H2 2027, but Altera has not said this and no press outlet reports a date.
- Quartus Prime 26.3 does not add Agilex 25 device support; even Agilex 27 support is gated behind an early access program starting mid-November 2026.

### Gaps
- Agilex 25 Quartus Prime support date, early access program, engineering sample date, production date: all unpublished.
- No production or volume-availability date is published for any Agilex 2X family.

## Key question 5: Positioning relative to Agilex 5 D/E-series, Agilex 3, and competitors (AMD Versal AI Edge Gen 2, Lattice Avant, Microchip PolarFire 2)

### Takeaway
Altera positions Agilex 25 as the mid-range tier of Agilex 2X, in the slot Agilex 5 occupies in the current lineup, but has published no direct Agilex 25 vs Agilex 5 comparison and no competitor comparison. No press or analyst piece found through 31 Oct 2026 compares Agilex 25 to Versal AI Edge Gen 2, Lattice Avant, or PolarFire 2.

### Cited Findings
- Portfolio page: "The Agilex 2X portfolio spans power- and cost-optimized, mid-range, and high-performance programmable devices"; Agilex 25 is "Built for mid-range systems". Agilex 23 is "Built for intelligent edge and control applications" (robotics, industrial automation, medical, automotive, vision) and Agilex 22 "Built for cost- and power-sensitive systems" (root of trust, BMC, motor control, system management). [vendor marketing] — [Altera portfolio page](https://www.altera.com/products/fpga/agilex-2x-portfolio)
- Portfolio brief frames the four families as spanning "I/O-centric control through digital AI infrastructure" and describes Agilex 2X as building "on the proven Agilex architecture". It does not map families to Agilex 3/5/7/9 predecessors. [vendor marketing] — [Agilex 2X Portfolio Brief PDF](https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content)
- The only explicit predecessor mapping is Agilex 27 to Agilex 7: "Agilex 27 FPGAs build on the architecture leadership of the prior generation Agilex 7 FPGAs". [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Current Agilex 5 D-series (the existing mid-range) for reference: A5D 051 to A5D 160, 515,070 to 1,616,600 LEs, 174,600 to 548,000 ALMs, 2,563 to 8,010 M20K blocks (50.06 to 156.45 Mb), 1,472 to 4,968 AI-capable variable-precision DSP blocks, peak INT8 45.22 to 152.62 TOPS. [vendor spec] — [Agilex 5 D-Series Product Table PDF](https://docs.altera.com/api/khub/documents/u3IUzUncU9s_fK0pS0LseA/content)
- Agilex 5 uses Arm Cortex-A76/A55 in SoC variants; Agilex 3 uses dual Cortex-A55. [secondary] — [Wikipedia: Agilex](https://en.wikipedia.org/wiki/Agilex)
- The smallest Agilex 27 device (A27F008, 866K LEs, 1,096 tensor DSP blocks, 63 INT8 TOPS) already overlaps the upper Agilex 5 D-series in logic count, which is roughly where Agilex 25 would be expected to sit. This overlap is an observation from the two tables, not an Altera statement. [vendor spec] — [Agilex 27 Product Table PDF](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- SiliconANGLE (John Furrier, 28 Oct 2026) frames the announcement around AI developers and programmable computing; it contains no competitor comparison or analyst quote. [press] — [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)
- TechTimes draws an analogy between HyperFlow and Nvidia's NVLink as a dedicated transport layer; this is the author's comparison, not Altera's. [press] — [TechTimes](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)
- CEO quote on positioning, Raghib Hussain: "Agilex 2X is designed to give customers one platform that delivers the performance and density the most complex Digital AI and aerospace and defense systems demand, and scales down to the low power and small footprint the intelligent edge requires." [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)
- Altera self-description in the release: "the largest pure-play FPGA provider with a full-spectrum portfolio". [vendor marketing] — [Altera press release](https://www.altera.com/newsroom/agilex-2x)

### Inferences
- Agilex 25 is the likely successor slot to Agilex 5 D-series (video, sensing, drones match Agilex 5's video/industrial/robotics messaging), and Agilex 23 appears to inherit the Agilex 5 E-series/Agilex 3 embedded-control role (functional safety, robotics, automotive). Altera has not stated either mapping.
- Nothing in the record says whether Agilex 5 and Agilex 3 are being replaced or will continue alongside Agilex 2X.

### Gaps
- No Altera statement maps Agilex 25 to Agilex 5 D-series or E-series, or states resource scaling versus Agilex 5.
- No vendor, press, or analyst comparison of Agilex 25 to AMD Versal AI Edge Gen 2, Lattice Avant, or Microchip PolarFire 2 was found through 31 Oct 2026. Searches for Moor Insights, Tirias, TechInsights, and SemiAnalysis commentary on Agilex 2X returned nothing on Agilex 25 (the TechInsights "Altera Extends Agilex Brand to Edge Applications" blog is about the earlier Agilex 3 launch, not Agilex 2X).
- EE Times (US), Electronic Design, EDN, HPCwire, The Register, cnx-software and Hackster coverage of Agilex 2X was not located by search through 31 Oct 2026. The EE Times Japan article surfaced by search is dated 28 Oct 2025 and covers Agilex 5 D-series, not Agilex 2X.

## Summary of what is explicitly not published for Agilex 25 (for the gaps section of the report)

- Product page (URL 404), product brief, device overview, product table, white paper, DSP user guide, any user guide.
- Any resource count: LEs, ALMs, DSP blocks, M20K/M80K/MLAB, transceiver channels or rates, I/O counts, PLLs.
- DSP block generation and INT8 or any TOPS figure.
- M80K presence; HyperFlow NoC presence or bandwidth.
- Process node and foundry (also unpublished for Agilex 27 and the whole portfolio).
- Package options and ball counts.
- External memory standards and controller counts.
- Power or performance/watt figures.
- HPS core type, count, or clock.
- Ordering part number scheme.
- Quartus Prime support version or date, early access date, engineering sample date, production date.
- Any vendor or third-party comparison to Agilex 5, Agilex 3, or competing mid-range FPGAs.

What is published for Agilex 25, in full: mid-range FPGA and SoC family; high-performance fabric with "an optimized mix of logic, memory, transceivers, I/O, and peripherals"; embedded compute; applications 4K/8K video processing, drones, low-latency sensing; shares the portfolio-wide Quartus Prime Pro and QuartusIQ flow, Arm-based hard processors and Nios V soft processors, PQC-ready secure boot, and functional-safety practices "where supported".
