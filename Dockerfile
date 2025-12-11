FROM golang:1.24-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -ldflags="-s -w" -o parser .

FROM alpine:latest
WORKDIR /app

COPY --from=builder /app/parser .

EXPOSE 8080

CMD ["./parser"]
