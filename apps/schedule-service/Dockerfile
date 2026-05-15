FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/schedule-service/package.json ./apps/schedule-service/
COPY packages/ ./packages/

WORKDIR /app/apps/schedule-service

RUN npm install -g pnpm && pnpm install

COPY apps/schedule-service/prisma ./prisma
COPY apps/schedule-service/src ./src
COPY apps/schedule-service/package.json ./
COPY apps/schedule-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3003

CMD ["./start.sh"]