FROM node:22-alpine
RUN apk add --no-cache openssl wget
RUN npm install -g pnpm
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/member-service/package.json ./apps/member-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    pnpm install 

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN pnpm --filter @church-app/shared build

COPY apps/member-service/prisma ./apps/member-service/prisma
COPY apps/member-service/src ./apps/member-service/src
COPY apps/member-service/start.sh ./apps/member-service/start.sh

WORKDIR /app/apps/member-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3006
CMD ["./start.sh"]
