FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/notification-service/package.json ./apps/notification-service/
COPY packages/shared ./packages/shared
COPY packages/tsconfig ./packages/tsconfig

WORKDIR /app/apps/notification-service

RUN npm install -g pnpm && pnpm install

RUN pnpm --filter @church-app/shared build

COPY apps/notification-service/prisma ./prisma
COPY apps/notification-service/start.sh ./
COPY apps/notification-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3005

CMD ["./start.sh"]
