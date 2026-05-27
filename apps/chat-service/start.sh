#!/bin/sh
set -e
npx prisma migrate deploy
exec npx --no-install tsx src/index.ts
