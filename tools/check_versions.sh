#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/tools/sdk/go/bin:${PATH:-}"
echo "Godot: $(godot --version 2>/dev/null || true)"
echo "Go: $(go version 2>/dev/null || true)"
echo "Docker: $(docker --version 2>/dev/null || true)"
test -f "$ROOT/docs/VERSIONS.md"
test -f "$ROOT/client/project.godot"
test -f "$ROOT/client/export_presets.cfg"
# No keystore secrets in export presets
if grep -Eiq 'keystore/password|secret' "$ROOT/client/export_presets.cfg"; then
  echo "FAIL secrets in export_presets.cfg"; exit 1
fi
echo "VERSIONS_CHECK_OK"
