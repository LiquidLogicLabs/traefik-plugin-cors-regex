# Development Guide

This document provides information for developers working on the Traefik CORS Regex Plugin.

## Prerequisites

- Go 1.21 or later
- Git
- Docker and Docker Compose (for testing)
- Make (for build automation)

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/liquidlogiclabs/traefik-plugin-cors-regex.git
cd traefik-plugin-cors-regex
```

### 2. Install Dependencies

```bash
go mod download
```

## Quick Start

### Run Complete Test Suite

```bash
# Run all tests (unit + integration)
make test && make docker-test
```

### Local Development Environment

```bash
# Start Traefik with the plugin in local mode
make docker-test

# In another terminal, test manually
curl -H "Origin: https://example.com" -H "Host: localhost" http://localhost:8989/test
curl -H "Origin: https://api.example.com" -H "Host: localhost" http://localhost:8989/test
```

## Development Workflow

### Running Tests

```bash
# Run unit tests
make test

# Run integration tests with Docker
make docker-test

# Run tests with coverage
make test-coverage

# Run specific test
go test -v -run TestNew_InvalidWildcardPattern

# Clean Docker test environment
make docker-clean
```

### Building

```bash
# Build for current platform
make build

# Build manually
go build -o cors-regex-plugin

# Clean build artifacts
make clean
```

### Code Quality

```bash
# Format code
go fmt .

# Run linter (if golangci-lint is installed)
golangci-lint run
```

## Project Structure

```
.
├── cors_regex.go         # Main plugin implementation
├── cors_regex_test.go    # Unit tests
├── .traefik.yml          # Plugin manifest
├── go.mod                # Go module definition
├── VERSION               # Current version
├── Makefile              # Build automation
├── README.md             # User documentation
├── README.dev.md         # This file
├── build/                # Docker build files
│   ├── Dockerfile        # Multi-stage build for testing
│   └── docker-compose.yml # Development environment
├── config/               # Configuration files
│   ├── traefik.yml       # Traefik static configuration
│   ├── dynamic.yml       # Traefik dynamic configuration
│   └── nginx.conf        # Test app configuration
├── tests/                # Integration tests
│   ├── test.sh           # CORS functionality tests
│   ├── run-tests.sh      # Test runner script
│   └── README.md         # Testing documentation
└── .github/              # GitHub Actions workflows
    └── workflows/
        └── ci.yml        # CI pipeline
```

## Plugin Architecture

### Core Components

1. **Config**: Plugin configuration structure
2. **CORSRegex**: Main plugin handler
3. **New**: Plugin factory function

### Configuration

The plugin accepts the following configuration options:

- `allowOriginList`: List of allowed origins (supports wildcards and regex)
- `allowMethods`: Allowed HTTP methods
- `allowHeaders`: Allowed request headers
- `exposeHeaders`: Headers to expose to the client
- `allowCredentials`: Whether to allow credentials
- `maxAge`: Maximum age for preflight requests
- `debug`: Enable debug logging (optional)

## Testing

### Unit Tests

```bash
# Run all unit tests
make test

# Run tests with coverage
make test-coverage

# Run specific test
go test -v -run TestNew
```

### Integration Tests

The project includes Docker-based integration tests that validate the plugin in a real Traefik environment:

```bash
# Run integration tests
make docker-test

# View test output in real-time
docker compose -f build/docker-compose.yml logs tester --follow

# Clean up test environment
make docker-clean
```

### Test Coverage

The plugin has comprehensive test coverage including:

**Unit Tests:**
- Plugin initialization with valid/invalid configurations
- CORS header handling for allowed/blocked origins
- Preflight request handling
- Regex pattern compilation and matching
- Wildcard pattern conversion

**Integration Tests:**
- Real CORS requests through Traefik
- Wildcard pattern matching in production environment
- Debug logging verification
- Headers validation for different scenarios

## Local Development with Docker

### Development Environment

The project includes a complete Docker-based development environment:

```bash
# Start all services (Traefik + test app + automated tests)
make docker-test

# Start services without running tests (for manual testing)
cd build && docker compose up traefik test-app

# View real-time logs
docker compose -f build/docker-compose.yml logs traefik --follow
docker compose -f build/docker-compose.yml logs test-app --follow

# Clean up
make docker-clean
```

### Manual Testing

With the development environment running:

```bash
# Test different origins
curl -H "Origin: https://example.com" -H "Host: localhost" -v http://localhost:8989/test
curl -H "Origin: https://api.example.com" -H "Host: localhost" -v http://localhost:8989/test
curl -H "Origin: https://malicious.com" -H "Host: localhost" -v http://localhost:8989/test

# Test preflight requests
curl -X OPTIONS -H "Origin: https://example.com" -H "Host: localhost" -v http://localhost:8989/test

# Access Traefik dashboard
open http://localhost:8990
```

## Version Management

The project uses semantic versioning with automatic version incrementing:

```bash
# Show current version
make version

# Increment patch version (0.1.0 -> 0.1.1)
make version-patch

# Increment minor version (0.1.0 -> 0.2.0)
make version-minor

# Increment major version (0.1.0 -> 1.0.0)
make version-major
```

## CI/CD Pipeline

The project uses GitHub Actions for continuous integration:

- **Test**: Runs tests on every push and PR
- **Build**: Builds the plugin and uploads artifacts

### Running CI Locally

You can use `act` to run GitHub Actions locally:

```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run CI locally
act -j test
act -j build
```

## Plugin Catalog Integration

### Requirements for Plugin Catalog

1. **Repository Structure**:
   - Must not be a fork
   - Must have `traefik-plugin` topic
   - Must have valid `go.mod` file

2. **Manifest File**:
   - `.traefik.yml` with plugin metadata
   - Valid `testData` configuration

3. **Versioning**:
   - Must be versioned with git tags
   - Dependencies must be vendored

## Debugging

### Local Plugin Testing

The project includes a complete Docker-based development environment for testing with Traefik's local mode:

```bash
# Start development environment with debug logging
make docker-test

# View Traefik logs with debug output
docker compose -f build/docker-compose.yml logs traefik --follow

# View plugin-specific debug logs
docker compose -f build/docker-compose.yml logs traefik | grep CORS-REGEX

# Test individual endpoints
curl -H "Origin: https://example.com" -H "Host: localhost" http://localhost:8989/test
curl -H "Origin: https://api.example.com" -H "Host: localhost" http://localhost:8989/test
```

### Debug Output

When debug logging is enabled, the plugin outputs detailed information:

```
[CORS-REGEX-DEBUG] Initializing plugin name=cors-regex@docker allowOrigins=3
[CORS-REGEX-DEBUG] Origin pattern converted wildcard origin="https://*.example.com" regex="^https://.*\\.example\\.com$"
[CORS-REGEX-DEBUG] Processing request method=GET path=/test origin="https://api.example.com"
[CORS-REGEX-DEBUG] Wildcard/regex pattern matched, returning actual origin pattern="https://*.example.com" origin="https://api.example.com"
```

### Manual Testing Configuration

For manual testing, the plugin can be configured in Traefik's static configuration:

```yaml
# config/traefik.yml
experimental:
  localPlugins:
    cors-regex:
      moduleName: github.com/liquidlogiclabs/traefik-plugin-cors-regex
```

## Contributing

### Code Style

- Follow Go best practices and conventions
- Use `gofmt` for formatting: `go fmt ./...`
- Run linter: `golangci-lint run` (if available)
- Write comprehensive tests for new features
- Update documentation for any changes

### Development Workflow

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/traefik-plugin-cors-regex.git
   cd traefik-plugin-cors-regex
   ```

2. **Create Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make Changes**
   - Write code following Go best practices
   - Add/update unit tests: `make test`
   - Test with Docker environment: `make docker-test`

4. **Test Thoroughly**
   ```bash
   # Run all tests
   make test && make docker-test
   
   # Check test coverage
   make test-coverage
   ```

5. **Update Documentation**
   - Update README.md for user-facing changes
   - Update README.dev.md for development changes
   - Add examples if appropriate

6. **Submit Pull Request**
   - Push to your fork
   - Create a pull request with clear description
   - Ensure all CI checks pass

### Pull Request Guidelines

- **Title**: Clear, descriptive title
- **Description**: Explain what changes were made and why
- **Testing**: Describe how you tested the changes
- **Breaking Changes**: Clearly mark any breaking changes
- **Documentation**: Ensure documentation is updated

## License

This project is licensed under the MIT License.
