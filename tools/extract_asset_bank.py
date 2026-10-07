#!/usr/bin/env python3
from __future__ import annotations

import base64
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BANK = ROOT / "asset_bank"
BUNDLES = BANK / "bundles"
OUT = BANK / "unpacked"

DEST = {
    "AgustinWojtyszyn/Rpg_new": "no_return",
    "AgustinWojtyszyn/Life--simulador-de-vida": "vida",
}

def git_blob_sha(data: bytes) -> str:
    header = f"blob {len(data)}\0".encode()
    return hashlib.sha1(header + data).hexdigest()

def main() -> None:
    bundles = sorted(BUNDLES.glob("*.json"))
    if not bundles:
        raise SystemExit("No asset bundles found.")

    written = 0
    bad = 0
    for bundle_path in bundles:
        payload = json.loads(bundle_path.read_text(encoding="utf-8"))
        repo = payload["source_repo"]
        root_name = DEST[repo]
        for item in payload["files"]:
            data = base64.b64decode(item["content_b64"])
            expected = item.get("git_blob_sha", "")
            actual = git_blob_sha(data)
            if expected and actual != expected:
                bad += 1
                print(f"[BAD SHA] {item['path']} expected={expected} actual={actual}")
                continue

            src_path = item["path"]
            if repo.endswith("/Rpg_new"):
                rel = src_path.removeprefix("assets/generated/")
            else:
                rel = src_path.removeprefix("assets/")

            dest = OUT / root_name / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(data)
            written += 1

    print(f"Asset bank extracted: {written} files -> {OUT}")
    if bad:
        raise SystemExit(f"{bad} files failed SHA validation.")

if __name__ == "__main__":
    main()
