"""Gate Premium en Python: el chequeo estatico debe aprobar los assets reales y RECHAZAR manifests de jugables defectuosos."""
import copy, importlib.util, json, unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("check_premium_art", ROOT / "tools/check_premium_art.py")
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


def good_player():
    dirs = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
    anim = lambda mode="aim": {"dirs": dirs, "counts": [2] * 8, "weapon_mode": mode}
    grips = {a: {d: [[0, 0, 0, 0, 0, 0]] * 2 for d in dirs} for a in ("idle", "walk", "hurt", "death")}
    return {"id": "t", "kind": "hero_ranged", "role": "player", "source_pack": "KayKit", "source_revision": "abc", "license": "CC0 1.0",
            "transformation": "x", "runtime_path": "res://assets/premium/characters/t/",
            "anims": {a: anim() for a in ("idle", "walk", "hurt", "death")}, "grips": grips}


class PremiumGate(unittest.TestCase):
    def test_real_assets_pass(self):
        self.assertEqual(gate.check_premium_assets(), [])
        self.assertEqual(gate.errors, [])

    def test_good_player_passes(self):
        self.assertEqual(gate.validate_manifest(good_player()), [])

    def test_rejects_missing_grips(self):
        m = good_player(); del m["grips"]
        self.assertTrue(gate.validate_manifest(m))

    def test_rejects_partial_grips(self):
        m = good_player(); m["grips"]["walk"]["east"] = []
        self.assertTrue(any("walk/east" in e for e in gate.validate_manifest(m)))

    def test_rejects_missing_locomotion_hurt_death(self):
        for a in ("walk", "hurt", "death"):
            m = good_player(); del m["anims"][a]
            self.assertTrue(any(a in e for e in gate.validate_manifest(m)), a)

    def test_rejects_fewer_than_8_dirs(self):
        m = good_player(); m["anims"]["idle"]["dirs"] = m["anims"]["idle"]["dirs"][:4]; m["anims"]["idle"]["counts"] = [2] * 4
        self.assertTrue(gate.validate_manifest(m))

    def test_rejects_unknown_license_or_revision(self):
        m = good_player(); m["license"] = "unknown"
        self.assertTrue(gate.validate_manifest(m))
        m = good_player(); m["source_revision"] = "unknown"
        self.assertTrue(gate.validate_manifest(m))

    def test_melee_requires_attack_and_ranged_requires_aim(self):
        m = good_player(); m["kind"] = "hero_melee"
        self.assertTrue(any("attack" in e for e in gate.validate_manifest(m)))
        m = good_player(); m["anims"]["idle"]["weapon_mode"] = "rig"
        self.assertTrue(any("apuntado" in e for e in gate.validate_manifest(m)))


class PremiumLook(unittest.TestCase):
    """Identidad visual: todo sprite Premium animado lleva contorno oscuro continuo (lectura en pantallas moviles)."""

    def test_silhouette_edges_are_dark(self):
        from PIL import Image
        import numpy as np
        for sheet in ("characters/vesper/idle", "characters/sable/idle", "enemies/skeleton_warrior/idle", "enemies/crab/idle", "weapons/pulsar"):
            im = np.asarray(Image.open(ROOT / f"assets/premium/{sheet}.png").convert("RGBA")).astype(np.float32)
            a = im[..., 3] > 200
            pad = np.pad(a, 1)
            edge = a & ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])
            lum = (im[..., :3] * [0.299, 0.587, 0.114]).sum(-1)
            self.assertGreater((lum[edge] < 70).mean(), 0.85, sheet)

    def test_weapon_points_exist(self):
        m = json.loads((ROOT / "assets/premium/weapons/manifest.json").read_text())
        for wid, it in m["items"].items():
            self.assertIn("tip", it["points"], wid)
            self.assertGreater(it["points"]["tip"][0], 10, wid)


if __name__ == "__main__":
    unittest.main()
