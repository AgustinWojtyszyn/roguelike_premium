# Premium asset source bank

This directory is ignored by Godot through `asset_bank/.gdignore`. It contains **source material only**. Runtime art must be curated/rendered into `assets/premium/`; never point game code at files in this folder.

## Pinned official KayKit sources (CC0)
- Adventurers 1.0 — commit `672074b73ba276876a19e8816ecdc5241817ab47`
- Skeletons 1.0 — commit `15b62b9bad122f72926c10fb14d622c73819fa54`
- Dungeon Remastered 1.0 — commit `b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07`

Initialize them with:

```bash
git submodule update --init --recursive
```

## Quaternius source bank (CC0)
Run `tools/fetch_quaternius_sources.sh`. It sparse-checks only the packs relevant to RPG Premium from a pinned public mirror; the official creator/source and CC0 provenance remain documented in `THIRD_PARTY_ASSETS.md`.

Do not ship the raw 3D source bank in Android exports. The intended pipeline is source 3D -> curated/pre-rendered 2D sprite sheets -> `assets/premium/`.
