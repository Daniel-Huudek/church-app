FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY apps/api-gateway/package.json ./apps/api-gateway/
COPY packages/shared/package.json ./packages/shared/
COPY packages/types/package.json ./packages/types/

RUN npm install -g pnpm && pnpm install --frozen-lockfile

COPY packages/shared/src ./packages/shared/src
COPY packages/types/src ./packages/types/src
COPY apps/api-gateway/src ./apps/api-gateway/src

RUN pnpm --filter @church-app/api-gateway build

FROM node:20-alpine
WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/apps/api-gateway/src ./apps/api-gateway/src

COPY package.json pnpm-workspace.yaml ./
COPY apps/api-gateway/package.json ./apps/api-gateway/

EXPOSE 3000
CMD ["tsx", "apps/api-gateway/src/index.ts"]
