FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/user-service/package.json ./apps/user-service/
COPY packages/ ./packages/

WORKDIR /app/apps/user-service

RUN npm install -g pnpm && pnpm install

COPY apps/user-service/prisma ./prisma
COPY apps/user-service/src ./src
COPY apps/user-service/package.json ./
COPY apps/user-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3002

CMD ["./start.sh"]