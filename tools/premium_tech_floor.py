#!/usr/bin/env python3
"""Deterministic generator of the Chapter-1 (tech) floor tiles -> assets/premium/dungeon/tech_floor/.

The Quaternius modular platforms are flat trim-sheet quads once the toon pipeline flattens their normal maps, so the
floor deck plates are ORIGINAL art drawn here (license: Original work (RPG Premium)). Every tile is 192 px, drawn at 4x and
downsampled, and shows the same 3 px inset seam on its border so neighbours read as bolted deck plates. Runtime draws
them at 96 game px (scale 0.5) inside RoomBake: zero per-frame cost.

Usage: python3 tools/premium_tech_floor.py && python3 tools/premium_pipeline.py manifest
"""
import json
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/premium/dungeon/tech_floor"
N = 192            # final px
S = 4              # supersample
W = N * S
SEAM = (7, 10, 16)
BASE = (38, 47, 62)


def noise(rng, shape, amp):
    return rng.normal(0.0, amp, shape)


def plate(draw, box, rng, shade):
    x0, y0, x1, y1 = box
    c = tuple(int(v * shade) for v in BASE)
    draw.rectangle(box, fill=c)
    b = 3 * S
    draw.rectangle((x0, y0, x1, y0 + b), fill=tuple(min(255, v + 26) for v in c))          # top bevel
    draw.rectangle((x0, y0, x0 + b, y1), fill=tuple(min(255, v + 18) for v in c))          # left bevel
    draw.rectangle((x0, y1 - b, x1, y1), fill=tuple(max(0, v - 16) for v in c))            # bottom bevel
    draw.rectangle((x1 - b, y0, x1, y1), fill=tuple(max(0, v - 12) for v in c))            # right bevel


def rivet(draw, p, r=2.4 * S):
    x, y = p
    draw.ellipse((x - r, y - r + 1.2 * S, x + r, y + r + 1.2 * S), fill=(8, 11, 17))
    draw.ellipse((x - r, y - r, x + r, y + r), fill=(70, 82, 100))
    draw.ellipse((x - r * 0.45, y - r * 0.6, x + r * 0.2, y + r * 0.1), fill=(150, 166, 188))


def base_tile(seed, plates):
    rng = random.Random(seed)
    im = Image.new("RGB", (W, W), SEAM)
    d = ImageDraw.Draw(im)
    m = 2 * S
    seam = 3 * S
    k = plates
    cell = (W - 2 * m - (k - 1) * seam) / k
    for iy in range(k):
        for ix in range(k):
            x0 = m + ix * (cell + seam)
            y0 = m + iy * (cell + seam)
            plate(d, (x0, y0, x0 + cell, y0 + cell), rng, rng.uniform(0.9, 1.1))
            for cx, cy in ((x0 + 9 * S, y0 + 9 * S), (x0 + cell - 9 * S, y0 + 9 * S), (x0 + 9 * S, y0 + cell - 9 * S), (x0 + cell - 9 * S, y0 + cell - 9 * S)):
                rivet(d, (cx, cy))
    return im, rng


def finish(im, rng, grime=0.5):
    a = np.asarray(im, dtype=np.float32)
    nrng = np.random.default_rng(rng.randrange(1 << 30))
    streak = noise(nrng, (W, 1), 2.2) + noise(nrng, (1, W), 1.0)       # brushed-metal streaks
    a += streak[..., None] + noise(nrng, (W, W), 2.4)[..., None]
    yy, xx = np.mgrid[0:W, 0:W].astype(np.float32)
    edge = np.minimum(np.minimum(xx, W - xx), np.minimum(yy, W - yy)) / (W * 0.5)
    a *= (0.90 + 0.10 * np.clip(edge * 3.0, 0, 1))[..., None]            # contact darkening toward the tile border keeps seams crisp
    img = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(int(14 * grime)):                                      # scuffs
        x, y = rng.uniform(0, W), rng.uniform(0, W)
        L = rng.uniform(10 * S, 34 * S)
        t = rng.uniform(-0.5, 0.5)
        d.line((x, y, x + L * math.cos(t), y + L * math.sin(t)), fill=(150, 165, 185, rng.randint(14, 34)), width=max(1, S // 2))
    for _ in range(int(5 * grime)):                                       # grime blobs
        x, y, r = rng.uniform(0, W), rng.uniform(0, W), rng.uniform(10 * S, 26 * S)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(0, 0, 0, rng.randint(14, 30)))
    return img


def to_final(im):
    return im.filter(ImageFilter.GaussianBlur(S * 0.35)).resize((N, N), Image.LANCZOS)


def v_plain(seed):
    im, r = base_tile(seed, 2)
    return finish(im, r)


def v_big(seed):
    im, r = base_tile(seed, 1)
    d = ImageDraw.Draw(im, "RGBA")
    c = W // 2
    pts = [(c, c - 46 * S), (c + 46 * S, c), (c, c + 46 * S), (c - 46 * S, c)]
    d.polygon(pts, outline=(90, 104, 126, 150), width=2 * S)
    d.polygon([(c, c - 30 * S), (c + 30 * S, c), (c, c + 30 * S), (c - 30 * S, c)], fill=(20, 26, 36, 160))
    return finish(im, r)


def v_grate(seed):
    im, r = base_tile(seed, 1)
    d = ImageDraw.Draw(im, "RGBA")
    x0, y0, x1, y1 = 20 * S, 20 * S, W - 20 * S, W - 20 * S
    d.rectangle((x0, y0, x1, y1), fill=(4, 8, 14))
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle((x0 + 8 * S, y0 + 8 * S, x1 - 8 * S, y1 - 8 * S), fill=(30, 220, 200, 70))
    glow = glow.filter(ImageFilter.GaussianBlur(10 * S))
    im = Image.alpha_composite(im.convert("RGBA"), glow).convert("RGB")
    d = ImageDraw.Draw(im, "RGBA")
    for i in range(7):                                                    # grating bars
        x = x0 + (i + 0.5) * (x1 - x0) / 7
        d.rectangle((x - 3 * S, y0, x + 3 * S, y1), fill=(52, 64, 82))
        d.rectangle((x - 3 * S, y0, x - 1.5 * S, y1), fill=(96, 112, 134))
    for i in range(2):
        y = y0 + (i + 1) * (y1 - y0) / 3
        d.rectangle((x0, y - 2 * S, x1, y + 2 * S), fill=(44, 54, 70))
    d.rectangle((x0, y0, x1, y1), outline=(100, 114, 136), width=2 * S)
    return finish(im, r, 0.3)


def v_hazard(seed):
    im, r = base_tile(seed, 2)
    d = ImageDraw.Draw(im, "RGBA")
    y0 = W - 40 * S
    d.rectangle((0, y0, W, W - 4 * S), fill=(18, 20, 24))
    step = 22 * S
    x = -step
    while x < W + step:
        d.polygon([(x, W - 4 * S), (x + step * 0.5, W - 4 * S), (x + step * 0.5 + 20 * S, y0), (x + 20 * S, y0)], fill=(214, 150, 30))
        x += step
    return finish(im, r)


def v_stencil(seed):
    im, r = base_tile(seed, 1)
    d = ImageDraw.Draw(im, "RGBA")
    c = W // 2
    o = (230, 150, 40, 170)
    d.polygon([(c - 34 * S, c + 8 * S), (c, c - 36 * S), (c + 34 * S, c + 8 * S), (c + 14 * S, c + 8 * S), (c + 14 * S, c + 40 * S), (c - 14 * S, c + 40 * S), (c - 14 * S, c + 8 * S)], fill=o)
    return finish(im, r, 0.7)


def v_vent(seed):
    im, r = base_tile(seed, 1)
    d = ImageDraw.Draw(im, "RGBA")
    c = W // 2
    d.ellipse((c - 50 * S, c - 50 * S, c + 50 * S, c + 50 * S), fill=(6, 9, 14), outline=(86, 100, 122), width=3 * S)
    for i in range(6):
        a = math.pi * i / 6
        d.line((c - 46 * S * math.cos(a), c - 46 * S * math.sin(a), c + 46 * S * math.cos(a), c + 46 * S * math.sin(a)), fill=(58, 70, 90), width=3 * S)
    d.ellipse((c - 9 * S, c - 9 * S, c + 9 * S, c + 9 * S), fill=(74, 88, 110))
    return finish(im, r, 0.3)


def v_strip(seed):
    im, r = base_tile(seed, 2)
    glow = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.rectangle((0, W // 2 - 5 * S, W, W // 2 + 5 * S), fill=(40, 235, 210, 150))
    glow = glow.filter(ImageFilter.GaussianBlur(5 * S))
    im = Image.alpha_composite(im.convert("RGBA"), glow).convert("RGB")
    d = ImageDraw.Draw(im, "RGBA")
    d.rectangle((0, W // 2 - 2 * S, W, W // 2 + 2 * S), fill=(170, 255, 245))
    return finish(im, r, 0.4)


def v_scorch(seed):
    im, r = base_tile(seed, 2)
    d = ImageDraw.Draw(im, "RGBA")
    c = (W * 0.55, W * 0.45)
    for k in range(6):
        rr = (62 - k * 9) * S
        d.ellipse((c[0] - rr, c[1] - rr * 0.8, c[0] + rr, c[1] + rr * 0.8), fill=(0, 0, 0, 34))
    for _ in range(4):
        x, y = c
        pts = [(x, y)]
        for _ in range(5):
            x += r.uniform(-18, 18) * S
            y += r.uniform(6, 20) * S
            pts.append((x, y))
        d.line(pts, fill=(3, 5, 9, 220), width=2 * S)
    return finish(im, r, 0.3)


VARIANTS = {"deck_a": (v_plain, 11), "deck_b": (v_plain, 29), "deck_big": (v_big, 5), "deck_grate": (v_grate, 7),
            "deck_hazard": (v_hazard, 13), "deck_stencil": (v_stencil, 17), "deck_vent": (v_vent, 19),
            "deck_strip": (v_strip, 23), "deck_scorch": (v_scorch, 31)}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    items = {}
    for name, (fn, seed) in VARIANTS.items():
        to_final(fn(seed)).save(OUT / f"{name}.png", optimize=True)
        items[name] = {"path": f"res://assets/premium/dungeon/tech_floor/{name}.png", "size": [N, N], "bbox": [0, 0, N, N],
                       "anchor": [N / 2, N / 2], "scale": 0.5, "pitch": 90.0, "source_file": "original:tools/premium_tech_floor.py"}
    manifest = {"id": "tech_floor", "kind": "static_set", "role": "environment", "source_pack": "RPG Premium original (tools/premium_tech_floor.py)",
                "source_revision": "original", "license": "Original work (RPG Premium)",
                "transformation": "procedural PIL deck-plate drawing, 4x supersample, deterministic seeds (tools/premium_tech_floor.py)",
                "runtime_path": "res://assets/premium/dungeon/tech_floor/", "ppu": 2.0, "ppu_game": 1.0, "items": items}
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1))
    print("tech floor:", ", ".join(items))


if __name__ == "__main__":
    main()
