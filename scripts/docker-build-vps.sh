#!/bin/sh
# Serial, low-RAM Docker builds for ~4GB VPS / Dokploy.
# Builds ONE service at a time to avoid OOM / system freeze.
set -e

cd "$(dirname "$0")/.."

export DOCKER_BUILDKIT=1
# Do NOT enable COMPOSE_BAKE — it parallelizes and OOMs small VPS.
unset COMPOSE_BAKE || true

SERVICES="${*:-api-gateway auth-service member-service schedule-service event-service notification-service prayer-service financial-service worship-service chat-service}"

echo "==> VPS serial build (parallel=1)"
echo "    Services: $SERVICES"
echo

for svc in $SERVICES; do
  echo "────────────────────────────────────────"
  echo "==> Building: $svc"
  # Show free memory when available (Linux VPS)
  if [ -r /proc/meminfo ]; then
    awk '/MemAvailable/ {printf "    MemAvailable: %.0f MB\n", $2/1024}' /proc/meminfo
  fi
  docker compose build --parallel 1 "$svc"
  echo "==> Done: $svc"
  # Drop dangling intermediate layers between services
  docker image prune -f >/dev/null 2>&1 || true
done

echo
echo "==> All requested images built."
echo "    Start with: docker compose up -d"
