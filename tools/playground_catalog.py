#!/usr/bin/env python3
"""Catalogue the preserved Playground bank (read-only on originals).

Reads asset_bank/playground/**/original_webp/*.webp (or PNG), measures them with Pillow/NumPy and writes:
  asset_bank/playground/reports/CATALOG.json   per-asset facts + status (1..6) + reasons
  asset_bank/playground/reports/CATALOG.md     summary table
  asset_bank/playground/reports/gallery/       256px thumbnails + index.html (side-by-side inspection)

Status codes (see docs/PLAYGROUND_CATALOG.md):
  1 ready_to_adapt          2 needs_conversion        3 needs_art_correction
  4 needs_more_animation    5 backdrop_menu_ambient   6 reserve_future

Nothing here promotes an asset to the runtime: promotion stays a manual, reviewed step
(tools/promote_playground_backdrops.py for the approved backdrops).
Usage: python3 tools/playground_catalog.py [--no-gallery]
"""
import argparse
import hashlib
import html
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
BANK = ROOT / "asset_bank" / "playground"
REPORTS = BANK / "reports"
STATUS = {1: "ready_to_adapt", 2: "needs_conversion", 3: "needs_art_correction",
          4: "needs_more_animation", 5: "backdrop_menu_ambient", 6: "reserve_future"}
CATS = {"char_": "characters", "hero_": "characters", "enemy_": "enemies", "boss_": "bosses", "prop_": "props",
        "weapon_": "weapons", "tileset_": "tilesets", "vfx_": "vfx", "fx_": "vfx", "scene_": "backgrounds",
        "bg_": "backgrounds"}
ANIM_TOKENS = ("idle", "walk", "run", "attack", "sword_attack", "shoot", "hurt", "death")
LOCOMOTION = ("walk", "run")


def category(name):
    return next((v for p, v in CATS.items() if name.startswith(p)), "other")


def small_signature(img):
    """64x32 alpha-premultiplied RGBA thumbnail: robust to sparse sprites where a luminance dhash collides."""
    t = np.asarray(img.convert("RGBA").resize((64, 32), Image.BOX), dtype=np.float32)
    t[..., :3] *= t[..., 3:4] / 255.0
    return t


def sig_distance(a, b):
    return float(np.abs(a - b).mean())


def corner_background(arr):
    """Classify the colour in the 4 corners: transparent / black / magenta / flat / none."""
    h, w = arr.shape[:2]
    pts = [arr[0, 0], arr[0, w - 1], arr[h - 1, 0], arr[h - 1, w - 1]]
    if all(p[3] < 8 for p in pts):
        return "transparent", None
    rgb = [tuple(int(c) for c in p[:3]) for p in pts if p[3] >= 8]
    if not rgb:
        return "transparent", None
    spread = max(max(c) - min(c) for c in zip(*rgb)) if len(rgb) > 1 else 0
    avg = tuple(int(sum(c) / len(c)) for c in zip(*rgb))
    if spread > 24:
        return "scene", None
    if max(avg) < 24:
        return "black", avg
    if avg[0] > 200 and avg[2] > 200 and avg[1] < 80:
        return "magenta", avg
    return "flat", avg


def foreground_mask(arr, bg_kind, bg_rgb):
    a = arr[..., 3] > 16
    if bg_kind in ("black", "magenta", "flat") and bg_rgb is not None:
        d = np.abs(arr[..., :3].astype(np.int16) - np.array(bg_rgb, dtype=np.int16)).max(axis=2)
        a = a & (d > 28)
    return a


def frame_grid(w, h, name):
    """Strips are horizontal runs of square(ish) cells. Returns (cols, rows, cell_w, cell_h, how)."""
    if w >= h * 2 and w % h == 0:
        return w // h, 1, h, h, "square_cells"
    for n in (16, 12, 8, 6, 4):
        if w % n == 0 and w // n >= h * 0.5 and w // n <= h * 1.5 and w > h * 1.6:
            return n, 1, w // n, h, "divisor"
    return 1, 1, w, h, "single"


def frame_report(fg, cols, rows, cw, ch):
    boxes, empty, edge = [], 0, 0
    for r in range(rows):
        for c in range(cols):
            m = fg[r * ch:(r + 1) * ch, c * cw:(c + 1) * cw]
            ys, xs = np.where(m)
            if len(xs) == 0:
                empty += 1
                continue
            x0, x1, y0, y1 = int(xs.min()), int(xs.max()), int(ys.min()), int(ys.max())
            boxes.append((x0, y0, x1, y1))
            if x0 == 0 or y0 == 0 or x1 == cw - 1 or y1 == ch - 1:
                edge += 1
    out = {"frames": cols * rows, "empty": empty, "edge_touching": edge}
    if boxes:
        hs = [b[3] - b[1] + 1 for b in boxes]
        feet = [b[3] for b in boxes]
        cx = [(b[0] + b[2]) / 2 for b in boxes]
        out.update(height_min=min(hs), height_max=max(hs), height_jitter=round((max(hs) - min(hs)) / max(hs), 3),
                   feet_jitter_px=max(feet) - min(feet), center_jitter_px=round(max(cx) - min(cx), 1))
    return out


def analyse(path):
    img = Image.open(path)
    img.load()
    rgba = img.convert("RGBA")
    arr = np.asarray(rgba)
    w, h = rgba.size
    alpha = arr[..., 3]
    has_alpha = bool(alpha.min() < 250)
    bg_kind, bg_rgb = corner_background(arr)
    name = path.stem
    cat = category(name)
    row = {"id": name, "category": cat, "round": path.parts[path.parts.index("playground") + 1],
           "path": str(path.relative_to(ROOT)), "size": [w, h], "has_alpha": has_alpha,
           "corner_background": bg_kind, "byte_size": path.stat().st_size,
           "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
    if cat in ("characters", "enemies", "bosses", "vfx") and w > h * 1.6:
        cols, rows, cw, ch, how = frame_grid(w, h, name)
        fg = foreground_mask(arr, bg_kind, bg_rgb)
        row["grid"] = {"cols": cols, "rows": rows, "cell": [cw, ch], "how": how}
        row["frames"] = frame_report(fg, cols, rows, cw, ch)
    elif cat in ("characters", "enemies", "bosses", "props", "weapons"):
        fg = foreground_mask(arr, bg_kind, bg_rgb)
        ys, xs = np.where(fg)
        if len(xs):
            row["bbox"] = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
            row["fill"] = round(float(fg.mean()), 3)
    row["_hash"] = small_signature(rgba)
    return row


def classify(row):
    """Conservative: only STATUS 1 for assets that need no further art decision for their role."""
    cat, name = row["category"], row["id"]
    reasons = []
    bg = row["corner_background"]
    w, h = row["size"]
    if cat == "backgrounds":
        reasons.append("panoramic illustration: usable for menus / chapter cards / parallax, not a walkable room")
        return 5, reasons
    if cat == "tilesets":
        reasons.append("illustration-style composition, not verified as modular tiles (needs grid/seam check)")
        return 6, reasons
    if bg in ("black", "magenta", "flat"):
        reasons.append(f"flat {bg} background baked into pixels: needs keying (colour-distance, edge-safe)")
        status = 2
    elif bg == "scene":
        reasons.append("non-uniform corners: may contain a scene background")
        status = 3
    else:
        status = 1
    if cat in ("characters", "enemies", "bosses"):
        fr = row.get("frames")
        if fr:
            if fr["edge_touching"]:
                reasons.append(f"{fr['edge_touching']} frame(s) touch the cell border (clipping)")
                status = max(status, 3)
            if fr.get("feet_jitter_px", 0) > max(12, 0.04 * row["grid"]["cell"][1]):
                reasons.append(f"feet jitter {fr['feet_jitter_px']}px between frames (needs recentering)")
                status = max(status, 3)
            if fr.get("height_jitter", 0) > 0.25:
                reasons.append(f"silhouette height varies {fr['height_jitter']:.0%} between frames")
                status = max(status, 3)
        else:
            reasons.append("single image, no animation strip")
            status = max(status, 4)
        reasons.append("single camera angle (no 8-direction set, no per-frame weapon grip metadata)")
        if cat == "characters":
            reasons.append("cannot enter VisualProfiles.CHARACTERS: no rig grip => not weapon_compatible")
            status = max(status, 4)
    if cat == "weapons":
        reasons.append("weapon art: must be re-scaled so tip == WeaponData.muzzle before adoption")
    if cat in ("props", "vfx") and status == 1:
        reasons.append("candidate for adaptation after scale/readability review")
    return status, reasons


def role_groups(rows):
    """Group animation strips by actor to report missing states."""
    actors = {}
    for r in rows:
        if r["category"] not in ("characters", "enemies", "bosses"):
            continue
        base, _, state = r["id"].rpartition("_")
        if r["id"].endswith("sword_attack"):
            base, state = r["id"][:-len("_sword_attack")], "sword_attack"
        elif state not in ANIM_TOKENS:
            base, state = r["id"], "single"
        actors.setdefault(base, {})[state] = r["id"]
    out = {}
    for base, states in sorted(actors.items()):
        have = set(states)
        gaps = []
        if "single" in have and len(have) == 1:
            gaps.append("single still image only")
        else:
            for need, opts in (("idle", ("idle",)), ("locomotion", LOCOMOTION), ("hurt", ("hurt",)), ("death", ("death",)),
                               ("attack", ("attack", "sword_attack", "shoot"))):
                if not any(o in have for o in opts):
                    gaps.append(f"no {need}")
        out[base] = {"states": sorted(have), "gaps": gaps, "complete_states": not gaps}
    return out


def near_duplicates(rows, thr=2.0):
    out = []
    for i, a in enumerate(rows):
        for b in rows[i + 1:]:
            if a["category"] != b["category"]:
                continue
            if a["sha256"] == b["sha256"]:
                out.append({"a": a["id"], "b": b["id"], "kind": "exact"})
            elif a["size"] == b["size"] and sig_distance(a["_hash"], b["_hash"]) <= thr:
                out.append({"a": a["id"], "b": b["id"], "kind": "near", "distance": round(sig_distance(a["_hash"], b["_hash"]), 2)})
    return out


def thumb(path, dest, size=256):
    im = Image.open(path).convert("RGBA")
    im.thumbnail((size * 2, size))
    bg = Image.new("RGBA", im.size, (38, 42, 52, 255))
    bg.alpha_composite(im)
    bg.convert("RGB").save(dest, "JPEG", quality=78)


def write_gallery(rows, dups):
    gal = REPORTS / "gallery"
    gal.mkdir(parents=True, exist_ok=True)
    cards = []
    for r in rows:
        t = gal / f"{r['id']}_{r['round'][:8]}.jpg"
        thumb(ROOT / r["path"], t)
        fr = r.get("frames")
        meta = f"{r['size'][0]}x{r['size'][1]} · bg={r['corner_background']}" + (f" · {fr['frames']}f" if fr else "")
        cards.append(f"<figure class='s{r['status']}'><img loading='lazy' src='{t.name}'><figcaption><b>{html.escape(r['id'])}</b>"
                     f"<br>{meta}<br>#{r['status']} {STATUS[r['status']]}</figcaption></figure>")
    doc = ("<!doctype html><meta charset=utf-8><title>Playground bank gallery</title><style>"
           "body{background:#14161c;color:#ddd;font:12px sans-serif;margin:12px}figure{display:inline-block;margin:6px;width:260px;vertical-align:top}"
           "img{width:260px;background:#262a34}.s1{outline:2px solid #4c8}.s2{outline:2px solid #cb4}.s3{outline:2px solid #e83}"
           ".s4{outline:2px solid #c5c}.s5{outline:2px solid #58c}.s6{outline:2px solid #777}</style>"
           f"<h2>{len(rows)} assets · {len(dups)} duplicate pairs</h2>" + "".join(cards))
    (gal / "index.html").write_text(doc, encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-gallery", action="store_true")
    args = ap.parse_args()
    files = sorted(p for p in BANK.glob("round_*/original_webp/**/*") if p.suffix.lower() in (".webp", ".png"))
    if not files:
        raise SystemExit("no originals found under asset_bank/playground/round_*/original_webp")
    rows = [analyse(p) for p in files]
    for r in rows:
        r["status"], r["reasons"] = classify(r)
        r["status_name"] = STATUS[r["status"]]
    dups = near_duplicates(rows)
    groups = role_groups(rows)
    for r in rows:
        r.pop("_hash", None)
    counts = {}
    for r in rows:
        counts[r["status_name"]] = counts.get(r["status_name"], 0) + 1
    REPORTS.mkdir(exist_ok=True)
    (REPORTS / "CATALOG.json").write_text(json.dumps(
        {"generator": "tools/playground_catalog.py", "total": len(rows), "status_counts": counts,
         "duplicates": dups, "actors": groups, "assets": rows}, indent=1), encoding="utf-8")
    lines = ["# Playground bank — catalogue (generated)", "", f"{len(rows)} images · duplicate pairs: {len(dups)}", "",
             "| status | count |", "|---|---:|"] + [f"| {k} | {v} |" for k, v in sorted(counts.items())]
    lines += ["", "## Actors and missing states", "", "| actor | states | gaps |", "|---|---|---|"]
    for k, v in groups.items():
        lines.append(f"| {k} | {', '.join(v['states'])} | {'; '.join(v['gaps']) or '-'} |")
    (REPORTS / "CATALOG.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if not args.no_gallery:
        write_gallery(rows, dups)
    print(f"catalogued {len(rows)} images; {counts}; duplicates={len(dups)}")


if __name__ == "__main__":
    main()
