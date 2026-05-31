#!/bin/sh
set -e

SERVICE=$1
OUTDIR=${2:-/tmp/docker-context/$SERVICE}

if [ -z "$SERVICE" ]; then
  echo "Usage: $0 <service-name> [output-dir]"
  echo "Example: $0 auth-service"
  exit 1
fi

if [ ! -d "apps/$SERVICE" ]; then
  echo "Error: apps/$SERVICE not found"
  exit 1
fi

rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# Root monorepo config files
cp pnpm-lock.yaml package.json pnpm-workspace.yaml "$OUTDIR/"

# Service-specific files
mkdir -p "$OUTDIR/apps/$SERVICE"
cp "apps/$SERVICE/package.json" "$OUTDIR/apps/$SERVICE/"
[ -d "apps/$SERVICE/prisma" ] && cp -r "apps/$SERVICE/prisma" "$OUTDIR/apps/$SERVICE/"
[ -f "apps/$SERVICE/start.sh" ] && cp "apps/$SERVICE/start.sh" "$OUTDIR/apps/$SERVICE/"
[ -d "apps/$SERVICE/src" ] && cp -r "apps/$SERVICE/src" "$OUTDIR/apps/$SERVICE/"

# Shared packages needed at build time
for pkg in shared tsconfig; do
  if [ -d "packages/$pkg" ]; then
    mkdir -p "$OUTDIR/packages/$pkg"
    cp -r "packages/$pkg/" "$OUTDIR/packages/$pkg/"
    # Remove any lingering node_modules in copied packages
    find "$OUTDIR/packages/$pkg" -name node_modules -type d -prune -exec rm -rf {} \; 2>/dev/null || true
  fi
done

echo "Context prepared at: $OUTDIR"
echo "Build with: docker build -t church-app-$SERVICE -f apps/$SERVICE/Dockerfile \"$OUTDIR\""

# Usage in docker-compose:
# build:
#   context: /tmp/docker-context/auth-service
#   dockerfile: Dockerfile
