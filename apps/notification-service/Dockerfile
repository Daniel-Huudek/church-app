FROM node:22-alpine
RUN apk add --no-cache openssl wget
ENV CI=true
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/notification-service/package.json ./apps/notification-service/
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

COPY apps/notification-service/prisma ./apps/notification-service/prisma
COPY apps/notification-service/src ./apps/notification-service/src
COPY apps/notification-service/start.sh ./apps/notification-service/start.sh

WORKDIR /app/apps/notification-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3005
CMD ["./start.sh"]
