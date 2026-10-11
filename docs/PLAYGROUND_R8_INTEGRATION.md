# RPG PREMIUM — Playground R8 High Quality Visual Integration

## What is integrated (and what is not)

- **12 independent designs**: 8 ordinary enemies (including two *static-only* images) and 4 bosses.
- **54 genuine imported clips** containing **726 original frames**.
- **36 additional assets** (weapons, VFX, environment) converted into real PNG and registered under `pg/r8/*` for future use. **These are staged references, not live attacks or placed levels.**
- 22 pre-existing AI identifiers: 18 ordinary enemies + 4 bosses. Each uses an R8 sprite profile. **Some AI identifiers share one design**: variants are temporary until more unique drawings exist.
- Preserves real combat mechanics, collision, boss attack patterns, health, damage, weapon energy rules, save states and modes. Presentation only.
- **No new enemy AI or boss patterns are created**, and **boss balance is NOT adjusted**.
- Existing `custodio`, `xocotl`, and `mariscal` bosses now map their actual state constants to animated windup/strike/recovery visuals via `PlaygroundProfiles.boss_phase()`; `vigia` already had explicit animation states. This is animation selection, not a combat mechanic change.

## Caveats to understand before evaluating

- Original Playground R7 export provides one perspective for every sheet. Horizontal mirror remains possible, but genuine 5/8 direction animation **does not exist**. Do not pretend otherwise.
- Spark Drone and Rift Skitter are still images. Death/hurt/movement sequences **do not exist** for those characters. Existing fallback visuals remain available with `--no-playground`.
- Original 512px frames have frequent **irrecoverable edge clipping**. All new sheets normalize their pivot and size but cannot regenerate art clipped in source. `docs/PLAYGROUND_R8_QA.json` reports it per action.
- PNG strips use 160/192/224/288px cells based on tiers, rather than the previous 80–144px. Actual world-space silhouette sizes are controlled independently by profiles so extra texture resolution does not enlarge hitboxes.
- Source licensing is **UNVERIFIED**. Runtime is strictly a private prototype. For commercial publication, verify terms and record a licence clearance decision.
- `asset_bank/` is Godot-ignored. When you provide the original ZIP, the installer copies all **113 real source files** as-is under `asset_bank/playground/round_03_four_families/source_export/`, including files whose `.png` filenames actually contain WebP. Those are historical source bytes, not runtime imports. The original 163MB ZIP itself remains in Downloads to avoid an individual GitHub file over 100MB.

## Test commands in Ubuntu WSL

Stop active AI tasks and tests before applying. Save/commit unrelated in-progress work. Start in the RPG Premium repository root on a non-main feature branch.

```bash
python3 /path/to/extracted/RPG_PREMIUM_PLAYGROUND_R8_QUALITY/apply_r8.py "$PWD" --source '/mnt/c/Users/Usuario/Downloads/project-files (7).zip' --dry-run
python3 /path/to/extracted/RPG_PREMIUM_PLAYGROUND_R8_QUALITY/apply_r8.py "$PWD" --source '/mnt/c/Users/Usuario/Downloads/project-files (7).zip'
godot --headless --path . --import
godot --headless --path . --script tests/test_playground_r8.gd
python3 tools/test_playground_r8.py
python3 tools/check_premium_art.py
bash tools/check_all.sh
godot --path .
# To compare the original visuals (different run):
godot --path . -- --no-playground
```

If you use the full bundle, the `--source` argument is optional; the R7 archive is included in `source/`.

## Checks before Git push

- Stage selectively, never automatically merge `main`.
- Confirm the full original export is preserved (if you used `--source`). The source files inside `asset_bank/` count toward repository size, but none of them exceeds the individual GitHub 100MB file limit. **Do not commit the 163MB source ZIP itself as one Git blob.**
- Validate visually with a real run (including boss appearances, readability of tells, clipped attack animations). Godot import and integrity checks by themselves are not gameplay tests.
- If an AI is editing these modules at the same time, do not apply over its uncommitted work.

## Important detail: early boss difficulty

Changing the robotic boss's appearance does not fix the ~10-minute fight. Separately adjust `custodio` HP, mobility and damage windows with reproducible playtesting; this package intentionally does not change those stats.
