# Stage 1: Builder Node.js (frontend React)
FROM node:20.19.0-alpine AS builder-ui

WORKDIR /app/ui

# Dependências para compilação (se precisar de python, make, etc, pode adicionar)
RUN apk add --no-cache python3 make g++

COPY ui/package*.json ./
RUN npm install

COPY ui/ ./

# Definindo variável para contornar erro OpenSSL
ENV NODE_OPTIONS=--openssl-legacy-provider

RUN npm run build

# Stage 2: Builder Go (backend)
FROM golang:1.21-alpine AS builder-go

WORKDIR /app/backend

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./

RUN go build -o /app/backend/server

# Stage 3: Final image (runtime)
FROM alpine:latest

# Instalar CA certs para HTTPS e outras libs se necessário
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copiar backend compilado
COPY --from=builder-go /app/backend/server ./server

# Copiar frontend build para servir (se usar algum servidor estático)
COPY --from=builder-ui /app/ui/build ./ui/build

# Se seu backend servir frontend, configure conforme necessário
# EX: expor porta e comando para rodar backend
EXPOSE 8080

CMD ["./server"]
