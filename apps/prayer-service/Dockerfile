FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/prayer-service/package.json ./apps/prayer-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install -g pnpm && pnpm install

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

