#!/bin/sh
set -e

# Boot from TypeScript source (tsx) — no docker/image rebuild on code change.
# Shared package dist is built by the deploy script before restart.

run_prisma() {
  if [ -x ./node_modules/.bin/prisma ]; then
    ./node_modules/.bin/prisma "$@"
  elif [ -x /app/node_modules/.bin/prisma ]; then
    /app/node_modules/.bin/prisma "$@"
  elif [ -f ./node_modules/prisma/build/index.js ]; then
    node ./node_modules/prisma/build/index.js "$@"
  else
    pnpm exec prisma "$@"
  fi
}

if [ -f prisma/schema.prisma ]; then
  if [ -d prisma/migrations ] && [ -n "$(ls -A prisma/migrations 2>/dev/null)" ]; then
    echo "Running prisma migrate deploy..."
    migrated=0
    i=1
    while [ "$i" -le 8 ]; do
      if run_prisma migrate deploy; then
        migrated=1
        break
      fi
      echo "migrate deploy failed (attempt $i/8), retrying in 3s..."
      sleep 3
      i=$((i + 1))
    done
    if [ "$migrated" -ne 1 ]; then
      echo "migrate deploy failed after retries" >&2
      exit 1
    fi
  else
    echo "No migrations — syncing schema with db push..."
    run_prisma db push --skip-generate
  fi
fi

echo "Starting (tsx) on port ${PORT:-unknown}..."
# Prefer global tsx from runtime image; fall back to pnpm
if command -v tsx >/dev/null 2>&1; then
  exec tsx src/index.ts
fi
exec pnpm exec tsx src/index.ts
