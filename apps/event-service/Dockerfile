FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/event-service/package.json ./apps/event-service/
COPY packages/ ./packages/

WORKDIR /app/apps/event-service

RUN npm install -g pnpm && pnpm install

COPY apps/event-service/prisma ./prisma
COPY apps/event-service/src ./src
COPY apps/event-service/package.json ./
COPY apps/event-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3004

CMD ["./start.sh"]