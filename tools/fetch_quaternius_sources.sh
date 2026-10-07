#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$ROOT/asset_bank/vendor/quaternius}"
REPO="https://github.com/agentkaerf/FreeModels.git"
PIN="db3df04d1e4714298a09510b26fb6de6645138a2"

PACKS=(
  "Animated Mech Pack - March 2021"
  "Cute Animated Monsters - Aug 2020"
  "Fantasy Props MegaKit[Standard]"
  "Medieval Village MegaKit[Standard]"
  "Modular Character Outfits - Fantasy[Standard]"
  "Modular SciFi MegaKit[Standard]"
  "Sci-Fi Essentials Kit[Standard]"
  "Ultimate Animated Animals - July 2021"
  "Ultimate Modular Men- Feb 2022"
  "Ultimate Modular Women - April 2022"
  "Ultimate Space Kit - March 2023"
  "Universal Animation Library 2[Standard]"
  "Zombie Apocalypse Kit - March 2024"
)

rm -rf "$DEST"
mkdir -p "$DEST"
git -C "$DEST" init -q
git -C "$DEST" remote add origin "$REPO"
git -C "$DEST" config core.sparseCheckout true
git -C "$DEST" sparse-checkout init --cone
git -C "$DEST" sparse-checkout set "${PACKS[@]}"
git -C "$DEST" fetch --depth 1 origin "$PIN"
git -C "$DEST" checkout --detach FETCH_HEAD
printf '\nFetched pinned Quaternius source bank at %s\n' "$PIN"
printf 'Source-only directory: %s\n' "$DEST"
