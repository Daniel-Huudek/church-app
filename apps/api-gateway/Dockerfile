FROM node:20-alpine
RUN apk add --no-cache wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/api-gateway/package.json ./apps/api-gateway/
COPY packages/ ./packages/

WORKDIR /app/apps/api-gateway

RUN npm install -g pnpm && pnpm install --frozen-lockfile

COPY apps/api-gateway/start.sh ./
COPY apps/api-gateway/src ./src

RUN chmod +x start.sh

EXPOSE 3030

CMD ["./start.sh"]
