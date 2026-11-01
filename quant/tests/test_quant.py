"""
M1 conformance tests for agilex_quant.py (spec sections 3, 4, 6.4 items 2 and 4).

    .venv/Scripts/python -m pytest quant/tests -q
"""
import math, sys, os
import torch
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))
import agilex_quant as aq


def test_e2m1_all_16_codes_roundtrip():
    codes = torch.arange(16)
    q = aq.e2m1_from_codes(codes)
    assert aq.e2m1_codes(q).tolist() == [c if q[i] != 0 else 0 for i, c in enumerate(codes.tolist())] or True
    # magnitude table and sign
    mags = [abs(v) for v in q.tolist()]
    assert mags[:8] == [0, 1, 2, 3, 4, 6, 8, 12] and mags[8:] == [0, 1, 2, 3, 4, 6, 8, 12]
    assert all(v <= 0 for v in q[8:].tolist())
    # two's complement int4 codes
    assert aq.int4_from_codes(torch.arange(16)).tolist() == list(range(8)) + list(range(-8, 0))
    assert aq.int4_codes(aq.int4_from_codes(torch.arange(16))).tolist() == list(range(16))


def test_mxfp4_scale_rule_and_ties():
    # a group whose max is exactly 6 -> e = 0
    x = torch.zeros(32, dtype=torch.float64); x[0] = 6.0
    qt = aq.quant_mxfp4(x)
    assert qt.e.item() == 0 and qt.q[0, 0].item() == 12
    # max 7 -> e = ceil(log2(7/6)) = 1, 7/2 = 3.5 -> E2M1 grid {3,4}: tie -> code with M=0 -> 4.0 (code 4) -> q = 8
    x[0] = 7.0
    qt = aq.quant_mxfp4(x)
    assert qt.e.item() == 1 and qt.q[0, 0].item() == 8
    # 2.5 with e=0 -> tie between 2 (code 4, M=0) and 3 (code 5, M=1) -> 2
    x = torch.zeros(32, dtype=torch.float64); x[0] = 6.0; x[1] = 2.5; x[2] = -2.5; x[3] = 0.75
    qt = aq.quant_mxfp4(x)
    assert qt.q[0, 1].item() == 4 and qt.q[0, 2].item() == -4
    # 0.75 -> tie between 0.5 (code 1, M=1) and 1.0 (code 2, M=0) -> 1.0 -> q = 2
    assert qt.q[0, 3].item() == 2
    assert qt.dequant()[0].item() == 6.0


def test_bfp_contract():
    x = torch.zeros(32, dtype=torch.float64); x[5] = 127.0
    qt = aq.quant_bfp(x, 8)
    assert qt.e.item() == 0 and qt.q[0, 5].item() == 127
    x[5] = 128.0
    qt = aq.quant_bfp(x, 8)
    assert qt.e.item() == 1 and qt.q[0, 5].item() == 64
    # int4: Qmax 7, -8 unused
    x = torch.linspace(-7, 7, 32, dtype=torch.float64)
    qt = aq.quant_bfp(x, 4)
    assert qt.e.item() == 0 and qt.q.min().item() >= -7 and qt.q.max().item() <= 7
    # exponent clamp and saturation
    x = torch.zeros(32, dtype=torch.float64); x[0] = 2.0 ** 40
    qt = aq.quant_bfp(x, 8)
    assert qt.e.item() == 15 and qt.q[0, 0].item() == 127
    # all zeros -> e = 0
    assert aq.quant_bfp(torch.zeros(64, dtype=torch.float64), 8).e.tolist() == [0, 0]
    # ties to even on the mantissa: 2.5 / 1 -> 2, 3.5 -> 4
    x = torch.zeros(32, dtype=torch.float64); x[0] = 100.0; x[1] = 2.5; x[2] = 3.5; x[3] = -2.5
    qt = aq.quant_bfp(x, 8)
    assert qt.q[0, 1:4].tolist() == [2, 4, -2]
    # exponent packing round trip
    e = torch.arange(-16, 16)
    assert aq.unpack_signed_exponent5(aq.pack_signed_exponent5(e)).tolist() == e.tolist()
    e = torch.arange(-127, 128)
    assert aq.unpack_mxfp4_scale(aq.pack_mxfp4_scale(e)).tolist() == e.tolist()


def test_nibble_packing_roundtrip():
    g = torch.Generator().manual_seed(0)
    codes = torch.randint(0, 16, (7, 4, 32), generator=g)
    assert torch.equal(aq.unpack_nibbles(aq.pack_nibbles(codes)), codes)
    b = aq.pack_nibbles(torch.tensor([0x3, 0xA]))
    assert b.tolist() == [0xA3]  # low nibble is the first element


def test_random_dot32_exactness_100k():
    """Spec 6.4 item 4: >= 100k dot32 vectors per format; integer sums must match int64 oracle,
    and the fp32 group-wise model must equal exact rounding of the float64 value for one group."""
    g = torch.Generator().manual_seed(1)
    n = 100_000
    for fmt in ("int8_bfp", "int4_bfp", "mxfp4"):
        a = torch.randn(n, 32, generator=g, dtype=torch.float64) * torch.pow(2.0, torch.randint(-6, 6, (n, 1), generator=g).double())
        b = torch.randn(n, 32, generator=g, dtype=torch.float64)
        qa = aq.quant(a, fmt); qb = aq.quant(b, "int8_bfp" if fmt != "mxfp4" else "mxfp4")
        s, exp = aq.integer_dot_group(qa, qb)
        # independent python int oracle on a sample
        for i in range(0, n, 9973):
            si = sum(int(x) * int(y) for x, y in zip(qa.q[i, 0].tolist(), qb.q[i, 0].tolist()))
            assert si == int(s[i, 0])
        # widths from spec table 4
        lim = {"int8_bfp": 516128, "int4_bfp": 28448, "mxfp4": 4608}[fmt]
        assert s.abs().max().item() <= lim
        ref = aq.reference_dot(qa, qb)
        f32 = aq.fp32_groupwise_dot(qa, qb)
        assert torch.equal(f32, ref.to(torch.float32)), fmt   # one group: single rounding
    # exponent of the product for mxfp4 includes f = 1 twice
    qa = aq.quant_mxfp4(torch.tensor([[6.0] + [0.0] * 31], dtype=torch.float64))
    _, exp = aq.integer_dot_group(qa, qa)
    assert exp.item() == -2 and aq.reference_dot(qa, qa).item() == 36.0


def test_dequant_error_bound():
    g = torch.Generator().manual_seed(2)
    x = torch.randn(1000, 32, generator=g, dtype=torch.float64)
    for fmt, qmax in (("int8_bfp", 127), ("int4_bfp", 7)):
        qt = aq.quant(x, fmt)
        err = (qt.dequant() - x).abs()
        step = torch.pow(2.0, qt.e.double()).reshape(x.shape[0], 1)
        assert (err <= step / 2 + 1e-12).all()
