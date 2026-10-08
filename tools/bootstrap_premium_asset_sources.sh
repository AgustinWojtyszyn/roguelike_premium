#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git submodule update --init --recursive   asset_bank/vendor/kaykit_adventurers   asset_bank/vendor/kaykit_skeletons   asset_bank/vendor/kaykit_dungeon

"$ROOT/tools/fetch_quaternius_sources.sh"

printf '\nPremium source bank ready. Runtime remains unchanged until curated renders are written to assets/premium/.\n'
