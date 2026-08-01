# syntax=docker/dockerfile:1
# Flutter member app → static web (no nginx). Build on CI/PC only, never on 4GB VPS.
# Runtime: Node `serve` (SPA) on port 8080.
# API URL is baked at build via --dart-define=API_URL (Flutter fromEnvironment).

FROM debian:bookworm-slim AS build

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    unzip \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

# Official SDK tarball (avoids discontinued/missing cirruslabs image tags).
# 3.35+ supports audioplayers 6.7.x and ships intl 0.20.x.
ARG FLUTTER_VERSION=3.35.7
ENV FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/opt/pub-cache \
    PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

RUN curl -fsSL \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar -xJ -C /opt \
  && git config --global --add safe.directory /opt/flutter \
  && flutter config --no-analytics --enable-web \
  && flutter precache --web

WORKDIR /app

COPY apps/flutter/pubspec.yaml ./
RUN flutter pub get

COPY apps/flutter/ ./
RUN flutter pub get

ARG API_URL=https://church.inspeare.com.br
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
