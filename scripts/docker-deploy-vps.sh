#!/bin/sh
# VPS / Dokploy host: pull pre-built images and start. NO BUILD.
set -e

cd "$(dirname "$0")/.."

IMAGE_TAG="${IMAGE_TAG:-latest}"
export IMAGE_TAG

COMPOSE="docker compose -f docker-compose.yml"

echo "==> Pull-only deploy (IMAGE_TAG=$IMAGE_TAG)"
echo "    Dokploy should do the same: pull + up (never build)."
echo

docker builder prune -f >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true

if [ -r /proc/meminfo ]; then
  awk '/MemAvailable/ {printf "    MemAvailable: %.0f MB\n", $2/1024}' /proc/meminfo
fi

if [ -n "${GHCR_TOKEN:-}" ] && [ -n "${GHCR_USER:-}" ]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

$COMPOSE pull
$COMPOSE up -d --remove-orphans --no-build

echo
$COMPOSE ps
echo
echo "Guide: docs/deploy-dokploy.md"
