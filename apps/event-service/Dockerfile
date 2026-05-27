FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/event-service/package.json ./apps/event-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN npm run build --workspace=@church-app/shared

COPY apps/event-service/prisma ./apps/event-service/prisma
COPY apps/event-service/src ./apps/event-service/src
COPY apps/event-service/start.sh ./apps/event-service/start.sh

WORKDIR /app/apps/event-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3004
CMD ["./start.sh"]
