#!/usr/bin/env bash
# Install ALL the Playground media into quarantined asset_bank and push ONLY that bank.
# Usage: bash tools/stage_and_push_playground_bank.sh ~/Downloads/RPG_PREMIUM_SOURCE_BANK_COMPACT_FOR_REPO.zip
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
EXPECTED="feat/rpg-premium-complete-asset-audit-20261010"
CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" != "$EXPECTED" ]]; then
  echo "ABORT: change to the approved branch $EXPECTED (current=$CURRENT)" >&2
  exit 2
fi
if [[ $# -ne 1 || ! -f "$1" ]]; then
  echo "Usage: bash tools/stage_and_push_playground_bank.sh /path/to/asset-bank.zip" >&2
  exit 2
fi
python3 tools/install_playground_bank.py "$1" --dry-run
python3 tools/install_playground_bank.py "$1"
git add -- asset_bank/playground/
if git diff --cached --quiet -- asset_bank/playground/; then
  echo "All asset bank files are already staged in this Git checkout."
  exit 0
fi
git commit -m "assets: preserve both complete Playground asset batches and references" --only -- asset_bank/playground/
git push --set-upstream origin "$EXPECTED"
echo "Uploaded bank to $EXPECTED. No gameplay scenes or main branch changed."
