#!/usr/bin/env python3
"""Safely import user-owned Playground export media into RPG Premium's ignored asset bank.

Requires Pillow: python3 -m pip install Pillow
Usage: python3 tools/import_playground_assets.py "project-files (1).zip"
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import zipfile

from PIL import Image

CATEGORIES = {
    "char_": "characters",
    "enemy_": "enemies",
    "boss_": "bosses",
    "prop_": "props",
    "weapon_": "weapons",
    "tileset_": "tilesets",
    "vfx_": "vfx",
    "scene_": "backgrounds",
}


def category(name):
    return next((value for prefix, value in CATEGORIES.items() if name.startswith(prefix)), "other")


def import_archive(source, output, batch):
    output.mkdir(parents=True, exist_ok=True)
    rows, issues = [], []
    with zipfile.ZipFile(source) as archive:
        for info in sorted(archive.infolist(), key=lambda i: i.filename):
            filename = info.filename
            if info.is_dir() or not filename.startswith(("assets/images/", "assets/audio/")):
                continue
            name = Path(filename).name
            if not re.fullmatch(r"[A-Za-z0-9_.-]+", name):
                issues.append("Unsafe file name: " + filename)
                continue
            data = archive.read(info)
            if data == b"__MEDIA__":
                issues.append("Media placeholder: " + filename)
                continue
            is_image = filename.startswith("assets/images/")
            cat = category(name) if is_image else "audio"
            folder = output / cat
            folder.mkdir(parents=True, exist_ok=True)
            entry = {
                "source": filename,
                "source_sha256": hashlib.sha256(data).hexdigest(),
                "category": cat,
                "approved_for_runtime": False,
                "status": "candidate_only",
            }
            if is_image:
                try:
                    with Image.open(io.BytesIO(data)) as image:
                        image.load()
                        real_format = image.format
                        w, h = image.size
                        alpha = "A" in image.getbands()
                        output_file = folder / (Path(name).stem + ".png")
                        image.convert("RGBA" if alpha else "RGB").save(output_file, "PNG", compress_level=1)
                        entry.update({
                            "original_encoding": real_format,
                            "output_encoding": "PNG",
                            "width": w,
                            "height": h,
                            "has_alpha_channel": alpha,
                            "has_any_transparency": image.getchannel("A").getextrema()[0] < 255 if alpha else False,
                        })
                        if cat in ("characters", "enemies", "bosses"):
                            entry["animation_layout_candidate"] = (
                                {"frame_width": 512, "frame_height": 512,
                                 "frames": w // 512, "verified_animation": False}
                                if h == 512 and w % 512 == 0 else None
                            )
                        if cat == "tilesets":
                            entry["warning"] = "Validate atlas grid/usable tile pieces before Godot import"
                except Exception as exc:
                    issues.append(f"Invalid image {filename}: {exc}")
                    continue
            else:
                if not data.startswith((b"ID3", b"OggS", b"RIFF", b"\xff\xfb")):
                    issues.append("Unknown audio format: " + filename)
                    continue
                output_file = folder / name
                output_file.write_bytes(data)
            entry["file"] = output_file.relative_to(output).as_posix()
            entry["output_sha256"] = hashlib.sha256(output_file.read_bytes()).hexdigest()
            rows.append(entry)
    counts = {}
    for entry in rows:
        key = entry["category"]
        counts[key] = counts.get(key, 0) + 1
    manifest = {
        "schema_version": 1,
        "project": "RPG Premium",
        "batch": batch,
        "platform": "Google Playground",
        "source_zip_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "license_review": "PENDING before commercial distribution",
        "runtime_integration": "NOT APPROVED",
        "summary": {"total": len(rows), "by_category": counts, "issues": len(issues)},
        "issues": issues,
        "files": rows,
    }
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return manifest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("zip_path", type=Path)
    ap.add_argument("--output", type=Path, default=Path("asset_bank/playground/round_01_drowned_harbor"))
    ap.add_argument("--batch", default="round_01_drowned_harbor")
    args = ap.parse_args()
    result = import_archive(args.zip_path, args.output, args.batch)
    print(json.dumps(result["summary"], indent=2))
    if result["issues"]:
        raise SystemExit("Import finished with errors: " + "; ".join(result["issues"]))


if __name__ == "__main__":
    main()
