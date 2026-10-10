# RPG Premium — Google Playground staging

Resources from Playground are **source candidates**, not runtime assets. Keep this folder under the existing `asset_bank/.gdignore` so Godot does not index unapproved bulk material.

## First captured batch (2026-10-10)

- Source: user-owned `project-files (1).zip` (provided in ChatGPT).
- 83 valid images internally encoded as WebP despite a `.png` filename.
- 1 MP3.
- 22 individually selected JPG screenshots/illustrations (reference only; some overlap with export).
- Local import verified: 84 export resources; formats and file signatures pass.
- Actual media files are **not yet uploaded to GitHub**. The staged package is provided separately to the project owner.

Run `python3 tools/import_playground_assets.py '/path/to/project-files (1).zip'` after installing Pillow. This generates true PNG files, retains alpha when present, and records a manifest.

## Safe integration

- Keep the original ZIP archived separately.
- Keep original/converted resources separate from `assets/premium/`.
- Deduplicate against current Premium assets before promoting.
- Character spritesheets are NOT weapon-ready just because frames exist: enforce `AGENTS.md` and `docs/PREMIUM_ASSET_REBUILD.md`.
- Validate source terms for commercial rights, including any music.
- Current first vertical slice: 1 ranged hero, 1 melee hero, 1 skeleton, 1 creature, 1 compact room.
- Keep game mechanics, hitboxes, pooling, RoomBake, profile/save, and Android controls unchanged until the slice passes.

Second batch should cover RPG Premium's four chapter families: corrupted machines, jade civilization, dark fortress, interdimensional anomalies.

See `docs/PLAYGROUND_REBUILD_HANDOFF.md` for the safe workflow.
