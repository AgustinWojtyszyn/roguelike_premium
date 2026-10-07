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
