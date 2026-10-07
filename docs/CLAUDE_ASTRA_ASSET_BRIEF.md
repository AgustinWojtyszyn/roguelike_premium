# Claude + Astra brief — Premium asset rebuild

Work only on branch `chore/premium-asset-rebuild-20261007`.

## Non-negotiable
RPG Premium remains a 2D Godot game at runtime. Use 3D CC0 packs as **source material** and pre-render/convert them; do not convert the game to 3D and do not add a 3D renderer per actor at runtime.

The previous player assets are intentionally archived because they cannot hold weapons convincingly. Do not restore them. Do not restore the procedural polygon player.

## Claude — engineering pass
- Audit the pinned source banks under `asset_bank/vendor/`.
- Build a reproducible source-3D -> 2D sprite pipeline (Blender headless is preferred; if unavailable, provide a deterministic alternative tool path).
- Export one ranged hero and one melee hero first.
- Export 8 directions where possible.
- Capture/derive right-hand grip metadata from the source rig; write it into a generated manifest instead of hand-tuning arbitrary offsets.
- Map idle/walk-or-run/hurt/death plus ranged hold/aim or melee attack.
- Keep weapon rendering, muzzle logic and combat mechanics owned by Premium.
- Add tests that reject a playable profile lacking `weapon_compatible=true`, grip metadata, locomotion, hurt and death.
- Curate one dungeon room using KayKit/Quaternius source pieces while keeping Premium collision/RoomBake.
- No broad gameplay rewrite.

## Astra — art/game-feel pass
After Claude's vertical slice works:
- normalize camera angle, character scale, outline, light direction, palette and shadow across all converted sources;
- make the room dense/readable like a premium mobile roguelite, not an asset-store demo;
- tune VFX hierarchy so enemies/loot/projectiles remain readable;
- reject assets that look generic or clash even if technically usable;
- profile draw calls, texture memory and frame pacing; preserve 60 FPS target.

## Definition of done for the slice
A character visibly holds the equipped weapon in every supported direction; muzzle originates at the visual barrel; no detached/floating hand; no procedural polygon body; movement/aiming do not snap badly; room is compact and visually dense; automated tests pass.
