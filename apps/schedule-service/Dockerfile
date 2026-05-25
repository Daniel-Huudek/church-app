FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/schedule-service/package.json ./apps/schedule-service/
COPY packages/ ./packages/

WORKDIR /app/apps/schedule-service

RUN npm install -g pnpm && pnpm install

COPY apps/schedule-service/prisma ./prisma
COPY apps/schedule-service/start.sh ./
COPY apps/schedule-service/src ./src

RUN npx prisma generate && chmod +x start.sh

EXPOSE 3003

CMD ["./start.sh"]
