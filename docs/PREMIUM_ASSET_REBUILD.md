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
