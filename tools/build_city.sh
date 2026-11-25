#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
ROOT=client/project.godot
BACKUP=$(mktemp)
cp "$ROOT" "$BACKUP"
trap 'cp "$BACKUP" "$ROOT"; rm -f "$BACKUP"' EXIT
# Point main scene at capital play for this export only.
if grep -q '^run/main_scene=' "$ROOT"; then
  sed -i 's|^run/main_scene=.*|run/main_scene="res://world/capital_play.tscn"|' "$ROOT"
else
  printf '\nrun/main_scene="res://world/capital_play.tscn"\n' >> "$ROOT"
fi
test -f client/world/imported/capital_geometry_v8.tscn
godot --headless --path client --editor --quit || true
godot --headless --path client --export-debug "Android City" ../build/LunexCityPreview.apk
sha256sum build/LunexCityPreview.apk | tee build/LunexCityPreview.apk.sha256
jarsigner -verify build/LunexCityPreview.apk
