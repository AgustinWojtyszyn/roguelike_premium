# RPG Premium — rebuilding with imported Playground art

**Correct repository**: `AgustinWojtyszyn/roguelike_premium`. **Work branch**: `feat/playground-asset-bank-20261010`.

## Goal

Keep RPG Premium's existing Godot 4.7 **2D mobile/PC** architecture and replace only art that passes a controlled quality review. A new Playground game can provide additional scene and creature assets, but its generated web code is not the target engine.

### Completed in ChatGPT

- Audited the repo, its agent rules, documented sprite-source pipeline, and existing 20-level/4-chapter content.
- Processed uploaded `project-files (1).zip`: 83 WebP-in-`.png` images and 1 MP3, producing authentic PNG candidate files and a provenance manifest.
- Collected 22 user-selected JPG illustrations as **reference-only**.
- Python import checks passed locally. A downloadable candidate asset package is available in the conversation.
- Created this working branch. No gameplay/runtime files touched; `main` remains unchanged.

### Still required before implementation

- Move extracted/converted images into `asset_bank/playground/round_01_drowned_harbor/` using the separate package or local import tool.
- Receive new exported world batch. Import it into `asset_bank/playground/round_02_other_worlds/`.
- Review each image/sprite sheet at real gameplay scale. Decorative tileset compositions are not guaranteed tile atlases.
- Validate orientation, consistent palette, accurate per-frame weapon grip sockets, and animation quality. Reject unqualified playables.
- Record provenance, generated-source terms and output path before promotion to `assets/premium/`.

### Reconstruction order for Claude or Astra

1. Read `AGENTS.md`, `docs/PREMIUM_ASSET_REBUILD.md`, `docs/CLAUDE_ASTRA_ASSET_BRIEF.md` and `docs/PREMIUM_ART_DIRECTION.md`.
2. Inventory and dedupe external candidates vs `assets/premium/` and `assets/migrated/`.
3. Prepare a sprite/tileset gallery and choose one premium benchmark room; do not bulk-wire 83 assets.
4. For playable characters, preserve rig-derived hand/grip and muzzle alignment, and require `weapon_compatible=true`. No hacks, no legacy `Rpg_new` player art, no polygon player fallback.
5. Integrate selected props and environment into one stage without changing physical collision geometry; use RoomBake for static decoration.
6. Visual QA in desktop and Android landscape; ensure responsive controls and 60 FPS frame pacing.
7. Run `python3 tools/check_premium_art.py`, `godot --headless --path . --import`, `godot --headless --path . --script tests/run_tests.gd`, `python3 -m unittest tests.test_premium_pipeline`, and Android build/device checks.
8. Expand chapter by chapter (tech, jade, castle, anomaly) after acceptance, retaining game behavior, saves, modes, and tests.

### Unverified items

Full Godot import/unit tests, APK device installation, performance and legal/commercial licensing of Playground assets have **not** been verified in this ChatGPT session. Do not claim a complete gameplay rebuild yet. Do not merge this staging branch into main until the user approves a tested playable vertical slice.
