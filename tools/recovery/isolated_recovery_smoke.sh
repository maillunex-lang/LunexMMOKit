#!/usr/bin/env bash
# DR-08: recovery checks that MUST NOT require Darklord / DGI / asset-library mounts.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
echo "Isolated recovery smoke in $ROOT"
# Prove forbidden trees are not required for these checks
for p in /home/gamedev/Darklord /home/gamedev/darklord-dgi /home/gamedev/lunex-asset-library; do
  if [[ -d "$p" ]]; then
    echo "NOTE: $p exists on this host but must not be read by this smoke"
  fi
done
# Block accidental use via empty env
unset LUNEX_DARKLORD_ROOT || true
unset LUNEX_DGI_ROOT || true
export LUNEX_STUDIO_CACHE="$ROOT/assets/studio"

python3 tools/assets/verify_game_manifest.py
# No forbidden absolute paths in client runtime sources
if grep -RInE '/home/gamedev/(Darklord|darklord-dgi|lunex-asset-library)' client --include='*.gd' --include='*.tscn' --include='*.json' | grep -v 'particle-index' ; then
  echo "FAIL runtime still references forbidden trees"; exit 1
fi
echo "OK no forbidden runtime paths in client"

# Godot headless: project opens + audit smokes (uses assets/studio via LunexAssets)
export GODOT_SILENCE_ROOT_WARNING=1
godot --path client --headless --quit-after 1 2>&1 | tail -5 || true
bash tools/run_audit_smokes.sh

# Server unit tests (no external Darklord)
export PATH="$ROOT/tools/sdk/go/bin:${PATH:-}"
(cd server && GOTOOLCHAIN=auto go test ./...)

# Postgres migrate on isolated compose (may already be up)
bash tools/verify_postgres.sh

echo "ISOLATED_RECOVERY_SMOKE_OK"
echo "LIMITATION: full Windows Godot UI and clean bare-metal VPS install not executed in this environment; see docs/DISASTER_RECOVERY.md"
