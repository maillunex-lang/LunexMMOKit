#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export GODOT_SILENCE_ROOT_WARNING=1
GODOT="${GODOT:-godot}"
cd "$ROOT"
echo "== integration_audit_smoke =="
"$GODOT" --path client --headless --script res://tests/integration_audit_smoke.gd
echo "== validator_smoke =="
"$GODOT" --path client --headless --script res://tests/validator_smoke.gd
echo "== nav_obstacle_smoke =="
"$GODOT" --path client --headless --script res://tests/nav_obstacle_smoke.gd
echo "== session_loop_smoke =="
"$GODOT" --path client --headless --script res://tests/session_loop_smoke.gd
echo "== a01_hero_smoke =="
"$GODOT" --path client --headless --script res://tests/a01_hero_smoke.gd
echo "== char_attachment_smoke =="
"$GODOT" --path client --headless --script res://tests/char_attachment_smoke.gd
echo "== char_mount_pet_smoke =="
"$GODOT" --path client --headless --script res://tests/char_mount_pet_smoke.gd
echo "== edit01_attachment_editor_smoke =="
"$GODOT" --path client --headless --script res://tests/edit01_attachment_editor_smoke.gd
echo "== d03_studio_import_smoke =="
"$GODOT" --path client --headless --script res://tests/d03_studio_import_smoke.gd
echo "== char06_costume_smoke =="
"$GODOT" --path client --headless --script res://tests/char06_costume_smoke.gd
echo "== char07_hit_time_smoke =="
"$GODOT" --path client --headless --script res://tests/char07_hit_time_smoke.gd
echo "== d04_scene_smoke =="
"$GODOT" --path client --headless --script res://tests/d04_scene_smoke.gd
echo "== d05_vfx_sync_smoke =="
"$GODOT" --path client --headless --script res://tests/d05_vfx_sync_smoke.gd
echo "== a02_attack_director_smoke =="
"$GODOT" --path client --headless --script res://tests/a02_attack_director_smoke.gd
echo "== w01_route_smoke =="
"$GODOT" --path client --headless --script res://tests/w01_route_smoke.gd
echo "== w02_travel_smoke =="
"$GODOT" --path client --headless --script res://tests/w02_travel_smoke.gd
echo "== n02_interp_smoke =="
"$GODOT" --path client --headless --script res://tests/n02_interp_smoke.gd
if command -v go >/dev/null || [[ -x "$ROOT/tools/sdk/go/bin/go" ]]; then
  export PATH="$ROOT/tools/sdk/go/bin:${PATH:-}"
  echo "== go test =="
  (cd server && GOTOOLCHAIN=auto go test ./...)
fi
echo "ALL_AUDIT_SMOKES_OK"
