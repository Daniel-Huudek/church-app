#!/bin/sh
set -e

# Production boot — keep this light for 96MB container limits.
# Prefer local prisma binary; fall back to node entry.

if [ -f prisma/schema.prisma ]; then
  if [ -x ./node_modules/.bin/prisma ]; then
    PRISMA="./node_modules/.bin/prisma"
  elif [ -f ./node_modules/prisma/build/index.js ]; then
    PRISMA="node ./node_modules/prisma/build/index.js"
  else
    PRISMA="npx prisma"
  fi

  if [ -d prisma/migrations ] && [ -n "$(ls -A prisma/migrations 2>/dev/null)" ]; then
    echo "Running prisma migrate deploy..."
    $PRISMA migrate deploy
  else
    echo "No migrations — syncing schema with db push..."
    $PRISMA db push --skip-generate
  fi
fi

echo "Starting on port ${PORT:-unknown}..."
exec node dist/index.js
