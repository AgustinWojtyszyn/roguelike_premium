# Legacy Asset Bank

Staging library for adapting art from the user's previous projects into `roguelike_premium`.

## Sources pinned for this import

- No Return / `AgustinWojtyszyn/Rpg_new`: `3099f5aaacad2488f9cf2ebbb3c4fbe87c33a433`
- VIDA / `AgustinWojtyszyn/Life--simulador-de-vida`: `5d5192da4b258d36a330ef84f5617269ab9d0530`

## Imported candidate set

No Return: 185 files (~1.4 MB raw)
- generated bank: 183
- decals 6
- enemies 8
- holding 24
- playables 37
- props 64
- tiles 10
- tilesets_2_5d 8
- vfx 16
- weapons 10
- fonts 2 (PixelifySans + OFL license, stored under `asset_bank/source_extras/no_return/fonts/`)

VIDA: 557 files (~14.9 MB raw)
- buildings 63
- catalog 86
- characters 181
- city 20
- environment 4
- houses 18
- interior 25
- oriented 57
- regions 7
- shaders 2
- vehicles 94

Total staged source files: **742**.

The 740 art source files are stored losslessly in JSON bundles under `asset_bank/bundles/`. PixelifySans and its OFL license are stored raw under `asset_bank/source_extras/no_return/fonts/`. `.gdignore` keeps this entire folder out of Godot's resource scan.

## Unpack

```bash
python3 tools/extract_asset_bank.py
```

This writes exact bundled source bytes to:

- `asset_bank/unpacked/no_return/`
- `asset_bank/unpacked/vida/`

The unpacked directory is gitignored and remains under the ignored asset-bank folder. Codex/Claude can inspect, edit and selectively promote assets into the live project.

## Integration rule

Do **not** bulk-wire this bank into gameplay.

Preferred workflow:
1. unpack;
2. choose a candidate;
3. adapt palette/silhouette/scale/animation to the current art direction;
4. copy only the adapted result into a live `assets/adapted/` or equivalent project path;
5. keep hitboxes/gameplay logic independent of sprite size;
6. test PC + Android and preserve 60 FPS.

Recommended first targets:
- No Return: 8-direction playable characters, Bone Guard, weapon art, muzzle flashes, impacts, explosions and projectile trails.
- VIDA: human walk cycles as bases for zombies/mutants/monsters; hospitals/buildings/interiors/city props for story-mode spaces; vehicles and environment props for future scenarios.

The purpose of this bank is an **asset workbench**, not a gameplay dump.


## Estado de la migración (2da fase)

La capa de arte ya esta cableada al juego: ver `docs/ASSET_AUDIT.md` (auditoria, mapeos y cifras) y `tools/migrate_assets.py`
(reproduce todo desde los clones de Rpg_new/VIDA). Lo util que aun no tiene uso en una run vive en `asset_bank/reserve/`
(ignorado por Godot) y se promueve a `assets/migrated/` anadiendolo a `visual/visual_profiles.gd` y volviendo a correr la herramienta.
