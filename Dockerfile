# --- JS Builder ---
FROM node:20-alpine AS js-builder

WORKDIR /src/gotify/ui

COPY ./ui/package*.json ./
RUN yarn install

COPY ./ui ./
ENV NODE_OPTIONS=--openssl-legacy-provider
RUN yarn add @babel/core@^7.22.0 --dev
RUN yarn build


# --- Go Builder ---
FROM golang:1.24-bullseye AS go-builder

# Instala dependências C para compilar sqlite3
RUN apt-get update && apt-get install -y git make bash gcc sqlite3 libsqlite3-dev

ENV CGO_ENABLED=1

WORKDIR /src/gotify

COPY . .
COPY --from=js-builder /src/gotify/ui/build ./ui/build

RUN make OUTPUT=/target/app/gotify-app _build_within_docker


# --- Imagem final para produção ---
FROM debian:sid-slim AS final

ARG GOTIFY_SERVER_EXPOSE=80
ENV GOTIFY_SERVER_PORT=$GOTIFY_SERVER_EXPOSE

WORKDIR /app

# Copia o binário primeiro
COPY --from=go-builder /target/app/gotify-app ./gotify-app

# Instala binutils + curl e realiza o strip
RUN apt-get update && \
    apt-get install -y --no-install-recommends binutils curl && \
    strip --strip-unneeded gotify-app && \
    apt-get purge -y binutils && \
    rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl --fail http://localhost:$GOTIFY_SERVER_PORT/health || exit 1

EXPOSE $GOTIFY_SERVER_EXPOSE

ENTRYPOINT ["./gotify-app"]
