#!/usr/bin/env python3
"""Static gate for the Premium visual rebuild. Intended for CI and Claude/Astra before proposing changes."""
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

rig = (ROOT / "characters/character_rig.gd").read_text(encoding="utf-8")
for forbidden in ("Gfx.gpoly", "_paint_torso", "_paint_leg", "_paint_head", "DEFAULT_LOOK"):
    if forbidden in rig:
        errors.append(f"playable procedural renderer leaked back into CharacterRig: {forbidden}")

legacy_runtime = ROOT / "assets/migrated/rpg/characters"
if legacy_runtime.exists() and any(legacy_runtime.rglob("*.png")):
    errors.append("legacy playable PNGs reappeared under assets/migrated/rpg/characters")

vp = (ROOT / "visual/visual_profiles.gd").read_text(encoding="utf-8")
block = vp.split("const CHARACTERS :=", 1)[1].split("static func character", 1)[0] if "const CHARACTERS :=" in vp else ""
for m in re.finditer(r'"([^"]+)"\s*:\s*\{', block):
    start = m.start()
    snippet = block[start:block.find("\n\t}", start) + 3] if "\n\t}" in block[start:] else block[start:start+1200]
    if '"weapon_compatible": true' not in snippet:
        errors.append(f"playable profile {m.group(1)} lacks weapon_compatible=true")

mig = (ROOT / "tools/migrate_assets.py").read_text(encoding="utf-8")
bad = re.findall(r'"player/[^"]+"\s*:\s*\("characters/[^"]+",\s*"migrate"\)', mig)
if bad:
    errors.append("migrate_assets.py still promotes legacy player sources to runtime: " + ", ".join(bad))
if re.search(r'HERO_VARIANTS\s*=\s*\{\s*"', mig):
    errors.append("migrate_assets.py still generates recolored legacy playable clones")

if errors:
    print("PREMIUM ART GATE: FAIL")
    for e in errors:
        print(" -", e)
    sys.exit(1)
print("PREMIUM ART GATE: OK")
