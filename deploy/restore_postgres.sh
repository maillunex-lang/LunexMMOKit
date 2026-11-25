#!/usr/bin/env bash
# Restore into an isolated DB (never overwrites without explicit target).
# Usage: LUNEX_RESTORE_FILE=backups/lunex-pg-....sql.gz bash deploy/restore_postgres.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="${LUNEX_RESTORE_FILE:?set LUNEX_RESTORE_FILE}"
PROJ="${LUNEX_COMPOSE_PROJECT:-lunexmmokit}"
DB="${LUNEX_RESTORE_DB:-lunex_restore}"
echo "Restoring $FILE into database $DB on project $PROJ"
if [[ "$FILE" == *.gpg ]]; then
  : "${LUNEX_BACKUP_PASSPHRASE:?passphrase required for .gpg}"
  TMP=$(mktemp)
  gpg --batch --yes --decrypt --passphrase "$LUNEX_BACKUP_PASSPHRASE" -o "$TMP" "$FILE"
  FILE="$TMP"
fi
if [[ "$FILE" == *.gz ]]; then
  CAT=(gzip -dc "$FILE")
else
  CAT=(cat "$FILE")
fi
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$DB';" || true
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d postgres -c "DROP DATABASE IF EXISTS $DB;"
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d postgres -c "CREATE DATABASE $DB OWNER lunex;"
"${CAT[@]}" | docker compose -p "$PROJ" exec -T postgres psql -U lunex -d "$DB"
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d "$DB" -c '\dt'
echo "RESTORE_OK db=$DB"
