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
if command -v go >/dev/null || [[ -x "$ROOT/tools/sdk/go/bin/go" ]]; then
  export PATH="$ROOT/tools/sdk/go/bin:${PATH:-}"
  echo "== go test =="
  (cd server && GOTOOLCHAIN=auto go test ./...)
fi
echo "ALL_AUDIT_SMOKES_OK"
