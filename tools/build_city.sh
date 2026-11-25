#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
ROOT=client/project.godot
BACKUP=$(mktemp)
cp "$ROOT" "$BACKUP"
trap 'cp "$BACKUP" "$ROOT"; rm -f "$BACKUP"' EXIT
# Point main scene at WORLD-DESIGN-002 Eternity Capital play for this export only.
MAIN='res://world/locations/eternity_capital/eternity_play.tscn'
if grep -q '^run/main_scene=' "$ROOT"; then
  sed -i "s|^run/main_scene=.*|run/main_scene=\"$MAIN\"|" "$ROOT"
else
  printf '\nrun/main_scene="%s"\n' "$MAIN" >> "$ROOT"
fi
test -f client/world/locations/eternity_capital/eternity_capital.tscn
test -f client/world/locations/eternity_capital/eternity_play.tscn
godot --headless --path client --editor --quit || true
godot --headless --path client --export-debug "Android City" ../build/LunexCityPreview.apk
sha256sum build/LunexCityPreview.apk | tee build/LunexCityPreview.apk.sha256
jarsigner -verify build/LunexCityPreview.apk || true
