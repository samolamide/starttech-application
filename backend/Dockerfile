FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /out/much-to-do ./cmd/api/main.go

FROM alpine:3.20

# Required for MongoDB Atlas (and other TLS) connections from Alpine
RUN apk add --no-cache ca-certificates \
  && addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=builder /out/much-to-do /app/much-to-do

USER app
EXPOSE 8080

CMD ["/app/much-to-do"]
