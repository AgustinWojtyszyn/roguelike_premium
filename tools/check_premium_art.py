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

REQUIRED_PLAYER_ANIMS = ("idle", "walk", "hurt", "death")
REQUIRED_PROVENANCE = ("source_pack", "source_revision", "license", "transformation", "runtime_path", "role")


def validate_manifest(m, files_exist=None):
    """Errores de un manifest de assets/premium (lista vacia = ok). Los jugables exigen agarre por frame desde el rig fuente."""
    errs = []
    for k in REQUIRED_PROVENANCE:
        if not m.get(k):
            errs.append(f"{m.get('id', '?')}: falta procedencia '{k}'")
    if m.get("license") not in ("CC0 1.0", "Original work (RPG Premium)"):
        errs.append(f"{m.get('id', '?')}: licencia no comercial-compatible verificada ({m.get('license')})")
    if m.get("source_revision") in (None, "", "unknown"):
        errs.append(f"{m.get('id', '?')}: revision de la fuente desconocida")
    if m.get("role") == "player":
        anims = m.get("anims", {})
        for a in REQUIRED_PLAYER_ANIMS:
            if a not in anims:
                errs.append(f"{m['id']}: jugable sin animacion {a}")
        if not m.get("grips"):
            errs.append(f"{m['id']}: jugable sin metadatos de agarre (grips)")
        for a, e in anims.items():
            if not set(("south", "south-east", "east", "north-east", "north")) <= set(e.get("dirs", [])):
                errs.append(f"{m['id']}/{a}: faltan direcciones del lado este (el oeste se espeja en runtime)")
            for d, n in zip(e.get("dirs", []), e.get("counts", [])):
                rows = m.get("grips", {}).get(a, {}).get(d, [])
                if len(rows) != n or any(len(r) < 6 for r in rows):
                    errs.append(f"{m['id']}/{a}/{d}: agarre no cubre los {n} frames")
        kind = m.get("kind", "")
        if kind == "hero_melee" and "attack" not in anims:
            errs.append(f"{m['id']}: melee sin animacion attack")
        if kind == "hero_ranged" and anims.get("idle", {}).get("weapon_mode") != "aim":
            errs.append(f"{m['id']}: ranged sin pose de apuntado")
    if files_exist is not None:
        paths = []
        for e in m.get("anims", {}).values():
            paths.append(e.get("sheet"))
            if e.get("hand"):
                paths.append(e["hand"].get("sheet"))
        for it in m.get("items", {}).values():
            paths.append(it.get("path"))
        for p in paths:
            if p and not files_exist(p):
                errs.append(f"{m.get('id', '?')}: falta el archivo {p}")
    return errs


def check_premium_assets():
    import json
    out = []
    pre = ROOT / "assets/premium"
    seen = set()
    for mf in sorted(pre.glob("**/manifest.json")):
        m = json.loads(mf.read_text(encoding="utf-8"))
        out += validate_manifest(m, lambda p: (ROOT / p.replace("res://", "")).exists())
        for png in mf.parent.glob("*.png"):
            seen.add(png)
    # todo PNG de assets/premium debe pertenecer a un manifest con procedencia
    for png in pre.glob("**/*.png"):
        if png not in seen:
            out.append(f"{png.relative_to(ROOT)}: PNG sin manifest/procedencia")
    gd = (ROOT / "data/visual/premium_manifest.gd")
    if pre.glob("**/manifest.json") and not gd.exists():
        out.append("falta data/visual/premium_manifest.gd (tools/premium_pipeline.py manifest)")
    return out


def main():
    errs = errors + check_premium_assets()
    if errs:
        print("PREMIUM ART GATE: FAIL")
        for e in errs:
            print(" -", e)
        sys.exit(1)
    print("PREMIUM ART GATE: OK")


if __name__ == "__main__":
    main()
