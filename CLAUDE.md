# Claude Code instructions

Follow `AGENTS.md` and execute the **Claude — engineering pass** in `docs/CLAUDE_ASTRA_ASSET_BRIEF.md`.

Start by bootstrapping the source bank with `tools/bootstrap_premium_asset_sources.sh`, inventory the animation/rig names, and build the deterministic 3D-source -> 2D-sprite pipeline. Do not mass-convert until the ranged + melee vertical slice passes the quality gate.

Do not restore legacy playables or procedural player polygons. Do not merge to main.
