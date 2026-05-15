#!/bin/sh
echo "Running database migrations..."
npx prisma db push --skip-generate --accept-data-loss || true
echo "Starting application..."
exec pnpm dev