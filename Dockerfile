# --- JS Builder ---
FROM node:20-alpine AS js-builder

WORKDIR /src/gotify/ui

COPY ./ui/package*.json ./
RUN yarn install

COPY ./ui ./
RUN yarn build


# --- Go Builder ---
FROM golang:1.21-alpine AS go-builder

WORKDIR /src/gotify

# Instalar dependências
RUN apk add --no-cache git make

# Copiar arquivos do projeto
COPY . .

# Copiar o frontend build
COPY --from=js-builder /src/gotify/ui/build ./ui/build

# Rodar build do backend
RUN make build

# --- Imagem final ---
FROM debian:sid-slim

ARG GOTIFY_SERVER_EXPOSE=80
ENV GOTIFY_SERVER_PORT=$GOTIFY_SERVER_EXPOSE

WORKDIR /app

RUN apt-get update && apt-get install -yq --no-install-recommends \
    ca-certificates curl tzdata && \
    rm -rf /var/lib/apt/lists/*

COPY --from=go-builder /src/gotify/gotify-linux-amd64 ./gotify-app

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl --fail http://localhost:$GOTIFY_SERVER_PORT/health || exit 1

EXPOSE $GOTIFY_SERVER_EXPOSE

ENTRYPOINT ["./gotify-app"]
