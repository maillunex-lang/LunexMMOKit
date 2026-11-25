#!/usr/bin/env bash
# F04: verify isolated lunexmmokit Postgres migrations without touching other VPS DBs.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"
PROJ=lunexmmokit
echo "Starting $PROJ postgres (no host ports)..."
docker compose -p "$PROJ" up -d postgres
echo "Waiting healthy..."
for i in $(seq 1 30); do
  if docker compose -p "$PROJ" exec -T postgres pg_isready -U lunex -d lunex >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
docker compose -p "$PROJ" exec -T postgres pg_isready -U lunex -d lunex
echo "Tables:"
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d lunex -c '\dt'
docker compose -p "$PROJ" exec -T postgres psql -U lunex -d lunex -c "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY 1;"
# Ensure required tables exist
for t in accounts characters schema_migrations; do
  docker compose -p "$PROJ" exec -T postgres psql -U lunex -d lunex -Atc "SELECT to_regclass('public.$t');" | grep -q "$t"
  echo "OK table $t"
done
echo "POSTGRES_MIGRATE_OK"
