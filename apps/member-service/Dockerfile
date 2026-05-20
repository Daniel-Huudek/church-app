FROM node:20-alpine AS builder
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY apps/member-service/package.json ./apps/member-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/types/package.json ./packages/types/
COPY packages/eslint-config/package.json ./packages/eslint-config/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install -g pnpm@8 && pnpm install

COPY apps/member-service/prisma ./apps/member-service/prisma
RUN cd apps/member-service && npx prisma generate

COPY packages/shared/src ./packages/shared/src
COPY packages/types/src ./packages/types/src
COPY apps/member-service/src ./apps/member-service/src

RUN pnpm --filter @church-app/member-service build

FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/member-service/prisma ./apps/member-service/prisma
COPY --from=builder /app/apps/member-service/src ./apps/member-service/src

COPY package.json pnpm-workspace.yaml ./
COPY apps/member-service/package.json ./apps/member-service/

EXPOSE 3006
CMD ["sh", "-c", "cd apps/member-service && npx prisma db push --skip-generate --accept-data-loss || true && tsx src/index.ts"]
