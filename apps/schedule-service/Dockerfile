FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/schedule-service/package.json ./apps/schedule-service/
COPY packages/ ./packages/

WORKDIR /app/apps/schedule-service

RUN npm install -g pnpm && pnpm install

COPY apps/schedule-service/prisma ./prisma
COPY apps/schedule-service/src ./src
COPY apps/schedule-service/package.json ./
RUN npx prisma generate

EXPOSE 3003

CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss || true && npx --no-install tsx src/index.ts"]