# syntax=docker/dockerfile:1.7
#
# Multi-stage build for the maarsch.net portfolio (Vite + React SPA).
# Build context = a checkout of github.com/NeoSlinkee/portfolio.
#
#   docker build -f app/Dockerfile -t ghcr.io/neoslinkee/portfolio:dev ../portfolio
#
# Stage 1 compiles the static bundle; stage 2 serves it from an unprivileged
# nginx image (runs as UID 101, listens on 8080, no root required).

ARG NODE_VERSION=22-alpine
ARG NGINX_VERSION=1.27-alpine

# ---------- build ----------
FROM node:${NODE_VERSION} AS build
WORKDIR /src

# Install dependencies first so this layer is cached between code changes.
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

COPY . .
RUN npm run build

# ---------- runtime ----------
FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}

LABEL org.opencontainers.image.title="portfolio" \
      org.opencontainers.image.description="maarsch.net portfolio served by unprivileged nginx" \
      org.opencontainers.image.source="https://github.com/NeoSlinkee/portfolio-platform"

ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

# Config is not inherited from the build context, so it is copied in via a
# named build context (see scripts/build.sh and CI: --build-context platform=app).
# hadolint's DL3022 does not understand named contexts, hence the ignores.
# hadolint ignore=DL3022
COPY --from=platform nginx/default.conf /etc/nginx/conf.d/default.conf
# hadolint ignore=DL3022
COPY --from=platform nginx/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY --from=build --chown=101:101 /src/dist /usr/share/nginx/html

USER 101
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
