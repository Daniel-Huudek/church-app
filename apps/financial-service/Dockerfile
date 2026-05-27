FROM node:22-alpine
RUN apk add --no-cache openssl wget
RUN corepack enable && corepack prepare pnpm@11 --activate
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/financial-service/package.json ./apps/financial-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install 

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN pnpm --filter @church-app/shared build

COPY apps/financial-service/prisma ./apps/financial-service/prisma
COPY apps/financial-service/src ./apps/financial-service/src
COPY apps/financial-service/start.sh ./apps/financial-service/start.sh

WORKDIR /app/apps/financial-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3008
CMD ["./start.sh"]
