# Testing Infrastructure

This directory contains comprehensive testing setups for the CORS Regex Plugin in different modes.

## Test Modes

### 🔧 Local Mode (`local-mode/`)
- **Purpose**: Development and debugging
- **Plugin Source**: Live source code (mounted as volume)
- **Configuration**: `localPlugins` in Traefik
- **Speed**: Fast (no downloads)
- **Use Case**: Active development, feature testing, debugging

### 🚀 Plugin Catalog Mode (`plugin-catalog-test/`)
- **Purpose**: Production validation
- **Plugin Source**: Published GitHub releases
- **Configuration**: `plugins` in Traefik (standard mode)
- **Speed**: Slower (downloads plugin)
- **Use Case**: Release validation, production testing

## Quick Start

```bash
# Run all available tests
make test-all

# Run only local mode tests (development)
make docker-test

# Run only plugin catalog tests (requires published plugin)
make plugin-catalog-test

# Clean all test environments
make clean-all
```

### Manual Testing

```bash
# Local mode testing
cd tests/local-mode
docker compose up -d
docker exec cors-plugin-tester sh /tests/test.sh
docker compose down

# Plugin catalog testing  
cd tests/plugin-catalog-test
docker compose up -d
docker exec plugin-catalog-tester sh /tests/plugin-catalog-test.sh
docker compose down
```

## Test Scenarios

The test suite covers:

### Allowed Origins
- `https://example.com` - Exact match
- `https://api.example.com` - Wildcard match (`https://*.example.com`)
- `https://www.example.com` - Wildcard match (`https://*.example.com`)
- `https://api.example.org` - Exact match

### Blocked Origins
- `https://malicious.com` - Not in allowlist

### Preflight Requests
- OPTIONS requests with proper CORS headers
- Validation of preflight response headers

### CORS Headers Validation
- Access-Control-Allow-Methods
- Access-Control-Allow-Headers
- Access-Control-Allow-Credentials
- Access-Control-Max-Age

## Network Configuration

Tests run inside Docker network using internal addresses:
- **Traefik**: `traefik-with-cors-plugin:80` (web), `:9000` (dashboard)
- **Test App**: `test-app:80`
- **Host header**: `localhost` (required for Traefik routing)

## Debugging

Enable plugin debug logging by setting `debug: true` in the middleware configuration (already enabled in the compose file).

View logs:
```bash
cd build
docker compose logs traefik | grep CORS-REGEX
```
