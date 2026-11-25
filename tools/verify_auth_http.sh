#!/usr/bin/env bash
# Register/login/character against lunexd on the isolated compose network.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"
PROJ=lunexmmokit
docker compose -p "$PROJ" up -d postgres
for i in $(seq 1 40); do
  if docker compose -p "$PROJ" exec -T postgres pg_isready -U lunex -d lunex >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
# One-shot lunexd on the compose network (no host ports)
CID=$(docker run -d --rm --network lunexmmokit_net \
  -v "$ROOT/server:/src" -w /src \
  -e LUNEX_DATABASE_URL='postgres://lunex:lunex_dev_only@postgres:5432/lunex?sslmode=disable' \
  -e LUNEX_LISTEN='0.0.0.0:18080' \
  golang:1.22-alpine \
  sh -c 'go run ./cmd/lunexd -addr 0.0.0.0:18080')
cleanup() { docker stop "$CID" >/dev/null 2>&1 || true; }
trap cleanup EXIT
# Wait for health
for i in $(seq 1 60); do
  if docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf http://"$CID":18080/health >/dev/null 2>&1; then
    break
  fi
  # resolve by container IP
  IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")
  if docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf "http://$IP:18080/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID")
H=$(docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf "http://$IP:18080/health")
echo "health=$H"
echo "$H" | grep -q '"database":"ok"'
LOGIN="beta$(date +%s)"
REG=$(docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf -X POST "http://$IP:18080/v1/register" \
  -H 'Content-Type: application/json' -d "{\"login\":\"$LOGIN\",\"password\":\"secret12\"}")
echo "register=$REG"
echo "$REG" | grep -q '"ok":true'
TOK=$(docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf -X POST "http://$IP:18080/v1/login" \
  -H 'Content-Type: application/json' -d "{\"login\":\"$LOGIN\",\"password\":\"secret12\"}")
echo "login=$TOK"
TOKEN=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['token'])" "$TOK")
CHAR=$(docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf -X POST "http://$IP:18080/v1/characters" \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"HeroBeta","class_actor_id":"10001"}')
echo "character=$CHAR"
echo "$CHAR" | grep -q '"ok":true'
# Expired/missing token rejected
CODE=$(docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -s -o /dev/null -w '%{http_code}' \
  -X GET "http://$IP:18080/v1/characters" -H 'Authorization: Bearer deadtoken')
test "$CODE" = "401"
echo "AUTH_HTTP_OK"
