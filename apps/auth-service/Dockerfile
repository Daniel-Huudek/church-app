FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/auth-service/package.json ./apps/auth-service/
COPY packages/ ./packages/

WORKDIR /app/apps/auth-service

RUN npm install -g pnpm && pnpm install

COPY apps/auth-service/prisma ./prisma
COPY apps/auth-service/start.sh ./
COPY apps/auth-service/src ./src

RUN npx prisma generate && chmod +x start.sh

EXPOSE 3001

CMD ["./start.sh"]
