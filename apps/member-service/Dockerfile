FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/member-service/package.json ./apps/member-service/
COPY packages/ ./packages/

WORKDIR /app/apps/member-service

RUN npm install -g pnpm && pnpm install

RUN pnpm --filter @church-app/shared build

COPY apps/member-service/prisma ./prisma
COPY apps/member-service/start.sh ./
COPY apps/member-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3006

CMD ["./start.sh"]
