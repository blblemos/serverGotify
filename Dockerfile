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

# Instala ferramentas necessárias
RUN apk add --no-cache git make

# Copia o código do projeto
COPY . .

# Copia o frontend build gerado
COPY --from=js-builder /src/gotify/ui/build ./ui/build

# Executa o build com Makefile
RUN make OUTPUT=/target/app/gotify-app _build_within_docker


# --- Imagem final para produção ---
FROM debian:sid-slim

ARG GOTIFY_SERVER_EXPOSE=80
ENV GOTIFY_SERVER_PORT=$GOTIFY_SERVER_EXPOSE

WORKDIR /app

RUN apt-get update && apt-get install -yq --no-install-recommends \
    curl tzdata ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copia binário gerado
COPY --from=go-builder /target/app/gotify-app ./gotify-app

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD curl --fail http://localhost:$GOTIFY_SERVER_PORT/health || exit 1

EXPOSE $GOTIFY_SERVER_EXPOSE

ENTRYPOINT ["./gotify-app"]
