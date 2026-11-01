#!/usr/bin/env python3
"""
Exact OCP-MX dot-product golden model and test-vector generator for the AXC3000 harness.

Generates NVEC random activation vectors plus two weight vectors (one per DSP column), computes
the exact MX dot products (Fraction arithmetic, then a single round to fp32), and emits a Tcl
data file that the System Console script sources and a JSON copy for the checker.

    python mx_golden.py --e 2 --m 1 --nvec 64 --seed 1 --out data_e2m1.tcl

The harness packs element j at bit [j*W +: W] of a 256-bit vector (W = 1+E+M), little-endian
32-bit words. Shared exponents are E8M0 (bias 127). We keep shared exponents in a modest range
so results stay normal fp32 (the Agilex tensor block flushes subnormals and we are testing the
datapath, not the corner cases).
"""
import argparse, json, random, struct
from fractions import Fraction


def mx_value(code: int, e: int, m: int) -> Fraction:
    """Exact value of an EeMm element code (no inf/nan for E2M1, E2M3, E3M2)."""
    bias = (1 << (e - 1)) - 1
    s = (code >> (e + m)) & 1
    ex = (code >> m) & ((1 << e) - 1)
    ma = code & ((1 << m) - 1)
    if ex == 0:
        v = Fraction(ma, 1 << m) * Fraction(2) ** (1 - bias)
    else:
        v = (1 + Fraction(ma, 1 << m)) * Fraction(2) ** (ex - bias)
    return -v if s else v


def to_fp32_bits(x: Fraction) -> int:
    f = float(x)  # correctly rounded (RNE) for values this size
    return struct.unpack(">I", struct.pack(">f", f))[0]


def pack_vec(codes, w):
    v = 0
    for j, c in enumerate(codes):
        v |= (c & ((1 << w) - 1)) << (j * w)
    return [(v >> (32 * k)) & 0xFFFFFFFF for k in range(8)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--e", type=int, default=2)
    ap.add_argument("--m", type=int, default=1)
    ap.add_argument("--nvec", type=int, default=64)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--k", type=int, default=32)
    ap.add_argument("--out", default="data.tcl")
    ap.add_argument("--bfp", type=int, default=0, help="block-FP mode: weights are signed WBITS-bit ints, activations int8, both sign-extended to 8-bit lanes")
    ap.add_argument("--zero_col", type=int, default=0, help="debug: zero the weights of column 1 or 2 (expected results become +0.0)")
    ap.add_argument("--mxfp4_lanes", action="store_true", help="C1 via raw lanes: E2M1 x E2M1 vectors presented as decoded q=2*value int8 lanes with shared exponent X-1 (host-side decode)")
    a = ap.parse_args()
    rnd = random.Random(a.seed)
    if a.mxfp4_lanes:
        # MXFP4 x MXFP4 with the E2M1 decode done on the host: lanes q = 2*value, exponent X - 1.
        w = 8
        codes1, codes2 = [rnd.randrange(16) for _ in range(a.k)], [rnd.randrange(16) for _ in range(a.k)]
        x1, x2 = rnd.randrange(120, 135), rnd.randrange(120, 135)
        q_of = {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 6, 6: 8, 7: 12}
        def dec(c):
            q = q_of[c & 7]; return -q if c & 8 else q
        w1 = [dec(c) & 0xFF for c in codes1]; w2 = [dec(c) & 0xFF for c in codes2]
        def sval(c): return c - 256 if c >= 128 else c
        acts, xas, exp1, exp2 = [], [], [], []
        for _ in range(a.nvec):
            ac = [rnd.randrange(16) for _ in range(a.k)]; xa = rnd.randrange(120, 135)
            av = [dec(c) & 0xFF for c in ac]
            acts.append(av); xas.append(xa - 1)
            d1 = sum(sval(w1[j]) * sval(av[j]) for j in range(a.k)); d2 = sum(sval(w2[j]) * sval(av[j]) for j in range(a.k))
            # value = q*2^-1 each side, scales 2^(X-127): total 2^((x1-1)-127 + (xa-1)-127)
            exp1.append(to_fp32_bits(Fraction(d1) * Fraction(2) ** ((x1 - 1) - 127 + (xa - 1) - 127)))
            exp2.append(to_fp32_bits(Fraction(d2) * Fraction(2) ** ((x2 - 1) - 127 + (xa - 1) - 127)))
        x1, x2 = x1 - 1, x2 - 1
        kind, efield, mfield = 1, 2, 1
    elif a.bfp:
        w = 8
        wb = a.bfp
        def rand_w():  # signed WBITS-bit ints, two's complement in 8-bit lanes
            return [rnd.randrange(-(1 << (wb - 1)), 1 << (wb - 1)) & 0xFF for _ in range(a.k)]
        def rand_a():
            return [rnd.randrange(-128, 128) & 0xFF for _ in range(a.k)]
        def sval(c):
            return c - 256 if c >= 128 else c
        w1, w2 = rand_w(), rand_w()
        x1, x2 = rnd.randrange(120, 135), rnd.randrange(120, 135)
        acts, xas, exp1, exp2 = [], [], [], []
        for _ in range(a.nvec):
            av = rand_a(); xa = rnd.randrange(120, 135)
            acts.append(av); xas.append(xa)
            d1 = sum(sval(w1[j]) * sval(av[j]) for j in range(a.k))
            d2 = sum(sval(w2[j]) * sval(av[j]) for j in range(a.k))
            exp1.append(to_fp32_bits(Fraction(d1) * Fraction(2) ** (x1 - 127 + xa - 127)))
            exp2.append(to_fp32_bits(Fraction(d2) * Fraction(2) ** (x2 - 127 + xa - 127)))
        kind, efield, mfield = 1, 8, wb
    else:
        w = 1 + a.e + a.m
        ncode = 1 << w

        def rand_vec():
            return [rnd.randrange(ncode) for _ in range(a.k)]

        # weights for the two columns, shared exponents near bias
        w1, w2 = rand_vec(), rand_vec()
        x1, x2 = rnd.randrange(120, 135), rnd.randrange(120, 135)
        acts, xas, exp1, exp2 = [], [], [], []
        for _ in range(a.nvec):
            av = rand_vec(); xa = rnd.randrange(120, 135)
            acts.append(av); xas.append(xa)
            d1 = sum(mx_value(w1[j], a.e, a.m) * mx_value(av[j], a.e, a.m) for j in range(a.k))
            d2 = sum(mx_value(w2[j], a.e, a.m) * mx_value(av[j], a.e, a.m) for j in range(a.k))
            exp1.append(to_fp32_bits(d1 * Fraction(2) ** (x1 - 127 + xa - 127)))
            exp2.append(to_fp32_bits(d2 * Fraction(2) ** (x2 - 127 + xa - 127)))
        kind, efield, mfield = 0, a.e, a.m

    if a.zero_col in (1, 2):
        if a.zero_col == 1: w1 = [0] * a.k; exp1 = [0] * a.nvec
        else:               w2 = [0] * a.k; exp2 = [0] * a.nvec

    with open(a.out, "w") as f:
        f.write(f"# generated by mx_golden.py kind={kind} E={efield} M={mfield} nvec={a.nvec} seed={a.seed}\n")
        f.write(f"set ::KIND {kind}\nset ::E {efield}\nset ::M {mfield}\nset ::NVEC {a.nvec}\n")
        f.write("set ::W1 {" + " ".join(f"0x{x:08X}" for x in pack_vec(w1, w)) + "}\n")
        f.write("set ::W2 {" + " ".join(f"0x{x:08X}" for x in pack_vec(w2, w)) + "}\n")
        f.write(f"set ::X1 {x1}\nset ::X2 {x2}\n")
        f.write("set ::ACT {\n")
        for av, xa in zip(acts, xas):
            f.write("  {" + " ".join(f"0x{x:08X}" for x in pack_vec(av, w)) + f" {xa}}}\n")
        f.write("}\n")
        f.write("set ::EXP1 {" + " ".join(f"0x{x:08X}" for x in exp1) + "}\n")
        f.write("set ::EXP2 {" + " ".join(f"0x{x:08X}" for x in exp2) + "}\n")
    with open(a.out.rsplit(".", 1)[0] + ".json", "w") as f:
        json.dump({"kind": kind, "E": efield, "M": mfield, "nvec": a.nvec, "seed": a.seed, "w1": w1, "w2": w2,
                   "x1": x1, "x2": x2, "acts": acts, "xas": xas,
                   "exp1": [f"0x{x:08X}" for x in exp1], "exp2": [f"0x{x:08X}" for x in exp2]}, f, indent=1)
    print(f"wrote {a.out}: kind={kind} E{efield}M{mfield}, {a.nvec} vectors, w={w} bits/element")


if __name__ == "__main__":
    main()
