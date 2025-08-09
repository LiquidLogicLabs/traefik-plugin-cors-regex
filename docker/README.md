# Docker Testing Setup

This directory contains the Docker configuration for testing the CORS regex plugin with Traefik.

## Overview

The Docker setup creates a complete test environment that includes:

1. **Traefik** - Loaded with our CORS regex plugin
2. **Test Application** - Nginx-based test app that returns JSON responses
3. **Test Scripts** - Automated testing of CORS functionality

## Files

- `Dockerfile` - Multi-stage build for Traefik with our plugin
- `docker-compose.yml` - Complete test environment setup
- `traefik.yml` - Traefik configuration
- `dynamic.yml` - Dynamic configuration for routes and middleware
- `nginx.conf` - Nginx configuration for test app
- `test.sh` - Comprehensive CORS testing script
- `run-tests.sh` - Test runner script

## Quick Start

### Prerequisites

- Docker
- Docker Compose

### Running Tests

1. **Build and test with Docker Compose:**
   ```bash
   make docker-test
   ```

2. **Manual testing:**
   ```bash
   # Start the services
   docker compose up -d
   
   # Wait for services to be ready
   sleep 10
   
   # Run tests
   docker exec traefik-with-cors-plugin /usr/local/bin/test.sh
   
   # Clean up
   docker compose down
   ```

3. **Interactive testing:**
   ```bash
   # Start services
   docker compose up -d
   
   # Test CORS manually
   curl -H "Origin: https://example.com" http://localhost:8989/api/test
   
   # Check Traefik dashboard
   open http://localhost:8990
   ```

## Ports

- **8989** - Traefik main service (HTTP)
- **8990** - Traefik dashboard (HTTP)
- **8991** - Test application (HTTP)

## Test Scenarios

The test suite covers:

### Allowed Origins
- `https://example.com` - Exact match
- `https://api.example.com` - Wildcard match
- `https://sub.example.com` - Wildcard match
- `https://api.example.org` - Exact match

### Blocked Origins
- `https://example.org` - Not in allowlist
- `https://malicious.com` - Not in allowlist
- `http://example.com` - Wrong protocol

### Preflight Requests
- OPTIONS requests for allowed origins
- CORS headers in responses

## Configuration

### Plugin Configuration

The plugin is configured in `docker/dynamic.yml`:

```yaml
http:
  middlewares:
    cors-regex:
      plugin:
        cors-regex:
          allowOriginList:
            - "https://example.com"
            - "https://*.example.com"
            - "https://api.example.org"
          allowMethods:
            - "GET"
            - "POST"
            - "PUT"
            - "DELETE"
            - "OPTIONS"
          allowHeaders:
            - "Origin"
            - "Content-Type"
            - "Accept"
            - "Authorization"
          exposeHeaders:
            - "X-Custom-Header"
          allowCredentials: true
          maxAge: 86400
```

### Traefik Configuration

The main Traefik configuration is in `docker/traefik.yml`:

```yaml
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  dashboard:
    address: ":8080"

providers:
  file:
    directory: /etc/traefik/conf
    watch: true
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false

log:
  level: INFO

accessLog: {}
```

## Testing Commands

### Manual Testing

1. **Test allowed origin:**
   ```bash
   curl -H "Origin: https://example.com" http://localhost:8989/api/test
   ```

2. **Test blocked origin:**
   ```bash
   curl -H "Origin: https://malicious.com" http://localhost:8989/api/test
   ```

3. **Test preflight request:**
   ```bash
   curl -X OPTIONS \
     -H "Origin: https://example.com" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type" \
     http://localhost:8989/api/test
   ```

4. **Check CORS headers:**
   ```bash
   curl -I -H "Origin: https://example.com" http://localhost:8989/api/test
   ```

### Automated Testing

The test script (`docker/test.sh`) automatically:

1. Waits for Traefik to be ready
2. Tests all configured origins
3. Verifies CORS headers
4. Tests preflight requests
5. Reports results

## Troubleshooting

### Common Issues

1. **Traefik not starting:**
   - Check Docker logs: `docker compose logs traefik`
   - Verify plugin binary exists: `docker exec traefik-with-cors-plugin ls -la /etc/traefik/plugins/`

2. **Plugin not loading:**
   - Check Traefik configuration syntax
   - Verify plugin binary is executable
   - Check Traefik logs for plugin errors

3. **CORS not working:**
   - Verify origin is in allowlist
   - Check request headers
   - Review plugin configuration

### Debug Commands

```bash
# Check Traefik status
docker exec traefik-with-cors-plugin curl -s http://localhost:8080/ping

# View Traefik logs
docker compose logs -f traefik

# Check plugin binary
docker exec traefik-with-cors-plugin ls -la /etc/traefik/plugins/

# Test plugin directly
docker exec traefik-with-cors-plugin /etc/traefik/plugins/cors-regex-plugin
```

## Development

### Adding New Tests

1. Edit `docker/test.sh` to add new test cases
2. Update `docker/dynamic.yml` for new configurations
3. Test with `make docker-test`

### Modifying Configuration

1. Update `docker/traefik.yml` for Traefik changes
2. Update `docker/dynamic.yml` for plugin configuration
3. Rebuild with `make docker`

### Custom Test App

To use a custom test application:

1. Replace the nginx service in `docker-compose.yml`
2. Update the service URL in `docker/dynamic.yml`
3. Modify test scripts as needed

## Cleanup

```bash
# Stop and remove containers
docker compose down

# Remove images
docker rmi liquidlogiclabs/traefik-plugin-cors-regex:latest

# Clean everything
make docker-clean
```
