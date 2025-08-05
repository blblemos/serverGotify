# Define a versão do Go para build
ARG GO_VERSION=1.21
ARG BUILD_JS=1
ARG DEBIAN_VERSION=sid-slim

# --- Build do frontend (JS) ---
FROM node:23 AS js-builder

WORKDIR /src/gotify

COPY ./Makefile ./Makefile
COPY ./ui ./ui

RUN if [ "$BUILD_JS" = "1" ]; then \
      cd ui && yarn install && cd .. && make build-js; \
    else \
      mkdir -p ui/build; \
    fi

# --- Build do backend (Go) ---
FROM gotify/build:${GO_VERSION} AS builder

ENV DEBIAN_FRONTEND=noninteractive
ARG BUILD_JS=1
ARG RUN_TESTS=0
ARG LD_FLAGS=""

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git

WORKDIR /src/gotify

COPY . .

# Copia build do frontend da etapa anterior
COPY --from=js-builder /src/gotify/ui/build /src/gotify/ui/build

RUN if [ "$RUN_TESTS" = "1" ]; then \
      go test -v ./...; \
    fi

RUN LD_FLAGS=${LD_FLAGS} make OUTPUT=/target/app/gotify-app _build_within_docker

# --- Imagem final para rodar o app ---
FROM debian:${DEBIAN_VERSION}

ARG GOTIFY_SERVER_EXPOSE=80
ENV GOTIFY_SERVER_PORT=$GOTIFY_SERVER_EXPOSE

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tzdata curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s CMD curl --fail http://localhost:$GOTIFY_SERVER_PORT/health || exit 1

EXPOSE $GOTIFY_SERVER_EXPOSE

COPY --from=builder /target/app/gotify-app ./gotify-app

ENTRYPOINT ["./gotify-app"]
