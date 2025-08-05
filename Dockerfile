# Stage 1: Build frontend
FROM node:20.19.0-alpine AS builder-ui
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Stage 2: Build backend
FROM golang:1.21-alpine AS builder-go
WORKDIR /app/backend
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN go build -o /app/serverGotify

# Stage 3: Final image
FROM alpine:latest
RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder-go /app/serverGotify .
COPY --from=builder-ui /app/frontend/build ./frontend/build

EXPOSE 8080
CMD ["./serverGotify"]
