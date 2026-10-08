#!/usr/bin/env python3
"""Pipeline reproducible: rig 3D fuente (KayKit/Quaternius, CC0) -> hojas de sprites 2D en assets/premium/.

  tools/premium_pipeline.py build vesper sable skeleton_warrior crab   # render + empaquetado + manifest
  tools/premium_pipeline.py build vesper --no-render                    # reempaqueta desde build/premium_render/
  tools/premium_pipeline.py manifest                                    # regenera data/visual/premium_manifest.gd
  tools/premium_pipeline.py list

Render: Godot (modo compatibilidad) como motor 3D offscreen (no hay Blender en el entorno): tools/premium_render/render_rig.gd.
Camara ortografica 3/4 fija, 8 direcciones, pose por mascara de huesos (piernas de una animacion, torso/brazos de otra) y
agarre derivado del hueso `handslot` del rig fuente. NADA se ajusta a mano: cada job (tools/premium_render/jobs/*.json) es la
unica entrada y el resultado es funcion de (job, revision de la fuente).
El runtime solo consume PNG 2D + data/visual/premium_manifest.gd (generado).
"""
import argparse, hashlib, json, math, os, shutil, subprocess, sys
from pathlib import Path
from PIL import Image, ImageChops, ImageFilter
sys.path.insert(0, str(Path(__file__).resolve().parent))
import premium_look  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
JOBS = ROOT / "tools/premium_render/jobs"
RENDER_BUILD = ROOT / "build/premium_render"
OUT = ROOT / "assets/premium"
MANIFEST_GD = ROOT / "data/visual/premium_manifest.gd"
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]

PACKS = {
    "own": ("tools/premium_render", "", "RPG Premium original models"),
    "kaykit_adventurers": ("asset_bank/vendor/kaykit_adventurers", "addons/kaykit_character_pack_adventures", "KayKit Adventurers 1.0"),
    "kaykit_skeletons": ("asset_bank/vendor/kaykit_skeletons", "addons/kaykit_character_pack_skeletons", "KayKit Skeletons 1.0"),
    "kaykit_dungeon": ("asset_bank/vendor/kaykit_dungeon", "addons/kaykit_dungeon_remastered", "KayKit Dungeon Remastered 1.0"),
    "quaternius": ("asset_bank/vendor/quaternius", "", "Quaternius FreeModels mirror"),
}


def pack_info(pack):
    rel, sub, name = PACKS[pack]
    base = ROOT / rel
    if pack == "own":
        return base, name, "original"
    try:
        rev = subprocess.check_output(["git", "-C", str(base), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        rev = "unknown"
    return base / sub if sub else base, name, rev


def load_job(jid):
    return json.loads((JOBS / f"{jid}.json").read_text())


def render(jid, job):
    base, _, _ = pack_info(job["pack"])
    static = job["kind"] == "static_set"
    j = dict(job)
    if static:
        j["items"] = [it if "build" in it else dict(it, file=str(base / job["dir"] / it["file"])) for it in job["items"]]
        for it in j["items"]:
            if "build" not in it and not Path(it["file"]).exists():
                sys.exit(f"fuente inexistente: {it['file']}")
    else:
        src = base / job["source"]
        if not src.exists():
            sys.exit(f"fuente inexistente: {src}")
        j["source"] = str(src)
    j["attach"] = [dict(a, file=str(base / a["file"])) for a in job.get("attach", [])]
    tmp = RENDER_BUILD / f"{jid}.job.json"
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_text(json.dumps(j))
    out = RENDER_BUILD / jid
    if out.exists():
        shutil.rmtree(out)
    script = "render_static.gd" if static else "render_rig.gd"
    cmd = ["godot", "--path", str(ROOT), "--rendering-driver", "opengl3", "--script", f"tools/premium_render/{script}",
           "--", f"--job={tmp}", f"--out={out}"]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not (out / "frames.json").exists():
        sys.stderr.write(r.stdout[-3000:] + r.stderr[-3000:])
        sys.exit(f"render fallo para {jid}")
    return out


def downscale(img, size):
    """Reduccion con alfa premultiplicado (sin halos oscuros en los bordes)."""
    return img.convert("RGBa").resize((size, size), Image.LANCZOS).convert("RGBA")


def clipped(img, cell, thr=10):
    """Gate de calidad: ningun pixel opaco puede tocar el borde de la celda (sprite recortado)."""
    a = img.getchannel("A")
    w, h = a.size
    return any(a.crop(box).getextrema()[1] > thr for box in ((0, 0, w, 1), (0, h - 1, w, h), (0, 0, 1, h), (w - 1, 0, w, h)))


def pack_asset(jid, job, rdir):
    meta = json.loads((rdir / "frames.json").read_text())
    cell = meta["cell"]
    feet = meta["feet"]
    ss = int(job.get("ss", 2))
    hero = job["kind"].startswith("hero")
    patch = int(job.get("hand_patch", 40))
    kind_dir = "characters" if hero else "enemies"
    odir = OUT / kind_dir / jid
    if odir.exists():
        shutil.rmtree(odir)
    odir.mkdir(parents=True)
    axis = job.get("weapon_axis", "fore")
    clip_errors = []
    anims_meta = {}
    grips = {}
    for an, spec in job["anims"].items():
        per_dir = meta["anims"][an]
        dirs = [d for d in DIRS if d in per_dir]
        nmax = max(len(per_dir[d]) for d in dirs)
        sheet = Image.new("RGBA", (nmax * cell, len(dirs) * cell), (0, 0, 0, 0))
        hsheet = Image.new("RGBA", (nmax * patch, len(dirs) * patch), (0, 0, 0, 0)) if hero and spec.get("hand_layer", job.get("hand_layer")) else None
        counts = []
        g_anim = {}
        for r, d in enumerate(dirs):
            frames = per_dir[d]
            counts.append(len(frames))
            g_dir = []
            for i, rec in enumerate(frames):
                im = Image.open(rdir / an / f"{d}_{i}.png").convert("RGBA")
                im = premium_look.stylize(im, "hero" if hero else "enemy", ss)
                fr = downscale(im, cell)
                if clipped(fr, cell):
                    clip_errors.append(f"{jid}/{an}/{d}_{i}")
                sheet.paste(fr, (i * cell, r * cell))
                if hero:
                    vx, vy = rec[axis] if axis in rec else rec["fore"]
                    ang = math.degrees(math.atan2(vy, vx))
                    g_dir.append([round(rec["grip"][0], 1), round(rec["grip"][1], 1), round(ang, 1),
                                  round(rec["grip_l"][0], 1), round(rec["grip_l"][1], 1), 1 if rec.get("behind") else 0])
                if hsheet is not None:
                    mask = Image.open(rdir / an / f"{d}_{i}_mask.png").convert("L")
                    # la mascara se dilata lo que mide el contorno para que el parche incluya el borde oscuro del puño
                    mask = mask.point(lambda v: 255 if v > 90 else 0)
                    for _ in range(int(1.5 * ss) + 1):
                        mask = mask.filter(ImageFilter.MaxFilter(3))
                    a = ImageChops.multiply(im.getchannel("A"), mask)
                    himg = im.copy()
                    himg.putalpha(a)
                    cx = (cell * 0.5 + rec["grip"][0]) * ss
                    cy = (feet[1] + rec["grip"][1]) * ss
                    half = patch * ss * 0.5
                    crop = himg.crop((round(cx - half), round(cy - half), round(cx + half), round(cy + half)))
                    hsheet.paste(downscale(crop, patch), (i * patch, r * patch))
            if hero:
                g_anim[d] = g_dir
        sheet.save(odir / f"{an}.png", optimize=True)
        entry = {"sheet": f"res://assets/premium/{kind_dir}/{jid}/{an}.png", "dirs": dirs, "counts": counts, "cell": [cell, cell]}
        if hero:
            entry["weapon_mode"] = spec.get("weapon_mode", "aim")
            grips[an] = g_anim
        if hsheet is not None:
            hsheet.save(odir / f"{an}_hand.png", optimize=True)
            entry["hand"] = {"sheet": f"res://assets/premium/{kind_dir}/{jid}/{an}_hand.png", "cell": [patch, patch]}
        anims_meta[an] = entry
    if clip_errors:
        sys.exit(f"QUALITY GATE: {len(clip_errors)} frames recortados por el borde de la celda en {jid} (subir ortho): " + ", ".join(clip_errors[:6]))
    base, pname, rev = pack_info(job["pack"])
    manifest = {
        "id": jid, "kind": job["kind"], "role": "player" if hero else "enemy",
        "source_pack": pname, "source_revision": rev, "license": "CC0 1.0",
        "source_file": job["source"],
        "transformation": "Godot offscreen ortho 3/4 render (tools/premium_render/render_rig.gd), 8 dirs, bone-masked pose blend; "
                          "grip from rig bone handslot; packed by tools/premium_pipeline.py",
        "job_sha256": hashlib.sha256(json.dumps(job, sort_keys=True).encode()).hexdigest()[:16],
        "runtime_path": f"res://assets/premium/{kind_dir}/{jid}/",
        "cell": [cell, cell], "feet": [feet[0], feet[1]], "ppu": meta["ppu"], "pitch": meta["pitch"],
        "anims": anims_meta,
    }
    if hero:
        manifest["weapon_axis"] = axis
        manifest["grips"] = grips
    (odir / "manifest.json").write_text(json.dumps(manifest, indent=1))
    return manifest


def pack_static(jid, job, rdir):
    """Recorta cada pieza por su caja alfa y guarda el ancla (origen del modelo en el recorte): nada se coloca con offsets a ojo."""
    meta = json.loads((rdir / "frames.json").read_text())
    odir = OUT / job["dest"]
    if odir.exists():
        shutil.rmtree(odir)
    odir.mkdir(parents=True)
    base, pname, rev = pack_info(job["pack"])
    items = {}
    bad = []
    ss = int(meta.get("ss", 1))
    for it in job["items"]:
        iid = it["id"]
        pad = int(it.get("pad", 2))
        im = Image.open(rdir / f"{iid}.png").convert("RGBA")
        kind = it.get("kind", job.get("look_kind", "prop"))
        if kind != "none":
            im = premium_look.stylize(im, kind, ss, it.get("outline_px"))
        bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        if bb is None:
            sys.exit(f"pieza vacia: {iid}")
        pd = pad * ss
        box = (max(0, bb[0] - pd), max(0, bb[1] - pd), min(im.width, bb[2] + pd), min(im.height, bb[3] + pd))
        if box[0] == 0 or box[1] == 0 or box[2] == im.width or box[3] == im.height:
            bad.append(iid)
            continue
        crop = im.crop(box)
        if ss > 1:
            crop = crop.convert("RGBa").resize((max(1, round(crop.width / ss)), max(1, round(crop.height / ss))), Image.LANCZOS).convert("RGBA")
        crop.save(odir / f"{iid}.png", optimize=True)
        a = meta["items"][iid]["anchor"]
        rec = {
            "path": f"res://assets/premium/{job['dest']}/{iid}.png", "size": [crop.width, crop.height],
            "bbox": [0, 0, crop.width, crop.height], "anchor": [round((a[0] - box[0]) / ss, 2), round((a[1] - box[1]) / ss, 2)],
            "scale": job["ppu_game"] / job["ppu"], "pitch": meta["items"][iid]["pitch"], "source_file": it.get("file", "original:" + it.get("build", iid)),
        }
        if "points" in meta["items"][iid]:
            rec["points"] = {k: [round(v[0] / ss, 2), round(v[1] / ss, 2)] for k, v in meta["items"][iid]["points"].items()}
        items[iid] = rec
    if bad:
        sys.exit(f"QUALITY GATE: piezas recortadas por el borde del render en {jid} (subir cell o quitarlas): {', '.join(bad)}")
    manifest = {
        "id": jid, "kind": "static_set", "role": "environment", "source_pack": pname, "source_revision": rev, "license": "Original work (RPG Premium)" if job["pack"] == "own" else "CC0 1.0",
        "transformation": "Godot offscreen ortho render (tools/premium_render/render_static.gd) + recorte por alfa; ancla = origen del modelo",
        "job_sha256": hashlib.sha256(json.dumps(job, sort_keys=True).encode()).hexdigest()[:16],
        "runtime_path": f"res://assets/premium/{job['dest']}/", "ppu": job["ppu"], "ppu_game": job["ppu_game"], "items": items,
    }
    (odir / "manifest.json").write_text(json.dumps(manifest, indent=1))
    return manifest


def write_gd_manifest():
    statics = {}
    for mf in sorted(OUT.glob("**/manifest.json")):
        m = json.loads(mf.read_text())
        if m.get("kind") != "static_set":
            continue
        rel = mf.parent.relative_to(OUT).as_posix()
        for iid, it in m["items"].items():
            statics[f"premium/{rel}/{iid}"] = dict(it, source={"pack": m["source_pack"], "revision": m["source_revision"], "license": m["license"]})
    sets = {}
    for mf in sorted(OUT.glob("*/*/manifest.json")):
        m = json.loads(mf.read_text())
        if m.get("kind") == "static_set":
            continue
        sid = f"premium/{mf.parent.parent.name}/{m['id']}"
        entry = {
            "kind": m["kind"], "role": m["role"], "weapon_compatible": m["role"] == "player",
            "bbox": [0, 0, m["cell"][0], int(round(m["feet"][1]))],
            "feet": m["feet"], "ppu": m["ppu"],
            "source": {"pack": m["source_pack"], "revision": m["source_revision"], "license": m["license"]},
            "anims": m["anims"],
        }
        if "grips" in m:
            entry["grips"] = m["grips"]
            entry["weapon_axis"] = m["weapon_axis"]
        sets[sid] = entry
    body = json.dumps(sets, indent="\t")
    sbody = json.dumps(statics, indent="\t")
    MANIFEST_GD.write_text(
        "class_name PremiumManifest\nextends RefCounted\n"
        "## GENERADO por tools/premium_pipeline.py (no editar a mano). Hojas pre-renderizadas desde rigs 3D CC0 + agarre derivado del hueso fuente.\n"
        "## SETS[id] = {bbox, feet, anims{anim:{sheet,dirs,counts,cell,weapon_mode,hand}}, grips{anim:{dir:[[gx,gy,ang,lgx,lgy,behind]...]}}}\n"
        "## grip: px de celda relativos a los pies; ang: eje del arma en pantalla (grados, y hacia abajo); lg*: mano libre; behind=1 si la mano queda detras del torso (arma bajo el cuerpo).\n\n"
        "## STATIC[id] = {path, size, bbox, anchor (origen del modelo en el recorte), scale (px de juego por px de textura), source}\n\n"
        f"const SETS := {body}\n\nconst STATIC := {sbody}\n")
    print("manifest ->", MANIFEST_GD.relative_to(ROOT), f"({len(sets)} sets, {len(statics)} estaticos)")


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build")
    b.add_argument("ids", nargs="+")
    b.add_argument("--no-render", action="store_true")
    sub.add_parser("manifest")
    sub.add_parser("list")
    a = ap.parse_args()
    if a.cmd == "list":
        for p in sorted(JOBS.glob("*.json")):
            print(p.stem)
    elif a.cmd == "manifest":
        write_gd_manifest()
    else:
        for jid in a.ids:
            job = load_job(jid)
            rdir = RENDER_BUILD / jid if a.no_render else render(jid, job)
            if job["kind"] == "static_set":
                pack_static(jid, job, rdir)
            else:
                pack_asset(jid, job, rdir)
            print("built", jid)
        write_gd_manifest()


if __name__ == "__main__":
    main()
