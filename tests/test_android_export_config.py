"""Android export contracts: prevent packaging regressions before signing/upload."""
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
PKG = "com.agustin.rpgpremium"


def contents(path):
    return (ROOT / path).read_text(encoding="utf-8")


class AndroidExportContracts(unittest.TestCase):
    def test_package_identifier_is_unambiguous(self):
        presets = contents("export_presets.cfg")
        self.assertIn(f'package/unique_name="{PKG}"', presets)
        self.assertIn(f"PACKAGE = '{PKG}'", contents("tools/android_cold_start.py"))

    def test_arm64_and_launcher(self):
        presets = contents("export_presets.cfg")
        self.assertIn('architectures/arm64-v8a=true', presets)
        self.assertIn('name="Android"', presets)
        self.assertIn('run/main_scene="res://scenes/home.tscn"', contents("project.godot"))

    def test_mobile_uses_safe_rendering(self):
        project = contents("project.godot")
        self.assertIn('renderer/rendering_method.mobile="gl_compatibility"', project)
        self.assertIn('renderer/rendering_method="gl_compatibility"', project)
        self.assertIn("screen/immersive_mode=false", contents("export_presets.cfg"))

    def test_apk_validation_is_not_just_export_success(self):
        ci = contents(".github/workflows/android-build.yml")
        for requirement in ("apksigner", "aapt", "zipalign", "adb install", "android_cold_start.py"):
            self.assertIn(requirement, ci)
        self.assertLess(ci.index("Verify Android package and signing"), ci.index("Upload APK"))


if __name__ == "__main__":
    unittest.main()
