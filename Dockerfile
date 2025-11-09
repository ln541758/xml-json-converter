FROM golang:1.22 AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -o parser .

FROM alpine:latest
WORKDIR /app

COPY --from=builder /app/parser .

EXPOSE 8080

CMD ["./parser"]
