#!/bin/sh
set -e
echo "Resolving any failed migrations..."
npx prisma migrate status 2>&1 | grep FAILED | awk '{print $2}' | while read migration; do
  [ -n "$migration" ] && npx prisma migrate resolve --rolled-back "$migration"
done
npx prisma migrate deploy
exec npx tsx src/index.ts
