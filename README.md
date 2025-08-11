# CORS Regex Plugin

A Traefik plugin that adds support for regex and wildcard domains in the `Access-Control-Allow-Origin` header for CORS (Cross-Origin Resource Sharing).

## Features

- **Wildcard Domain Support**: Use `*` wildcards in domain patterns (e.g., `https://*.example.com`)
- **Regex Pattern Support**: Full regex pattern matching for complex origin rules
- **Multiple Origin Patterns**: Configure multiple allowed origins with different patterns
- **Standard CORS Headers**: Support for all standard CORS headers
- **Preflight Request Handling**: Automatic handling of OPTIONS preflight requests
- **Debug Logging**: Optional debug logging for troubleshooting CORS issues
- **Local Mode Support**: Supports Traefik's local plugin mode for development

## Installation

### Traefik Plugin Catalog (Recommended)

The plugin will be available in the official Traefik Plugin Catalog. Add it to your Traefik configuration:

```yaml
# traefik.yml
experimental:
  plugins:
    cors-regex:
      modulename: github.com/liquidlogiclabs/traefik-plugin-cors-regex
      version: v0.1.1
```

### Manual Installation

If installing manually, ensure the plugin is properly configured in your Traefik setup according to the [Traefik plugin documentation](https://doc.traefik.io/traefik/plugins/).

## Configuration

### YAML Configuration

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
          debug: true  # Optional: Enable debug logging
```

### Docker Labels Configuration

```yaml
# Using Docker labels (recommended for Docker deployments)
services:
  my-app:
    image: my-app:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.my-app.rule=Host(`localhost`)"
      - "traefik.http.routers.my-app.middlewares=cors-regex"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.alloworiginlist=https://example.com,https://*.example.com"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowmethods=GET,POST,PUT,DELETE,OPTIONS"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowheaders=Origin,Content-Type,Accept,Authorization"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.allowcredentials=true"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.maxage=86400"
      - "traefik.http.middlewares.cors-regex.plugin.cors-regex.debug=true"
```

## Pattern Examples

### Wildcard Patterns

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `https://*.example.com` | `https://api.example.com`, `https://www.example.com` | `https://example.com`, `https://api.example.org` |
| `https://api.*.example.com` | `https://api.prod.example.com`, `https://api.dev.example.com` | `https://api.example.com`, `https://web.prod.example.com` |

### Regex Patterns

| Pattern | Matches | Doesn't Match |
|---------|---------|---------------|
| `https://.*\\.test\\.com` | `https://api.test.com`, `https://www.test.com` | `https://test.com`, `https://api.test.org` |
| `https://(dev|staging|prod)\\.app\\.com` | `https://dev.app.com`, `https://staging.app.com` | `https://test.app.com`, `https://dev.app.org` |

## Configuration Options

| Option | Type | Description | Example |
|--------|------|-------------|---------|
| `allowOriginList` | []string | List of allowed origins (supports wildcards and regex) | `["https://example.com", "https://*.example.com"]` |
| `allowMethods` | []string | Allowed HTTP methods | `["GET", "POST", "PUT", "DELETE", "OPTIONS"]` |
| `allowHeaders` | []string | Allowed request headers | `["Origin", "Content-Type", "Accept", "Authorization"]` |
| `exposeHeaders` | []string | Headers to expose to the client | `["X-Custom-Header"]` |
| `allowCredentials` | bool | Whether to allow credentials | `true` |
| `maxAge` | int | Maximum age for preflight requests (seconds) | `86400` |
| `debug` | bool | Enable debug logging (optional) | `true` |

## Troubleshooting

### Common Issues

**CORS requests are blocked:**
1. Verify your origin patterns match exactly
2. Check that the middleware is properly attached to your routes
3. Enable debug logging to see detailed matching information

**Wildcard patterns not working:**
- Use `*` for subdomain wildcards: `https://*.example.com`
- The plugin returns the actual requesting origin for wildcard matches (CORS compliant)

**Debug logging:**
Set `debug: true` in your configuration to see detailed logs about pattern matching and CORS decisions.

## Development

For development setup, testing, and contribution guidelines, see [README.dev.md](README.dev.md).

## Support

- **Documentation**: See [README.dev.md](README.dev.md) for development and troubleshooting
- **Issues**: Report bugs or request features on [GitHub Issues](https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/discussions)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
