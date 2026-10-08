# RPG Premium — art direction (Astra pass, 2026-10-07)

KayKit and Quaternius are **raw material** (geometry, rigs, palette textures). The look below is ours and is applied at render time by `tools/premium_render/style.gd` + `tools/premium_look.py`, identically to heroes, enemies, weapons, props and dungeon pieces.

## The look
- **Dark, readable, saturated accents.** Bodies and environment sit in cool desaturated navy/steel/teal; the eye is pulled by emissive accents only: weapon glow strips and muzzle rings (palette of each weapon), the crimson of Sable/the castle, the pink-red energy blade.
- **Toon lighting, one rig for everything.** 3-band ramp with violet-tinted shadows, warm key light (upper-left, same direction in every render), cold rim light from the back-right, hemisphere ambient, and a height gradient that grounds objects on the floor (darker near y=0). No shadow maps: the in-game contact shadow is the Premium shadow node.
- **Outline.** Dark navy ~1.5 game px for heroes, dark crimson for enemies (instant friend/foe read on a phone), 1.1 px for props, thicker for weapons (they are drawn at ~25 px). Floor and wall modules have no outline. Done in post at 3x supersampling and downscaled, so edges are anti-aliased. Hand patches keep the outline ring so the fist separates from the weapon.
- **Proportions.** Source chibi heads are scaled to 0.82, hands to 1.3 (`bone_scale` in the job) so arms/hands read as holding something at Android scale.
- **Palette ownership.** Per-mesh HSV remaps (`look.mesh_look`, optionally limited to a hue/value window so skin or hair is not tinted with the tunic): Vesper = ink-violet hair, teal tunic, cyan weapon accents; Sable = blue steel, crimson cape, pink-red blade; enemies = crimson hoods/bone/horns, jade creature for the non-humanoid.
- **Weapons are ours.** `tools/premium_render/weapon_models.gd` builds chunky weapons (SMG, pistol, rifle, shotgun, energy blade) from primitives in the same toon material. Tip/foregrip come from the geometry, projected with the render camera.

## Depth and hands
- Only the east side (S, SE, E, NE, N) is rendered; the west is mirrored at runtime so the firing hand is always on the camera side. Weapons that must occlude the head (N-W/N-E) are therefore always drawn in front; only **north** draws the weapon behind the torso (`weapon_behind_dirs` in the profile), where the barrel pokes out beside the head and stays readable.
- Two-handed weapons (every category except pistol/melee) use the `*_2h` pose sets: the free hand is solved by two-bone IK in the renderer to the weapon's foregrip (`grip2`, 0.30 u ahead of the firing hand). One hand patch contains both fists and is drawn over the weapon.

## Room benchmark: `patio_armas` (castle)
1100x600, composed with `decor.composed = true`: no random scatter. Zones: heraldic wall (gold shield, banners, torches), guard table with stools and a warm light pool, supply corner (crates/barrels as real cover), loot corner, central sigil flanked by two monument pillars. Baked low pieces (`authored`), localized lights (`lights`), wall pieces (`wall_items`), all data in `RoomDef.decor`; collision and RoomBake untouched.

## Quality sheet
```bash
godot --path . --rendering-driver opengl3 --resolution 1920x1080 tools/premium_review.tscn -- --page=heroes|weapons|enemies --snap=1.0 --snapdir=/tmp/q --exit=1.8
godot --path . --rendering-driver opengl3 tools/premium_review.tscn -- --char=vesper --state=idle|walk|attack|hurt|death [--weapon=trinca --only=2 --zoom=8]
godot --path . --rendering-driver opengl3 scenes/run.tscn -- --god --fresh --chapter=ch3 --seed=3 --stage=0 --spawn=caballero,ballestero,sabueso --zoom=0.95 --shots=9 --shotdir=/tmp/q --quit=10
```
Red dots on the `weapons` page are the real muzzle (`muzzle_world()`); they must sit on each barrel tip.

## Performance / memory (measured locally, WSLg GL; Android not measured)
- Same scene (ch3, bot, 40 s): draw calls 395 -> 366, primitives 8689 -> 8170, prewarm 486 -> 298 ms. West mirroring removed 3/8 of the hero sheets.
- Raw RGBA8: ~11-13 MB per hero, ~11 MB per humanoid enemy, ~5-7 MB per creature, ~5 MB dungeon+weapons. Union opaque bbox is only 56-73% of the cell: **trimming empty cell area (`premium_pipeline.py pack_asset`, per set `opaque union bbox`) saves 25-45%**, and enabling VRAM compression (ASTC/ETC2) on `assets/premium/**` import presets saves ~4x more. Neither is done yet on purpose (affects all 11 heroes; do it once, in the pipeline).

## Presentation revision — 2026-10-07

The **home no longer displays a combat sprite**. A single offline fortress render provides architectural depth, warm candlelight and a gold focal point. Ivory typography, restrained brass controls and a compact loadout card replace the pedestal, neon rings and duplicate mission/pass/gift panels. All six navigation routes, character/chapter cycling, settings and the mode selector remain accessible. The character card opens the collection.

Vesper is the single new playable benchmark: taller source proportions, smaller head/hands, charcoal hair, slate clothing and burgundy cape. Rig/IK/socket projection and hand masks all see the same transformed source; no hand offsets were introduced. The other ten heroes are not being converted. Sable's existing body stays as the melee acceptance reference. Original weapon models now share a 35° projection and a steel/leather palette.

`patio_armas` retains its cover and collision layout. Larger stone tiles, a burgundy east/west runner, octagonal stone inlay, perimeter trim, soft reflected torch pools and baked directional shadows make the combat center distinct. Destructible props are excluded from baked shadows. All added floor detail is baked by RoomBake; there are no added live lights or gameplay obstacles.

See [the visual review](PREMIUM_PRESENTATION_REVIEW.md) for before/after screenshots, reproduction commands, validation and limits. This revision supersedes the earlier Vesper palette/proportions above; it does not imply that every other hero has been restyled.
