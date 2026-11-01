"""
sensitivity.py -- per-layer sensitivity map and W8 budget allocator (spec 5.4).

delta_L[l] = loss(model with only layer l at W4, activations INT8) - loss(bf16), on a fixed slice.
allocate_w8 ranks layers by delta_L per additional weight byte (W8 - W4) and promotes layers to
INT8-BFP until the parameter budget is spent (deterministic greedy baseline from the spec).
"""
from __future__ import annotations
import math
import torch, torch.nn.functional as F
from model_wrappers import set_all


@torch.no_grad()
def mean_loss(model, ids, seqlen, device):
    n = (ids.numel() // seqlen) * seqlen
    tot, cnt = 0.0, 0
    for i in range(0, n, seqlen):
        chunk = ids[i:i + seqlen].unsqueeze(0).to(device)
        lg = model(chunk).logits[0, :-1].float()
        tot += F.cross_entropy(lg, chunk[0, 1:], reduction="sum").item()
        cnt += seqlen - 1
    return tot / cnt


def sensitivity_map(model, emus, ids, seqlen, device, w4_fmt="int4_bfp", act_fmt="int8_bfp"):
    set_all(emus, None, None)
    base = mean_loss(model, ids, seqlen, device)
    out = {"base_loss": base, "w4_fmt": w4_fmt, "act_fmt": act_fmt, "tokens": int(ids.numel()), "layers": {}}
    names = list(emus)
    for k, n in enumerate(names):
        per = {m: None for m in names}
        per[n] = w4_fmt
        # only layer n quantized (weights W4, its activations INT8); everything else bf16
        for m, e in emus.items():
            e.set_formats(per[m], act_fmt if m == n else None)
        loss = mean_loss(model, ids, seqlen, device)
        e = emus[n]
        out["layers"][n] = {"delta_loss": loss - base, "params": int(e.master_weight.numel()),
                            "extra_bytes_w8": int(e.master_weight.numel() * 4 / 8)}
        if k % 20 == 0:
            print(f"    sensitivity {k+1}/{len(names)} {n}: dL={loss-base:+.5f}")
    set_all(emus, None, None)
    return out


def allocate_w8(sens: dict, emus: dict, budget_fraction: float) -> set:
    total = sum(e.master_weight.numel() for e in emus.values())
    budget = budget_fraction * total
    ranked = sorted(sens["layers"].items(), key=lambda kv: kv[1]["delta_loss"] / max(1, kv[1]["extra_bytes_w8"]), reverse=True)
    chosen, used = set(), 0
    for n, s in ranked:
        if used + s["params"] <= budget:
            chosen.add(n); used += s["params"]
    return chosen
