#!/bin/sh
# Deploy on ~4GB VPS WITHOUT building (pull pre-built GHCR images).
# Requires images published by .github/workflows/docker-publish.yml
set -e

cd "$(dirname "$0")/.."

IMAGE_TAG="${IMAGE_TAG:-latest}"
export IMAGE_TAG

COMPOSE="docker compose -f docker-compose.yml -f docker-compose.prod.yml"

echo "==> VPS pull-only deploy (IMAGE_TAG=$IMAGE_TAG)"
echo "    This does NOT build on the VPS."
echo

# Free disk/memory pressure from old build cache (safe; does not remove running images in use)
echo "==> Pruning unused build cache (best-effort)..."
docker builder prune -f >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true

if [ -r /proc/meminfo ]; then
  awk '/MemAvailable/ {printf "    MemAvailable before pull: %.0f MB\n", $2/1024}' /proc/meminfo
fi

echo "==> Logging into GHCR (optional if packages are public)..."
if [ -n "${GHCR_TOKEN:-}" ] && [ -n "${GHCR_USER:-}" ]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

echo "==> Pulling images..."
$COMPOSE pull

if [ -r /proc/meminfo ]; then
  awk '/MemAvailable/ {printf "    MemAvailable after pull: %.0f MB\n", $2/1024}' /proc/meminfo
fi

echo "==> Starting stack..."
$COMPOSE up -d --remove-orphans --no-build

echo
echo "==> Done. Status:"
$COMPOSE ps
echo
echo "Tip: never run 'docker compose build' / bake on this VPS."
echo "     Images are built on GitHub Actions → ghcr.io/daniel-huudek/church-app/*"
