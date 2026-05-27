FROM node:22-alpine
RUN apk add --no-cache openssl wget
ENV CI=true
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/prayer-service/package.json ./apps/prayer-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN corepack enable && corepack prepare pnpm@10.12.1 --activate
RUN pnpm config set fetch-timeout 120000
RUN pnpm config set network-timeout 120000
RUN pnpm config set network-concurrency 3
RUN pnpm config set child-concurrency 2

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN pnpm --filter @church-app/shared build

COPY apps/prayer-service/prisma ./apps/prayer-service/prisma
COPY apps/prayer-service/src ./apps/prayer-service/src
COPY apps/prayer-service/start.sh ./apps/prayer-service/start.sh

WORKDIR /app/apps/prayer-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3007
CMD ["./start.sh"]
