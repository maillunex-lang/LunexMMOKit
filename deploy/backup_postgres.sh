#!/usr/bin/env bash
# DR-06: encrypted-capable dump of player DB. Never commit dumps to public GitHub.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJ="${LUNEX_COMPOSE_PROJECT:-lunexmmokit}"
DIR="${LUNEX_BACKUP_DIR:-$ROOT/backups}"
AGE_DAYS="${LUNEX_BACKUP_AGE_DAYS:-14}"
mkdir -p "$DIR"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="$DIR/lunex-pg-$STAMP.sql.gz"
echo "Dumping to $OUT"
if docker compose -p "$PROJ" ps postgres 2>/dev/null | grep -q Up; then
  docker compose -p "$PROJ" exec -T postgres pg_dump -U lunex -d lunex | gzip -c > "$OUT"
elif docker compose -f "$ROOT/deploy/docker-compose.prod.yml" -p "$PROJ" ps postgres 2>/dev/null | grep -q Up; then
  docker compose -f "$ROOT/deploy/docker-compose.prod.yml" -p "$PROJ" exec -T postgres pg_dump -U "${POSTGRES_USER:-lunex}" -d "${POSTGRES_DB:-lunex}" | gzip -c > "$OUT"
else
  echo "No running lunex postgres container for project $PROJ"
  exit 2
fi
sha256sum "$OUT" | tee "$OUT.sha256"
if [[ -n "${LUNEX_BACKUP_PASSPHRASE:-}" ]]; then
  gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$LUNEX_BACKUP_PASSPHRASE" -o "$OUT.gpg" "$OUT"
  rm -f "$OUT"
  sha256sum "$OUT.gpg" | tee "$OUT.gpg.sha256"
  echo "ENCRYPTED $OUT.gpg"
fi
if [[ -n "${LUNEX_BACKUP_RCLONE_REMOTE:-}" ]]; then
  command -v rclone >/dev/null || { echo "rclone missing"; exit 3; }
  rclone copy "$DIR" "$LUNEX_BACKUP_RCLONE_REMOTE" --include "lunex-pg-*"
  echo "REMOTE_SYNC_OK $LUNEX_BACKUP_RCLONE_REMOTE"
fi
find "$DIR" -name 'lunex-pg-*.sql.gz*' -mtime +"$AGE_DAYS" -delete || true
echo "BACKUP_OK"
