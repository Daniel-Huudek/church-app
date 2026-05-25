#!/bin/sh
echo "Running database migrations..."
npx prisma migrate deploy || true
echo "Starting application..."
exec npx --no-install tsx src/index.ts
