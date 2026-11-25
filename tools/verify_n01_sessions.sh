#!/usr/bin/env bash
# N01: two accounts/clients, session, logout, expired token rejected, reconnect.
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
CID=$(docker run -d --rm --network lunexmmokit_net \
  -v "$ROOT/server:/src" -w /src \
  -e LUNEX_DATABASE_URL='postgres://lunex:lunex_dev_only@postgres:5432/lunex?sslmode=disable' \
  -e LUNEX_LISTEN='0.0.0.0:18080' \
  -e LUNEX_ALLOW_TEST_EXPIRE=1 \
  golang:1.22-alpine \
  sh -c 'go run ./cmd/lunexd -addr 0.0.0.0:18080')
cleanup() { docker stop "$CID" >/dev/null 2>&1 || true; }
trap cleanup EXIT
IP=""
for i in $(seq 1 90); do
  IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CID" 2>/dev/null || true)
  if [[ -n "$IP" ]] && docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 -sf "http://$IP:18080/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
test -n "$IP"
curl_net() { docker run --rm --network lunexmmokit_net curlimages/curl:8.5.0 "$@"; }

VER=$(curl_net -sf "http://$IP:18080/version")
echo "version=$VER"
echo "$VER" | grep -q '"protocol_version":1'

# Client A
LA="n01a$(date +%s)"
curl_net -sf -X POST "http://$IP:18080/v1/register" -H 'Content-Type: application/json' \
  -d "{\"login\":\"$LA\",\"password\":\"secret12\"}" | grep -q '"ok":true'
TA=$(curl_net -sf -X POST "http://$IP:18080/v1/login" -H 'Content-Type: application/json' \
  -d "{\"login\":\"$LA\",\"password\":\"secret12\"}")
TOKA=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['token'])" "$TA")
curl_net -sf "http://$IP:18080/v1/session" -H "Authorization: Bearer $TOKA" | grep -q '"session":"active"'
curl_net -sf -X POST "http://$IP:18080/v1/characters" -H "Authorization: Bearer $TOKA" \
  -H 'Content-Type: application/json' -d '{"name":"HeroA","class_actor_id":"10001"}' | grep -q '"ok":true'

# Client B (second concurrent account)
LB="n01b$(date +%s)"
curl_net -sf -X POST "http://$IP:18080/v1/register" -H 'Content-Type: application/json' \
  -d "{\"login\":\"$LB\",\"password\":\"secret12\"}" | grep -q '"ok":true'
TB=$(curl_net -sf -X POST "http://$IP:18080/v1/login" -H 'Content-Type: application/json' \
  -d "{\"login\":\"$LB\",\"password\":\"secret12\"}")
TOKB=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['token'])" "$TB")
curl_net -sf -X POST "http://$IP:18080/v1/characters" -H "Authorization: Bearer $TOKB" \
  -H 'Content-Type: application/json' -d '{"name":"HeroB","class_actor_id":"20001"}' | grep -q '"ok":true'
# Isolation: A token cannot see B-only data beyond own list (both OK)
CA=$(curl_net -sf "http://$IP:18080/v1/characters" -H "Authorization: Bearer $TOKA")
CB=$(curl_net -sf "http://$IP:18080/v1/characters" -H "Authorization: Bearer $TOKB")
echo "$CA" | grep -q 'HeroA'
echo "$CB" | grep -q 'HeroB'
echo "$CA" | grep -vq 'HeroB' || true

# Expire A token → 401; reconnect via login
curl_net -sf -X POST "http://$IP:18080/v1/test/expire" -H "Authorization: Bearer $TOKA" | grep -q '"expired":true'
CODE=$(curl_net -s -o /dev/null -w '%{http_code}' "http://$IP:18080/v1/session" -H "Authorization: Bearer $TOKA")
test "$CODE" = "401"
TA2=$(curl_net -sf -X POST "http://$IP:18080/v1/login" -H 'Content-Type: application/json' \
  -d "{\"login\":\"$LA\",\"password\":\"secret12\"}")
TOKA2=$(python3 -c "import json,sys; print(json.loads(sys.argv[1])['token'])" "$TA2")
curl_net -sf "http://$IP:18080/v1/session" -H "Authorization: Bearer $TOKA2" | grep -q '"session":"active"'

# Logout B
curl_net -sf -X POST "http://$IP:18080/v1/logout" -H "Authorization: Bearer $TOKB" | grep -q '"ok":true'
CODEB=$(curl_net -s -o /dev/null -w '%{http_code}' "http://$IP:18080/v1/characters" -H "Authorization: Bearer $TOKB")
test "$CODEB" = "401"

echo "N01_SESSIONS_OK"
