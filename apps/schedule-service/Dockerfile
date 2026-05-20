FROM node:20-alpine AS builder
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY apps/schedule-service/package.json ./apps/schedule-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/types/package.json ./packages/types/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install -g pnpm && pnpm install --frozen-lockfile

COPY apps/schedule-service/prisma ./apps/schedule-service/prisma
RUN cd apps/schedule-service && npx prisma generate

COPY packages/shared/src ./packages/shared/src
COPY packages/types/src ./packages/types/src
COPY apps/schedule-service/src ./apps/schedule-service/src

RUN pnpm --filter @church-app/schedule-service build

FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/schedule-service/prisma ./apps/schedule-service/prisma
COPY --from=builder /app/apps/schedule-service/src ./apps/schedule-service/src

COPY package.json pnpm-workspace.yaml ./
COPY apps/schedule-service/package.json ./apps/schedule-service/

EXPOSE 3003
CMD ["sh", "-c", "cd apps/schedule-service && npx prisma db push --skip-generate --accept-data-loss || true && tsx src/index.ts"]
