FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/auth-service/package.json ./apps/auth-service/
COPY packages/shared ./packages/shared
COPY packages/tsconfig ./packages/tsconfig

WORKDIR /app/apps/auth-service

RUN npm install -g pnpm && pnpm install

RUN pnpm --filter @church-app/shared build

COPY apps/auth-service/prisma ./prisma
COPY apps/auth-service/start.sh ./
COPY apps/auth-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3001

CMD ["./start.sh"]
