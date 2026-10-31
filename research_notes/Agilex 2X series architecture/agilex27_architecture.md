# Altera Agilex 27 (Agilex 2X portfolio) silicon architecture and published device resource tables

Scope note: everything below was published on or before 31 October 2026. Agilex 27 was announced 28 Oct 2026 at Altera's Innovators Day; engineering samples are not expected until H2 2027, so every vendor number is marked "preliminary and subject to change" by Altera itself. I label each finding as (spec) = Altera technical document, (marketing) = Altera press release/product page/brief, or (press) = third-party reporting. Where a number cannot be found I say so in Gaps rather than estimate.

Primary Altera documents located (all live on docs.altera.com; altera.com itself is behind Akamai bot protection and returns 403 to scripted fetches, so the product/newsroom pages were read through a real browser):

| Document | Doc ID / version | URL |
|---|---|---|
| Agilex 27 FPGAs and SoCs Device Overview (DITA book, 14 chapters) | Version 2026.10.28, "Initial release"; Fluid Topics map m9NQizMY2AroL9DbIEijmQ; reader path /r/docs/d791593 | https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview |
| Agilex 27 FPGA and SoC Product Table (4 pp PDF) | Gen-1088-1.0, "Version 2026.10.28", footer "Preliminarily and Subject to Change" | https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content |
| White paper "Engineered for Throughput: How Agilex 27 FPGAs Sustain System Performance in the Age of Exponential Data Growth" (16 pp) | WP-01358-1.0; authors Ilya Ganusov (Chief Architect) and Graham Baker (Sr. Product Line Manager) | https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content |
| Agilex 27 FPGA and SoC Product Brief (2 pp) | PB-1026-1.0 | https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content |
| Agilex 2X FPGA and SoC Portfolio Brief (2 pp) | PB-1025-1.0; last edition 2026-10-26, published 2026-10-28 | https://docs.altera.com/api/khub/documents/IjU1pWhQ3R1a7ET~TcQspg/content |
| Solution brief "1.6T FPGA-Based AI NIC and DPU for Evolving Ethernet Standards" (4 pp) | SB-1213-1.0 | https://docs.altera.com/api/khub/documents/MJjESyrW__pqrR1DLbgjCQ/content |
| Solution brief "Build an Efficient, High-Performance Giga-MIMO 6G RU" (3 pp) | SB-1215-1.0 | https://docs.altera.com/api/khub/documents/T4~~UVWU3Jd9rgKAZjWVZA/content |
| Solution brief "Deterministic RF & Photonic Signal Processing with Agilex 27 FPGAs" (3 pp, not read in detail) | documentId YwnS9n0mptHpCzpubGa9RQ | https://docs.altera.com/api/khub/documents/YwnS9n0mptHpCzpubGa9RQ/content |
| Solution brief "Build Deterministic Physical-AI Systems with Agilex 27 Devices" (3 pp, not read in detail) | documentId YDCk~6Aqx7lbFuofXOUg7A | https://docs.altera.com/api/khub/documents/YDCk~6Aqx7lbFuofXOUg7A/content |
| Press release "Altera Announces Agilex 2X..." | San Jose, 28 Oct 2026 | https://www.altera.com/newsroom/agilex-2x |
| Agilex 2X portfolio page | n/a | https://www.altera.com/products/fpga/agilex-2x-portfolio |
| Agilex 27 product page (incl. FAQ) | n/a | https://www.altera.com/products/fpga/agilex-2x-portfolio/agilex-27 |

Individual Device Overview chapters can be pulled as HTML from `https://docs.altera.com/api/khub/maps/m9NQizMY2AroL9DbIEijmQ/topics/<contentId>/content`; the contentIds that matter here are `_em3M0BUjfe6BBAfVUP1LQ` (2.3 AI Tensor DSP Blocks), `qXTLq2Ip8cnNe4Rc536OtA` (2.5 Internal Embedded Memory), `bG3FlxRESiU~YbGQ4xdCSw` (2.1 HyperFlow Data Network), `K7wQXSSDNADkrl10W6N8vg` (2.2 ALM), `C_ugCKqsAs0wEMyEajaVIw` (4. External Memory Interface), `kR7zZPKZ69idijwtkYH7xw` (5. Transceivers), `KJDyrRH6TB7nTaRadcwzEQ` (12. Power Management), `DRcqkvsK2vb3Bo6HuZ2Qeg` (1.2 Key Features).

## Key question 1: What does Altera document about the Agilex 27 DSP block's tensor mode (dot-product length, columns, numeric formats, FP8/MXFP/block floating point)?

### Takeaway
Altera's own documents say the second-generation "AI Tensor DSP block" has two tensor columns per block, each computing a 16-element dot product (32 INT8 or 32 "Block FP16" multipliers per block, accumulating to INT32 or FP32). That is a step up from Agilex 5's two 10-element columns. The supported-format list is INT8/INT9/INT16/INT32, BFLOAT16, "BlockFP16", FP16, FP32, TF32 (called FP19 in one table), CINT16, CINT18. No Altera document published by 31 Oct 2026 mentions FP8, FP4, MXFP/microscaling, OCP MX, or shared-exponent block formats by name; "BlockFP16" is the only block-floating-point hint and it is never defined.

### Cited Findings
- (spec) Device Overview Table 8 "AI Tensor DSP Block Configurations", row INT8 Tensor: "Two tensor columns are integrated in one DSP block, with INT32 or FP32 output/accumulation." Target application: "Tensor dot products of 16-element vectors computation and matrix multiplication." — [Agilex 27 Device Overview, 2.3 AI Tensor DSP Blocks](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Same section: "second-generation AI tensor DSP blocks with fixed-point, floating-point, complex, tensor, and vector modes"; "Multiply, add, subtract, accumulate, and cascade operations for high-throughput datapaths"; "Tensor and vector modes added to increase compute density"; "These enhancements increase arithmetic density per DSP block by two to four times compared to Agilex 7 FPGAs and SoCs." — [Agilex 27 Device Overview, 2.3](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 3 "Feature Summary", AI and DSP Blocks row: "Second-generation AI DSP blocks with fixed-point, floating-point, complex, tensor, and vector modes. Broad set of integer and floating-point data types: INT8, INT9, INT16, and INT32. BFLOAT16 and BlockFP16. FP16, FP32, and TF32. CINT16 and CINT18." — [Agilex 27 Device Overview, 1.4 Summary of Features](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) White paper, AI Tensor DSP Blocks section: "New tensor modes provide 32 INT8 or 32 Block FP16 multipliers per DSP block, and new INT18 and INT32 modes remove the soft logic that complex integer arithmetic previously required. Overall, compute density per DSP block rises 2 to 4 times." — [WP-01358-1.0, p.10](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper Table 4 "Multipliers per DSP block, Agilex 7 versus Agilex 27 devices" (transcribed; the PDF lays it out as three rows). Columns: workload / precision / Agilex 7 / Agilex 27 / change:
  - AI-oriented, INT8 (scalar): 4 / 8 / 2x
  - AI-oriented, INT8 (tensor): n/a / 32 / New
  - AI-oriented, Block FP16 (tensor): n/a / 32 / New
  - AI-oriented, Bfloat16: 2 / 4 / 2x
  - AI-oriented, FP19 (TF32): 2 / 3 / 1.5x
  - Wireless, CINT16: 0.5 + soft logic / 2 / 4x
  - Wireless, INT18: 2 / 4 / 2x
  - Wireless, CINT18: 0.5 + soft logic / 1 / 2x
  - General purpose, INT32: n/a / 1 / New
  - General purpose, FP16: 2 / 4 / 2x
  - General purpose, FP32: 1 / 2 / 2x
  — [WP-01358-1.0, Table 4, p.10](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Device Overview Table 8, other rows: "9x9 INT: One-sixth of a DSP block"; "FP16 / bfloat16 / TF32: One DSP block supports multiple low-precision floating-point configurations, including up to four FP16/bfloat16 multipliers"; "FP16 complex: One DSP block in the new native complex floating-point mode. Legacy implementations may use two blocks"; "18x19 complex INT: One DSP block"; "27x27 INT: One-half of a block per independent multiplier. Supports a sum of two 27x27 multipliers in one block"; "36x36 INT: One full DSP block. This mode produces a 72-bit result"; "54x54 INT: Four variable-precision DSP blocks with external adder." — [Agilex 27 Device Overview, 2.3](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) White paper Figure 11 describes the three mapping patterns: "FIR filters cascade DSP blocks down a column, FFTs place DSP blocks at the twiddle multipliers, and matrix multiplication uses a systolic DSP array whose partial sums cascade down." — [WP-01358-1.0, p.9-10](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Product table: "18x19 Multipliers" are listed at exactly 4x the "AI Tensor DSP Blocks" count for every device (e.g. A27F008: 1,096 blocks / 4,384 multipliers; A27F180: 21,048 / 84,192). — [Agilex 27 Product Table Gen-1088-1.0](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- (spec) Giga-MIMO solution brief: "a 4x increase in complex INT16 multiplication performance compared with Agilex 7, with each DSP block capable of performing two complex INT16 multiplications." — [SB-1215-1.0, p.2](https://docs.altera.com/api/khub/documents/T4~~UVWU3Jd9rgKAZjWVZA/content)
- (spec) Peak INT8: Device Overview Key Features table says "Peak DSP (INT8): 1,212 TOPS"; product brief says "Peak DSP TOPS (INT8): Up to 1,211"; product table gives 1,211 for A27F180. — [Device Overview 1.2](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [PB-1026-1.0](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content); [Product Table](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- (spec, context only, previous generation) Agilex 5's DSP user guide describes the earlier tensor block as "two DOT product vector engines in each column" where "The DOT engine computes the fixed-point product of 10 individual 8-bit data inputs and 10 pre-loaded 8-bit buffers, and sums all of the results together", and the Agilex 5 block floating-point tensor mode "uses an 8-bit shared exponent per 10-element vector operand and accumulates results in fp32" (20 INT8 multiplies per block). This is the Agilex 5 baseline, not an Agilex 27 statement. — [Agilex 5 Variable Precision DSP Blocks User Guide, tensor mode](https://intel.com/content/www/us/en/docs/programmable/813968/24-1/tensor-mode.html); [Agilex 5 Enhanced DSP with AI Tensor Block architecture brief](https://cdrdv2-public.intel.com/776602/agilex-5-fpgas-enhanced-dsp-with-ai-tensor-block-architecture-brief.pdf)
- (marketing) Press release: "Enhanced AI tensor DSP blocks accelerate compute in signal processing applications." No numeric format named. — [Altera newsroom, 28 Oct 2026](https://www.altera.com/newsroom/agilex-2x)
- (press) None of the trade coverage read (ServeTheHome, Embedded.com, Converge Digest, SiliconANGLE, TechTimes, ENGtechnica, inelectronics) gives any DSP format detail beyond "AI tensor DSP blocks". ServeTheHome explicitly omits DSP formats. — [ServeTheHome, Patrick Kennedy, 28 Oct 2026](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)

### Inferences
- 32 INT8 multipliers per block with "two tensor columns" and "16-element vectors" is internally consistent: 2 columns x 16 = 32. That is 1.6x the Agilex 5 block (2 x 10 = 20), and the Agilex 5 pattern of two dot engines per column was not restated for Agilex 27, so column-internal structure beyond "16-element dot product" is not documented.
- The TOPS column of the product table divides out to a near-constant implied clock: 1,211e12 / (21,048 blocks x 32 mult x 2 ops) = ~899 MHz for A27F180, and 63e12 / (1,096 x 64) = ~898 MHz for A27F008. So the published INT8 TOPS assume the full 32-multiplier tensor mode at roughly 900 MHz. Altera does not state the clock; this is my arithmetic.
- "Block FP16 (tensor)" having the same 32 multipliers per block as INT8 tensor strongly suggests a block-floating-point mode where the 16-element vector shares one exponent and the mantissa multiplies run on the INT8 hardware (the same construction Agilex 5 used with a per-10-element shared exponent). Altera never says this for Agilex 27, and the word "BlockFP16" is not defined anywhere, so treat as inference.
- The white paper's "INT8 (scalar) 8 per block" and the Device Overview's "9x9 INT = one-sixth of a block" (i.e. 6 per block) disagree unless 8-bit scalar and 9x9 modes are distinct packings. Not resolvable from published material.
- The "two to four times" density claim lines up with Table 4: 2x for most modes, 4x for CINT16, 1.5x for TF32.

### Gaps
- No Altera document mentions FP8 (E4M3/E5M2), FP6, FP4, INT4, MXFP, OCP Microscaling, or "shared exponent" for Agilex 27. INT4 is absent from every data-type list. Either unsupported or undisclosed as of 31 Oct 2026; the Agilex 27 DSP user guide is not yet published on docs.altera.com (search returned only the Device Overview, product table, white paper, briefs, and Simics topics).
- Accumulator width beyond "INT32 or FP32 output/accumulation" is not given. No statement on accumulator chaining depth, cascade bus width, or whether tensor-mode results can cascade between blocks (the white paper only says partial sums "cascade down" in the systolic pattern).
- Block FP16 exponent sharing granularity, exponent width, and rounding behavior: undocumented.
- Whether "FP19 (TF32)" is a true 19-bit internal format or a TF32 input mode: undocumented beyond the label.
- DSP block operating frequency: not published (the ~900 MHz figure above is derived, not stated).

## Key question 2: What is the full published Agilex 27 product table (resource counts per device), with document title/version/date?

### Takeaway
The "Agilex 27 FPGA and SoC Product Table" (Agilex 2X Portfolio, Version 2026.10.28, doc code Gen-1088-1.0, every page stamped "Preliminarily and Subject to Change") lists 14 devices from A27F008 (0.866 M LE, 1,096 tensor DSP blocks, 63 INT8 TOPS, 103 Mb block RAM) to A27F180 (17.6 M LE, 21,048 tensor DSP blocks, 1,211 INT8 TOPS, 1,918 Mb block RAM, 24.6 Tb/s transceiver bandwidth). Each device comes in "A" (FPGA) and "B" (SoC) specification options.

### Cited Findings
All rows below are transcribed from page 2 and page 3 of the product table, extracted with coordinate-based table recovery from the PDF and cross-checked against a second row-clustering pass. — [Agilex 27 FPGA and SoC Product Table, Version 2026.10.28, Gen-1088-1.0](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)

Header note on the table: "All parameters listed are maximum values, check against indivdual packages for supported number of I/O." Specification Options row: "A, B" for every device (A = FPGA, B = SoC per the part-number decoder on page 4).

Programmable logic and memory (page 2):

| Device | A27F008 | A27F012 | A27F018 | A27F027 | A27F031 | A27F045 | A27F054 | A27F070 | A27F100 | A27F110 | A27F120 | A27F140 | A27F142 | A27F180 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Logic Elements (M LE) | 0.866 | 1.2 | 1.8 | 2.7 | 3.1 | 4.5 | 5.4 | 7.0 | 10.6 | 11.2 | 12.1 | 14.0 | 14.2 | 17.6 |
| ALMs | 274,190 | 399,672 | 602,784 | 852,067 | 1,002,432 | 1,445,940 | 1,735,128 | 2,265,648 | 3,418,224 | 3,625,037 | 3,885,180 | 4,531,296 | 4,570,800 | 5,683,872 |
| MLAB memory (Mb) | 8 | 11 | 17 | 24 | 28 | 40 | 48 | 63 | 95 | 101 | 108 | 126 | 127 | 158 |
| M20K blocks | 2,040 | 2,928 | 4,416 | 6,569 | 7,728 | 11,083 | 13,300 | 16,632 | 25,464 | 26,611 | 29,152 | 33,264 | 34,296 | 42,096 |
| M20K size (Mb) | 40 | 57 | 86 | 128 | 151 | 216 | 260 | 325 | 497 | 520 | 569 | 650 | 670 | 822 |
| M80K blocks | 806 | 976 | 1,472 | 2,190 | 2,576 | 3,692 | 4,430 | 5,544 | 8,488 | 8,870 | 9,717 | 11,088 | 11,432 | 14,032 |
| M80K size (Mb) | 63 | 76 | 115 | 171 | 201 | 288 | 346 | 433 | 663 | 693 | 759 | 866 | 893 | 1,096 |
| Total block memory (Mb) | 103 | 133 | 201 | 299 | 352 | 505 | 606 | 758 | 1,160 | 1,213 | 1,329 | 1,516 | 1,563 | 1,918 |
| HyperFlow Data Network, "B'width Fabic (Slice) Tb/s" | 6.80 | 6.80 | 6.80 | 11.89 | 11.89 | 15.29 | 15.29 | 13.59 (12.44) | 13.59 (12.44) | 13.59 (12.44) | 13.59 (12.44) | 13.59 (12.44) | 13.59 (12.44) | 13.59 (12.44) |
| Fabric PLL | 3 | 3 | 3 | 7 | 7 | 8 | 8 | 9 | 9 | 9 | 9 | 18 | 9 | 18 |
| HSIO PLL | 3 | 3 | 3 | 7 | 7 | 8 | 8 | 9 | 9 | 9 | 9 | 9 | 9 | 18 |
| MSIO PLL | 3 | 3 | 4 | 6 | 6 | 4 | 4 | 4 | 8 | 8 | 12 | 8 | 12 | 12 |

DSP (page 2):

| Device | A27F008 | A27F012 | A27F018 | A27F027 | A27F031 | A27F045 | A27F054 | A27F070 | A27F100 | A27F110 | A27F120 | A27F140 | A27F142 | A27F180 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| AI Tensor DSP Blocks | 1,096 | 1,464 | 2,208 | 3,284 | 3,864 | 5,540 | 6,648 | 8,316 | 12,732 | 13,306 | 13,718 | 16,632 | 17,148 | 21,048 |
| 18x19 Multipliers | 4,384 | 5,856 | 8,832 | 13,138 | 15,456 | 22,160 | 26,592 | 33,264 | 50,928 | 53,222 | 54,874 | 66,528 | 68,592 | 84,192 |
| INT8 TOPS | 63 | 84 | 127 | 189 | 222 | 318 | 382 | 478 | 732 | 766 | 790 | 957 | 987 | 1,211 |
| "Total Processing Performance (TPP)" (unit not stated) | 839 | 1,121 | 1,694 | 2,517 | 2,961 | 4,247 | 5,096 | 6,377 | 9,765 | 10,213 | 10,533 | 12,766 | 13,167 | 16,155 |

I/O, external memory, transceivers (page 2):

| Device | A27F008 | A27F012 | A27F018 | A27F027 | A27F031 | A27F045 | A27F054 | A27F070 | A27F100 | A27F110 | A27F120 | A27F140 | A27F142 | A27F180 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| HSIO (up to 1.1 V) incl. MIPI C-PHY & D-PHY | 273 | 273 | 273 | 637 | 637 | 784 | 784 | 882 | 882 | 882 | 882 | 1,764 | 882 | 1,764 |
| MSIO (up to 1.8 V / LVDS pairs) incl. MIPI D-PHY | 39 | 39 | 52 | 78 | 78 | 52 | 52 | 52 | 104 | 104 | 156 | 104 | 156 | 156 |
| Memory device standards | DDR5, LPDDR4, LPDDR5/5X (A27F008 to A27F031) | | | | | DDR5, LPDDR5/5X, LPDDR6 (A27F045 to A27F180) | | | | | | | | |
| DDR memory controllers x32 incl. hard IME | 3 | 3 | 3 | 7 | 7 | 8 | 8 | 9 | 9 | 9 | 9 | 18 | 9 | 18 |
| Max DDR5 (x32) / LP4/5 (x16) | 3/6 | 3/6 | 3/6 | 7/14 | 7/14 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Max DDR5 (x40) / LP5 (x16) / LP6 (x48) | 0 | 0 | 0 | 0 | 0 | 8/8/8 | 8/8/8 | 9/9/9 | 9/9/9 | 9/9/9 | 9/9/9 | 9/9/9 | 9/9/9 | 9/9/9 |
| Max memory bandwidth (Gbps) | 922 | 922 | 922 | 2,150 | 2,150 | 4,375 | 4,375 | 4,921 | 4,921 | 4,921 | 4,921 | 9,843 | 4,921 | 9,843 |
| GT transceiver channels (256 Gbps) | 0 | 0 | 0 | 0 | 0 | 8 | 8 | 0 | 16 | 0 | 32 | 0 | 32 | 16 |
| GX transceiver channels (128 Gbps) | 16 | 16 | 16 | 48 | 48 | 48 | 48 | 80 | 96 | 160 | 112 | 160 | 112 | 176 |
| GS transceiver channels (32 Gbps) | 0 | 0 | 16 | 0 | 0 | 16 | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Max transceiver bandwidth (Gbps) | 2,048 | 2,048 | 2,560 | 6,144 | 6,144 | 8,704 | 8,704 | 10,240 | 14,336 | 20,480 | 18,432 | 20,480 | 18,432 | 24,576 |

Hard IP subsystem blocks (page 3):

| Device | A27F008 | A27F012 | A27F018 | A27F027 | A27F031 | A27F045 | A27F054 | A27F070 | A27F100 | A27F110 | A27F120 | A27F140 | A27F142 | A27F180 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| PCIe 6.0 x8, bifurcatable (RP/EP) incl. IDE hard IP | 1 | 1 | 1 | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| PCIe 7.0 x8 (PCIe 6.0 x16), bifurcatable (RP/EP) incl. IDE hard IP / Ethernet 8x100GbE bifurcatable MAC incl. hard IP | 0 | 0 | 0 | 0 | 0 | 2 | 2 | 3 | 3 | 6 | 3 | 6 | 3 | 6 |
| Ethernet 800GbE, bifurcatable incl. hard MACsec IP | 1 | 1 | 1 | 2 | 4 | 4 | 4 | 4 | 4 | 6 | 8 | 8 | 8 | 10 |
| Ethernet 1.6TbE, bifurcatable incl. hard MACsec / L2 parser / PFC IP | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 2 | 0 | 4 | 0 | 4 | 2 |
| Inline Crypto Accelerator (ICA) blocks | 0 | 1 | 2 | 6 | 6 | 10 | 10 | 6 | 14 | 12 | 22 | 12 | 22 | 20 |

Hard processor system (page 3, identical across all devices): "Arm Cortex SoC (Dual A720 + Dual A520) up to 2.3GHz with 64KB I/D L1 cache, 256K L2 cache, and up to 2MB L3 shared cache"; performance "68.2K" DMIPS; subsystem "Multi-channel direct memory access (DMA), 512 KB on-chip RAM w/ECC, USB 3.1 Gen 2 (10G) x1, USB 2.0 OTG x2, TSN MAC x3, UART x3, I2C x5, I3C x2, SPI M x2, SPI S x2, OPSI x1, watchdog x4, Osc Timer x2, SP Timer x2, GPIO x2, SDMMC x2". Secure Device Manager: "Aligned to CNSA 2.0 (PQC) and EU quantum mandates. Security Protocol and Data Model (SPDM 1.4) for device authentication & attestation enabling crypto agility to future proof trust. Physically Unclonable Function (PUF), protected key storage, physical anti-tamper support, side-channel attack resistance & cryptographic services support."

Packages (page 3; cell format "HSIO / MSIO / (HPS & SDM) IO / GX (GbE, PCIe) / GS (NRZ) XCVR channels" for small devices, "HSIO / MSIO / (HPS & SDM) IO / GX XCVR channels / GT XCVR channels" for large):
- U10A, 1085 balls, lidless, 27 x 27 mm, 0.8 mm BGA: A27F008/012: 182/39/90/(8, 8)/0; A27F018: 182/52/90/(8, 8)/0
- U14A, 1440 balls, lidless, 31 x 31 mm, 0.8 mm: A27F008/012: 273/39/90/(8, 8)/0; A27F018: 273/52/90/(8 8)/0
- U17A, 1744 balls, lidless, 38 x 31 mm, 0.8 mm: A27F027/031: 455/78/90/(8, 8)/0
- U18A, 1845 balls, lidless, 35 x 35 mm, 0.8 mm: A27F008/012: 273/39/90/(8, 8)/0; A27F018: 273/52/90/(8, 8)/16
- U22A, 2232 balls, lidless, 42.5 x 35 mm, 0.8 mm: A27F027/031: 455/78/90/(24, 16)/0
- N24A, 2397 balls, lidless, 46 x 46 mm, 0.92 mm: A27F012: 273/39/90/(8, 8)/0; A27F018: 273/52/90/(8, 8)/0; A27F027/031: 637/65/90/(32, 16)/0
- 56 x 56 mm (0.92 mm) lidded: A27F045/054/070: 98/52/90/80/0
- 65 x 55 mm (0.92 mm) lidded: A27F045/054: 392/52/90/64/0; A27F070: 196/52/90/80/0
- 65 x 65 mm (0.92 mm) lidded: A27F070: 882/52/90/80/0; A27F100: 882/104/90/96/16; A27F110/120 (second 65x65 row): 392/104/90/96/16
- A27F140, A27F142, A27F180: "Contact Altera Sales" (no package listed)

Part-number decoder (page 4), example "A27 F 031 A N 24 A E 2L": Portfolio "A2" = Agilex 2X; Tier "7"; Variant "F" = FPGA and SoC; Density 008/012/018/027/031 (M LE); Specification A = FPGA, B = SoC; Ball pitch F = 1.0 grid, N = 0.92 grid, U = 0.8 grid; Package code 10 = 1085 balls, 14 = 1440, 17 = 1744, 18 = 1845, 22 = 2232, 24 = 2397; Package lid A = lidless with stiffener, B = lidded; Operating temp E = 0 to 100 C Tj, I = -40 to 100 C Tj; Speed grade 1V fastest, 2V mid, 2L low power, 3V standard; optional suffix Rn = engineering sample, NL = no-license OPN, FP = FIPS 140-3 L2 certifiable, blank = production (RoHS6).

Cross-checks from other Altera documents:
- (spec) Device Overview Key Features: "Logic density: 866 thousand to 17.6 million logic elements"; "On-chip block memory: Up to 1,918 Mb"; "Peak DSP (INT8): 1,212 TOPS"; "High-speed SERDES: Up to 32x 256 Gbps and up to 176x 128 Gbps." — [Device Overview 1.2](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (marketing) Product brief spec table: "866K - 17.6M Logic Elements", "Up to 1,918Mb", "Up to 1,211" INT8 TOPS, "Up to 32x 256 Gb/s + Up to 176x 128 Gb/s", "Up to 3x PCIe 7.0 + Integrity and Data Encryption", "Up to 4x 1.6 TbE + 10x 800 GbE + MACsec", and separately "Up to 6x 1.6 TbE or 4x 1.6 TbE with MACsec; up to 8x 800 GbE or 4x 800 GbE". — [PB-1026-1.0](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content)
- (marketing) NIC solution brief specs: "Transceivers: up to 32x 256 Gb/s, 176x 128 Gb/s and 16 x 32 Gb/s SerDes"; "up to 1,211 INT8 TOPS of DSP"; "densities ranging from 866K to 17.6M programmable logic elements". Its Figure 1 box reads "AI Inference / DSP Up to 1.271 INT8 TOPS (I-Series)". — [SB-1213-1.0](https://docs.altera.com/api/khub/documents/MJjESyrW__pqrR1DLbgjCQ/content)
- (marketing) Giga-MIMO brief gives a utilization data point on A27F031: "Olympia Bridge Cat B ... at 64TR with 2CC 100MHz can comfortably fit on an A27F031 with an estimated resource usage of 75% ALM, 58% M20K, 52% M80K, and 38% DSP"; "a single A27F031 can accommodate a 128TR 2CC ORAN and Beamformer using 76% ALMs, 49% M20K, 48% M80K, and 44% DSP." — [SB-1215-1.0](https://docs.altera.com/api/khub/documents/T4~~UVWU3Jd9rgKAZjWVZA/content)

### Inferences
- The product table's "Max transceiver bandwidth" row is internally inconsistent with the channel rows for devices A27F070 and up: A27F045 works out exactly (48x128 + 8x256 + 16x32 = 8,704), but A27F180 (176 GX + 16 GT) would be 26,624 Gbps at face value while the table says 24,576 = 192 x 128. For the large devices the row appears to count every channel at 128 Gbps, which may mean GT channels are a mode of a shared lane pool rather than additive lanes. Altera does not explain this.
- The "(12.44)" parenthetical on the HyperFlow bandwidth row for A27F070 and larger is unexplained in the PDF; it may be a secondary (e.g. speed-grade) figure.
- 1,211 vs 1,212 TOPS and the "1.271" in the NIC figure look like rounding/typo variants of one number. The "(I-Series)" label in that figure is the only place the old Agilex 7 "I-Series" naming appears in Agilex 27 material.
- The "A, B" specification options plus the part-number decoder imply every density ships as both FPGA (A) and SoC with Arm HPS (B); the device names (A27F...) use "F" for "FPGA and SoC" rather than the Agilex 7 F/I/M series letters.

### Gaps
- The TPP ("Total Processing Performance") row has no unit or definition anywhere in the four pages. Ratio to INT8 TOPS is about 13.3 across all devices.
- No ordering part numbers (OPNs), speed-grade Fmax, or power figures are published; the table is explicitly "Preliminarily and Subject to Change".
- No package information for A27F140/142/180 ("Contact Altera Sales").
- M-Series (memory-in-package) and RF-Series devices have no product table: "For Memory (M-Series) or Direct RF (RF-Series) specifications, contact Sales for advance details." (product brief).
- No PCIe lane counts or Ethernet port mapping per package.

## Key question 3: What are M80K blocks (capacity, ports, modes, intended use) and how do they differ from M20K?

### Takeaway
M80K is a new 80 Kb (81,920-bit) embedded block RAM with hard ECC, four times the capacity of the M20K it sits beside, offered in 8,192x10, 4,096x20, 2,048x40 and 1,024x80 configurations with the same RAM mode set (single-port, simple dual-port, true dual-port, simple quad-port, FIFO, ROM, shift register). Altera positions it for bulk buffering, deep FIFOs, packet queues, lookup tables and metadata stores, and says it replaces the old practice of ganging four M20Ks behind an output mux; the fabric NoC also runs alongside the M20K/M80K columns.

### Cited Findings
- (spec) Device Overview 2.5: "Agilex 27 FPGAs and SoCs keep the proven Agilex 7 embedded memory architecture and add a new and larger M80K block for applications that need more on-chip memory." — [Device Overview 2.5 Internal Embedded Memory](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 9 "Embedded Memory Blocks":
  - Usage: MLAB "Small, shallow distributed LUTRAM, lookup tables, and local FIFOs"; M20K "General-purpose embedded block RAM for buffers, FIFOs, caches, and scratchpads"; M80K "Deeper, wider bulk storage and high-density on-chip memory."
  - Block size: MLAB "Up to 768 bits per MLAB"; M20K "20 Kb (20,480 bits)"; M80K "80 Kb (81,920 bits)".
  - Configurations: MLAB "32 x 24 or 16 x 48"; M20K "Principal modes: 2,048 x 10. 1,024 x 20. 512 x 40. Supported widths x8, x10, x16, x20, x32, and x40"; M80K "8,192 x 10. 4,096 x 20. 2,048 x 40. 1,024 x 80."
  - Hard ECC: MLAB "No"; M20K "32-bit data + 8-bit ECC"; M80K "32-bit data + 8-bit ECC. 64-bit data + 16-bit ECC."
  - Modes (all block types): "Single-port RAM. Simple dual-port RAM. True dual-port RAM. Simple quad-port RAM. FIFO. ROM. Shift register."
  — [Device Overview 2.5](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 3: "Multi-level on-chip memory hierarchy: M80K, 80 kb with hard error correction code (ECC) support. M20K, 20 kb with hard ECC support. MLAB, 768-bit distributed LUTRAM." (Note the MLAB grows from 640 bits in Agilex 7 to 768 bits.) — [Device Overview 1.4](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); Agilex 7 MLAB = 640 bits per [Agilex 7 Device Overview, Internal Embedded Memory](https://www.intel.com/content/www/us/en/docs/programmable/683458/current/internal-embedded-memory.html)
- (spec) White paper, "Upgraded block memory hierarchy": "Agilex 27 devices provide 15% to 40% higher on-chip memory capacity per device at the same logic element count"; "adds a new M80K embedded memory block, a new block with four times the capacity of M20K (Figure 9). M80K blocks are intended for larger local storage structures: bulk buffering, deep FIFOs, packet queues, lookup tables, and metadata stores." — [WP-01358-1.0, p.6](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper: "M80K blocks are designed to overlap with M20K configurations, keeping the memory system flexible. Previously, an FPGA designer ganged four M20K blocks side by side with a shared address to build a wide memory behind an output multiplexer to create a deep memory. One M80K block provides the same width in a single block, which removes logic and a level of routing from the path." Guidance: "Use M80K blocks for structures larger than a few M20K blocks ... Use M20K and MLAB for smaller, distributed storage close to the logic that uses it. Because the modes overlap, Quartus software can map to either block as the design evolves." Figure 9 caption: "M80K blocks deliver 4x the depth at the same width, or 4x the width at the same depth"; figure annotation "M80K adds 80-bit width and 4x depth at common widths". — [WP-01358-1.0, p.6](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Fabric structure: "Sectorized programmable fabric with integrated LAB/MLAB, M20K, M80K, DSP, routing, and clocking resources." — [Device Overview 2.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) NoC attachment: "a distributed fabric NoC runs alongside the columns of M20K and M80K memory blocks, enabling direct access to network-attached memory resources"; the "Fabric NoC (FNoC) extends data movement vertically through the FPGA fabric using embedded memory resources." — [WP-01358-1.0, p.7](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content); [Device Overview 2.1](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) SEU and power: "SEU error detection and correction circuitry that protects the configuration RAM (CRAM) programming bits and the M20K and M80K user memories"; "the Quartus Prime software automatically powers down specific unused resources such as the M20K or M80K blocks." — [Device Overview 11, 12](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Counts: the product table shows M80K blocks at roughly 0.4x the M20K block count on every device (A27F180: 42,096 M20K = 822 Mb; 14,032 M80K = 1,096 Mb; MLAB 158 Mb; total 1,918 Mb), so M80K supplies more than half the block RAM bits on every device. — [Product Table](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- (marketing) Giga-MIMO brief: "Agilex 27 also introduces the M80K on-chip RAM block, providing significantly larger memory capacity, well suited to support the large memory requirements of mMIMO applications." — [SB-1215-1.0](https://docs.altera.com/api/khub/documents/T4~~UVWU3Jd9rgKAZjWVZA/content)
- (spec, context) Agilex 7 for comparison had MLAB (640 bits), M20K (20 Kbits) and, on some devices, eSRAM (18 Mbits). No eSRAM is mentioned anywhere for Agilex 27. — [Agilex 7 Device Overview, Internal Embedded Memory](https://www.intel.com/content/www/us/en/docs/programmable/683458/current/internal-embedded-memory.html)

### Inferences
- M80K's deepest/widest modes (8,192 deep at x10; 1,024 deep at x80) are exactly 4x the M20K modes (2,048x10; 512x40 -> 1,024x80 adds a new 80-bit width), matching the "4x depth or 4x width" claim.
- The 64+16 ECC option implies a 80-bit physical word (64 data + 16 ECC) in the x80 mode, the first Altera block RAM with a native 64-bit ECC word.
- Because the fabric NoC is routed beside the memory columns, M80K is also the natural landing buffer for HyperFlow DMA transfers ("DDR straight into M20K/M80K memory" in white paper Figure 10).

### Gaps
- Port widths per port in true dual-port mode, maximum clock frequency, read/write latency, mixed-width support, and whether M80K supports the "coherent read" or byte-enable features of M20K are not published; an Agilex 27 Embedded Memory User Guide does not exist on docs.altera.com as of 31 Oct 2026.
- Whether M80K blocks are built from four M20K arrays sharing a port or are a distinct macro is not stated.
- No statement on M80K power per bit vs M20K.

## Key question 4: What is HyperFlow (topology, bandwidth, endpoints, DMA; is it a hard NoC like the Agilex 7 M-Series)?

### Takeaway
Altera documents HyperFlow as a hardened, full-chip network-on-chip, explicitly "built on the production-proven hard memory NoC in Agilex 7 M-Series devices and extended into a full-chip data network." It has three parts: a Main NoC (bulk data) and Register NoC (AXI-Lite control) around the periphery, and a Fabric NoC that runs vertically alongside the M20K/M80K columns, with 512-bit NoC ports and descriptor-driven distributed DMA engines connecting DDR/LPDDR, PCIe, the Arm HPS, embedded memory, and the SDM. The product table lists a "HyperFlow Data Network bandwidth, fabric (slice)" of 6.80 to 15.29 Tb/s per device; the press release says "multi terabit-per-second".

### Cited Findings
- (spec) Device Overview 1.: "The full-chip HyperFlow Data Network, a hardened network-on-chip (NoC), forms the data movement backbone." — [Device Overview 1.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 2: "HyperFlow Data Network: Full-chip Network-on-Chip (NoC) connectivity with hardened DMA and data movers." Table 3: "High-bandwidth fabric network and data movers connecting FPGA fabric, memory, HPS, I/O, hard IP, and SDM." — [Device Overview 1.2, 1.4](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 6 "HyperFlow Data Network Components": "Main NoC (MNoC): Provides high-throughput data path for bulk transfers. Register NoC (RNoC): Carries low-latency AXI-Lite control and register-access traffic. Fabric NoC (FNoC): Extends data movement vertically through the FPGA fabric using embedded memory resources." — [Device Overview 2.1](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview 2.1 on DMA: "Descriptor-driven, distributed DMA engines manage data transfers in hardened logic. Transfer descriptors let your system request and control movement between supported endpoints. The DMA engines then execute those requests for memory-to-memory and endpoint-to-memory transfers. Supported paths include DDR, LPDDR, the HPS, and PCIe." Endpoints listed: "DDR5, LPDDR4, LPDDR5X, and LPDDR6 external memory interfaces (EMIF). The hard processor system (HPS). PCI Express (PCIe). Embedded memory blocks. Secure Device Manager (SDM)." — [Device Overview 2.1](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) White paper: "Agilex 27 devices build on the production-proven hard memory NoC in Agilex 7 M-Series devices and extend it into a full-chip data network. The HyperFlow data network resources are hardened so they do not consume programmable fabric logic or routing." — [WP-01358-1.0, p.7](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper topology: "combines a hardened system NoC that runs around the periphery of the FPGA with a distributed fabric NoC integrated throughout the programmable fabric (Figure 10). The system NoC connects key subsystems including DDR and LPDDR memory controllers, PCIe, Ethernet, Arm SoC HPS, SDM, and other hardened IP ... Within the fabric, a distributed fabric NoC runs alongside the columns of M20K and M80K memory blocks." Figure 10 caption: "wide horizontal and vertical NoCs carry peripheral traffic, and a distributed fabric NoC moves data vertically through the fabric beside the memory columns." — [WP-01358-1.0, p.7](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper port/QoS detail: "the HyperFlow data network provides 512-bit NoC ports, distributed DMA access to all major system resources, and the proven characteristics of the Agilex 7 M-Series NoC, including deadlock-free operation, quality-of-service (QoS) support, and low-latency cut-through. Flexible NoC port placement, together with NoC-to-periphery and NoC-to-NoC connectivity, further reduces congestion." — [WP-01358-1.0, p.7](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper "Hardened data movers": "Dedicated, hardened DMA controllers handle transaction adaptation, memory movement, and endpoint-to-memory transfers ... They enable direct memory access, including remote DMA (RDMA) implementations, with minimal soft logic overhead ... Typical hardened flows include fabric to DDR channels, PCIe to DDR, and CPU to DDR. Fabric memories can be accessed through an AXI port or through DMA transfer modes, at lower power than equivalent soft logic, and the network is fully reconfigurable." — [WP-01358-1.0, p.8](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) White paper Figure 10(b) explanation: the hardened network carries "PCIe to DDR, HPS to DDR, and DDR straight into M20K/M80K memory, with no soft logic or routing in the path. Only the memory-to-DSP datapath and the SDM connection remain in the fabric." — [WP-01358-1.0, p.7](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Memory-controller side of the NoC: "The NoC interface is a pair of 256-bit AXI ports. The controller is single-port. AXI4 compliant with selected AXI5 features (poison via user bits), including four priority QoS levels (three priorities used), programmable address mapping". The HPS has "two 256-bit CHI memory ports to the cache-coherent unit and NoC". — [Device Overview 4., Table 13](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.11](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Product table row "HyperFlow Data Network - B'width Fabic (Slice) Tb/s": 6.80 (A27F008/012/018), 11.89 (A27F027/031), 15.29 (A27F045/054), 13.59 (12.44) (A27F070 through A27F180). — [Product Table](https://docs.altera.com/api/khub/documents/XCwjkADTS8Ob_yREw1E4YA/content)
- (spec) Tool flow: "In Quartus Prime Pro Edition Software and Visual Designer Studio, designers enter the NoC endpoints they want. Quartus software then builds the network of IP needed to realize the design and creates the NoC address maps automatically." Tools named: Interface Planner (manual NoC bridge placement), NoC Analyzer (pre/post-compile congestion analysis), Visual Designer Studio. — [WP-01358-1.0, p.8](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) PCIe hard IP includes "Configuration via Protocol (CvP) using a PCIe configuration DMA engine" and "DMA to the NoC". — [Device Overview 6.1](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.9](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (marketing) Press release: "a new full-chip, distributed HyperFlow data network, delivering multi terabit-per-second data movement throughout the FPGA without consuming soft logic resources or introducing routing congestion." — [Altera newsroom](https://www.altera.com/newsroom/agilex-2x)
- (marketing) Product page FAQ: "HyperFlow is a hardened, full-chip data network that combines a system NoC, distributed fabric NoC, and integrated DMA engines to move data efficiently between memory, PCIe, SDM, HPS, and FPGA fabric without consuming programmable logic or routing resources." — [Agilex 27 product page](https://www.altera.com/products/fpga/agilex-2x-portfolio/agilex-27)
- (marketing) NIC solution brief calls it "DMA-NoC": "The FPGA internally links the data ingest with a DMA-NoC and dedicated data movers, so bulk traffic travels through hardened circuitry rather than programmable routing." — [SB-1213-1.0](https://docs.altera.com/api/khub/documents/MJjESyrW__pqrR1DLbgjCQ/content)
- (press) Embedded.com (briefing with Lux Joshi, Senior Director of Product Management): HyperFlow "includes PCIe-to-memory, memory-to-Arm processor, and memory-to-fabric pathways; reduces soft logic consumption and routing congestion" and supports "direct memory access transfers while using less soft logic". — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)
- (press) Converge Digest: "described as a network-on-chip architecture capable of multi-terabit-per-second data movement across the different interfaces". — [Converge Digest, 29 Oct 2026](https://convergedigest.com/altera-agilex-2x-fpga-16t-ethernet-256g-serdes/)
- (press) CEO Raghib Hussain, quoted by SiliconANGLE and TechTimes: "Compute is one part, but data movement is the biggest problem to be solved." — [SiliconANGLE, John Furrier, 28 Oct 2026](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/); [TechTimes, 29 Oct 2026](https://www.techtimes.com/articles/329663/20261029/altera-launches-agilex-2x-fpgas-chip-data-network-built-physical-ai.htm)

### Inferences
- Yes, it is a hard NoC in the Agilex 7 M-Series lineage; the novelty is (a) extending it from a memory-only ring to a full-chip system NoC that also reaches PCIe, HPS, SDM and Ethernet hard IP, (b) the vertical Fabric NoC along memory columns, and (c) hardened descriptor DMA engines. Altera's "non-intrusive" framing is a deliberate contrast with router-in-the-array NoCs (the white paper criticizes "Classic NoC architectures that place routers in the middle of the logic array").
- The product-table bandwidth row scaling in steps (6.80 / 11.89 / 15.29 / 13.59 Tb/s) rather than with device size suggests it is a per-"slice" or per-NoC-ring figure tied to die/package family, not a sum over the whole device; the term "Fabric (Slice)" supports that. Not explained by Altera.
- 512-bit NoC ports and 256-bit AXI pairs at the memory controllers imply a wide, moderately clocked network, consistent with the M-Series NoC, but no clock or per-port bandwidth is published.

### Gaps
- No NoC clock, per-port bandwidth, router count, latency, or number of NoC initiator/target bridges per device is published.
- The meaning of "(12.44)" in the bandwidth row and of "Fabric (Slice)" is undocumented.
- No HyperFlow user guide or IP documentation exists yet on docs.altera.com; Quartus early-access support starts mid-November 2026.

## Key question 5: Process node, and vendor claims about performance per watt vs Agilex 7 / Agilex 5

### Takeaway
Altera has not disclosed the process node or foundry for Agilex 27 in any document, product page, or press interview found; I could not find it. The headline claims are all relative to Agilex 7: ">1.8x performance per watt", ">15% higher Fmax on average", "approximately 40% lower fabric power at iso-frequency", clock uncertainty down 34% (65% with deskew), and 5-10% denser ALM packing, all based on "Altera's modelling", not silicon.

### Cited Findings
- (spec) Device Overview 12. Power Management: "Agilex 27 is designed for approximately 40 percent lower fabric power at iso-frequency versus Agilex 7, and for more than 1.8x performance per watt versus Agilex 7." Footnote: "Based on Altera's modelling of Agilex 27 versus Agilex 7 device fabric performance and power. Tests measure performance of components on a particular test, in specific systems." Features: "Compile-time performance or power selection through flexible speed options. Power-gating of unused fabric resources. Power domains and CPU power management controls in the HPS." — [Device Overview 12.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Device Overview Table 3: "up to 40% overall lower power compared to the previous generation high-performance Agilex FPGAs." Table 5: "Delivers more than 15% higher FMAX, on average, versus the previous-generation Hyperflex fabric architecture in Agilex 7"; "Reduces fabric power by approximately 40% at iso-frequency versus Agilex 7." — [Device Overview 1.4, 2.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) White paper Figure 3 (normalized to Stratix 10 = 1.00): relative fabric Fmax Agilex 7 = 1.54 (+54%), Agilex 27 = 1.77 (+15%); relative fabric power at iso-frequency Agilex 7 = 0.60 (-40%), Agilex 27 = 0.36 (-40%). Text: "delivers >15% higher Fmax, on average, than the previous-generation HyperFlex fabric architecture in Agilex 7 devices ... approximately 40% power reduction at iso-frequency versus Agilex 7 devices ... a performance-per-watt advantage of >1.8X versus Agilex 7 devices." Footnote 1: "Based on Altera's modelling of Agilex 27 versus Agilex 7 device fabric performance and power. Results may vary." — [WP-01358-1.0, p.4](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Clocking: "Worst-case clock uncertainty drops by 34% versus Agilex 7 devices across device sizes, and by 65% with deskew enabled. For comparison, Agilex 7 devices reduced worst-case clock uncertainty by 30% versus Stratix 10 devices." — [WP-01358-1.0, p.5](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) ALM: "20% increase in ALMs per LAB over previous Agilex generation"; "Fracturable 6-LUT-based logic with extended 7/8-input function coverage. New dedicated 2-LUT, enabling 6-LUT + independent 2-LUT or 3-LUT + 3-LUT + 2-LUT packing"; "Hard adders are now LAB-only (removed from the MLAB) and the adder is refactored into three lane-aligned 8-bit chunks versus the previous generation's two 5xALM half-LAB chunks"; "The new ALM modes give a 5% to 10% denser implementation of the same design with fewer ALMs, transparent on recompile." White paper adds: up to three independent functions per ALM, 8-input XOR/NAND/NOR in one ALM, and two independent registers packable with a 6-LUT. — [Device Overview 2.2](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.4-5](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) HyperFlex 3rd gen features: "Distributed Hyperflex pipeline resources ... Sectorized programmable fabric with integrated LAB/MLAB, M20K, M80K, DSP, routing, and clocking resources. Fabric-to-periphery interfaces with optional pipeline registers ... Adaptive deskew ... Fine-grained partial reconfiguration"; "Hyper-Registers throughout the fabric and at the input of all functional blocks." — [Device Overview 2., 1.4](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) PHY Lite I/O timing vs Agilex 5 and Agilex 7 M-Series: "27% higher Fmax, 20% finer delay resolution, and up to 15.3x lower delay update latency, while retaining a 32 UI maximum delay range." This is the only Agilex 5 comparison in any Agilex 27 document. — [WP-01358-1.0, p.9](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) HPS vs Agilex 7: "Compared with the quad-core Cortex-A53 HPS in Agilex 7 devices, the Agilex 27 devices HPS delivers up to 6x faster single-thread performance with a Cortex-A720 core, 2x with a Cortex-A520 core, and more than 4x quad-core throughput (Dhrystone)." — [WP-01358-1.0, p.11](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (marketing) Giga-MIMO brief: "Agilex 27 devices deliver over 40% power reduction compared to similar logic density Agilex 7 devices." — [SB-1215-1.0](https://docs.altera.com/api/khub/documents/T4~~UVWU3Jd9rgKAZjWVZA/content)
- (marketing) Press release: "the 3rd generation HyperFlex fabric, delivering 1.8X gen-over-gen performance/watt improvements. HyperFlex embeds registers throughout the routing fabric, giving Altera's Quartus Prime software more opportunities to re-time and pipeline designs without consuming logic resources." — [Altera newsroom](https://www.altera.com/newsroom/agilex-2x)
- (marketing) Portfolio page FAQ: "Agilex 2X combines an advanced fabric optimized to provide the best performance while keeping minimizing leakage current." — [Agilex 2X portfolio page](https://www.altera.com/products/fpga/agilex-2x-portfolio)
- (press) Every outlet repeats the 1.8x figure; none names a process node. ServeTheHome explicitly lists "process node" among items not specified. A targeted search for "Agilex 27" with TSMC / Intel 18A / Intel 3 / N3 returned only generic foundry-roadmap articles with no Agilex 27 mention. — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/)
- (press, speculative framing) An Embedded.com/search-summary line attributed to Altera says Agilex 27 "provides 2x to 4x the bandwidth in an equivalently-sized device compared to a prior generation, with the latest generation of PCIe, 800-GbE, 1.6-TbE Ethernet, and UCIe capabilities." I did not find this sentence on the Altera pages I read directly, so treat its provenance as unverified. — [Embedded.com](https://www.embedded.com/altera-brings-fpgas-to-physical-ai-with-agilex-2x-and-an-agentic-design-assistant)

### Inferences
- 1.15 (Fmax) / 0.60 (power) = 1.92, which is how Altera arrives at ">1.8x" performance per watt; the figure is fabric-only and model-based.
- A 40% iso-frequency power cut plus 15% Fmax on top of Agilex 7 (Intel 10 nm SuperFin) is more than a single architectural generation usually delivers, which is suggestive of a node shrink, but Altera has said nothing and I will not guess the node.
- Agilex 5 is not Altera's comparison point for Agilex 27 anywhere except the PHY Lite I/O block; Agilex 27 is positioned strictly as the Agilex 7 successor (flagship/high-performance tier), while Agilex 25/23/22 (unlaunched) will presumably succeed Agilex 5 and Agilex 3.

### Gaps
- Process node and foundry: not disclosed in any Altera document, page, FAQ, press release, or press interview found. No analyst-day or investor material from 2026 mentioning the node was found (Altera is private under Silver Lake majority ownership since 2025, so there are no SEC filings to check).
- No absolute Fmax, static or dynamic power numbers, or speed-grade definitions; "1V/2V/2L/3V" speed grades are named in the part-number decoder but not characterized.
- No Agilex 5 or competitor (AMD Versal) comparisons beyond PHY Lite.

## Key question 6: External memory interfaces, HBM/M-Series plans, transceivers, hard IP, and HPS (supporting detail requested in the objective)

### Takeaway
Agilex 27 has hard DDR5 (to 9,200 MT/s), LPDDR4 (4,266), LPDDR5X (9,600) and, on 4.5 M LE and larger devices, LPDDR6 (14,400 MT/s) controllers with inline AES-XTS-256 encryption; GT transceivers to 256 Gbps PAM4, GX to 128 Gbps, GS to 32 Gbps NRZ; hard PCIe 6.0 x8 and PCIe 7.0 x8 / 6.0 x16 with IDE; hard 800GbE and 1.6TbE with MACsec; and an Armv9.2 HPS (2x Cortex-A720 + 2x Cortex-A520). An "M-Series" with memory in package (up to 921 GB/s) and a "Direct RF-Series" with UCIe-attached data converters are announced without specifications; the memory type is never named as HBM.

### Cited Findings
- (spec) Device Overview Table 12 "Memory Standards and Performance": 866K to 3.1M LE devices: "DDR5, LPDDR5, LPDDR4"; "DDR5 up to 9,200 MT/s, LPDDR4 up to 4,266 MT/s, LPDDR5x up to 9,600 MT/s". 4.5M to 18M LE devices: "DDR5, LPDDR5X, LPDDR6"; "DDR5 up to 9,200 MT/s, LPDDR5x up to 9,600 MT/s, LPDDR6 up to 14,400 MT/s". — [Device Overview 4.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Controller: "Each HSIO bank contains general-purpose I/Os and three high-efficiency hard memory controllers, configured in banks of 13"; interface widths "DDR5: 32-bit and 32-bit with ECC (36b and 40b); LPDDR4 or LPDDR5X: 16-bit channels (two per bank; x32 package = two x16, x64 across two adjacent banks)"; DIMM types "CUDIMM, UDIMM, CSODIMM, SODIMM, and RDIMM"; "DDR5 up to four ranks"; scheduling for "70%+ utilization on full-random 64-byte access". — [Device Overview Table 13](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) White paper Table 3: Agilex 27 "DDR5-9200, LPDDR5/5X-9600, LPDDR6-ready"; 38.4 GB/s per memory interface; "269 GB/s with LPDDR5, Higher with LPDDR6" per device; vs Agilex 7 M-Series 25.6 GB/s / 205 GB/s and Agilex 7 F/I 12.8 GB/s / 102 GB/s. "Deeper 64-entry read and write queues ... 256-bit AES-XTS inline memory encryption". — [WP-01358-1.0, p.9](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (marketing) M-Series: product brief "Memory (M-Series): Maximum memory bandwidth: Memory-in-package, for greater data in less board area"; NIC brief "Agilex 27 M-Series device options add memory on package with up to 921 GB/s of in-package bandwidth plus up to 4x 1.6 TbE"; "M-Series in-package memory delivers up to 921 GB/s, about 4.6 times the 200 GB/s line rate of a 1.6 Tb/s port". Product page FAQ: "Choose Memory when high-bandwidth memory in-package and greater data locality are needed". — [PB-1026-1.0](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content); [SB-1213-1.0](https://docs.altera.com/api/khub/documents/MJjESyrW__pqrR1DLbgjCQ/content); [Agilex 27 product page](https://www.altera.com/products/fpga/agilex-2x-portfolio/agilex-27)
- (marketing) RF-Series: "Direct RF (RF-Series): Integrated RF signal chain: Next-generation data converters in package via UCIe chiplets"; white paper: "UCIe provides a path to chiplet integration, enabling direct attachment of data converters in Agilex 27 RF-Series devices". — [PB-1026-1.0](https://docs.altera.com/api/khub/documents/D1hI5l2t7xc3Op2N9C1sYw/content); [WP-01358-1.0, p.9](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Transceivers, Device Overview Table 14: GS "2 Gbps to 32 Gbps NRZ, PMA-direct"; GX "1 Gbps to 58 Gbps NRZ, 20 Gbps to 128 Gbps PAM4"; GT "25 Gbps to 58 Gbps NRZ, 51 Gbps to 256 Gbps PAM4"; "monolithic multiprotocol PHY targeted to support more than 40 protocols". White paper: ADC-based receiver ("An analog front end (CTLE and VGA) feeds an ADC, followed by digital equalization (FFE, DFE, and PAM4) and digital clock and data recovery"), per-lane embedded multi-core firmware, Linear Pluggable Optics support. — [Device Overview 5.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.8](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) Hard IP pairing (Table 15): PCIe 6.0 x8 and PCIe 7.0 x8 / 6.0 x16 on GX only; 800 GbE "Channelized 800 GbE x8 with MACsec" on GX; 1.6 TbE "Channelized 1.6 TbE x16 with MACsec, L2 parser and hard priority flow control buffering" on GX or GT. — [Device Overview 5.1](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) Crypto: "200 Gbps full-duplex inline symmetric crypto accelerator blocks" (Key Features) vs "The 200 Gbps half-duplex SCA" (section 6.3) with "200G full-duplex crypto-engine options" (Table 16); AES-GCM, AES-XTS, SM4; "FIPS 140-3 Level 2 certifiable". — [Device Overview 1.2, 6.3](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview)
- (spec) HPS: "Dual Arm Cortex-A720 cores (targeted for up to 2.5 GHz) plus dual Arm Cortex-A520 (targeted for up to 1.85 GHz), Armv9.2" (Table 4) but "CPU frequency up to 2.3 GHz" (Table 17) and "up to 2.3GHz" (product table); DynamIQ cluster, 2 MB shared L3, "two 256-bit CHI memory ports". — [Device Overview 1.5, 8.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.11](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (spec) MIPI: "C-PHY 2.1 and D-PHY 3.0 up to 4.5 Gbps per lane" on HSIO; MSIO D-PHY 3.0 to 2.5 Gsps, true LVDS to 2 Gb/s, 13 I/Os per MSIO block with its own PLL. — [Device Overview 1.2, 3.](https://docs.altera.com/r/docs/d791593/current/agilex-27-fpgas-and-socs-device-overview); [WP-01358-1.0, p.9](https://docs.altera.com/api/khub/documents/hGPnldzZxr4wmKkmVpzs1w/content)
- (marketing) Availability: "Quartus Prime software support for Agilex 27 FPGAs will be available to early access customers starting in mid-November. Engineering sample silicon for Agilex 27 FPGAs is expected in the second half of 2027. QuartusIQ ... is now available ... as part of Quartus Prime version 26.3." — [Altera newsroom](https://www.altera.com/newsroom/agilex-2x)
- (press) ServeTheHome and SiliconANGLE both note the H2 2027 sample date and Quartus 26.3; SiliconANGLE quotes Hussain: "AI is going to force a redesign of every equipment out there." — [ServeTheHome](https://www.servethehome.com/altera-agilex-27-800gbe-1-6tbe-hyperflow/); [SiliconANGLE](https://siliconangle.com/2026/10/28/altera-unveils-agilex-2x-betting-on-ai-developers-to-expand-programmable-computing/)

### Inferences
- 921 GB/s in-package bandwidth is in the range of one HBM3E stack (about 1.2 TB/s) or a couple of HBM3 stacks, but Altera never uses the word HBM for its own part; the only HBM mentions in the NIC brief refer to GPU accelerators. The Agilex 7 M-Series used HBM2e, so HBM is the obvious candidate, but this is my inference.
- The 2.3 GHz (product table, Table 17) vs 2.5 GHz "targeted" (Table 4, white paper) HPS discrepancy looks like a conservative-spec vs target-spec difference within the same preliminary doc set.
- The 1.6TbE "GX or GT" pairing means a 1.6T port can be built from 16x 128G GX lanes or 8x 256G GT lanes (the hard IP is described as "x16").

### Gaps
- M-Series and RF-Series: no device names, memory type, capacity, stack count, UCIe generation, converter specs, or dates. "Contact Sales".
- HBM is never named by Altera for Agilex 27.
- No per-lane transceiver power, no Ethernet port/lane-rate matrix, no PCIe lane widths per package.
- The 200 Gbps crypto block is described as both full-duplex and half-duplex in the same Device Overview; unresolved.
- Agilex 25, 23, 22 have no technical specifications published ("Contact Sales"); only one-paragraph positioning in the press release and portfolio brief.
