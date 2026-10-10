#!/usr/bin/env python3
"""Install a complete or compact Playground asset bank inside RPG Premium.

Example: python3 tools/install_playground_bank.py ~/Downloads/RPG_PREMIUM_COMPLETE_BANK_FOR_REPO.zip
Use --dry-run to check before installing. No gameplay/runtime files are changed.
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "asset_bank" / "playground"
PREFIX = "asset_bank/playground/"


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def validate_archive(archive):
    entries, size = [], 0
    for item in archive.infolist():
        if item.is_dir():
            continue
        name = item.filename
        parts = PurePosixPath(name).parts
        if (not name.startswith(PREFIX) or "\\" in name or
                ".." in parts or Path(name).is_absolute() or
                item.file_size > 100 * 1024 * 1024):
            raise ValueError("Invalid or oversized entry: " + name)
        size += item.file_size
        if size > 1024 * 1024 * 1024:
            raise ValueError("Archive exceeds the 1 GiB safety limit")
        entries.append(item)
    if not entries:
        raise ValueError("No RPG Premium asset-bank entries")
    bad = archive.testzip()
    if bad:
        raise ValueError("Bad ZIP CRC: " + bad)
    return entries, size


def verify_staging():
    manifest_path = BANK / "reports" / "FULL_MEDIA_MANIFEST.json"
    if not manifest_path.exists():
        raise ValueError("Missing FULL_MEDIA_MANIFEST.json")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    counts = {"png": 0, "original_webp": 0, "audio": 0, "manual_jpg": 0}
    problems = []
    for item in manifest["files"]:
        output = ROOT / item["local_path"]
        if output.is_file():
            if digest(output) != item["converted_sha256"]:
                problems.append("Checksum mismatch: " + str(output))
            counts["audio" if item["category"] == "audio" else "png"] += 1
        else:
            if item["category"] == "audio":
                problems.append("Missing audio: " + str(output))
                continue
            stem = PurePosixPath(item["source_path"]).stem
            source = BANK / item["round"] / "original_webp" / item["category"] / (stem + ".webp")
            if not source.exists():
                problems.append("Missing media: " + str(source))
            elif digest(source) != item["source_sha256"]:
                problems.append("Checksum mismatch: " + str(source))
            else:
                counts["original_webp"] += 1
    for item in manifest["manual_selection"]:
        target = ROOT / item["full_path"]
        if not target.is_file() or digest(target) != item["sha256"]:
            problems.append("Missing/bad selection: " + str(target))
        else:
            counts["manual_jpg"] += 1
    return counts, problems


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("zip_path", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    if not (ROOT / "project.godot").is_file() or not (ROOT / "AGENTS.md").is_file():
        parser.error("Run only inside the RPG Premium repository")
    with ZipFile(args.zip_path) as archive:
        entries, size = validate_archive(archive)
        new = 0
        for entry in entries:
            dest = ROOT / entry.filename
            if dest == BANK / "README.md" and dest.exists():
                continue
            if dest.is_file():
                existing = digest(dest)
                incoming = hashlib.sha256(archive.read(entry)).hexdigest()
                if existing != incoming:
                    raise ValueError("Refusing to overwrite different staged data: " + str(dest))
                continue
            new += 1
            if not args.dry_run:
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_bytes(archive.read(entry))
        print(f"ZIP: {len(entries)} entries, {size / 1048576:.1f} MiB; new files: {new}")
        if args.dry_run:
            return
    counts, errors = verify_staging()
    print("Verified:", json.dumps(counts, sort_keys=True))
    if errors:
        for line in errors[:20]:
            print("ERROR:", line, file=sys.stderr)
        raise SystemExit(f"Asset-bank validation FAILED: {len(errors)} problems")
    print("PASS: assets preserved in quarantined bank. Runtime remains unchanged.")


if __name__ == "__main__":
    main()
