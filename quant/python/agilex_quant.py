"""
agilex_quant.py -- quantizers, exact oracles and packing for spec AGX5-MXQ-001 (quant/AGX5_MXQ_SPEC.md).

Numeric contracts (spec section 3):

  BFP (C0 INT8-BFP, C2 INT4-BFP): per group of K=32 values x,
      e   = clamp(ceil(log2(max|x| / Qmax)), -16, +15), e = 0 if the group is all zero
      q_i = clip(roundTiesToEven(x_i / 2^e), -Qmax, +Qmax)         Qmax = 127 (int8) or 7 (int4)
      value = q * 2^e ; exponent stored as signed 5-bit two's complement
  MXFP4 (C1): E2M1 elements, E8M0 scale X per group of 32
      e = clamp(ceil(log2(max|x| / 6)), -127, +127), X = e + 127 (0xFF reserved, never emitted)
      element = nearest E2M1 value of x / 2^e, ties to the code with mantissa LSB 0
      integer operand q = 2 * E2M1_value in {0, +-1, +-2, +-3, +-4, +-6, +-8, +-12}, so value = q * 2^(e-1)

Exact arithmetic (spec section 4): for one group S_g = sum q_w q_a (int64), Y_g = S_g * 2^(e_w + e_a - f_w - f_a)
with f = 1 for MXFP4 operands and 0 for BFP operands.

Everything is torch-based so the same code runs the fake-quant model path on GPU.
"""
from __future__ import annotations
import math
from dataclasses import dataclass
import torch

K_DEFAULT = 32
E2M1_MAGS = torch.tensor([0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0])          # code 0..7 (sign bit separate)
E2M1_Q = torch.tensor([0, 1, 2, 3, 4, 6, 8, 12], dtype=torch.int64)      # 2 * value

FORMATS = {
    # name: (kind, Qmax or None, f, exp_bits)
    "int8_bfp": ("bfp", 127, 0, 5),
    "int4_bfp": ("bfp", 7, 0, 5),
    "int5_bfp": ("bfp", 15, 0, 5),      # extra: what the MXFP4 lanes could carry as plain integers
    "mxfp4":    ("mx", None, 1, 8),
}


@dataclass
class QTensor:
    """Group-quantized tensor. q: int64 operands [..., G, K]; e: int64 exponents [..., G]; fmt: format name."""
    q: torch.Tensor
    e: torch.Tensor
    fmt: str
    orig_shape: tuple
    group: int

    @property
    def f(self) -> int:
        return FORMATS[self.fmt][2]

    def dequant(self) -> torch.Tensor:
        """Reference reconstruction: q * 2^(e - f), un-padded to the original shape (float64)."""
        scale = torch.pow(2.0, (self.e - self.f).to(torch.float64)).unsqueeze(-1)
        x = (self.q.to(torch.float64) * scale).reshape(*self.orig_shape[:-1], -1)
        return x[..., : self.orig_shape[-1]]


def _group(x: torch.Tensor, group: int):
    """Pad the last dim to a multiple of `group` with zeros and view as [..., G, group]."""
    n = x.shape[-1]
    pad = (-n) % group
    xp = torch.nn.functional.pad(x, (0, pad))
    return xp.reshape(*x.shape[:-1], -1, group), pad


def quant_bfp(x: torch.Tensor, width: int = 8, group: int = K_DEFAULT, emin: int = -16, emax: int = 15) -> QTensor:
    assert width in (4, 5, 8)
    qmax = 2 ** (width - 1) - 1
    fmt = {8: "int8_bfp", 4: "int4_bfp", 5: "int5_bfp"}[width]
    if not torch.isfinite(x).all():
        raise ValueError("non-finite input: fail closed (spec 3.2)")
    g, _ = _group(x.to(torch.float64), group)
    maxabs = g.abs().amax(dim=-1)
    e = torch.ceil(torch.log2(torch.clamp(maxabs, min=torch.finfo(torch.float64).tiny) / qmax))
    e = torch.where(maxabs > 0, e, torch.zeros_like(e)).clamp(emin, emax).to(torch.int64)
    scale = torch.pow(2.0, e.to(torch.float64)).unsqueeze(-1)
    q = torch.round(g / scale)                      # torch.round is round-half-to-even
    q = q.clamp(-qmax, qmax).to(torch.int64)
    return QTensor(q, e, fmt, tuple(x.shape), group)


def quant_mxfp4(x: torch.Tensor, group: int = K_DEFAULT) -> QTensor:
    if not torch.isfinite(x).all():
        raise ValueError("non-finite input: fail closed (spec 3.2)")
    g, _ = _group(x.to(torch.float64), group)
    maxabs = g.abs().amax(dim=-1)
    e = torch.ceil(torch.log2(torch.clamp(maxabs, min=torch.finfo(torch.float64).tiny) / 6.0))
    e = torch.where(maxabs > 0, e, torch.zeros_like(e)).clamp(-127, 127).to(torch.int64)
    scale = torch.pow(2.0, e.to(torch.float64)).unsqueeze(-1)
    y = g / scale
    sign = torch.sign(y)
    mag = y.abs().clamp(max=6.0)
    mags = E2M1_MAGS.to(torch.float64).to(x.device)
    hi_idx = torch.bucketize(mag, mags, right=False).clamp(1, 7)   # mags[hi_idx-1] <= mag <= mags[hi_idx]
    lo, hi = mags[hi_idx - 1], mags[hi_idx]
    d_lo, d_hi = mag - lo, hi - mag
    take_hi = d_hi < d_lo
    tie = d_hi == d_lo
    # ties -> code with mantissa LSB 0: codes are 0..7 = {E,M}; LSB is M; even code index has M=0
    take_hi = take_hi | (tie & ((hi_idx % 2) == 0))
    code = torch.where(take_hi, hi_idx, hi_idx - 1)
    q = E2M1_Q.to(x.device)[code] * sign.to(torch.int64)
    return QTensor(q, e, "mxfp4", tuple(x.shape), group)


def quant(x: torch.Tensor, fmt: str, group: int = K_DEFAULT) -> QTensor:
    kind, qmax, _, _ = FORMATS[fmt]
    if kind == "mx":
        return quant_mxfp4(x, group)
    width = {127: 8, 7: 4, 15: 5}[qmax]
    return quant_bfp(x, width, group)


def fake_quant(x: torch.Tensor, fmt: str, group: int = K_DEFAULT) -> torch.Tensor:
    """Quantize-dequantize in x's dtype with a straight-through gradient (minimal STE surrogate)."""
    with torch.no_grad():
        xq = quant(x, fmt, group).dequant().to(x.dtype)
    return x + (xq - x).detach()


# --------------------------------------------------------------------------- exact oracles
def integer_dot_group(qa: QTensor, qb: QTensor):
    """Exact int64 group sums S_g and the combined exponent (e_a + e_b - f_a - f_b) per group."""
    assert qa.group == qb.group and qa.q.shape == qb.q.shape
    s = (qa.q * qb.q).sum(dim=-1)                       # int64 exact (|S| <= 32 * 127 * 127)
    exp = qa.e + qb.e - qa.f - qb.f
    return s, exp


def reference_dot(qa: QTensor, qb: QTensor) -> torch.Tensor:
    """float64 oracle: sum_g S_g * 2^exp_g."""
    s, exp = integer_dot_group(qa, qb)
    return (s.to(torch.float64) * torch.pow(2.0, exp.to(torch.float64))).sum(dim=-1)


def fp32_groupwise_dot(qa: QTensor, qb: QTensor) -> torch.Tensor:
    """Bit-level FPGA-style model: each group scaled exactly then rounded once to fp32, groups
    accumulated in fp32 in order. Matches the tensor-FP cascade for one group; multi-group order
    is the model's convention."""
    s, exp = integer_dot_group(qa, qb)
    y_g = (s.to(torch.float64) * torch.pow(2.0, exp.to(torch.float64))).to(torch.float32)
    acc = torch.zeros(y_g.shape[:-1], dtype=torch.float32, device=y_g.device)
    for g in range(y_g.shape[-1]):
        acc = acc + y_g[..., g]
    return acc


# --------------------------------------------------------------------------- packing
def pack_nibbles(codes: torch.Tensor) -> torch.Tensor:
    """codes: int64 [..., N] with values 0..15, N even. Low nibble = first element."""
    c = codes.to(torch.int64) & 0xF
    assert c.shape[-1] % 2 == 0
    lo, hi = c[..., 0::2], c[..., 1::2]
    return (lo | (hi << 4)).to(torch.uint8)


def unpack_nibbles(b: torch.Tensor) -> torch.Tensor:
    b = b.to(torch.int64)
    out = torch.stack([b & 0xF, (b >> 4) & 0xF], dim=-1)
    return out.reshape(*b.shape[:-1], -1)


def int4_codes(q: torch.Tensor) -> torch.Tensor:
    """Signed int4 two's complement codes 0..15 from q in [-8, 7]."""
    return q.to(torch.int64) & 0xF


def int4_from_codes(c: torch.Tensor) -> torch.Tensor:
    c = c.to(torch.int64) & 0xF
    return torch.where(c >= 8, c - 16, c)


def e2m1_codes(q: torch.Tensor) -> torch.Tensor:
    """E2M1 4-bit codes {S,E1,E0,M} from integer operands q = 2*value."""
    mag = q.abs()
    table = {0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 6: 5, 8: 6, 12: 7}
    lut = torch.full((13,), -1, dtype=torch.int64, device=q.device)
    for k, v in table.items():
        lut[k] = v
    code = lut[mag]
    assert (code >= 0).all(), "non-E2M1 operand"
    return code | ((q < 0).to(torch.int64) << 3)


def e2m1_from_codes(c: torch.Tensor) -> torch.Tensor:
    c = c.to(torch.int64) & 0xF
    q = E2M1_Q.to(c.device)[c & 7]
    return torch.where((c >> 3) == 1, -q, q)


def pack_signed_exponent5(e: torch.Tensor) -> torch.Tensor:
    assert ((e >= -16) & (e <= 15)).all()
    return (e.to(torch.int64) & 0x1F).to(torch.uint8)


def unpack_signed_exponent5(b: torch.Tensor) -> torch.Tensor:
    v = b.to(torch.int64) & 0x1F
    return torch.where(v >= 16, v - 32, v)


def pack_mxfp4_scale(e: torch.Tensor) -> torch.Tensor:
    x = e.to(torch.int64) + 127
    assert ((x >= 0) & (x <= 254)).all(), "E8M0 0xFF reserved"
    return x.to(torch.uint8)


def unpack_mxfp4_scale(b: torch.Tensor) -> torch.Tensor:
    x = b.to(torch.int64)
    assert (x != 0xFF).all(), "reserved E8M0 NaN scale"
    return x - 127


def to_dsp_lanes(qt: QTensor) -> torch.Tensor:
    """Signed 8-bit DSP operands (sign-extended), as int8. Valid for every format here."""
    assert ((qt.q >= -128) & (qt.q <= 127)).all()
    return qt.q.to(torch.int8)


def bits_per_weight(fmt: str, group: int = K_DEFAULT, practical_scale_byte: bool = False) -> float:
    kind, qmax, _, ebits = FORMATS[fmt]
    elem = {"int8_bfp": 8, "int4_bfp": 4, "int5_bfp": 5, "mxfp4": 4}[fmt]
    sbits = 8 if practical_scale_byte else ebits
    return elem + sbits / group
