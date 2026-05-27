FROM node:22-alpine
RUN apk add --no-cache openssl wget
RUN npm install -g pnpm
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/worship-service/package.json ./apps/worship-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN pnpm --filter @church-app/shared build

COPY apps/worship-service/prisma ./apps/worship-service/prisma
COPY apps/worship-service/src ./apps/worship-service/src
COPY apps/worship-service/start.sh ./apps/worship-service/start.sh

WORKDIR /app/apps/worship-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3010
CMD ["./start.sh"]
