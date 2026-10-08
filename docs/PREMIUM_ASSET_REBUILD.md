# RPG Premium — visual rebuild gate

## Decision
The legacy playable sprites imported from Rpg_new are **not acceptable as shipping player art**. They provide only idle/walk/hurt/death, lack a real weapon-holding/aiming pose, and require per-direction hand/weapon hacks. They were removed from the current runtime tree; `asset_bank/legacy_playables/README.md` documents the decision and Git history retains the old blobs. They must not return to runtime.

The old polygon/procedural playable-character renderer is also considered legacy. Runtime player presentation must become sprite-only (or pre-rendered sprite-only) with a temporary missing-art placeholder during migration.

## Source strategy
1. KayKit Adventurers: primary player rig/animation reference.
2. KayKit Skeletons + Quaternius animated creatures/mechs: enemies and elites.
3. KayKit Dungeon + Quaternius fantasy/sci-fi kits: room construction and prop source.
4. Existing Premium weapons/VFX/content stay unless a replacement is demonstrably better.

## Playable acceptance contract
A playable asset is rejected unless it has:
- a real hand/weapon-ready pose or rig socket; no fake detached hand glued over a neutral walk sprite;
- >=4 directions, target 8 directions;
- idle, locomotion, hurt and death;
- ranged hold/aim support for firearm characters;
- melee attack support for melee characters;
- consistent feet origin, silhouette height and camera angle;
- deterministic grip/muzzle metadata per direction (prefer generated from the source hand bone);
- no weapon baked into the body unless the character is permanently locked to that weapon;
- readable silhouette at Android gameplay scale.

Target pre-render: 192-256 px source frame, orthographic 3/4 camera, transparent PNG, consistent lighting/outlines. Runtime remains 2D.

## Dungeon acceptance contract
Do not import whole demo scenes blindly. Curate modules/props into chapter-specific sets. Static floor/wall/decor should continue to use RoomBake. Collision/gameplay geometry stays owned by RPG Premium.

## What stays
Keep current Premium gameplay logic, weapon behaviors, input, pooling, RoomBake, enemies' logical roles, progression, modes, tests, VFX that pass visual review, and useful Rpg_new/VIDA props/weapons/enemies.

## What goes
- active Rpg_new playable sprite sheets and their recolored clones;
- procedural polygon player renderer;
- duplicate/raw generations in runtime folders;
- any playable sprite that cannot convincingly hold the currently equipped weapon;
- any third-party asset without provenance/license metadata.

## Vertical slice before mass conversion
Do not convert 11 heroes at once. First prove:
- 1 ranged hero;
- 1 melee hero;
- 1 skeleton enemy;
- 1 non-humanoid monster;
- 1 compact dungeon room with 15-25 curated props;
- 60 FPS target on Android unchanged.

Only after the slice passes visual + performance review should the pipeline batch the rest.

## Validation baseline — 2026-10-07
Commit `977f62e268c74cb206c020294d6e824fdfd3c760` passed the repository's Godot 4.7.2 import, headless smoke runs, full GDScript/Python validation suite, and Android APK export in GitHub Actions. The Android emulator cold-start stage still fails on SwiftShader/Vulkan presentation (`VkResult error 5`); the same stage is already failing on the current `main` commit `0bb8aa00c345636a921f1b694eb329bc287f507c`, so it is not a regression introduced by this asset-rebuild branch.

## Vertical slice pipeline — Claude engineering pass (2026-10-07)

### Reproduce
```bash
tools/bootstrap_premium_asset_sources.sh                       # pinned source bank (asset_bank/vendor, git-ignored by Godot)
python3 tools/premium_pipeline.py build vesper sable skeleton_warrior crab castle_set   # render + pack + manifest
godot --headless --path . --import                              # import the new PNGs
python3 tools/check_premium_art.py && godot --headless --path . --script tests/run_tests.gd
```
Blender is **not** required (and was not available): Godot itself is the deterministic 3D->2D renderer (`tools/premium_render/render_rig.gd` for rigs, `render_static.gd` for props/floor/walls) and needs a GL driver (`--rendering-driver opengl3`, works on WSLg). The only input of a build is `tools/premium_render/jobs/<id>.json` + the pinned source revision.

### How a hero holds a weapon (no anchors, no floating hands)
1. The render script poses the *source rig*: legs/hips from a locomotion clip, torso/arms from a weapon-ready clip (`1H_Ranged_Aiming`, or the first frame of the 1H slice for melee). Bone-masked blend, sampled directly from the clips' tracks.
2. For **every frame of every direction** it reads the socket bone `handslot.r`, projects it with the render camera and writes `[gx, gy, axis_deg, off_hand_x, off_hand_y, behind]` (px relative to the feet) into the manifest. Nothing is hand-tuned.
3. Runtime (`CharacterRig`, `grip_mode: "rig"`): the weapon pivot is placed on that grip each frame; `weapon_mode: aim` rotates the weapon with the continuous aim angle around the hand, `weapon_mode: rig` (melee attack, death) follows the rig's own blade axis. A small **hand patch** (the fist pixels, cut from the same render with a bone-proximity mask) is drawn on top of the weapon so the fingers wrap the grip.
4. Muzzle is still `WeaponData.muzzle` from the grip; the Premium weapon art is already scaled so its tip == muzzle, hence muzzle == visual barrel tip for any weapon (asserted in `tests/test_premium_slice.gd`).

### Gate (automated)
`tools/check_premium_art.py` + `tests/test_premium_pipeline.py` (static, manifest-level) and `tests/test_premium_slice.gd` (runtime): weapon_compatible, grip metadata for every frame, idle/walk/hurt/death, 8 directions, melee->attack / ranged->aim pose, grip lands on opaque body pixels in every frame, pivot==grip and muzzle distance in 8 aim directions, provenance for every static piece, and synthetic bad profiles are rejected. The pipeline also refuses to emit any frame/piece clipped by the cell border.

### Art pass
See `docs/PREMIUM_ART_DIRECTION.md` (look, weapons, depth, two-handed IK, benchmark room, quality sheet). Hero sets now ship the east side only (west mirrored at runtime).

### Known limits before mass conversion
See the hand-off report in the PR/commit message; short list: two-handed weapons (off-hand `grip_l` is exported but unused), weapon art is still the legacy pixel/vector art (style clash to be resolved in the Astra pass), texture memory/VRAM compression, outline/palette normalisation, behind-torso weapon layering (`weapon_behind`, off by default for readability).
