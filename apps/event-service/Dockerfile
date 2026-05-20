FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/event-service/package.json ./apps/event-service/
COPY packages/ ./packages/

WORKDIR /app/apps/event-service

RUN npm install -g pnpm && pnpm install

COPY apps/event-service/prisma ./prisma
COPY apps/event-service/src ./src
COPY apps/event-service/package.json ./
RUN npx prisma generate

EXPOSE 3004

CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss || true && npx --no-install tsx src/index.ts"]