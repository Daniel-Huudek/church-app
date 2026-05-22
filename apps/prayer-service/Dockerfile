FROM node:20-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/prayer-service/package.json ./apps/prayer-service/
COPY packages/ ./packages/

WORKDIR /app/apps/prayer-service

RUN npm install -g pnpm && pnpm install

COPY apps/prayer-service/prisma ./prisma
COPY apps/prayer-service/start.sh ./
COPY apps/prayer-service/src ./src

RUN npx prisma generate && chmod +x start.sh

EXPOSE 3007

CMD ["./start.sh"]
