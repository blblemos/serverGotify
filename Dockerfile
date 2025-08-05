# Etapa 1: build da UI e do backend
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Instala dependências
RUN apk add --no-cache git nodejs npm

# Clona o repositório do Gotify
RUN git clone --branch v2.6.3 https://github.com/gotify/server.git .

# Compila o frontend (UI)
WORKDIR /app/ui
RUN npm install && npm run build

# Compila o backend (Go)
WORKDIR /app
RUN go build -o gotify

# Etapa 2: imagem final
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/gotify .
COPY --from=builder /app/ui/build ./ui

VOLUME ["/app/data"]

EXPOSE 80

CMD ["./gotify"]
