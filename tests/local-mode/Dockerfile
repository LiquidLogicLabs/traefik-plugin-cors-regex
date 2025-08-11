# Builder/test image for the plugin (no Traefik runtime here)
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git ca-certificates make bash
WORKDIR /app

# Dependencies (go.mod is at parent level)
COPY ../go.mod ./
RUN go mod download && go mod tidy

# Source (plugin files are at parent level)
COPY ../ .

# Run unit tests (fail build if tests fail)
RUN go test -v ./...

# Optional: build a test binary artifact
RUN go build -o cors-regex-test-build .

# This image is only for CI/build checks. Runtime testing happens via docker-compose with Traefik local mode.
