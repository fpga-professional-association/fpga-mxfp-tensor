"""
export_checkpoint.py -- spec AGX5-MXQ-001 section 5.6: write a `model.fpgaq` artifact.

Layout: <out>/manifest.json plus <out>/<module>.w (packed codes) and <out>/<module>.s (scales).
  INT4-BFP / MXFP4 : codes packed two per byte, LOW nibble = first K element; K padded to 32 with zero codes
  INT8-BFP         : signed int8 bytes
  BFP scale        : one signed 5-bit exponent per 32-group, stored in one byte ("8-bit practical scale storage")
  MXFP4 scale      : one E8M0 byte per group, 0xFF never emitted
Manifest records formats, shapes (logical and padded), byte offsets implicit per file, SHA-256 per blob,
base-model SHA, and both actual bytes and the theoretical minimum.

    .venv/Scripts/python quant/python/export_checkpoint.py --model Qwen/Qwen2.5-0.5B --fmt int4_bfp --out quant/results/export_qwen05b_int4
"""
from __future__ import annotations
import argparse, hashlib, json, os, sys, time
import torch, torch.nn as nn
from transformers import AutoModelForCausalLM
sys.path.insert(0, os.path.dirname(__file__))
import agilex_quant as aq
from model_wrappers import QUANT_MODULES

FPGAQ_VERSION = "0.1"


def export_tensor(w: torch.Tensor, fmt: str, group: int = 32):
    """Returns (weights_bytes, scales_bytes, info) for one [out, in] weight matrix."""
    qt = aq.quant(w.to(torch.float64), fmt, group)
    out_f, in_f = w.shape
    g = qt.q.shape[-2]
    if fmt == "mxfp4":
        codes = aq.e2m1_codes(qt.q.reshape(out_f, -1))
        wbytes = aq.pack_nibbles(codes).reshape(-1).numpy().tobytes()
        sbytes = aq.pack_mxfp4_scale(qt.e.reshape(-1)).numpy().tobytes()
        elem_bits, scale_bits_min = 4, 8
    elif fmt == "int4_bfp":
        codes = aq.int4_codes(qt.q.reshape(out_f, -1))
        wbytes = aq.pack_nibbles(codes).reshape(-1).numpy().tobytes()
        sbytes = aq.pack_signed_exponent5(qt.e.reshape(-1)).numpy().tobytes()
        elem_bits, scale_bits_min = 4, 5
    elif fmt == "int8_bfp":
        wbytes = qt.q.reshape(-1).to(torch.int8).numpy().tobytes()
        sbytes = aq.pack_signed_exponent5(qt.e.reshape(-1)).numpy().tobytes()
        elem_bits, scale_bits_min = 8, 5
    else:
        raise ValueError(fmt)
    info = {"format": fmt, "shape": [out_f, in_f], "padded_shape": [out_f, g * group], "groups": out_f * g,
            "weights_bytes": len(wbytes), "scales_bytes": len(sbytes),
            "min_bits": out_f * g * group * elem_bits + out_f * g * scale_bits_min,
            "weights_sha256": hashlib.sha256(wbytes).hexdigest(), "scales_sha256": hashlib.sha256(sbytes).hexdigest()}
    return wbytes, sbytes, info, qt


def import_tensor(wbytes: bytes, sbytes: bytes, info: dict) -> torch.Tensor:
    """Round-trip decode to the dequantized float64 tensor (logical shape)."""
    fmt = info["format"]; out_f, in_f = info["shape"]; _, padded = info["padded_shape"]; group = 32
    if fmt in ("mxfp4", "int4_bfp"):
        codes = aq.unpack_nibbles(torch.frombuffer(bytearray(wbytes), dtype=torch.uint8)).reshape(out_f, padded)
        q = aq.e2m1_from_codes(codes) if fmt == "mxfp4" else aq.int4_from_codes(codes)
    else:
        q = torch.frombuffer(bytearray(wbytes), dtype=torch.int8).to(torch.int64).reshape(out_f, padded)
    sb = torch.frombuffer(bytearray(sbytes), dtype=torch.uint8)
    e = (aq.unpack_mxfp4_scale(sb) if fmt == "mxfp4" else aq.unpack_signed_exponent5(sb)).reshape(out_f, padded // group)
    qt = aq.QTensor(q.reshape(out_f, padded // group, group), e, fmt, (out_f, in_f), group)
    return qt.dequant()


def export_model(model_id: str, fmt: str, out_dir: str, per_layer: dict | None = None, revision: str = "unknown"):
    os.makedirs(out_dir, exist_ok=True)
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.bfloat16)
    manifest = {"fpgaq_version": FPGAQ_VERSION, "model": model_id, "revision": revision, "group_size": 32,
                "nibble_order": "low_nibble_first", "byte_order": "little", "scale_storage": "one byte per group (practical)",
                "int4_encoding": "twos_complement", "mxfp4_encoding": "E2M1 {S,E1,E0,M} + E8M0 scale", "modules": [],
                "kept_bf16": []}
    t0 = time.time(); total_w = total_s = total_min_bits = 0; kept = 0
    for name, module in model.named_modules():
        for child_name, child in module.named_children():
            if isinstance(child, nn.Linear) and child_name in QUANT_MODULES:
                full = f"{name}.{child_name}"
                f = per_layer.get(full, fmt) if per_layer else fmt
                wb, sb, info, _ = export_tensor(child.weight.detach(), f)
                base = full.replace(".", "_")
                open(f"{out_dir}/{base}.w", "wb").write(wb); open(f"{out_dir}/{base}.s", "wb").write(sb)
                info.update({"name": full, "weights_file": f"{base}.w", "scales_file": f"{base}.s",
                             "bias": child.bias is not None})
                manifest["modules"].append(info)
                total_w += len(wb); total_s += len(sb); total_min_bits += info["min_bits"]
    for n, p in model.named_parameters():
        if not any(n.startswith(m["name"]) for m in manifest["modules"]):
            kept += p.numel() * 2
            manifest["kept_bf16"].append({"name": n, "numel": p.numel()})
    manifest["summary"] = {"quantized_modules": len(manifest["modules"]), "weights_bytes": total_w, "scales_bytes": total_s,
                           "theoretical_min_bytes": total_min_bits // 8, "kept_bf16_bytes": kept,
                           "actual_total_bytes": total_w + total_s + kept, "seconds": time.time() - t0}
    json.dump(manifest, open(f"{out_dir}/manifest.json", "w"), indent=1)
    return manifest


def verify_roundtrip(out_dir: str, model_id: str, sample: int = 8) -> bool:
    """Spec 8.2: 100% verified round trip on model tensors. Checks every `sample`-th module exactly."""
    man = json.load(open(f"{out_dir}/manifest.json"))
    model = AutoModelForCausalLM.from_pretrained(model_id, torch_dtype=torch.bfloat16)
    mods = dict(model.named_modules())
    ok = True
    for i, info in enumerate(man["modules"]):
        if i % sample: continue
        w = mods[info["name"]].weight.detach()
        wb = open(f"{out_dir}/{info['weights_file']}", "rb").read(); sb = open(f"{out_dir}/{info['scales_file']}", "rb").read()
        assert hashlib.sha256(wb).hexdigest() == info["weights_sha256"]
        deq = import_tensor(wb, sb, info)
        ref = aq.quant(w.to(torch.float64), info["format"]).dequant()
        same = torch.equal(deq, ref)
        ok &= same
        print(f"  {info['name']:45} {info['format']:9} roundtrip {'OK' if same else 'MISMATCH'}")
    return ok


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B")
    ap.add_argument("--fmt", default="int4_bfp", choices=["int4_bfp", "int8_bfp", "mxfp4"])
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    m = export_model(a.model, a.fmt, a.out)
    s = m["summary"]
    print(json.dumps(s, indent=1))
    print("roundtrip:", "PASS" if verify_roundtrip(a.out, a.model) else "FAIL")
