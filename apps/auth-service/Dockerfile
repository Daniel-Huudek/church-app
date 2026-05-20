FROM node:20-alpine AS builder
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY apps/auth-service/package.json ./apps/auth-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/types/package.json ./packages/types/

RUN npm install -g pnpm && pnpm install --frozen-lockfile

COPY apps/auth-service/prisma ./apps/auth-service/prisma
RUN cd apps/auth-service && npx prisma generate

COPY packages/shared/src ./packages/shared/src
COPY packages/types/src ./packages/types/src
COPY apps/auth-service/src ./apps/auth-service/src

RUN pnpm --filter @church-app/auth-service build

FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/auth-service/prisma ./apps/auth-service/prisma
COPY --from=builder /app/apps/auth-service/src ./apps/auth-service/src

COPY package.json pnpm-workspace.yaml ./
COPY apps/auth-service/package.json ./apps/auth-service/

EXPOSE 3001
CMD ["sh", "-c", "cd apps/auth-service && npx prisma db push --skip-generate --accept-data-loss || true && tsx src/index.ts"]
