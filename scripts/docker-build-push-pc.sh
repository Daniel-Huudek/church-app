#!/bin/sh
# Build images on your PC and push to GHCR (do NOT run this on the 4GB VPS).
#
# Prerequisites:
#   1. Docker Desktop (or Docker Engine) running
#   2. GitHub Personal Access Token with: write:packages, read:packages
#   3. Logged in once:
#        export GHCR_USER=seu-usuario-github
#        export GHCR_TOKEN=ghp_xxxxxxxx
#        echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
#
# Usage:
#   ./scripts/docker-build-push-pc.sh              # all services
#   ./scripts/docker-build-push-pc.sh auth-service # one service
#   IMAGE_TAG=abc1234 ./scripts/docker-build-push-pc.sh
set -e

cd "$(dirname "$0")/.."

IMAGE_TAG="${IMAGE_TAG:-latest}"
export IMAGE_TAG
export DOCKER_BUILDKIT=1
unset COMPOSE_BAKE || true

PREFIX="ghcr.io/daniel-huudek/church-app"
ALL="api-gateway auth-service member-service schedule-service event-service notification-service prayer-service financial-service worship-service chat-service"
SERVICES="${*:-$ALL}"

# Refuse to run on tiny hosts (likely the VPS)
if [ -r /proc/meminfo ]; then
  MEM_MB=$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)
  if [ "$MEM_MB" -lt 5000 ] && [ "${FORCE_VPS_BUILD:-}" != "1" ]; then
    echo "This machine has ~${MEM_MB}MB RAM. Building here will likely freeze it."
    echo "Use GitHub Actions (Docker Publish) or a PC with 8GB+ RAM."
    echo "Override with FORCE_VPS_BUILD=1 only if you accept the risk."
    exit 1
  fi
fi

echo "==> PC build + push to GHCR"
echo "    IMAGE_TAG=$IMAGE_TAG"
echo "    Services: $SERVICES"
echo

# Ensure GHCR login
if [ -n "${GHCR_TOKEN:-}" ] && [ -n "${GHCR_USER:-}" ]; then
  echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
elif ! docker buildx imagetools inspect ghcr.io/daniel-huudek/church-app/api-gateway:latest >/dev/null 2>&1 \
  && [ ! -f "${HOME}/.docker/config.json" ]; then
  echo "Faça login no GHCR antes:"
  echo "  export GHCR_USER=seu-usuario-github"
  echo "  export GHCR_TOKEN=ghp_xxx   # write:packages"
  echo "  echo \"\$GHCR_TOKEN\" | docker login ghcr.io -u \"\$GHCR_USER\" --password-stdin"
  exit 1
fi

# If config exists but login expired, push will fail with a clear error from Docker.
for svc in $SERVICES; do
  echo "────────────────────────────────────────"
  echo "==> Building $svc ..."
  docker compose build --parallel 1 "$svc"
  echo "==> Pushing $PREFIX/$svc:$IMAGE_TAG ..."
  docker push "$PREFIX/$svc:$IMAGE_TAG"
  # Also keep :latest when tagging a sha
  if [ "$IMAGE_TAG" != "latest" ]; then
    docker tag "$PREFIX/$svc:$IMAGE_TAG" "$PREFIX/$svc:latest"
    docker push "$PREFIX/$svc:latest"
  fi
  echo "==> Done: $svc"
done

echo
echo "==> All pushed to GHCR."
echo "    On the VPS run:"
echo "      IMAGE_TAG=$IMAGE_TAG ./scripts/docker-deploy-vps.sh"
echo
echo "    First time: make GHCR packages Public (GitHub → Packages),"
echo "    or login on the VPS with a read:packages token."
