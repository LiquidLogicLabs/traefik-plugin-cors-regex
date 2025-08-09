# Traefik CORS Regex Plugin

A Traefik plugin that adds support for regex and wildcard domains in the `Access-Control-Allow-Origin` header for CORS (Cross-Origin Resource Sharing).

## Features

- **Wildcard Domain Support**: Use `*` wildcards in domain patterns (e.g., `https://*.example.com`)
- **Regex Pattern Support**: Full regex pattern matching for complex origin rules
- **Multiple Origin Patterns**: Configure multiple allowed origins with different patterns
- **Standard CORS Headers**: Support for all standard CORS headers
- **Preflight Request Handling**: Automatic handling of OPTIONS preflight requests
- **Performance Optimized**: Compiled regex patterns for efficient matching

## Installation

### Using Docker

```bash
docker pull liquidlogiclabs/traefik-plugin-cors-regex:latest
```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/liquidlogiclabs/traefik-plugin-cors-regex.git
cd traefik-plugin-cors-regex

# Build the plugin
./scripts/build.sh build

# Or build with Docker
docker build -t cors-regex-plugin .
```

## Configuration

### Traefik Configuration

Add the plugin to your Traefik configuration:

```yaml
# traefik.yml
experimental:
  plugins:
    cors-regex:
      modulename: github.com/liquidlogiclabs/traefik-plugin-cors-regex
      version: v0.1.0
```

### Plugin Configuration

```yaml
# traefik.yml or dynamic configuration
http:
  middlewares:
    cors-regex:
      plugin:
        cors-regex:
          allowOriginList:
            - "https://example.com"
            - "https://*.example.com"
            - "https://api.example.org"
            - "https://.*\.test\.com"
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

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `allowOriginList` | `[]string` | `[]` | List of allowed origins (supports wildcards and regex) |
| `allowMethods` | `[]string` | `["GET", "POST", "PUT", "DELETE", "OPTIONS"]` | Allowed HTTP methods |
| `allowHeaders` | `[]string` | `["Origin", "Content-Type", "Accept", "Authorization"]` | Allowed request headers |
| `exposeHeaders` | `[]string` | `[]` | Headers to expose to the client |
| `allowCredentials` | `bool` | `false` | Whether to allow credentials |
| `maxAge` | `int` | `86400` | Maximum age for preflight requests (in seconds) |

## Usage Examples

### Basic Configuration

```yaml
http:
  middlewares:
    cors-basic:
      plugin:
        cors-regex:
          allowOriginList:
            - "https://example.com"
            - "https://*.example.com"
          allowMethods:
            - "GET"
            - "POST"
          allowHeaders:
            - "Content-Type"
            - "Authorization"
```

### Advanced Configuration with Regex

```yaml
http:
  middlewares:
    cors-advanced:
      plugin:
        cors-regex:
          allowOriginList:
            - "https://example.com"
            - "https://*.example.com"
            - "https://api.*.example.com"
            - "https://.*\.test\.com"
            - "https://(dev|staging|prod)\.app\.com"
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
            - "X-API-Key"
          exposeHeaders:
            - "X-Total-Count"
            - "X-Page-Count"
          allowCredentials: true
          maxAge: 3600
```

### Docker Compose Example

```yaml
version: '3.8'

services:
  traefik:
    image: traefik:v3.0
    command:
      - --api.insecure=true
      - --providers.docker=true
      - --experimental.plugins.cors-regex.modulename=github.com/liquidlogiclabs/traefik-plugin-cors-regex
      - --experimental.plugins.cors-regex.version=v0.1.0
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik.yml:/etc/traefik/traefik.yml

  app:
    image: your-app:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`api.example.com`)"
      - "traefik.http.routers.app.middlewares=cors-regex"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.alloworiginlist=https://*.example.com"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowmethods=GET,POST,PUT,DELETE,OPTIONS"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowheaders=Origin,Content-Type,Accept,Authorization"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowcredentials=true"
```

## Pattern Examples

### Wildcard Patterns

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `https://*.example.com` | `https://api.example.com`, `https://www.example.com` | `https://example.com`, `https://api.example.org` |
| `https://api.*.example.com` | `https://api.prod.example.com`, `https://api.dev.example.com` | `https://api.example.com`, `https://web.prod.example.com` |
| `https://*.sub.example.com` | `https://test.sub.example.com`, `https://api.sub.example.com` | `https://sub.example.com`, `https://test.example.com` |

### Regex Patterns

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `https://.*\.test\.com` | `https://api.test.com`, `https://www.test.com` | `https://test.com`, `https://api.test.org` |
| `https://(dev|staging|prod)\.app\.com` | `https://dev.app.com`, `https://staging.app.com` | `https://test.app.com`, `https://dev.app.org` |
| `https://api-[0-9]+\.example\.com` | `https://api-1.example.com`, `https://api-123.example.com` | `https://api.example.com`, `https://api-test.example.com` |

## Development

### Prerequisites

- Go 1.21 or later
- Docker (for containerized builds)
- Make (optional, for using Makefile)

### Building

```bash
# Run tests
./scripts/build.sh test

# Build plugin
./scripts/build.sh build

# Build Docker image
./scripts/build.sh docker

# Create release artifacts
./scripts/build.sh release

# Run all steps
./scripts/build.sh all
```

### Running Tests

```bash
# Run all tests
go test ./src/... -v

# Run tests with coverage
go test ./src/... -v -coverprofile=coverage.out

# View coverage report
go tool cover -html=coverage.out
```

### Local Development

```bash
# Install dependencies
go mod download

# Run tests
go test ./src/... -v

# Build for local testing
go build -o cors-regex-plugin ./src/
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Go best practices and conventions
- Write comprehensive tests for new features
- Update documentation for any configuration changes
- Ensure all tests pass before submitting PRs

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/issues)
- **Discussions**: [GitHub Discussions](https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/discussions)
- **Documentation**: [GitHub Wiki](https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/wiki)

## Changelog

### v0.1.0
- Initial release
- Support for wildcard domain patterns
- Support for regex patterns
- Standard CORS header support
- Preflight request handling
- Comprehensive test coverage
