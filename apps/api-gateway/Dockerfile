FROM node:22-alpine
RUN apk add --no-cache wget

WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/api-gateway/package.json ./apps/api-gateway/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN corepack enable && corepack prepare pnpm@10.12.1 --activate
RUN pnpm config set fetch-timeout 120000
RUN pnpm config set network-timeout 120000
RUN pnpm config set network-concurrency 3
RUN pnpm config set child-concurrency 2

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN pnpm --filter @church-app/shared build

COPY apps/api-gateway/src ./apps/api-gateway/src
COPY apps/api-gateway/start.sh ./apps/api-gateway/start.sh

WORKDIR /app/apps/api-gateway
RUN chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3030
CMD ["./start.sh"]
