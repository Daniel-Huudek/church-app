FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/financial-service/package.json ./apps/financial-service/
COPY packages/ ./packages/

WORKDIR /app/apps/financial-service

RUN npm install -g pnpm && pnpm install

COPY apps/financial-service/prisma ./prisma
COPY apps/financial-service/start.sh ./
COPY apps/financial-service/src ./src

RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3008

CMD ["./start.sh"]
