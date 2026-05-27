#!/bin/sh
set -e
npx prisma db push --skip-generate --accept-data-loss 2>&1 || echo "Migration warning (continuing)..."
exec npx --no-install tsx src/index.ts
