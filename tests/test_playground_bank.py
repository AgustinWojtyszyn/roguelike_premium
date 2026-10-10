import hashlib
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BANK = ROOT / "asset_bank" / "playground"


class PlaygroundBankTests(unittest.TestCase):
    def test_every_manifest_entry_is_preserved_by_hash(self):
        manifest = json.loads((BANK / "reports" / "FULL_MEDIA_MANIFEST.json").read_text())
        present = {hashlib.sha256(p.read_bytes()).hexdigest() for p in BANK.rglob("*") if p.is_file()}
        missing = [f["local_path"] for f in manifest["files"]
                   if f["source_sha256"] not in present and f["converted_sha256"] not in present]
        self.assertEqual(missing, [])
        self.assertEqual(len(manifest["manual_selection"]), len(list((BANK / "manual_selection" / "source_jpg").glob("*"))))

    def test_catalog_covers_all_originals_and_status_is_valid(self):
        cat = json.loads((BANK / "reports" / "CATALOG.json").read_text())
        originals = [p for p in BANK.glob("round_*/original_webp/**/*") if p.suffix == ".webp"]
        self.assertEqual(cat["total"], len(originals))
        for a in cat["assets"]:
            self.assertIn(a["status"], range(1, 7))
            self.assertTrue((ROOT / a["path"]).exists())
            if a["category"] == "characters":   # no rig grip => never weapon-ready
                self.assertGreaterEqual(a["status"], 3)

    def test_promoted_backdrops_have_provenance_and_stay_small(self):
        out = ROOT / "assets" / "premium" / "presentation" / "backdrops"
        manifest = json.loads((out / "PROVENANCE.json").read_text())
        self.assertEqual({m["chapter"] for m in manifest}, {"ch1", "ch2", "ch3", "ch4"})
        for m in manifest:
            self.assertTrue((out / m["output"]).exists())
            self.assertLess((out / m["output"]).stat().st_size, 600 * 1024)
            src = ROOT / m["source"]
            self.assertEqual(hashlib.sha256(src.read_bytes()).hexdigest(), m["source_sha256"])
            self.assertIn("UNVERIFIED", m["license_status"])

    def test_playground_originals_never_reach_runtime_wholesale(self):
        runtime = [p for p in (ROOT / "assets").rglob("*") if "playground" in p.name.lower()]
        self.assertEqual(runtime, [])


if __name__ == "__main__":
    unittest.main()
