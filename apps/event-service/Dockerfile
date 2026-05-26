FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/event-service/package.json ./apps/event-service/
COPY packages/shared ./packages/shared
COPY packages/tsconfig ./packages/tsconfig

WORKDIR /app/apps/event-service

RUN npm install -g pnpm && pnpm install --frozen-lockfile

RUN pnpm --filter @church-app/shared build

COPY apps/event-service/prisma ./prisma
COPY apps/event-service/start.sh ./
COPY apps/event-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3004

CMD ["./start.sh"]
