#!/bin/sh
set -e

# Production boot for small VPS containers.

run_prisma() {
  if [ -x ./node_modules/.bin/prisma ]; then
    ./node_modules/.bin/prisma "$@"
  elif [ -f ./node_modules/prisma/build/index.js ]; then
    node ./node_modules/prisma/build/index.js "$@"
  else
    npx prisma "$@"
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

echo "Starting on port ${PORT:-unknown}..."
exec node dist/index.js
