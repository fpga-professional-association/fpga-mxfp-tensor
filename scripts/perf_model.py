#!/usr/bin/env python3
"""
Peak-throughput and LLM-fit model for MXFP dot products on Altera FPGAs.

Reproduces the paper's "fill the device" peak TFLOPS method (Sec. III-E / Table V of
arXiv 2607.13898) from the per-unit costs in Tables I and V, then applies the same
per-unit costs to other devices (Agilex 3 A3CY100 that we own, Agilex 7 AGF027 /
AGM039 which have no tensor mode) and adds a simple LLM memory/bandwidth fit model.

Everything here is a first-order estimate. Per-unit costs are the paper's Agilex 5
single-instance Quartus results; Agilex 7 ALM/DSP costs for the same RTL will differ
a little (different speed grades, 18x19 vs 18x18 arrays) and must be re-measured.

Run:  python scripts/perf_model.py
"""
from dataclasses import dataclass
from math import floor

# --------------------------------------------------------------------------------------
# Devices
# --------------------------------------------------------------------------------------
@dataclass
class Device:
    name: str
    alms: int
    dsps: int
    has_tensor_mode: bool
    # fmax used for the "realistic full-device" scenario (paper's full-device systolic
    # arrays closed at ~400 MHz on Agilex 5; Agilex 7 -2 fabric is a bit faster)
    realistic_mhz: float
    note: str = ""

DEVICES = [
    # Agilex 5 E-series 065: 222,400 ALMs, 846 DSP blocks (1,692 18x19 mults), 1,611 M20K.
    # Source: Altera Agilex 5 E-series product table (2025.09.30).
    Device("Agilex 5  A5E065 (paper)",  222_400,   846, True,  400,
           "paper device; 846 DSP x 20 MAC = exactly reproduces Table V peaks"),
    # Agilex 3 A3CY100 on the Arrow AXC3000 we own: 138 DSP blocks (276 18x19), ~100K LE.
    # ALM count approximated as LE/2.95 (Agilex LE:ALM ratio); verify in Quartus.
    Device("Agilex 3  A3CY100 (owned)",  34_000,   138, True,  240,
           "34,000 ALMs per Quartus; tensor DSP restricted fmax 343 MHz on -7; harness measured at 240 MHz"),
    # Agilex 7 F-series 027: 912,800 ALMs, 8,528 DSP blocks. Source: F-series product table.
    Device("Agilex 7  AGF027",           912_800, 8_528, False, 450,
           "no tensor mode; 18x19 fixed fmax 771 MHz (-2V) but fabric-bound designs ~450"),
    # Agilex 7 M-series 039: 1,305,600 ALMs, 12,300 DSP blocks, 32 GB HBM2e (820 GB/s).
    Device("Agilex 7  AGM039 (HBM2e)", 1_305_600, 12_300, False, 450,
           "no tensor mode; HBM2e 32 GB @ 820 GB/s makes this the LLM candidate"),
]

# --------------------------------------------------------------------------------------
# Per-unit costs of a k=32 MXFP dot-product module (ALMs, DSPs, D dot products per module,
# single-instance fmax MHz). From Table I (baseline DSP) and Table V (proposed DSP).
# --------------------------------------------------------------------------------------
@dataclass
class Unit:
    approach: str
    alms: int
    dsps: int
    d: int
    mhz: float
    needs_tensor: bool = False
    needs_proposed_dsp: bool = False

K = 32
TABLE = {
    "E5M2": [Unit("opt soft logic", 4432, 0, 1, 516), Unit("packed DSP", 10421, 16, 3, 525),
             Unit("fp16 vector", 319, 16, 1, 460),
             Unit("proposed DSP (iter 2/3.3)", 210, 4, 2, 458, needs_proposed_dsp=True)],
    "E4M3": [Unit("opt soft logic", 3287, 0, 1, 539), Unit("packed DSP", 4841, 16, 2, 581),
             Unit("fp16 vector", 660, 16, 1, 455),
             Unit("proposed DSP (iter 4)", 210, 4, 2, 458, needs_proposed_dsp=True)],
    "E3M2": [Unit("opt soft logic", 1657, 0, 1, 597), Unit("packed DSP", 4153, 16, 3, 654),
             Unit("fp16 vector", 381, 16, 1, 455),
             Unit("proposed DSP (iter 4)", 96, 3, 2, 458, needs_proposed_dsp=True)],
    "E2M3": [Unit("opt soft logic", 1579, 0, 1, 658), Unit("packed DSP", 1962, 16, 2, 850),
             Unit("fp16 vector", 368, 16, 1, 446), Unit("tensor mode", 420, 4, 2, 458, needs_tensor=True),
             Unit("proposed DSP (iter 4)", 96, 3, 2, 458, needs_proposed_dsp=True)],
    "E2M1": [Unit("opt soft logic", 885, 0, 1, 713), Unit("packed DSP", 3590, 16, 5, 740),
             Unit("fp16 vector", 224, 16, 1, 460), Unit("tensor mode", 198, 4, 2, 458, needs_tensor=True),
             Unit("proposed DSP (iter 4)", 39, 2, 2, 458, needs_proposed_dsp=True)],
}

# Our own proposal for devices WITHOUT a tensor mode (Agilex 7): pre-align MXFP4 / MXFP6
# (E2M3) elements to signed fixed point in soft logic (5 b / 7 b, exactly as the paper does
# before the tensor block), then use the Agilex 7 DSP "9x9 signed sum-of-4" mode so one DSP
# block does a dot-4 with no alignment logic after the multiplier. dot-32 = 8 DSP blocks +
# a 7-adder soft tree + one fixed->fp32 converter. ALM cost is an ESTIMATE to be measured.
PREALIGNED_SUM4 = {
    "E2M1": Unit("pre-aligned 9x9 sum-of-4 (our idea, est.)", 260, 8, 1, 600),
    "E2M3": Unit("pre-aligned 9x9 sum-of-4 (our idea, est.)", 300, 8, 1, 600),
}


def units_fit(dev: Device, u: Unit) -> int:
    n = dev.alms // u.alms if u.alms else 10**9
    if u.dsps:
        n = min(n, dev.dsps // u.dsps)
    return n


def tflops(dev: Device, u: Unit, mhz: float) -> float:
    n = units_fit(dev, u)
    return n * u.d * K * 2 * mhz * 1e6 / 1e12


def best_mix_two(dev: Device, a: Unit, b: Unit, mhz: float):
    """Max FLOP/cycle mixing two unit types under ALM and DSP budgets (2-var LP, vertices)."""
    best = (0.0, 0, 0)
    fa, fb = a.d * K * 2, b.d * K * 2
    # vertices: all-a, all-b, and the ALM/DSP line intersection
    cands = [(units_fit(dev, a), 0), (0, units_fit(dev, b))]
    det = a.alms * b.dsps - b.alms * a.dsps
    if det:
        na = (dev.alms * b.dsps - dev.dsps * b.alms) / det
        nb = (dev.dsps * a.alms - dev.alms * a.dsps) / det
        if na >= 0 and nb >= 0:
            cands.append((floor(na), floor(nb)))
    for na, nb in cands:
        if na * a.alms + nb * b.alms <= dev.alms and na * a.dsps + nb * b.dsps <= dev.dsps:
            f = na * fa + nb * fb
            if f > best[0]:
                best = (f, na, nb)
    f, na, nb = best
    return f * mhz * 1e6 / 1e12, na, nb


def section(title):
    print("\n" + "=" * 100)
    print(title)
    print("=" * 100)


def peak_tables():
    for dev in DEVICES:
        section(f"{dev.name}: {dev.alms:,} ALMs, {dev.dsps:,} DSP blocks   [{dev.note}]")
        print(f"{'format':6} {'approach':42} {'units':>6} {'ALM%':>5} {'DSP%':>5} "
              f"{'peak@unit-fmax':>15} {'peak@%d MHz' % dev.realistic_mhz:>13}")
        for fmt, units in TABLE.items():
            rows = list(units)
            if fmt in PREALIGNED_SUM4 and not dev.has_tensor_mode:
                rows.append(PREALIGNED_SUM4[fmt])
            for u in rows:
                if u.needs_tensor and not dev.has_tensor_mode:
                    continue
                if u.needs_proposed_dsp and "paper" not in dev.name:
                    continue  # proposed block only exists as an ASIC proposal on the A5 baseline
                n = units_fit(dev, u)
                alm_pct = 100 * n * u.alms / dev.alms
                dsp_pct = 100 * n * u.dsps / dev.dsps if dev.dsps else 0
                print(f"{fmt:6} {u.approach:42} {n:6d} {alm_pct:5.0f} {dsp_pct:5.0f} "
                      f"{tflops(dev, u, u.mhz):15.1f} {tflops(dev, u, dev.realistic_mhz):13.1f}")
        if not dev.has_tensor_mode:
            print("\n  Best two-approach mixes (fill ALMs with one, leftover DSPs with another), "
                  f"at {dev.realistic_mhz} MHz:")
            for fmt in ("E2M1", "E2M3", "E4M3"):
                pool = [u for u in TABLE[fmt] if not (u.needs_tensor or u.needs_proposed_dsp)]
                if fmt in PREALIGNED_SUM4:
                    pool.append(PREALIGNED_SUM4[fmt])
                best = None
                for i in range(len(pool)):
                    for j in range(i + 1, len(pool)):
                        t, na, nb = best_mix_two(dev, pool[i], pool[j], dev.realistic_mhz)
                        if best is None or t > best[0]:
                            best = (t, pool[i].approach, na, pool[j].approach, nb)
                t, a, na, b, nb = best
                print(f"    {fmt}: {t:6.1f} TFLOPS  = {na} x [{a}] + {nb} x [{b}]")


# --------------------------------------------------------------------------------------
# LLM fit model
# --------------------------------------------------------------------------------------
MXFP4_BYTES_PER_PARAM = 4.25 / 8          # 4-bit element + 8-bit shared scale per 32
BF16_BYTES_PER_PARAM = 2.0

@dataclass
class Model:
    name: str
    total_params_b: float
    active_params_b: float
    ckpt_gb: float | None = None          # if the published checkpoint size is known
    note: str = ""

MODELS = [
    Model("gpt-oss-20b (native MXFP4 MoE)",  20.9,  3.6, ckpt_gb=12.8 * 1.0737, note="OpenAI ships MXFP4 experts"),
    Model("gpt-oss-120b (native MXFP4 MoE)", 116.8, 5.1, ckpt_gb=60.8 * 1.0737, note="OpenAI ships MXFP4 experts"),
    Model("Llama-3.1-8B -> MXFP4",            8.03, 8.03),
    Model("Qwen3-30B-A3B -> MXFP4",           30.5,  3.3),
    Model("Qwen3-32B -> MXFP4",               32.8, 32.8),
    Model("Llama-3.3-70B -> MXFP4",           70.6, 70.6),
]

@dataclass
class MemSys:
    name: str
    capacity_gb: float
    bw_gbs: float
    eff: float          # achievable fraction of peak bandwidth for streaming weights

MEMS = [
    MemSys("Agilex 7 AGM039 HBM2e (1 device)", 32, 820, 0.70),
    MemSys("Agilex 7 AGM039 HBM2e (2 devices)", 64, 1640, 0.65),
    MemSys("Agilex 7 AGM039 HBM2e + 2ch DDR5-5600 (experts in DDR)", 32 + 64, 90, 0.75),
    MemSys("Agilex 5 A5E065 dev kit, LPDDR5 (board dependent)", 8, 50, 0.70),
    MemSys("Agilex 3 AXC3000 HyperRAM", 0.016, 0.34, 0.77),
    MemSys("AMD MI355X HBM3E (1 GPU, reference)", 288, 8000, 0.80),
]


def llm_fit():
    section("LLM fit: MXFP4 weights (4.25 b/param), batch-1 decode is weight-bandwidth bound")
    print(f"{'model':38} {'weights GB':>10} {'active GB/tok':>13}   fits / est. batch-1 tok/s per memory system")
    for m in MODELS:
        w_gb = m.ckpt_gb if m.ckpt_gb else m.total_params_b * MXFP4_BYTES_PER_PARAM
        # per-token traffic: active weights (MXFP4) + ~15% for bf16 attention/embeddings + KV
        act_gb = m.active_params_b * MXFP4_BYTES_PER_PARAM * 1.15
        print(f"{m.name:38} {w_gb:10.1f} {act_gb:13.2f}")
        for ms in MEMS:
            fits = w_gb * 1.10 <= ms.capacity_gb      # 10% headroom for KV cache + activations
            toks = ms.bw_gbs * ms.eff / act_gb
            print(f"    {ms.name:60} {'FITS ' if fits else 'no   '} {toks:8.0f} tok/s" if fits
                  else f"    {ms.name:60} {'FITS ' if fits else 'no   '}")
    print("\nDecode compute need is tiny: e.g. gpt-oss-20b at 200 tok/s = 2*3.6e9*200 = 1.4 TFLOPS.")
    print("Prefill is compute bound: 1,000-token prompt on gpt-oss-20b = 7.2 TFLOP ->"
          " ~0.25 s at a sustained 30 TFLOPS, ~1.2 s at 6 TFLOPS.")


if __name__ == "__main__":
    peak_tables()
    llm_fit()
