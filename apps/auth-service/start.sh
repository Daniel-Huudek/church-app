#!/bin/sh
echo "Running database migrations..."
npx prisma migrate deploy 2>/dev/null || npx prisma db push --skip-generate --accept-data-loss || true
echo "Starting application..."
exec npx --no-install tsx src/index.ts
