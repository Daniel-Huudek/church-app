FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/chat-service/package.json ./apps/chat-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN npm run build --workspace=@church-app/shared

COPY apps/chat-service/prisma ./apps/chat-service/prisma
COPY apps/chat-service/src ./apps/chat-service/src
COPY apps/chat-service/start.sh ./apps/chat-service/start.sh

WORKDIR /app/apps/chat-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3002
CMD ["./start.sh"]
