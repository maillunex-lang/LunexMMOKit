#!/usr/bin/env bash
# DISASTER-RECOVERY-001 DR-05: bootstrap LunexMMOKit on a clean Ubuntu VPS.
# Usage (on NEW server, after git clone):
#   cp deploy/env.example /etc/lunex/lunex.env  # edit secrets
#   sudo bash deploy/install_vps.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "== LunexMMOKit VPS install =="
echo "ROOT=$ROOT"
command -v docker >/dev/null || { echo "Install Docker first"; exit 1; }
command -v docker compose >/dev/null || { echo "Install Docker Compose plugin"; exit 1; }
mkdir -p /etc/lunex /var/backups/lunex
if [[ ! -f /etc/lunex/lunex.env ]]; then
  echo "Missing /etc/lunex/lunex.env — copy deploy/env.example and set secrets"
  exit 2
fi
# shellcheck disable=SC1091
set -a; source /etc/lunex/lunex.env; set +a
: "${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD in lunex.env}"
cd "$ROOT/deploy"
docker compose -f docker-compose.prod.yml --env-file /etc/lunex/lunex.env up -d --build
echo "Waiting health via compose network..."
sleep 5
docker compose -f docker-compose.prod.yml ps
echo "INSTALL_VPS_OK — configure reverse proxy/TLS for \$LUNEX_DOMAIN separately (see docs/DEPLOY_VPS.md)"
