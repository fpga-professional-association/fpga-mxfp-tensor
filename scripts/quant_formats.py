#!/usr/bin/env python3
"""
Post-training weight-only quantization of a small causal LM into the formats discussed in
docs/07_external_quantization_formats.md, measured by perplexity on a fixed text sample.

Formats (all weight-only, per group of G consecutive weights along the input dimension):
  bf16        : no quantization (baseline)
  int8_bfp    : signed 8-bit integers with one power-of-two scale per group (Altera INT8-BFP style)
  mxfp4       : OCP MXFP4 E2M1 elements with one E8M0 (power-of-two) scale per group of 32
  int4_bfp    : signed 4-bit integers with one power-of-two scale per group (the note's INT4-BFP)
  int4_bfp_g10/g20/g40 : same, with DSP-tile-sized groups

Scale rule for the BFP formats: the group's shared exponent is the smallest power of two such
that the largest magnitude fits the integer range (round-to-nearest-even on the mantissa, saturate).
For MXFP4 the shared scale is 2^(floor(log2(max|w|)) - 2) (OCP MX v1.0 reference: emax of the
element format is 2 for E2M1), then each element is rounded to the nearest E2M1 value.

Only nn.Linear weights inside transformer blocks are quantized; embeddings, lm_head and norms stay
in bf16, which mirrors how FPGA deployments would keep the sensitive layers at higher precision.

    .venv/Scripts/python scripts/quant_formats.py --model Qwen/Qwen2.5-0.5B --tokens 16384

Writes results/quant_formats_<model>.json and prints a table.
"""
import argparse, json, math, os, time
import torch, torch.nn as nn
from transformers import AutoModelForCausalLM, AutoTokenizer

E2M1_POS = torch.tensor([0.0, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0])


def pow2_shared_exp(maxabs: torch.Tensor, qmax: float) -> torch.Tensor:
    # smallest 2^e with maxabs / 2^e <= qmax ; maxabs==0 -> e = 0
    e = torch.ceil(torch.log2(torch.clamp(maxabs, min=1e-30) / qmax))
    return torch.where(maxabs > 0, e, torch.zeros_like(e))


def quant_int_bfp(w: torch.Tensor, bits: int, group: int) -> torch.Tensor:
    """Signed `bits`-bit integers per group with a shared power-of-two scale."""
    out_f, in_f = w.shape
    pad = (-in_f) % group
    wp = torch.nn.functional.pad(w.float(), (0, pad))
    g = wp.view(out_f, -1, group)
    qmax = 2 ** (bits - 1) - 1
    e = pow2_shared_exp(g.abs().amax(dim=-1, keepdim=True), qmax)
    scale = torch.pow(2.0, e)
    q = torch.clamp(torch.round(g / scale), -(qmax + 1), qmax)
    return (q * scale).view(out_f, -1)[:, :in_f].to(w.dtype)


def quant_mxfp4(w: torch.Tensor, group: int = 32) -> torch.Tensor:
    """OCP MXFP4: E2M1 elements, E8M0 shared scale per group (power of two)."""
    out_f, in_f = w.shape
    pad = (-in_f) % group
    wp = torch.nn.functional.pad(w.float(), (0, pad))
    g = wp.view(out_f, -1, group)
    maxabs = g.abs().amax(dim=-1, keepdim=True)
    # shared exponent so that the largest element maps near the top of E2M1 range (6.0)
    e = torch.floor(torch.log2(torch.clamp(maxabs, min=1e-30))) - 2.0
    e = torch.where(maxabs > 0, e, torch.zeros_like(e))
    scale = torch.pow(2.0, e)
    x = g / scale
    sign = torch.sign(x)
    mag = x.abs().clamp(max=6.0)
    # nearest E2M1 magnitude (ties to even on the representable grid)
    grid = E2M1_POS.to(w.device)
    idx = torch.bucketize(mag, grid)                       # grid[idx-1] <= mag < grid[idx]
    idx = idx.clamp(1, len(grid) - 1)
    lo, hi = grid[idx - 1], grid[idx]
    pick_hi = (mag - lo) > (hi - mag)
    tie = (mag - lo) == (hi - mag)
    # ties: pick the value whose mantissa LSB is even (grid index even)
    pick_hi = pick_hi | (tie & ((idx % 2) == 0))
    qmag = torch.where(pick_hi, hi, lo)
    return (sign * qmag * scale).view(out_f, -1)[:, :in_f].to(w.dtype)


FORMATS = {
    "bf16": None,
    "int8_bfp_g32": lambda w: quant_int_bfp(w, 8, 32),
    "mxfp4_g32": lambda w: quant_mxfp4(w, 32),
    "int4_bfp_g32": lambda w: quant_int_bfp(w, 4, 32),
    "int4_bfp_g10": lambda w: quant_int_bfp(w, 4, 10),
    "int4_bfp_g20": lambda w: quant_int_bfp(w, 4, 20),
    "int4_bfp_g40": lambda w: quant_int_bfp(w, 4, 40),
    "int5_bfp_g32": lambda w: quant_int_bfp(w, 5, 32),   # what MXFP4->INT5 pre-alignment costs in range terms
}


@torch.no_grad()
def perplexity(model, enc, seqlen, device):
    nll, count = 0.0, 0
    ids = enc.input_ids[0]
    n = (ids.numel() // seqlen) * seqlen
    for i in range(0, n, seqlen):
        chunk = ids[i:i + seqlen].unsqueeze(0).to(device)
        out = model(chunk, labels=chunk)
        nll += out.loss.float().item() * (seqlen - 1)
        count += seqlen - 1
    return math.exp(nll / count)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-0.5B")
    ap.add_argument("--tokens", type=int, default=16384)
    ap.add_argument("--seqlen", type=int, default=1024)
    ap.add_argument("--formats", default=",".join(FORMATS))
    ap.add_argument("--text", default="wikitext")
    a = ap.parse_args()
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    tok = AutoTokenizer.from_pretrained(a.model)
    model = AutoModelForCausalLM.from_pretrained(a.model, torch_dtype=dtype).to(device).eval()

    if a.text == "wikitext":
        from datasets import load_dataset
        ds = load_dataset("Salesforce/wikitext", "wikitext-2-raw-v1", split="test")
        text = "\n\n".join(ds["text"])
    else:
        text = open(a.text, encoding="utf-8").read()
    enc = tok(text, return_tensors="pt")
    enc.input_ids = enc.input_ids[:, :a.tokens]

    # the linear layers we quantize: everything inside the transformer blocks
    targets = [(n, m) for n, m in model.named_modules()
               if isinstance(m, nn.Linear) and "lm_head" not in n and "embed" not in n]
    originals = {n: m.weight.detach().clone() for n, m in targets}
    nparams = sum(w.numel() for w in originals.values())
    print(f"{a.model}: {len(targets)} linear layers, {nparams/1e6:.1f}M quantized params, "
          f"{enc.input_ids.numel()} eval tokens, device {device}")

    results = {}
    for name in a.formats.split(","):
        fn = FORMATS[name]
        t0 = time.time()
        for n, m in targets:
            w = originals[n]
            m.weight.data.copy_(w if fn is None else fn(w))
        ppl = perplexity(model, enc, a.seqlen, device)
        bits = {"bf16": 16, "int8_bfp_g32": 8 + 8 / 32, "mxfp4_g32": 4 + 8 / 32, "int4_bfp_g32": 4 + 8 / 32,
                "int4_bfp_g10": 4 + 8 / 10, "int4_bfp_g20": 4 + 8 / 20, "int4_bfp_g40": 4 + 8 / 40,
                "int5_bfp_g32": 5 + 8 / 32}[name]
        results[name] = {"ppl": ppl, "bits_per_weight": bits, "seconds": time.time() - t0}
        print(f"  {name:16} ppl {ppl:8.3f}   {bits:5.2f} b/weight   ({results[name]['seconds']:.0f}s)")

    os.makedirs("results", exist_ok=True)
    out = f"results/quant_formats_{a.model.replace('/', '_')}.json"
    json.dump({"model": a.model, "tokens": int(enc.input_ids.numel()), "seqlen": a.seqlen,
               "quantized_params": nparams, "results": results}, open(out, "w"), indent=1)
    print("wrote", out)


if __name__ == "__main__":
    main()
