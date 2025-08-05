# Etapa 1: builder
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Instalações necessárias
RUN apk add --no-cache git

# Clona o código do Gotify (ou copie do seu próprio repositório)
RUN git clone --branch v2.6.3 https://github.com/gotify/server.git .

# Instala dependências e compila
RUN go mod tidy && \
    go build -ldflags="-w -s" -o gotify .

# Etapa 2: imagem final
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copia o binário
COPY --from=builder /build/gotify /app/gotify
COPY --from=builder /build/ui /app/ui

# Volume para persistência de dados
VOLUME /app/data

ENV GOTIFY_SERVER_PORT=80 \
    TZ=UTC

EXPOSE 80

ENTRYPOINT ["/app/gotify"]
CMD ["server"]
