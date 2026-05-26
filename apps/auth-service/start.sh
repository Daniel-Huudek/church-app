#!/bin/sh
set -e
echo "Running database migrations..."
npx prisma migrate deploy
echo "Starting application..."
exec npx --no-install tsx src/index.ts
