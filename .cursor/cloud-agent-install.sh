#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export OMARCHY_PATH="$ROOT"
export PATH="$ROOT/bin:$PATH"

mkdir -p "$HOME/.config/omarchy/plugins"

shopt -s nullglob
for plugin_dir in "$ROOT/config/omarchy/plugins"/*/; do
  plugin_id="$(basename "$plugin_dir")"
  target="$HOME/.config/omarchy/plugins/$plugin_id"
  mkdir -p "$target"
  cp -a "$plugin_dir"/. "$target"/
done
shopt -u nullglob

if [[ -f "$HOME/.config/omarchy/plugins/thelinuxitguy.change-cursor/manifest.json" ]]; then
  omarchy plugin enable thelinuxitguy.change-cursor >/dev/null 2>&1 || true
fi

echo "Synced Omarchy plugins into $HOME/.config/omarchy/plugins"
