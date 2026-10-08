# Runtime Premium art

Only **curated runtime derivatives** go here. Raw KayKit/Quaternius source models stay under `asset_bank/vendor/` and are ignored by Godot.

Expected structure:

```
assets/premium/
  characters/<id>/{idle,walk,aim,hurt,death,...}.png
  enemies/<id>/...
  bosses/<id>/...
  dungeon/<chapter>/...
  props/<chapter>/...
```

Playable profiles must satisfy `docs/PREMIUM_ASSET_REBUILD.md` and set `weapon_compatible=true` in `VisualProfiles.CHARACTERS`.

## Generated content (do not edit by hand)
Everything under `characters/`, `enemies/` and `dungeon/` is produced by `tools/premium_pipeline.py` from `tools/premium_render/jobs/*.json`; each folder carries a `manifest.json` with provenance. Re-run the pipeline instead of touching PNGs.
