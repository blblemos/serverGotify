# Etapa 1: build
FROM golang:1.21-alpine AS builder

ENV GO111MODULE=on \
    GOTIFY_VERSION=v2.6.3

WORKDIR /build

# Baixa o código fonte específico da tag
RUN apk add --no-cache git && \
    git clone --branch ${GOTIFY_VERSION} --depth 1 https://github.com/gotify/server.git . && \
    go mod tidy

# Compila o binário principal
RUN go build -ldflags="-w -s" -o gotify .

# Etapa 2: image final
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copia o binário compilado e diretório do web UI, se necessário
COPY --from=builder /build/gotify /app/gotify
COPY --from=builder /build/ui /app/ui

# Cria diretório de dados persistente
VOLUME /app/data

ENV GOTIFY_SERVER_EXPOSE=80 \
    GOTIFY_SERVER_PORT=80 \
    TZ=UTC

EXPOSE 80

# Healthcheck opcional
HEALTHCHECK --interval=30s --timeout=5s CMD /app/gotify health || exit 1

# Define comando para execução
ENTRYPOINT ["/app/gotify"]
CMD ["server"]
