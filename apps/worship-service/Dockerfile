FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/worship-service/package.json ./apps/worship-service/
COPY packages/ ./packages/

WORKDIR /app/apps/worship-service

RUN npm install -g pnpm && pnpm install

RUN pnpm --filter @church-app/shared build

COPY apps/worship-service/prisma ./prisma
COPY apps/worship-service/start.sh ./
COPY apps/worship-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3010

CMD ["./start.sh"]
