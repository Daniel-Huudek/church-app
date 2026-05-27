FROM node:22-alpine
RUN apk add --no-cache openssl wget
WORKDIR /app

COPY pnpm-lock.yaml package.json pnpm-workspace.yaml ./
COPY apps/worship-service/package.json ./apps/worship-service/
COPY packages/shared/package.json ./packages/shared/
COPY packages/tsconfig/package.json ./packages/tsconfig/

RUN npm install

COPY packages/shared/ ./packages/shared/
COPY packages/tsconfig/ ./packages/tsconfig/
RUN npm run build --workspace=@church-app/shared

COPY apps/worship-service/prisma ./apps/worship-service/prisma
COPY apps/worship-service/src ./apps/worship-service/src
COPY apps/worship-service/start.sh ./apps/worship-service/start.sh

WORKDIR /app/apps/worship-service
RUN npx prisma generate && chmod +x start.sh
RUN chown -R node:node /app
USER node

EXPOSE 3010
CMD ["./start.sh"]
