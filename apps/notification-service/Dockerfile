FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/notification-service/package.json ./apps/notification-service/
COPY packages/ ./packages/

WORKDIR /app/apps/notification-service

RUN npm install -g pnpm && pnpm install

COPY apps/notification-service/prisma ./prisma
COPY apps/notification-service/src ./src
COPY apps/notification-service/package.json ./
COPY apps/notification-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3005

CMD ["./start.sh"]