"""
model_wrappers.py -- QuantizedLinearEmulator (spec 5.1) and helpers to wrap a HF causal LM.

Modes:
  observer        : pass-through, records activation statistics (max|x|, exponent histogram, clip rate)
  fake_quant      : y = linear(fake_quant(x, act_fmt), fake_quant(W, w_fmt), b) in the model dtype
  packed_reference: not implemented here (see agilex_quant.integer_dot_group for the exact oracle)

Activation quantization is dynamic per token and per 32-element K group (spec 3.1 default).
Weight quantization is per output channel, per 32-element K group; computed once and cached.
"""
from __future__ import annotations
import re
import torch, torch.nn as nn
import agilex_quant as aq

QUANT_MODULES = ("q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj")


class QuantizedLinearEmulator(nn.Module):
    def __init__(self, lin: nn.Linear, name: str, weight_fmt: str | None, activation_fmt: str | None,
                 group_size: int = 32, mode: str = "fake_quant"):
        super().__init__()
        self.lin = lin
        self.name = name
        self.weight_fmt = weight_fmt            # None = keep bf16
        self.activation_fmt = activation_fmt    # None = keep bf16
        self.group_size = group_size
        self.mode = mode
        self.master_weight = lin.weight.detach().clone()
        self._wq = None
        self.stats = {"max_abs": 0.0, "clip_count": 0, "count": 0, "exp_hist": {}}

    def set_formats(self, weight_fmt, activation_fmt):
        if weight_fmt != self.weight_fmt:
            self._wq = None
        self.weight_fmt, self.activation_fmt = weight_fmt, activation_fmt

    def quantized_weight(self) -> torch.Tensor:
        if self.weight_fmt is None:
            return self.master_weight
        if self._wq is None:
            w = self.master_weight
            # quantize in chunks of rows to bound float64 memory
            out = torch.empty_like(w)
            step = 2048
            for r in range(0, w.shape[0], step):
                out[r:r + step] = aq.quant(w[r:r + step], self.weight_fmt, self.group_size).dequant().to(w.dtype)
            self._wq = out
        return self._wq

    def forward(self, x):
        if self.mode == "observer":
            with torch.no_grad():
                g, _ = aq._group(x.detach().float(), self.group_size)
                m = g.abs().amax(dim=-1)
                self.stats["max_abs"] = max(self.stats["max_abs"], float(m.max()))
                self.stats["count"] += x.numel()
            return self.lin(x)
        w = self.quantized_weight()
        if self.activation_fmt is not None:
            xq = aq.quant(x.float(), self.activation_fmt, self.group_size)
            # clipping statistics: saturated operands
            qmax = {"int8_bfp": 127, "int4_bfp": 7, "int5_bfp": 15, "mxfp4": 12}[self.activation_fmt]
            self.stats["clip_count"] += int((xq.q.abs() == qmax).sum())
            self.stats["count"] += x.numel()
            x = xq.dequant().to(x.dtype)
        return nn.functional.linear(x, w, self.lin.bias)


def wrap_model(model: nn.Module, weight_fmt, activation_fmt, group_size=32, mode="fake_quant",
               per_layer_weight_fmt: dict | None = None):
    """Replace every transformer-block Linear in QUANT_MODULES with an emulator. Returns {name: emulator}."""
    emus = {}
    for name, module in list(model.named_modules()):
        for child_name, child in list(module.named_children()):
            if isinstance(child, nn.Linear) and child_name in QUANT_MODULES:
                full = f"{name}.{child_name}" if name else child_name
                wf = per_layer_weight_fmt.get(full, weight_fmt) if per_layer_weight_fmt else weight_fmt
                emu = QuantizedLinearEmulator(child, full, wf, activation_fmt, group_size, mode)
                setattr(module, child_name, emu)
                emus[full] = emu
    return emus


def set_all(emus: dict, weight_fmt, activation_fmt, per_layer_weight_fmt: dict | None = None):
    for n, e in emus.items():
        wf = per_layer_weight_fmt.get(n, weight_fmt) if per_layer_weight_fmt else weight_fmt
        e.set_formats(wf, activation_fmt)


def layer_index(name: str) -> int:
    m = re.search(r"layers\.(\d+)\.", name)
    return int(m.group(1)) if m else -1
