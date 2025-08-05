# Etapa 1: Compilar a interface web
FROM node:18-alpine AS ui-builder

WORKDIR /app
RUN apk add --no-cache git
RUN git clone --branch v2.6.3 https://github.com/gotify/server.git .
WORKDIR /app/ui
RUN npm install && npm run build

# Etapa 2: Compilar o servidor Go
FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY --from=ui-builder /app /app
WORKDIR /app
RUN go mod tidy && go build -ldflags="-w -s" -o gotify .

# Etapa 3: Imagem final
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app
COPY --from=builder /app/gotify .
COPY --from=ui-builder /app/ui/build ./build

EXPOSE 80
CMD ["./gotify"]
