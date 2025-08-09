# Development Guide

This document provides information for developers working on the Traefik CORS Regex Plugin.

## Prerequisites

- Go 1.21 or later
- Docker (for containerized builds)
- Make (optional, for using Makefile)
- Git

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

### 3. Install Development Tools

```bash
make install-tools
```

## Development Workflow

### Running Tests

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run specific test
go test ./src/... -v -run TestNew_InvalidWildcardPattern
```

### Building

```bash
# Build for all platforms
make build

# Build for specific platform
GOOS=linux GOARCH=amd64 go build -o cors-regex-plugin ./src/

# Build with Docker
make docker
```

### Code Quality

```bash
# Format code
make fmt

# Run linter
make lint

# Run all quality checks
make dev
```

## Project Structure

```
.
├── src/                    # Source code
│   ├── cors_regex.go      # Main plugin implementation
│   └── cors_regex_test.go # Tests
├── scripts/               # Build and deployment scripts
│   └── build.sh          # Main build script
├── .github/              # GitHub Actions workflows
│   └── workflows/
│       └── ci.yml        # CI/CD pipeline
├── docker/               # Docker-related files
├── Makefile              # Build automation
├── go.mod                # Go module definition
├── VERSION               # Current version
├── .traefik.yml          # Plugin manifest
├── README.md             # User documentation
└── README.dev.md         # This file
```

## Plugin Architecture

### Core Components

1. **Config**: Plugin configuration structure
2. **CORSRegex**: Main plugin handler
3. **New**: Plugin factory function
4. **CreateConfig**: Default configuration creator

### Key Features

- **Wildcard Support**: `https://*.example.com`
- **Regex Support**: `https://.*\.test\.com`
- **Multiple Patterns**: Support for multiple origin patterns
- **CORS Headers**: Full CORS header support
- **Preflight Handling**: Automatic OPTIONS request handling

## Testing Strategy

### Unit Tests

- Configuration validation
- Regex pattern compilation
- CORS header generation
- Origin matching logic
- Error handling

### Integration Tests

- Full HTTP request/response cycle
- Multiple origin patterns
- Complex regex patterns
- Edge cases

### Test Coverage

Target: >95% code coverage

```bash
# Generate coverage report
go test ./src/... -v -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html
```

## Version Management

### Version Increment

```bash
# Increment patch version (0.1.0 -> 0.1.1)
make increment-patch

# Increment minor version (0.1.0 -> 0.2.0)
make increment-minor

# Increment major version (0.1.0 -> 1.0.0)
make increment-major
```

### Release Process

1. Update version in `VERSION` file
2. Update changelog
3. Create git tag
4. Push to trigger release workflow

```bash
# Create and push tag
git tag v0.1.0
git push origin v0.1.0
```

## Docker Development

### Local Docker Build

```bash
# Build Docker image
make docker

# Run container for testing
docker run --rm -it liquidlogiclabs/traefik-plugin-cors-regex:latest
```

### Multi-stage Build

The Dockerfile uses multi-stage builds:
1. **Builder stage**: Compiles the Go code
2. **Final stage**: Minimal Alpine image with binary

## CI/CD Pipeline

### GitHub Actions Workflows

- **Test**: Runs unit tests and coverage
- **Build**: Compiles for multiple platforms
- **Docker**: Builds and pushes Docker images
- **Release**: Creates release artifacts
- **Security**: Runs vulnerability scans

### Local Testing with Act

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
   - Proper schema definition

3. **Versioning**:
   - Must be versioned with git tags
   - Dependencies must be vendored

### Testing Plugin Catalog Integration

```bash
# Test manifest validation
# (This would be done by the Plugin Catalog system)
```

## Debugging

### Local Plugin Testing

```bash
# Build plugin
go build -o cors-regex-plugin ./src/

# Test with Traefik (local mode)
# Add to traefik.yml:
# experimental:
#   plugins:
#     cors-regex:
#       modulename: github.com/liquidlogiclabs/traefik-plugin-cors-regex
#       version: v0.1.0
```

### Logging

The plugin uses standard Go logging. For debugging:

```go
import "log"

log.Printf("Processing request from origin: %s", origin)
```

## Performance Considerations

### Optimization Strategies

1. **Compiled Regex**: Patterns are compiled once at startup
2. **Efficient Matching**: Uses compiled regex for origin matching
3. **Minimal Allocations**: Reuses header values where possible
4. **Fast Paths**: Early returns for common cases

### Benchmarking

```bash
# Run benchmarks
go test ./src/... -bench=.

# Memory profiling
go test ./src/... -bench=. -memprofile=mem.out
go tool pprof mem.out
```

## Security Considerations

### Input Validation

- All regex patterns are validated at startup
- Origin headers are properly sanitized
- No arbitrary code execution through patterns

### CORS Security

- Proper origin validation
- Secure header handling
- Credentials protection

## Contributing

### Code Style

- Follow Go best practices
- Use `gofmt` for formatting
- Run `golangci-lint` for linting
- Write comprehensive tests

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Run full test suite
5. Submit pull request

### Commit Messages

Use conventional commit format:

```
feat: add new regex pattern support
fix: resolve wildcard matching issue
docs: update configuration examples
test: add edge case coverage
```

## Troubleshooting

### Common Issues

1. **Build Failures**:
   - Check Go version compatibility
   - Verify all dependencies are downloaded
   - Check for syntax errors

2. **Test Failures**:
   - Run tests with verbose output
   - Check test data validity
   - Verify regex patterns

3. **Plugin Loading Issues**:
   - Verify `.traefik.yml` format
   - Check module path in configuration
   - Ensure proper version tagging

### Getting Help

- Check existing issues on GitHub
- Review test cases for examples
- Consult Traefik plugin documentation
- Create detailed issue reports

## Release Checklist

Before releasing a new version:

- [ ] All tests pass
- [ ] Code coverage >95%
- [ ] Documentation updated
- [ ] Version incremented
- [ ] Changelog updated
- [ ] Git tag created
- [ ] Docker image builds successfully
- [ ] Release artifacts generated
- [ ] Security scan passed

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
