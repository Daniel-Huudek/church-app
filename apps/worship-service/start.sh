#!/bin/sh
set -e

# Fast production boot: migrate (when applicable) then run compiled JS.
# Avoids tsx transpile-on-start and slow `db push` + failed-migration scans.

if [ -f prisma/schema.prisma ]; then
  PRISMA_BIN="./node_modules/.bin/prisma"
  if [ ! -x "$PRISMA_BIN" ]; then
    PRISMA_BIN="npx prisma"
  fi

  if [ -d prisma/migrations ] && [ -n "$(ls -A prisma/migrations 2>/dev/null)" ]; then
    echo "Running prisma migrate deploy..."
    $PRISMA_BIN migrate deploy
  else
    echo "No migrations directory — syncing schema with db push..."
    $PRISMA_BIN db push --skip-generate
  fi
fi

echo "Starting application on port ${PORT:-unknown}..."
exec node dist/index.js
