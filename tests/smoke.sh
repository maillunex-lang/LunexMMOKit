#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot --headless --path client --editor --import --quit
godot --headless --path client --quit-after 3
python3 -m json.tool shared/zone.schema.json >/dev/null
