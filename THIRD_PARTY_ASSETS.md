# Third-party asset provenance

Only assets with commercial-compatible terms may enter RPG Premium. Source packs live under `asset_bank/` (Godot-ignored); only curated derivatives belong in runtime `assets/`.

| Source | Pinned revision | License | Intended use |
|---|---|---|---|
| KayKit Adventurers 1.0 | 672074b73ba276876a19e8816ecdc5241817ab47 | CC0 1.0 | playable-character source rigs, hand/weapon poses, accessories, animations |
| KayKit Skeletons 1.0 | 15b62b9bad122f72926c10fb14d622c73819fa54 | CC0 1.0 | enemies, elite variants, weapon-ready humanoids |
| KayKit Dungeon Remastered 1.0 | b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07 | CC0 1.0 | dungeon kitbashing, props, walls, traps, chests |
| Quaternius FreeModels mirror | db3df04d1e4714298a09510b26fb6de6645138a2 | CC0 1.0 per mirrored packs | monsters, mechs, sci-fi/fantasy environment, animation sources |

Official KayKit repositories:
- https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0
- https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0
- https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0

Quaternius creator/source: https://quaternius.com/
Pinned mirror used for reproducible sparse acquisition: https://github.com/agentkaerf/FreeModels

## Shipping rule
A third-party asset may enter `assets/premium/` only when its manifest records: source pack, source revision, license, transformation, runtime path, and whether it is player/enemy/environment. Playable characters additionally require a weapon-compatible hand pose/socket contract.
