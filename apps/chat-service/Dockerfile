FROM node:22-alpine AS builder
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY pnpm-lock.yaml pnpm-workspace.yaml ./
COPY package.json ./
RUN pnpm fetch
COPY . .
RUN pnpm install --offline
RUN pnpm --filter @church-app/chat-service build

FROM node:22-alpine
RUN apk add --no-cache tini
WORKDIR /app/apps/chat-service
COPY --from=builder /app/apps/chat-service/dist ./dist
COPY --from=builder /app/apps/chat-service/package.json .
COPY --from=builder /app/apps/chat-service/prisma ./prisma
COPY --from=builder /app/apps/chat-service/start.sh .
COPY --from=builder /app/node_modules ./node_modules
RUN chown -R node:node /app
USER node
EXPOSE 3002
ENTRYPOINT ["tini", "--"]
CMD ["sh", "start.sh"]
