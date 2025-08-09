# Build stage for the plugin
FROM golang:1.21-alpine AS builder

# Install git and ca-certificates
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod ./

# Download dependencies and generate go.sum
RUN go mod download && go mod tidy

# Copy source code
COPY src/ ./src/

# Build the plugin
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o cors-regex-plugin ./src/

# Test stage with Traefik
FROM traefik:latest

# Install necessary tools for testing
RUN apk add --no-cache curl jq

# Create directories for plugin and configuration
RUN mkdir -p /etc/traefik/plugins /etc/traefik/conf

# Copy the plugin binary
COPY --from=builder /app/cors-regex-plugin /etc/traefik/plugins/cors-regex-plugin

# Make the plugin executable
RUN chmod +x /etc/traefik/plugins/cors-regex-plugin

# Copy test configuration
COPY docker/traefik.yml /etc/traefik/traefik.yml
COPY docker/dynamic.yml /etc/traefik/dynamic.yml

# Copy test script
COPY docker/test.sh /usr/local/bin/test.sh
RUN chmod +x /usr/local/bin/test.sh

# Expose Traefik ports
EXPOSE 80 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ping || exit 1

# Default command runs Traefik with our plugin
CMD ["traefik", "--configfile=/etc/traefik/traefik.yml"]
