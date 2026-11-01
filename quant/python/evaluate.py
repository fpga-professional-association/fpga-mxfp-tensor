"""
evaluate.py -- M2 PTQ model-quality matrix for spec AGX5-MXQ-001 (sections 5.3, 5.4, 8.1).

Runs, on one pinned model and one fixed token stream:
  B0   bf16 baseline
  C0   INT8-BFP  W8A8
  C1   MXFP4     W4A4           C1a  MXFP4 weights + INT8-BFP activations (W4A8)
  C2   INT4-BFP  W4A8           C2a  INT4-BFP W4A4
  C3   mixed W4/W8 - A8 at W8 budgets 5/10/20/40% of eligible parameters, allocated by the
       per-layer sensitivity map from sensitivity.py (delta loss per extra byte)
  X5   INT5-BFP W5A8 (extra: the operand width the MXFP4 lanes already carry)

Metrics: WikiText-2 perplexity, mean KL(bf16 || quant) over next-token distributions, top-1
agreement with bf16, mean clipping rate of activations. Writes results/quality/<model>.json and a
manifest with model/tokenizer SHAs and library versions.

    .venv/Scripts/python quant/python/evaluate.py --model Qwen/Qwen2.5-1.5B-Instruct --tokens 65536
"""
from __future__ import annotations
import argparse, hashlib, json, math, os, sys, time, platform
import torch, torch.nn.functional as F
import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer
from huggingface_hub import HfApi

sys.path.insert(0, os.path.dirname(__file__))
import agilex_quant as aq
from model_wrappers import wrap_model, set_all
from sensitivity import sensitivity_map, allocate_w8

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

CONFIGS = [
    ("B0_bf16", None, None),
    ("C0_int8_bfp_w8a8", "int8_bfp", "int8_bfp"),
    ("C1_mxfp4_w4a4", "mxfp4", "mxfp4"),
    ("C1a_mxfp4_w4a8", "mxfp4", "int8_bfp"),
    ("C2_int4_bfp_w4a8", "int4_bfp", "int8_bfp"),
    ("C2a_int4_bfp_w4a4", "int4_bfp", "int4_bfp"),
    ("X5_int5_bfp_w5a8", "int5_bfp", "int8_bfp"),
]


def load_text(tok, tokens: int):
    from datasets import load_dataset
    ds = load_dataset("Salesforce/wikitext", "wikitext-2-raw-v1", split="test")
    text = "\n\n".join(ds["text"])
    ids = tok(text, return_tensors="pt").input_ids[0, :tokens]
    return ids


@torch.no_grad()
def run_eval(model, ids, seqlen, device, ref_logits=None, keep_logits=False):
    """Returns ppl, mean KL vs ref (if given), top1 agreement vs ref, and optionally the logits."""
    n = (ids.numel() // seqlen) * seqlen
    nll, cnt, kl, agree, tot = 0.0, 0, 0.0, 0, 0
    logits_out = [] if keep_logits else None
    for ci, i in enumerate(range(0, n, seqlen)):
        chunk = ids[i:i + seqlen].unsqueeze(0).to(device)
        out = model(chunk)
        lg = out.logits[0, :-1].float()
        tgt = chunk[0, 1:]
        nll += F.cross_entropy(lg, tgt, reduction="sum").item()
        cnt += tgt.numel()
        if ref_logits is not None:
            rl = ref_logits[ci].to(device)
            kl += F.kl_div(F.log_softmax(lg, -1), F.log_softmax(rl, -1), log_target=True, reduction="sum").item()
            agree += (lg.argmax(-1) == rl.argmax(-1)).sum().item()
            tot += tgt.numel()
        if keep_logits:
            logits_out.append(lg.to(torch.float16).cpu())
    res = {"ppl": math.exp(nll / cnt), "tokens": cnt}
    if ref_logits is not None:
        res["kl_vs_bf16"] = kl / tot
        res["top1_agree_vs_bf16"] = agree / tot
    return res, logits_out


def sha256_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="Qwen/Qwen2.5-1.5B-Instruct")
    ap.add_argument("--tokens", type=int, default=65536)
    ap.add_argument("--seqlen", type=int, default=1024)
    ap.add_argument("--sens_tokens", type=int, default=8192, help="tokens for the per-layer sensitivity map")
    ap.add_argument("--skip_c3", action="store_true")
    a = ap.parse_args()
    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.bfloat16 if device == "cuda" else torch.float32

    tok = AutoTokenizer.from_pretrained(a.model)
    model = AutoModelForCausalLM.from_pretrained(a.model, torch_dtype=dtype).to(device).eval()
    ids = load_text(tok, a.tokens)
    # manifest (spec M0)
    try:
        info = HfApi().model_info(a.model)
        revision = info.sha
    except Exception:
        revision = "offline"
    manifest = {"model": a.model, "revision": revision, "transformers": transformers.__version__,
                "torch": torch.__version__, "device": torch.cuda.get_device_name(0) if device == "cuda" else platform.processor(),
                "eval_tokens": int(ids.numel()), "seqlen": a.seqlen,
                "eval_text_sha256": hashlib.sha256(ids.numpy().tobytes()).hexdigest()}
    os.makedirs(f"{ROOT}/manifests", exist_ok=True); os.makedirs(f"{ROOT}/results/quality", exist_ok=True)
    json.dump(manifest, open(f"{ROOT}/manifests/model_sha.json", "w"), indent=1)

    emus = wrap_model(model, None, None)
    nparams = sum(e.master_weight.numel() for e in emus.values())
    print(f"{a.model}: {len(emus)} quantized linears, {nparams/1e6:.1f}M params, {ids.numel()} eval tokens")

    results = {}
    t0 = time.time()
    base, ref_logits = run_eval(model, ids, a.seqlen, device, keep_logits=True)
    results["B0_bf16"] = {**base, "weight_fmt": None, "act_fmt": None, "bits_per_weight": 16.0, "seconds": time.time() - t0}
    print(f"  {'B0_bf16':22} ppl {base['ppl']:8.3f}")

    for name, wf, af in CONFIGS[1:]:
        t0 = time.time()
        set_all(emus, wf, af)
        for e in emus.values(): e.stats["clip_count"] = 0; e.stats["count"] = 0
        r, _ = run_eval(model, ids, a.seqlen, device, ref_logits)
        clip = sum(e.stats["clip_count"] for e in emus.values()) / max(1, sum(e.stats["count"] for e in emus.values()))
        results[name] = {**r, "weight_fmt": wf, "act_fmt": af, "bits_per_weight": aq.bits_per_weight(wf),
                         "act_clip_rate": clip, "seconds": time.time() - t0}
        print(f"  {name:22} ppl {r['ppl']:8.3f}  KL {r['kl_vs_bf16']:.4f}  top1 {r['top1_agree_vs_bf16']:.4f}  clip {clip:.2e}  ({time.time()-t0:.0f}s)")

    if not a.skip_c3:
        # sensitivity map: loss with only layer l at INT4-BFP (W4A8) minus bf16 loss, on a slice
        sens = sensitivity_map(model, emus, ids[: a.sens_tokens], a.seqlen, device, w4_fmt="int4_bfp", act_fmt="int8_bfp")
        json.dump(sens, open(f"{ROOT}/results/quality/sensitivity_{a.model.replace('/', '_')}.json", "w"), indent=1)
        for budget in (0.05, 0.10, 0.20, 0.40):
            alloc = allocate_w8(sens, emus, budget)
            per_layer = {n: ("int8_bfp" if n in alloc else "int4_bfp") for n in emus}
            t0 = time.time()
            set_all(emus, "int4_bfp", "int8_bfp", per_layer)
            r, _ = run_eval(model, ids, a.seqlen, device, ref_logits)
            w8_params = sum(emus[n].master_weight.numel() for n in alloc)
            bpw = (w8_params * aq.bits_per_weight("int8_bfp") + (nparams - w8_params) * aq.bits_per_weight("int4_bfp")) / nparams
            name = f"C3_mixed_w8_{int(budget*100):02d}pct"
            results[name] = {**r, "weight_fmt": "mixed", "act_fmt": "int8_bfp", "bits_per_weight": bpw,
                             "w8_layers": sorted(alloc), "w8_param_fraction": w8_params / nparams, "seconds": time.time() - t0}
            print(f"  {name:22} ppl {r['ppl']:8.3f}  KL {r['kl_vs_bf16']:.4f}  top1 {r['top1_agree_vs_bf16']:.4f}  {bpw:.2f} b/w  ({len(alloc)} layers W8)")

    out = f"{ROOT}/results/quality/{a.model.replace('/', '_')}.json"
    json.dump({"manifest": manifest, "quantized_params": nparams, "results": results}, open(out, "w"), indent=1)
    print("wrote", out)


if __name__ == "__main__":
    main()
