FROM node:20-alpine
WORKDIR /app

COPY package.json pnpm-workspace.yaml ./
COPY apps/api-gateway/package.json ./apps/api-gateway/
COPY packages/ ./packages/

WORKDIR /app/apps/api-gateway

RUN npm install -g pnpm && pnpm install

COPY apps/api-gateway/src ./src
COPY apps/api-gateway/package.json ./

EXPOSE 3030

CMD ["npx", "--no-install", "tsx", "src/index.ts"]