FROM node:20-alpine
RUN apk add --no-cache openssl
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/member-service/package.json ./apps/member-service/
COPY packages/ ./packages/

WORKDIR /app/apps/member-service

RUN npm install -g pnpm && pnpm install

COPY apps/member-service/prisma ./prisma
COPY apps/member-service/src ./src
COPY apps/member-service/package.json ./
COPY apps/member-service/start.sh ./

RUN npx prisma generate
RUN chmod +x start.sh

EXPOSE 3006

CMD ["./start.sh"]
