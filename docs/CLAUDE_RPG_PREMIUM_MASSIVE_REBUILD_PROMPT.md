# Claude — RPG PREMIUM reconstruction handoff (2026-10-10)

**Only target repository:** `AgustinWojtyszyn/roguelike_premium`.
**Working branch:** `feat/rpg-premium-complete-asset-audit-20261010`. Do not merge to `main` without explicit approval.

## Read in order
1. `AGENTS.md` and `THIRD_PARTY_ASSETS.md`.
2. `docs/RPG_PREMIUM_COMPLETE_AUDIT_20261010.md`.
3. `asset_bank/playground/README.md`, including `reports/FULL_MEDIA_MANIFEST.json` once binary library is installed.
4. `docs/PREMIUM_ASSET_REBUILD.md`, `docs/PREMIUM_ART_DIRECTION.md`, and `docs/CLAUDE_ASTRA_ASSET_BRIEF.md`.
5. `docs/CLAUDE_RPG_PREMIUM_MASSIVE_REBUILD_PROMPT.md` (execution sequence).

## Request for the next session
Reconstruct the visual identity of **RPG PREMIUM**, keeping the existing Godot 4.7 2D game, not porting the Playground web app.

The user provided two complete Playground batches (168 images, 3 audio), 22 hand-picked JPGs, and a partial export to preserve. **Never discard source media**; keep every asset in the quarantine bank regardless of current suitability. The exported package is provided separately in this chat and must be installed locally by running `python3 tools/install_playground_bank.py "<downloaded ZIP>"` from a branch checkout. The full package has true PNG; the compact package has original real WEBP.

Do not claim source media are already uploaded to GitHub if `asset_bank/playground/reports/FULL_MEDIA_MANIFEST.json` is missing. The staging branch currently contains docs/importer, not the heavyweight binaries.

Your engineering task is to catalog, preview, standardize, and **selectively** integrate first an exemplary room with one ranged and one melee character, two enemies, collision, coherent perspective, correct weapon hand grips, and Android 60 FPS as the quality target.

Maintain Premium's characters, 20-level/4-chapter structure, modes, weapons, save data, RoomBake, pooled bullets, audio and input; don't restore old Rpg_new playable sheets. No bulk replacement of all chapters before a validated slice.

Run pre-existing tests and a real Android installation test; GitHub's last emulator run was cancelled waiting for emulator boot. Report actual measurements rather than assuming passes.

After a quality-approved vertical slice, prepare a staged art rollout across the four families: corrupted machinery, jade civilization, dark fortress, dimensional anomalies. Keep original bank archived without deleting or editing it.

**Definition of done for YOUR first pass**: all extracted media present with SHA256 verification, gallery/categorization, licensed provenance notes, one attractive playable room in desktop + Android, tests passing, hand-grip validation, no unnecessary gameplay regressions, and no main merge.
