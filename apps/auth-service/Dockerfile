FROM node:20-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/auth-service/package.json ./apps/auth-service/
COPY packages/ ./packages/

WORKDIR /app/apps/auth-service

RUN npm install -g pnpm && pnpm install

COPY apps/auth-service/prisma ./prisma
COPY apps/auth-service/src ./src
COPY apps/auth-service/package.json ./
RUN npx prisma generate

EXPOSE 3001

CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss || true && npx --no-install tsx src/index.ts"]