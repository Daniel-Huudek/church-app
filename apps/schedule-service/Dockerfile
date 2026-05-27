FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/schedule-service/package.json ./apps/schedule-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN npm run build --workspace=@church-app/shared

COPY apps/schedule-service/prisma ./apps/schedule-service/prisma
COPY apps/schedule-service/src ./apps/schedule-service/src
COPY apps/schedule-service/start.sh ./apps/schedule-service/start.sh

WORKDIR /app/apps/schedule-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3003
CMD ["./start.sh"]
