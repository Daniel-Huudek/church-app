# syntax=docker/dockerfile:1
# Flutter member app → static web (no nginx). Build on CI/PC only, never on 4GB VPS.
# Runtime: Node `serve` (SPA) on port 8080.
# API URL is baked at build via --dart-define=API_URL (Flutter fromEnvironment).

FROM ghcr.io/cirruslabs/flutter:3.27.4 AS build
WORKDIR /app

COPY apps/flutter/pubspec.yaml ./
RUN flutter pub get

COPY apps/flutter/ ./
# Refresh deps after full copy (assets / path deps may change the graph)
RUN flutter pub get

ARG API_URL=https://api.ipiavare.com.br
ARG GOOGLE_WEB_CLIENT_ID=520104571386-kj462ur3tstcoprsftlnut4qm3nssc1l.apps.googleusercontent.com

RUN flutter build web --release \
  --dart-define=API_URL=${API_URL} \
  --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID}

FROM node:22-alpine AS runner
WORKDIR /srv

RUN npm install --global serve@14.2.4 \
  && apk add --no-cache wget

COPY --from=build /app/build/web ./web

ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null || exit 1

# -s: SPA fallback to index.html (GoRouter deep links)
CMD ["serve", "-s", "web", "-l", "tcp://0.0.0.0:8080"]
