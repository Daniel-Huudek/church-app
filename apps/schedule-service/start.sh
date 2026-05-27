#!/bin/sh
set -e
echo "Running database migrations..."
npx prisma db push --skip-generate --accept-data-loss 2>&1 || echo "Migration warning (continuing)..."
echo "Starting application..."
exec npx --no-install tsx src/index.ts
