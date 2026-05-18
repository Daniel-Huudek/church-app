FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/financial-service/package.json ./apps/financial-service/
COPY packages/ ./packages/

WORKDIR /app/apps/financial-service

RUN npm install -g pnpm && pnpm install

COPY apps/financial-service/prisma ./prisma
COPY apps/financial-service/src ./src
COPY apps/financial-service/package.json ./
COPY apps/financial-service/start.sh ./

RUN npx prisma generate

EXPOSE 3008

CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss || true && pnpm dev"]
