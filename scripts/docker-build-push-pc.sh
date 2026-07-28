#!/bin/sh
# Build on PC + push to GHCR. Never run on the 4GB VPS.
set -e

cd "$(dirname "$0")/.."

IMAGE_TAG="${IMAGE_TAG:-latest}"
export IMAGE_TAG
export DOCKER_BUILDKIT=1
unset COMPOSE_BAKE || true

PREFIX="ghcr.io/daniel-huudek/church-app"
COMPOSE="docker compose -f docker-compose.yml -f docker-compose.build.yml"
ALL="api-gateway auth-service member-service schedule-service event-service notification-service prayer-service financial-service worship-service chat-service"
SERVICES="${*:-$ALL}"

if [ -r /proc/meminfo ]; then
  MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
  if [ "$MEM_MB" -lt 5000 ] && [ "${FORCE_VPS_BUILD:-}" != "1" ]; then
    echo "This machine has ~${MEM_MB}MB RAM. Building here will likely freeze it."
    echo "Use GitHub Actions (Docker Publish) or a PC with 8GB+ RAM."
    exit 1
  fi
fi

echo "==> PC build + push (IMAGE_TAG=$IMAGE_TAG)"
echo "    Services: $SERVICES"
echo

if [ -n "${GHCR_TOKEN:-}" ] && [ -n "${GHCR_USER:-}" ]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
fi

for svc in $SERVICES; do
  echo "────────────────────────────────────────"
  echo "==> Building $svc ..."
  $COMPOSE build --parallel 1 "$svc"
  echo "==> Pushing $PREFIX/$svc:$IMAGE_TAG ..."
  docker push "$PREFIX/$svc:$IMAGE_TAG"
  if [ "$IMAGE_TAG" != "latest" ]; then
    docker tag "$PREFIX/$svc:$IMAGE_TAG" "$PREFIX/$svc:latest"
    docker push "$PREFIX/$svc:latest"
  fi
  echo "==> Done: $svc"
done

echo
echo "==> Pushed. No Dokploy: Redeploy (pull only)."
echo "    Guide: docs/deploy-dokploy.md"
