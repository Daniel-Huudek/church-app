#!/bin/sh
# DEPRECATED for 4GB VPS — building here freezes the machine when ~1.2GB is already used.
# Prefer: ./scripts/docker-deploy-vps.sh  (pull GHCR images built by GitHub Actions)
set -e

cd "$(dirname "$0")/.."

echo "WARNING: Building Docker images on a 4GB VPS will likely freeze the host."
echo "         Prefer pull-only deploy: ./scripts/docker-deploy-vps.sh"
echo
if [ "${FORCE_VPS_BUILD:-}" != "1" ]; then
  echo "Refusing to build. Re-run with FORCE_VPS_BUILD=1 if you really mean it."
  exit 1
fi

export DOCKER_BUILDKIT=1
unset COMPOSE_BAKE || true

SERVICES="${*:-api-gateway auth-service member-service schedule-service event-service notification-service prayer-service financial-service worship-service chat-service}"

echo "==> FORCED serial VPS build (parallel=1)"
echo "    Services: $SERVICES"
echo

for svc in $SERVICES; do
  echo "────────────────────────────────────────"
  echo "==> Building: $svc"
  if [ -r /proc/meminfo ]; then
    awk '/MemAvailable/ {printf "    MemAvailable: %.0f MB\n", $2/1024}' /proc/meminfo
  fi
  docker compose build --parallel 1 "$svc"
  echo "==> Done: $svc"
  docker builder prune -f >/dev/null 2>&1 || true
  docker image prune -f >/dev/null 2>&1 || true
done

echo
echo "==> All requested images built."
echo "    Start with: docker compose up -d"
