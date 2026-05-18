FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/prayer-service/package.json ./apps/prayer-service/
COPY packages/ ./packages/

WORKDIR /app/apps/prayer-service

RUN npm install -g pnpm && pnpm install

COPY apps/prayer-service/prisma ./prisma
COPY apps/prayer-service/src ./src
COPY apps/prayer-service/package.json ./
COPY apps/prayer-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3007

CMD ["./start.sh"]
