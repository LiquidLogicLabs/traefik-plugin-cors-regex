# Local Mode Test

This test suite validates the CORS Regex Plugin using Traefik's local plugin mode for development.

## Purpose

This test ensures that:
1. The plugin loads correctly from local source code
2. CORS functionality works as expected during development
3. All wildcard patterns and regex functionality operate correctly
4. Debug logging works properly
5. Integration with Traefik local mode is successful

## Local Mode vs Plugin Catalog

| Aspect | Local Mode Test | Plugin Catalog Test |
|--------|-----------------|-------------------|
| **Plugin Loading** | Mounts source code from filesystem | Downloads from GitHub releases |
| **Configuration** | `localPlugins` in traefik.yml | `plugins` in traefik.yml |
| **Source** | Live code changes | Published releases |
| **Use Case** | Development & testing | Production validation |
| **Speed** | Fast (no download) | Slower (download required) |
| **Dependencies** | Live go.mod | Vendored dependencies |

## Files

- **`docker-compose.yml`**: Service definitions for local mode testing
- **`Dockerfile`**: Build container for the plugin (if needed)
- **`test.sh`**: Comprehensive CORS functionality test script
- **`run-tests.sh`**: Test runner that manages the Docker environment
- **`README.md`**: This documentation

## Running the Tests

### Quick Test
```bash
# From project root
make docker-test
```

### Manual Testing
```bash
# From project root
cd tests/local-mode

# Start services
docker compose up -d

# Run tests manually
docker exec cors-plugin-tester sh /tests/test.sh

# View logs
docker compose logs traefik --follow

# Clean up
docker compose down -v
```

### Development Workflow
```bash
# Make code changes to cors_regex.go
# Tests automatically use the latest code (mounted as volume)
make docker-test

# Or for continuous development
cd tests/local-mode
docker compose up traefik test-app  # Keep services running
# In another terminal, run tests repeatedly:
docker compose restart tester
```

## Test Coverage

The local mode test covers:

1. **Plugin Loading**: Verifies plugin loads from mounted source code
2. **Exact Origin Matching**: Standard CORS origin validation
3. **Wildcard Patterns**: `https://*.example.com` matching `https://api.example.com`
4. **Regex Patterns**: Full regex pattern support
5. **Origin Blocking**: Validates rejected origins don't get CORS headers
6. **Preflight Requests**: OPTIONS request handling with all headers
7. **Debug Logging**: Verifies debug output when enabled
8. **Header Validation**: All required CORS headers present

## Configuration

The test uses the following key configurations:

### Traefik Configuration (`../../config/traefik.yml`)
```yaml
experimental:
  localPlugins:
    cors-regex:
      moduleName: github.com/liquidlogiclabs/traefik-plugin-cors-regex
```

### Plugin Configuration (Docker labels)
```yaml
- "traefik.http.middlewares.cors-regex.plugin.cors-regex.alloworiginlist=https://example.com,https://*.example.com,https://api.example.org"
- "traefik.http.middlewares.cors-regex.plugin.cors-regex.debug=true"
```

## Test Scenarios

1. **Test 1**: Exact origin match (`https://example.com`)
2. **Test 2**: Wildcard pattern match (`https://api.example.com` via `https://*.example.com`)
3. **Test 3**: Another wildcard match (`https://www.example.com` via `https://*.example.com`)
4. **Test 4**: Different exact match (`https://api.example.org`)
5. **Test 5**: Blocked origin (`https://malicious.com`)
6. **Test 6**: Preflight OPTIONS request
7. **Test 7**: CORS headers presence validation

## Expected Results

All tests should pass with output like:
```
🚀 Starting CORS Regex Plugin tests...
✅ Traefik is ready!
✅ Test app is ready!

🧪 Running CORS tests...
Test 1: Allowed origin (exact match)
   ✅ PASS: Origin https://example.com is allowed
Test 2: Allowed origin (wildcard match)
   ✅ PASS: Origin https://api.example.com is allowed via wildcard
...
✨ CORS Regex Plugin tests completed!
```

## Debug and Troubleshooting

### View Plugin Debug Logs
```bash
cd tests/local-mode
docker compose logs traefik | grep CORS-REGEX
```

### Common Issues

**Plugin not loading:**
```
Error: plugin cors-regex not found
```
**Solution**: Check that the source code is properly mounted and the go.mod file is valid.

**CORS headers missing:**
```
Access-Control-Allow-Origin header not found
```
**Solution**: Check plugin configuration and ensure middleware is attached to the route.

**Test timeouts:**
```
Traefik failed to start within timeout
```
**Solution**: Increase timeout or check Docker logs for startup errors.

## Integration with Development

This test is ideal for:
- **Active development**: Live code changes are immediately testable
- **Debugging**: Debug logging shows real-time plugin behavior  
- **Feature testing**: New CORS patterns can be validated quickly
- **Regression testing**: Ensure changes don't break existing functionality

The local mode test should be your primary testing method during development, with plugin catalog tests reserved for final validation before release.
