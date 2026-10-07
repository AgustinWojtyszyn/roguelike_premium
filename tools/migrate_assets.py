#!/usr/bin/env python3
"""Migracion de assets desde Rpg_new y VIDA hacia roguelike_premium (reproducible).

Uso:
    python3 tools/migrate_assets.py --rpg <clon Rpg_new en soulknight-polish-pass> --vida <clon VIDA> [--dry]

- Audita TODOS los PNG/OGG/WAV de todas las ramas de Rpg_new (por hash de blob git) y de VIDA.
- Deduplica por contenido, descarta .import / capturas / duplicados / fuentes de generacion.
- Empaqueta las animaciones por personaje en sheets (filas = direcciones, columnas = frames) para reducir
  archivos, memoria y texturas. Los frames originales siguen en los repos fuente (commits fijados en el informe).
- Copia los estaticos utiles a assets/migrated/<fuente>/<categoria>/ y deja lo bueno-pero-sin-uso-todavia en
  asset_bank/reserve/ (ignorado por Godot).
- Genera data/visual/asset_manifest.gd (tabla que lee AssetCatalog) y docs/ASSET_AUDIT.md + docs/asset_inventory.json.
No toca scripts, escenas ni project.godot de las fuentes.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from collections import OrderedDict, defaultdict

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DIRS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
ART_EXT = (".png", ".ogg", ".wav", ".mp3", ".webp", ".jpg", ".jpeg", ".svg")
RPG_REFS = ["origin/main", "origin/soulknight-polish-pass", "origin/discard/enemy-families-v2",
            "origin/discard/pre-astra-single-room-v2"]

# ---------------------------------------------------------------- plan
# personajes animados: carpeta fuente -> (id destino, estado)
RPG_ANIM_CHARS = {
    "player/playable_human_ranger_unarmed": ("characters/human_ranger", "migrate"),
    "player/playable_human_ranger": ("characters/human_ranger_armed", "reserve"),
    "player/playable_combat_android": ("characters/combat_android", "migrate"),
    "player/playable_beetle_cyborg": ("characters/beetle_cyborg", "migrate"),
    "player/playable_mutant_striker": ("characters/mutant_striker", "migrate"),
    "enemies/enemy_bone_guard": ("enemies/bone_guard", "migrate"),
    "enemies/enemy_iron_beetle": ("enemies/iron_beetle", "migrate"),
    "enemies/enemy_orb_stalker": ("enemies/orb_stalker", "migrate"),
    "enemies/enemy_raptor": ("enemies/raptor", "migrate"),
    "enemies/enemy_root_vine": ("enemies/root_vine", "migrate"),
    "bosses/boss_rift_warden": ("bosses/rift_warden", "migrate"),
    "bosses/boss_trex": ("bosses/trex", "reserve"),
}
# polish: animaciones extra de una sola direccion que se fusionan como `<anim>_alt`
RPG_POLISH = {
    "polish/playable_combat_android": "characters/combat_android",
    "polish/playable_beetle_cyborg": "characters/beetle_cyborg",
    "polish/playable_mutant_striker": "characters/mutant_striker",
    "polish/bone_guard": "enemies/bone_guard",
    "polish/iron_beetle": "enemies/iron_beetle",
    "polish/raptor_scout": "enemies/raptor",
}

# estaticos de Rpg_new: (prefijo relativo a assets/generated/, destino, estado). Gana el primer prefijo que coincide.
RPG_STATIC = [
    ("animations/", None, "skip"),
    ("holding/source/", None, "discard:fuente de generacion (duplica holding/)"),
    ("holding/", "characters/holding", "reserve"),
    ("playables/portraits/", "ui/portraits", "migrate"),
    ("playables/", "characters/static", "reserve"),
    ("enemies/", "enemies/static", "reserve"),
    ("bosses/", "bosses/static", "reserve"),
    ("weapons/held/", "weapons/held", "reserve"),
    ("weapons/icons/", "weapons/icons", "reserve"),
    ("weapons/pickups/", "weapons/pickups", "reserve"),
    ("props/chests/", "chests", "migrate"),
    ("props/pickups/", "props/pickups", "migrate"),
    ("props/", "props", "migrate"),
    ("decals/", "decals", "migrate"),
    ("rooms/", "props/rooms", "migrate"),
    ("vfx/", "vfx", "migrate"),
    ("ui/", "ui", "reserve"),
    ("tiles/", "tiles", "reserve"),
    ("tilesets_2_5d/", "tiles/2_5d", "reserve"),
    ("terrain/", "tiles/terrain", "reserve"),
]
# VIDA: estaticos utiles para HOME / hub
VIDA_STATIC = [
    ("interior/", "interior", "migrate"),
    ("city/props/ar/", "props/city", "reserve"),
    ("city/props/jp/vending_machine", "props/city", "migrate"),
    ("city/props/bench", "props/city", "migrate"),
    ("city/props/lamp", "props/city", "migrate"),
    ("city/props/planter", "props/city", "migrate"),
    ("city/props/fountain", "props/city", "reserve"),
    ("city/props/", "props/city", "reserve"),
    ("city/vegetation/", "props/city", "reserve"),
    ("oriented/props/bench/", "props/bench", "reserve"),
    ("environment/", "environment", "reserve"),
    ("characters/resident/", "npc/resident", "reserve"),
    ("buildings/", "urban/buildings", "reserve"),
    ("city/buildings/", "urban/buildings", "reserve"),
    ("houses/", "urban/buildings", "reserve"),
    ("oriented/", "urban/buildings", "reserve"),
    ("vehicles/", "urban/vehicles", "reserve"),
    ("city/vehicles/", "urban/vehicles", "reserve"),
    ("regions/", "urban/regions", "reserve"),
    ("catalog/", "urban/catalog", "reserve"),
]


# armas: id Premium -> (arte fuente de weapons/pickups, espejar [el canon apunta con el canon a la izquierda], rotacion extra, fraccion del agarre)
WEAPON_ORIENT = {
    "pulsar": ("pulse_smg", True, 0, 0.45),
    "maul12": ("breach_shotgun", False, 0, 0.42),
    "lancex": ("alien_beam_rifle", True, 0, 0.42),
    "chispa": ("tactical_sidearm", False, 0, 0.28),
    "trinca": ("swat_compact", False, 0, 0.42),
    "mastin": ("beetle_core", True, 0, 0.42),
    "gota": ("living_spore_gun", False, 0, 0.36),
    "pomelo": ("toxic_mortar", True, 0, 0.42),
    "relampago": ("arc_rifle", False, 0, 0.42),
    "rebote": ("void_pistol", True, 0, 0.30),
    "colmena": ("hive_launcher", True, 0, 0.42),
    "filo_z": ("rift_spear", False, 0, 0.30),
    "garra": ("mutant_claws", False, 90, 0.12),
    "enjambre": ("beetle_cannon", False, 0, 0.5),
    "anomalia": ("orb_projector", False, 0, 0.22),
    "riel_q": ("bone_rail", False, 0, 0.40),
    "brasero": ("void_launcher", True, 0, 0.45),
    "aguja": ("swat_carbine", True, 0, 0.42),
}


def build_weapon_art(src_pick_dir, out_dir):
    """Normaliza el arte de armas: gira el eje largo a horizontal (canon a +x), recorta y calcula agarre y punta."""
    import numpy as np
    from PIL import ImageOps
    out = OrderedDict()
    UP = 3
    for wid, (art, flip, extra, gfrac) in WEAPON_ORIENT.items():
        src = os.path.join(src_pick_dir, art + ".png")
        if not os.path.exists(src):
            continue
        im = Image.open(src).convert("RGBA")
        m = np.array(im)[:, :, 3] > 40
        ys, xs = np.nonzero(m)
        pts = np.stack([xs, ys], 1).astype(float)
        c = pts.mean(0)
        _, _, vt = np.linalg.svd(pts - c, full_matrices=False)
        ang = np.degrees(np.arctan2(vt[0][1], vt[0][0]))
        while ang > 90:
            ang -= 180
        while ang <= -90:
            ang += 180
        if extra:
            ang = extra
        big = im.resize((im.width * UP, im.height * UP), Image.NEAREST)
        r = big.rotate(float(ang), resample=Image.BICUBIC, expand=True)
        if flip:
            r = ImageOps.mirror(r)
        bb = r.getchannel("A").point(lambda v: 255 if v > 40 else 0).getbbox()
        r = r.crop(bb)
        w, h = r.size
        gx = w * gfrac
        gy = h * 0.5
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, wid + ".png")
        r.save(path, optimize=True)
        out[wid] = {"path": res_path_global(path), "size": [w, h], "grip": [round(gx, 1), round(gy, 1)], "tip": float(w), "src": art}
    return out


def res_path_global(abs_path):
    return "res://" + os.path.relpath(abs_path, ROOT).replace(os.sep, "/")


def md5(b):
    return hashlib.md5(b).hexdigest()


def read(p):
    with open(p, "rb") as f:
        return f.read()


def sh(cwd, *a):
    return subprocess.check_output(a, cwd=cwd).decode().strip()


# ---------------------------------------------------------------- auditoria
def audit_rpg(rpg):
    """Todos los blobs de arte de todas las ramas. Devuelve {oid: {paths, refs, ext}}."""
    inv = OrderedDict()
    for ref in RPG_REFS:
        for line in sh(rpg, "git", "ls-tree", "-r", ref).splitlines():
            meta, path = line.split("\t", 1)
            if not path.lower().endswith(ART_EXT):
                continue
            oid = meta.split()[2]
            e = inv.setdefault(oid, {"paths": [], "refs": []})
            if path not in e["paths"]:
                e["paths"].append(path)
            if ref not in e["refs"]:
                e["refs"].append(ref)
    return inv


def audit_vida(vida):
    inv = OrderedDict()
    for line in sh(vida, "git", "ls-tree", "-r", "HEAD").splitlines():
        meta, path = line.split("\t", 1)
        if not path.lower().endswith(ART_EXT):
            continue
        oid = meta.split()[2]
        e = inv.setdefault(oid, {"paths": [], "refs": ["HEAD"]})
        e["paths"].append(path)
    return inv


def load_blob(repo, oid):
    return subprocess.check_output(["git", "cat-file", "blob", oid], cwd=repo)


# ---------------------------------------------------------------- empaquetado
def parse_anim_file(rel):
    """rel = ruta bajo la carpeta del personaje. Devuelve (anim, dir) o None."""
    parts = rel.split("/")
    if len(parts) == 3 and parts[1] in DIRS:
        return parts[0], parts[1]
    if len(parts) == 2:
        folder = parts[0]
        for d in sorted(DIRS, key=len, reverse=True):
            if folder.endswith("_" + d):
                return folder[: -len(d) - 1], d
        return folder, "south"
    return None


def trim_bbox(im):
    return im.getchannel("A").getbbox()


def pack_sheet(frames_by_dir, out_png):
    """frames_by_dir: {dir: [Image,...]} -> sheet. Devuelve (dirs, counts, cell)."""
    dirs = [d for d in DIRS if d in frames_by_dir]
    cw = max(f.width for d in dirs for f in frames_by_dir[d])
    ch = max(f.height for d in dirs for f in frames_by_dir[d])
    n = max(len(frames_by_dir[d]) for d in dirs)
    sheet = Image.new("RGBA", (cw * n, ch * len(dirs)), (0, 0, 0, 0))
    for r, d in enumerate(dirs):
        for c, f in enumerate(frames_by_dir[d]):
            ox = (cw - f.width) // 2
            oy = ch - f.height
            sheet.paste(f, (c * cw + ox, r * ch + oy))
    os.makedirs(os.path.dirname(out_png), exist_ok=True)
    sheet.save(out_png, optimize=True)
    return dirs, [len(frames_by_dir[d]) for d in dirs], [cw, ch]


def median_box(boxes):
    """Caja 'tipica' (mediana de alto/ancho/base) para escalar y anclar los pies sin que un frame extremo la distorsione."""
    if not boxes:
        return None
    def med(v):
        v = sorted(v)
        return v[len(v) // 2]
    h = med([b[3] - b[1] for b in boxes])
    w = med([b[2] - b[0] for b in boxes])
    bot = med([b[3] for b in boxes])
    cx = med([(b[0] + b[2]) // 2 for b in boxes])
    return (cx - w // 2, bot - h, cx - w // 2 + w, bot)


def build_animated(src_dir, out_dir, extra_polish=None):
    """Lee frames de una carpeta de personaje y los empaqueta por animacion."""
    slots = defaultdict(dict)  # anim -> dir -> [paths]
    for root, _, files in os.walk(src_dir):
        for fn in sorted(files):
            if not fn.endswith(".png"):
                continue
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, src_dir).replace(os.sep, "/")
            if rel.startswith("static"):
                continue
            ad = parse_anim_file(rel)
            if ad is None:
                continue
            slots[ad[0]].setdefault(ad[1], []).append(full)
    anims = {}
    boxes = []
    for anim, byd in sorted(slots.items()):
        frames = {}
        for d, paths in byd.items():
            # una misma ranura puede venir de dos layouts (walk/north y walk_north): gana la de mas frames
            frames.setdefault(d, [])
            if len(paths) > len(frames[d]):
                pass
            frames[d] = sorted(paths)
        imgs = {d: [Image.open(p).convert("RGBA") for p in ps] for d, ps in frames.items()}
        for d in imgs:
            for im in imgs[d]:
                b = trim_bbox(im)
                if b is None:
                    continue
                if anim in ("walk", "idle", "move"):
                    boxes.append(b)
        out_png = os.path.join(out_dir, anim + ".png")
        dirs, counts, cell = pack_sheet(imgs, out_png)
        anims[anim] = {"sheet": out_png, "dirs": dirs, "counts": counts, "cell": cell}
    return anims, median_box(boxes)


def keys_for_pack_polish(base_dir, out_dir, anims):
    """Anade las animaciones 'polish' (una direccion, 3-4 frames) como <anim>_alt."""
    slots = defaultdict(list)
    for fn in sorted(os.listdir(base_dir)) if os.path.isdir(base_dir) else []:
        pass
    for root, _, files in os.walk(base_dir):
        for fn in sorted(files):
            if fn.endswith(".png"):
                rel = os.path.relpath(os.path.join(root, fn), base_dir).replace(os.sep, "/")
                slots[rel.split("/")[0]].append(os.path.join(root, fn))
    for anim, paths in slots.items():
        imgs = {"south": [Image.open(p).convert("RGBA") for p in sorted(paths)]}
        key = anim + "_alt"
        out_png = os.path.join(out_dir, key + ".png")
        dirs, counts, cell = pack_sheet(imgs, out_png)
        anims[key] = {"sheet": out_png, "dirs": dirs, "counts": counts, "cell": cell}


# ---------------------------------------------------------------- main
def classify(rel, table):
    for prefix, dest, state in table:
        if rel.startswith(prefix):
            return dest, state
    return None, "reserve"


def gd_value(v, ind=0):
    pad = "\t" * ind
    if isinstance(v, dict):
        if not v:
            return "{}"
        items = ",\n".join(f"{pad}\t{json.dumps(k)}: {gd_value(x, ind + 1)}" for k, x in v.items())
        return "{\n" + items + "\n" + pad + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(gd_value(x, ind + 1) for x in v) + "]"
    if isinstance(v, bool):
        return "true" if v else "false"
    if v is None:
        return "null"
    return json.dumps(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rpg", required=True)
    ap.add_argument("--vida", required=True)
    ap.add_argument("--dry", action="store_true")
    a = ap.parse_args()
    rpg, vida = os.path.abspath(a.rpg), os.path.abspath(a.vida)
    rpg_head = sh(rpg, "git", "rev-parse", "HEAD")
    vida_head = sh(vida, "git", "rev-parse", "HEAD")

    inv_r = audit_rpg(rpg)
    inv_v = audit_vida(vida)
    audited = {"rpg": len(inv_r), "vida": len(inv_v)}
    dup_paths = {"rpg": sum(len(e["paths"]) for e in inv_r.values()) - len(inv_r),
                 "vida": sum(len(e["paths"]) for e in inv_v.values()) - len(inv_v)}
    print("auditados (blobs unicos):", audited, "rutas duplicadas:", dup_paths)
    if a.dry:
        return

    mig = os.path.join(ROOT, "assets", "migrated")
    res = os.path.join(ROOT, "asset_bank", "reserve")
    for d in (mig, res):
        if os.path.isdir(d):
            shutil.rmtree(d)
    manifest = {"anims": OrderedDict(), "static": OrderedDict(), "aliases": OrderedDict()}
    stats = defaultdict(int)
    decisions = []  # inventario por blob
    seen_hash = {}

    def res_path(abs_path):
        return "res://" + os.path.relpath(abs_path, ROOT).replace(os.sep, "/")

    gen = os.path.join(rpg, "assets", "generated")
    # ----- Rpg_new: animaciones
    for srcrel, (dest, state) in RPG_ANIM_CHARS.items():
        src_dir = os.path.join(gen, "animations", srcrel)
        base = mig if state == "migrate" else res
        out_dir = os.path.join(base, "rpg", dest)
        anims, bb = build_animated(src_dir, out_dir)
        if dest in RPG_POLISH.values():
            for pol, d2 in RPG_POLISH.items():
                if d2 == dest:
                    keys_for_pack_polish(os.path.join(gen, "animations", pol), out_dir, anims)
        for k in anims:
            anims[k]["sheet"] = res_path(anims[k]["sheet"])
        key = "rpg/" + dest
        manifest["anims"][key] = {"state": state, "bbox": list(bb) if bb else [0, 0, 0, 0], "anims": anims}
        stats["rpg_sheets_" + state] += len(anims)
    # ----- Rpg_new: estaticos (se recorre el checkout de la rama grande + blobs que solo viven en otras ramas)
    covered = set()
    for root, _, files in os.walk(gen):
        for fn in sorted(files):
            if not fn.lower().endswith(ART_EXT):
                continue
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, gen).replace(os.sep, "/")
            data = read(full)
            h = md5(data)
            oid = subprocess.check_output(["git", "hash-object", full], cwd=rpg).decode().strip()
            covered.add(oid)
            dest, state = classify(rel, RPG_STATIC)
            entry = {"src": "rpg", "path": "assets/generated/" + rel, "oid": oid, "bytes": len(data)}
            if state == "skip":
                entry["decision"] = "sheet"
                decisions.append(entry)
                continue
            if state.startswith("discard"):
                entry["decision"] = state
                decisions.append(entry)
                stats["rpg_discard"] += 1
                continue
            if h in seen_hash:
                entry["decision"] = "duplicate-of:" + seen_hash[h]
                decisions.append(entry)
                manifest["aliases"]["rpg/" + dest + "/" + os.path.splitext(fn)[0]] = seen_hash[h]
                stats["rpg_dup"] += 1
                continue
            sub = os.path.relpath(root, gen).replace(os.sep, "/")
            tail = sub
            for prefix, d2, _ in RPG_STATIC:
                if rel.startswith(prefix) and d2 is not None:
                    tail = os.path.relpath(os.path.dirname(rel), prefix.rstrip("/")).replace(os.sep, "/")
                    break
            tail = "" if tail == "." else tail
            name = fn
            outp = os.path.join(mig if state == "migrate" else res, "rpg", dest, tail, name)
            os.makedirs(os.path.dirname(outp), exist_ok=True)
            if fn.lower().endswith(".json"):
                continue
            shutil.copyfile(full, outp)
            sid = "rpg/" + dest + ("/" + tail if tail else "") + "/" + os.path.splitext(fn)[0]
            seen_hash[h] = sid
            entry["decision"] = state
            entry["dest"] = os.path.relpath(outp, ROOT).replace(os.sep, "/")
            decisions.append(entry)
            stats["rpg_" + state] += 1
            if state == "migrate" and fn.lower().endswith(".png"):
                im = Image.open(full)
                manifest["static"][sid] = {"path": res_path(outp), "size": [im.width, im.height], "bbox": list(Image.open(full).convert("RGBA").getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0, im.width, im.height))}
            elif state == "migrate":
                manifest["static"][sid] = {"path": res_path(outp), "size": [0, 0]}
    # blobs que solo existen en otras ramas (main / discard/*): se auditan y se archivan en reserve
    extra = [(oid, e) for oid, e in inv_r.items() if oid not in covered]
    for oid, e in extra:
        path = e["paths"][0]
        if path.startswith("assets/audio/") or not path.startswith("assets/generated/"):
            dest_dir = os.path.join(res, "rpg", "extras", os.path.dirname(path))
        else:
            dest_dir = os.path.join(res, "rpg", "extras", os.path.dirname(path))
        data = load_blob(rpg, oid)
        h = md5(data)
        entry = {"src": "rpg", "path": path, "oid": oid, "bytes": len(data), "refs": e["refs"]}
        if h in seen_hash:
            entry["decision"] = "duplicate-of:" + seen_hash[h]
            stats["rpg_dup"] += 1
        else:
            os.makedirs(dest_dir, exist_ok=True)
            outp = os.path.join(dest_dir, os.path.basename(path))
            with open(outp, "wb") as f:
                f.write(data)
            seen_hash[h] = path
            entry["decision"] = "reserve"
            entry["dest"] = os.path.relpath(outp, ROOT).replace(os.sep, "/")
            stats["rpg_reserve"] += 1
        decisions.append(entry)
    # audio Kenney (CC0): la rama grande trae assets/audio -> reserve (Premium sintetiza su propio audio)
    kdir = os.path.join(rpg, "assets", "audio")
    if os.path.isdir(kdir):
        for root, _, files in os.walk(kdir):
            for fn in sorted(files):
                if not fn.lower().endswith((".ogg", ".wav", ".mp3", ".txt")) or fn.endswith(".import"):
                    continue
                full = os.path.join(root, fn)
                rel = os.path.relpath(full, kdir)
                data = read(full)
                h = md5(data)
                entry = {"src": "rpg", "path": "assets/audio/" + rel.replace(os.sep, "/"), "bytes": len(data)}
                if h in seen_hash:
                    entry["decision"] = "duplicate-of:" + seen_hash[h]
                    stats["rpg_dup"] += 1
                else:
                    outp = os.path.join(res, "rpg", "audio", rel)
                    os.makedirs(os.path.dirname(outp), exist_ok=True)
                    shutil.copyfile(full, outp)
                    seen_hash[h] = rel
                    entry["decision"] = "reserve"
                    stats["rpg_reserve"] += 1
                decisions.append(entry)

    # ----- armas normalizadas (rotadas/recortadas con agarre y punta) a partir de weapons/pickups
    manifest["oriented"] = build_weapon_art(os.path.join(gen, "weapons", "pickups"), os.path.join(mig, "rpg", "weapons", "oriented"))
    stats["rpg_weapon_oriented"] = len(manifest["oriented"])

    # ----- VIDA
    va = os.path.join(vida, "assets")
    # personajes con walk de 8 dirs (hombre/mujer) y poses de una direccion
    for who in ("male", "female"):
        cdir = os.path.join(va, "characters", who)
        out_dir = os.path.join(mig, "vida", "npc", who)
        anims = {}
        walk = defaultdict(list)
        for fn in sorted(os.listdir(os.path.join(cdir, "walk"))):
            m = re.match(r"(.+)_(\d+)\.png$", fn)
            if m:
                walk[m.group(1)].append((int(m.group(2)), os.path.join(cdir, "walk", fn)))
        imgs = {d: [Image.open(p).convert("RGBA") for _, p in sorted(v)] for d, v in walk.items()}
        dirs, counts, cell = pack_sheet(imgs, os.path.join(out_dir, "walk.png"))
        anims["walk"] = {"sheet": res_path(os.path.join(out_dir, "walk.png")), "dirs": dirs, "counts": counts, "cell": cell}
        stills = {d: [Image.open(os.path.join(cdir, d + ".png")).convert("RGBA")] for d in DIRS if os.path.exists(os.path.join(cdir, d + ".png"))}
        dirs, counts, cell = pack_sheet(stills, os.path.join(out_dir, "idle.png"))
        anims["idle"] = {"sheet": res_path(os.path.join(out_dir, "idle.png")), "dirs": dirs, "counts": counts, "cell": cell}
        for pose in ("phone", "drink"):
            pd = os.path.join(cdir, pose)
            if os.path.isdir(pd):
                fr = [Image.open(os.path.join(pd, fn)).convert("RGBA") for fn in sorted(os.listdir(pd)) if fn.endswith(".png")]
                dirs, counts, cell = pack_sheet({"south": fr}, os.path.join(out_dir, pose + ".png"))
                anims[pose] = {"sheet": res_path(os.path.join(out_dir, pose + ".png")), "dirs": dirs, "counts": counts, "cell": cell}
        bb = median_box([trim_bbox(i) for v in imgs.values() for i in v if trim_bbox(i)])
        manifest["anims"]["vida/npc/" + who] = {"state": "migrate", "bbox": list(bb), "anims": anims}
        stats["vida_sheets_migrate"] += len(anims)
    covered_v = set()
    for root, _, files in os.walk(va):
        for fn in sorted(files):
            if not fn.lower().endswith(ART_EXT):
                continue
            full = os.path.join(root, fn)
            rel = os.path.relpath(full, va).replace(os.sep, "/")
            data = read(full)
            h = md5(data)
            oid = subprocess.check_output(["git", "hash-object", full], cwd=vida).decode().strip()
            covered_v.add(oid)
            entry = {"src": "vida", "path": "assets/" + rel, "oid": oid, "bytes": len(data)}
            if rel.startswith("characters/male/") or rel.startswith("characters/female/"):
                entry["decision"] = "sheet"
                decisions.append(entry)
                stats["vida_sheet_src"] += 1
                continue
            dest, state = classify(rel, VIDA_STATIC)
            if h in seen_hash:
                entry["decision"] = "duplicate-of:" + seen_hash[h]
                decisions.append(entry)
                stats["vida_dup"] += 1
                continue
            if state != "migrate":
                # sin uso aun: ya esta guardado sin perdida en asset_bank/bundles (import VIDA completo); solo se inventaria
                seen_hash[h] = "vida/" + (dest or "x") + "/" + os.path.splitext(os.path.basename(rel))[0]
                entry["decision"] = "reserve:asset_bank/bundles"
                decisions.append(entry)
                stats["vida_reserve"] += 1
                continue
            base = mig
            tail = rel
            for prefix, d2, _ in VIDA_STATIC:
                if rel.startswith(prefix):
                    tail = rel[len(prefix):] if prefix.endswith("/") else os.path.basename(rel)
                    break
            outp = os.path.join(base, "vida", dest, tail)
            os.makedirs(os.path.dirname(outp), exist_ok=True)
            shutil.copyfile(full, outp)
            sid = "vida/" + dest + "/" + os.path.splitext(tail)[0]
            seen_hash[h] = sid
            entry["decision"] = state
            entry["dest"] = os.path.relpath(outp, ROOT).replace(os.sep, "/")
            decisions.append(entry)
            stats["vida_" + state] += 1
            if state == "migrate":
                im = Image.open(full)
                manifest["static"][sid] = {"path": res_path(outp), "size": [im.width, im.height], "bbox": list(im.convert("RGBA").getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox() or (0, 0, im.width, im.height))}
    for oid, e in inv_v.items():
        if oid not in covered_v:
            decisions.append({"src": "vida", "path": e["paths"][0], "oid": oid, "decision": "unlisted"})

    # ----- salidas
    manifest["aliases"] = OrderedDict((k, v) for k, v in manifest["aliases"].items() if v in manifest["static"])
    out_gd = os.path.join(ROOT, "data", "visual", "asset_manifest.gd")
    os.makedirs(os.path.dirname(out_gd), exist_ok=True)
    live_anims = OrderedDict((k, v) for k, v in manifest["anims"].items() if v["state"] == "migrate")
    with open(out_gd, "w") as f:
        f.write("class_name AssetManifest\nextends RefCounted\n")
        f.write("## GENERADO por tools/migrate_assets.py (no editar a mano). Hojas de animacion y estaticos migrados.\n")
        f.write("## anims[id].anims[anim] = {sheet, dirs (filas), counts (frames por fila), cell}; bbox = caja opaca union (pies = y max).\n\n")
        f.write("const ANIMS := " + gd_value(live_anims) + "\n\n")
        f.write("const STATIC := " + gd_value(manifest["static"]) + "\n\n")
        f.write("const ALIASES := " + gd_value(manifest["aliases"]) + "\n\n")
        f.write("## Armas normalizadas: eje a +x, `grip` = punto de agarre (origen del arma), `tip` = x de la punta.\n")
        f.write("const ORIENTED := " + gd_value(manifest["oriented"]) + "\n")
    sources = {"rpg": {"repo": "AgustinWojtyszyn/Rpg_new", "head_checkout": rpg_head, "refs": RPG_REFS},
               "vida": {"repo": "AgustinWojtyszyn/Life--simulador-de-vida", "head": vida_head}}
    os.makedirs(os.path.join(ROOT, "docs"), exist_ok=True)
    with open(os.path.join(ROOT, "docs", "asset_inventory.json"), "w") as f:
        json.dump({"sources": sources, "audited": audited, "stats": dict(stats), "items": decisions}, f, indent=0)
    summary = {"audited": audited, "dup_paths": dup_paths, "stats": dict(stats), "sources": sources,
               "static_migrated": len(manifest["static"]), "anim_sets": len(live_anims)}
    with open(os.path.join(ROOT, "docs", "asset_migration_summary.json"), "w") as f:
        json.dump(summary, f, indent=1)
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    main()
