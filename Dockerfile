# Etapa 1: Build do backend e UI
FROM golang:1.21-alpine AS builder

# Instala dependências do sistema para Go e NodeJS
RUN apk add --no-cache git nodejs npm python3 make g++

WORKDIR /app

# Clona a versão desejada do repositório Gotify
RUN git clone --branch v2.6.3 https://github.com/gotify/server.git .

# Build do frontend (UI)
WORKDIR /app/ui
RUN npm install
RUN npm run build

# Build do backend Go
WORKDIR /app
RUN go build -o gotify

# Etapa 2: Imagem final mais leve
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/gotify .
COPY --from=builder /app/ui/build ./ui

VOLUME ["/app/data"]

EXPOSE 80

CMD ["./gotify"]
