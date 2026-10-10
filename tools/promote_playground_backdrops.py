#!/usr/bin/env python3
"""Promote the approved Playground chapter backdrops into assets/premium/presentation/backdrops/.

Originals in asset_bank/playground stay untouched. Baked letterbox/pillarbox bands are detected
(near-uniform edge rows/columns) and cropped, the result is cover-fitted to 1600x900 and written as JPEG
(illustrations only, never used as walkable rooms). Provenance goes to backdrops/PROVENANCE.json.
Usage: python3 tools/promote_playground_backdrops.py
"""
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "premium" / "presentation" / "backdrops"
BANK = ROOT / "asset_bank" / "playground"
TARGET = (1600, 900)
# chapter id -> (source file, role)
SELECTION = {
    "ch1": ("round_02_four_worlds/original_webp/backgrounds/bg_machine_empire.webp", "chapter backdrop: corrupted technology"),
    "ch2": ("round_02_four_worlds/original_webp/backgrounds/bg_jade_empire.webp", "chapter backdrop: jade civilization"),
    "ch3": ("round_02_four_worlds/original_webp/backgrounds/bg_scarlet_fortress.webp", "chapter backdrop: dark fortress"),
    "ch4": ("round_02_four_worlds/original_webp/backgrounds/bg_fractured_dimension.webp", "chapter backdrop: interdimensional rift"),
}


def _edge(profile, lo, hi, ratio=4.0):
    """Index of the sharpest step of `profile` inside [lo, hi) if it stands out from the median; else None."""
    seg = profile[lo:hi]
    i = int(seg.argmax())
    base = float(np.median(profile)) + 1e-3
    return lo + i + 1 if seg[i] > ratio * base and seg[i] > 6.0 else None


def band_crop(arr):
    """Crop baked letterbox/pillarbox bands. They are blurred out-painted extensions of the scene, so a flat
    colour test fails; the content/band seam shows up as one abnormally large neighbouring-pixel step."""
    h, w = arr.shape[:2]
    g = arr[..., :3].astype(np.float32).mean(axis=2)
    dcol = np.abs(np.diff(g, axis=1)).mean(axis=0)   # step between column j and j+1
    drow = np.abs(np.diff(g, axis=0)).mean(axis=1)
    l = _edge(dcol, 0, w // 3) or 0
    r = _edge(dcol, w * 2 // 3, w - 1) or w
    t = _edge(drow, 0, h // 3) or 0
    b = _edge(drow, h * 2 // 3, h - 1) or h
    return l, t, r, b


def cover(im, size):
    k = max(size[0] / im.width, size[1] / im.height)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    x, y = (im.width - size[0]) // 2, (im.height - size[1]) // 2
    return im.crop((x, y, x + size[0], y + size[1]))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = []
    for ch, (rel, role) in SELECTION.items():
        src = BANK / rel
        im = Image.open(src).convert("RGB")
        box = band_crop(np.asarray(im))
        cropped = im.crop(box)
        out = cover(cropped, TARGET)
        dst = OUT / f"{ch}.jpg"
        out.save(dst, "JPEG", quality=88, optimize=True)
        manifest.append({"chapter": ch, "output": f"{ch}.jpg", "size": list(TARGET), "role": role,
                         "source": str(src.relative_to(ROOT)), "source_sha256": hashlib.sha256(src.read_bytes()).hexdigest(),
                         "source_size": [im.width, im.height], "band_crop_box": list(box),
                         "transformation": "edge-band crop + cover fit + JPEG q88 (tools/promote_playground_backdrops.py)",
                         "license_status": "UNVERIFIED commercial terms (Google Playground output); runtime use is provisional"})
        print(ch, box, dst.stat().st_size // 1024, "KB")
    (OUT / "PROVENANCE.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")


if __name__ == "__main__":
    main()
