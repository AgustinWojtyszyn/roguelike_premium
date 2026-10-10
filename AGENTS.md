# RPG Premium — agent rules

Read these before changing anything:
1. `docs/PREMIUM_ASSET_REBUILD.md`
2. `docs/CLAUDE_ASTRA_ASSET_BRIEF.md`
3. `THIRD_PARTY_ASSETS.md`

## Hard rules
- Runtime remains Godot 4.7 2D, mobile-first.
- Do not restore the old Rpg_new playable sprites.
- Do not add a procedural/polygon playable-character renderer.
- A playable asset cannot enter `VisualProfiles.CHARACTERS` unless it is genuinely weapon-compatible and sets `"weapon_compatible": true`.
- Grip/weapon metadata should come from the source rig/hand bone or a reproducible render pipeline, not arbitrary visual nudging.
- Source 3D packs belong in `asset_bank/vendor/`; runtime derivatives belong in `assets/premium/`.
- Keep Premium gameplay logic, weapon behavior, pooling, RoomBake, progression and Android controls unless a narrowly scoped change is required.
- Prefer a vertical slice over mass conversion.
- Run `python3 tools/check_premium_art.py` and the existing Godot tests before considering work finished.
- Do not merge to main automatically.

## Current target
Prove one ranged hero, one melee hero, one humanoid enemy, one non-humanoid enemy and one compact premium dungeon room. Preserve the 60 FPS Android target.

## Current 2026-10-10 asset-bank assignment
Read `docs/RPG_PREMIUM_COMPLETE_AUDIT_20261010.md` and `docs/CLAUDE_RPG_PREMIUM_MASSIVE_REBUILD_PROMPT.md` before using any Playground source asset. All source files must be preserved in `asset_bank/playground/` but must not be bulk-wired into runtime. Continue on branch `feat/rpg-premium-complete-asset-audit-20261010`; do not merge automatically.
