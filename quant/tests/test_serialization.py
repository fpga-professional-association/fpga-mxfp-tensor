"""Spec M1: packing / export round trip on synthetic tensors for all three formats."""
import os, sys, torch
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))
import agilex_quant as aq
from export_checkpoint import export_tensor, import_tensor


def test_export_roundtrip_all_formats():
    g = torch.Generator().manual_seed(3)
    for fmt in ("int4_bfp", "int8_bfp", "mxfp4"):
        for shape in ((16, 32), (7, 45), (64, 1536)):   # includes K not multiple of 32
            w = torch.randn(*shape, generator=g, dtype=torch.float32) * 0.05
            wb, sb, info, qt = export_tensor(w, fmt)
            deq = import_tensor(wb, sb, info)
            assert torch.equal(deq, qt.dequant()), (fmt, shape)
            # padded lanes are zero codes and do not change the group scale
            if shape[1] % 32:
                assert (qt.q[..., -1, shape[1] % 32:] == 0).all()
            assert info["weights_bytes"] == shape[0] * info["padded_shape"][1] * (1 if fmt == "int8_bfp" else 0.5)
            if fmt == "mxfp4":
                assert all(b != 0xFF for b in sb)
