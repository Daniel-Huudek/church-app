#!/bin/bash
# Dev launcher for the church-app backend (9 microservices + API gateway) in
# TypeScript dev mode (tsx), against a local PostgreSQL on localhost:5432.
#
# Why this script exists (non-obvious constraints):
#  1. No service loads dotenv — they read process.env directly. So `pnpm dev`
#     (parallel) at the root cannot give each service its own DATABASE_URL.
#  2. All services share ONE hoisted @prisma/client (pnpm). `prisma generate`
#     overwrites the same files, so each service's client must be generated
#     immediately before that service starts, and the process must load it
#     (we use plain `tsx`, NOT `tsx watch`, so a later generate can't hot-reload
#     a running service into the wrong client).
#
# Prereqs (see AGENTS.md): postgres running, role church/church123, the 9 DBs
# created, and `prisma db push` applied per service.
set -u
cd "$(dirname "$0")/.."

export JWT_SECRET="${JWT_SECRET:-dev-secret-church-app}"
export JWT_EXPIRES_IN="15m"
export JWT_REFRESH_EXPIRES_IN="7d"
export CORS_ORIGIN="http://localhost:5173,http://localhost:3000,http://localhost:8085"
export NODE_ENV="development"

LOGDIR="${LOGDIR:-/tmp/logs}"
mkdir -p "$LOGDIR"
PGBASE="postgresql://church:church123@localhost:5432"

SERVICES=(
  "auth-service:3001:auth_db"
  "member-service:3006:member_db"
  "schedule-service:3003:schedule_db"
  "event-service:3004:event_db"
  "notification-service:3005:notification_db"
  "prayer-service:3007:prayer_db"
  "financial-service:3008:financial_db"
  "worship-service:3010:worship_db"
  "chat-service:3002:chat_db"
)

wait_health() {
  local port=$1 name=$2
  for _ in $(seq 1 30); do
    curl -sf "http://localhost:$port/health" >/dev/null 2>&1 && { echo "  [OK] $name:$port"; return 0; }
    sleep 1
  done
  echo "  [FAIL] $name did not become healthy on $port"; return 1
}

for entry in "${SERVICES[@]}"; do
  IFS=":" read -r svc port db <<< "$entry"
  echo "=== $svc (port $port, db $db) ==="
  ( cd "apps/$svc" && npx prisma generate >/dev/null 2>&1 )
  ( cd "apps/$svc" && \
    DATABASE_URL="$PGBASE/$db" PORT="$port" \
    EVOLUTION_API_URL="http://localhost:8080" EVOLUTION_API_KEY="dev" YOUTUBE_API_KEY="" \
    nohup npx tsx src/index.ts > "$LOGDIR/$svc.log" 2>&1 & echo $! > "$LOGDIR/$svc.pid" )
  wait_health "$port" "$svc"
done

echo "=== api-gateway (port 3030) ==="
( cd apps/api-gateway && PORT=3030 \
  AUTH_SERVICE_URL="http://localhost:3001" MEMBER_SERVICE_URL="http://localhost:3006" \
  SCHEDULE_SERVICE_URL="http://localhost:3003" EVENT_SERVICE_URL="http://localhost:3004" \
  NOTIFICATION_SERVICE_URL="http://localhost:3005" PRAYER_SERVICE_URL="http://localhost:3007" \
  FINANCIAL_SERVICE_URL="http://localhost:3008" WORSHIP_SERVICE_URL="http://localhost:3010" \
  CHAT_SERVICE_URL="http://localhost:3002" \
  nohup npx tsx src/index.ts > "$LOGDIR/api-gateway.log" 2>&1 & echo $! > "$LOGDIR/api-gateway.pid" )
wait_health 3030 "api-gateway"

echo "=== backend up (logs in $LOGDIR) ==="
