"""
gen_rtl_vectors.py -- deterministic golden vectors for quant/rtl/mxq_decoders.sv (spec 6.4 items 2, 3, 4).

Writes tests/golden_vectors/*.hex consumed by tests/tb_mxq_decoders.sv:
  e2m1.hex        : 16 lines "code q"             (all codes)
  int4.hex        : 16 lines "code q invalid"
  scale.hex       : lines "is_mx scale_in e trap"  (all 32 BFP codes, all 256 E8M0 codes)
  qdot10.hex      : N lines of 10 a + 10 w1 + 10 w2 lanes (hex bytes) and s1 s2 (int32 hex)
  scale_apply.hex : N lines "s e fp32 ovf unf"
"""
import os, random, struct, sys
import torch
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))
import agilex_quant as aq

OUT = os.path.join(os.path.dirname(__file__), "golden_vectors")
os.makedirs(OUT, exist_ok=True)
rnd = random.Random(7)


def h(v, bits):
    return f"{v & ((1 << bits) - 1):0{bits // 4}x}"


with open(f"{OUT}/e2m1.hex", "w") as f:
    for c in range(16):
        q = int(aq.e2m1_from_codes(torch.tensor([c]))[0])
        f.write(f"{h(c,4)} {h(q,8)}\n")

with open(f"{OUT}/int4.hex", "w") as f:
    for c in range(16):
        q = int(aq.int4_from_codes(torch.tensor([c]))[0])
        f.write(f"{h(c,4)} {h(q,8)} {1 if c == 8 else 0}\n")

with open(f"{OUT}/scale.hex", "w") as f:
    for c in range(32):
        e = c - 32 if c >= 16 else c
        f.write(f"0 {h(c,8)} {h(e,12)} 0\n")
    for c in range(256):
        f.write(f"1 {h(c,8)} {h(c - 127,12)} {1 if c == 255 else 0}\n")

N = 2000
with open(f"{OUT}/qdot10.hex", "w") as f:
    for n in range(N):
        if n < 4:   # directed: all max, all min, alternating, one lane
            a = [127] * 10 if n == 0 else [-128] * 10 if n == 1 else [127, -128] * 5 if n == 2 else [0] * 9 + [-128]
            w1 = [127] * 10 if n != 1 else [-128] * 10
            w2 = [-128] * 10 if n != 3 else [0] * 9 + [-128]
        else:
            a, w1, w2 = ([rnd.randrange(-128, 128) for _ in range(10)] for _ in range(3))
        s1 = sum(x * y for x, y in zip(a, w1)); s2 = sum(x * y for x, y in zip(a, w2))
        f.write(" ".join(h(v, 8) for v in a + w1 + w2) + f" {h(s1,32)} {h(s2,32)}\n")

with open(f"{OUT}/scale_apply.hex", "w") as f:
    cases = [(0, 0), (1, 0), (-1, 0), (516128, -2), (-516128, 5), (4608, -4), (28448, -3), (2**31 - 1, 0), (-2**31, 0),
             (12345678, 100), (3, -140), (0x00FFFFFF, 0), (0x01FFFFFF, 0), (0x01000001, 0), (0x01000003, 0)]
    for _ in range(N):
        cases.append((rnd.randrange(-(2**20), 2**20), rnd.randrange(-60, 60)))
    for s, e in cases:
        exact = s * (2.0 ** e)
        f32 = struct.unpack(">I", struct.pack(">f", exact))[0] if abs(exact) < 3.4e38 else (0x7F800000 | (0x80000000 if exact < 0 else 0))
        ovf = 1 if abs(exact) >= 2.0 ** 128 else 0
        unf = 1 if (exact != 0 and abs(exact) < 2.0 ** -126) else 0
        if unf: f32 = 0x80000000 if exact < 0 else 0  # flush to zero convention of the RTL
        f.write(f"{h(s,32)} {h(e,12)} {h(f32,32)} {ovf} {unf}\n")
print("wrote golden vectors to", OUT)
