# Plugin Catalog Test

This test suite validates the CORS Regex Plugin when used in standard Traefik mode via the Plugin Catalog (not local mode).

## Purpose

This test ensures that:
1. The plugin loads correctly from the Traefik Plugin Catalog
2. CORS functionality works identically to local mode
3. The wildcard pattern fix is working in production mode
4. Plugin integration with standard Traefik is successful

## Differences from Local Mode Test

| Aspect | Local Mode Test | Plugin Catalog Test |
|--------|-----------------|-------------------|
| Plugin Loading | Mounts source code | Downloads from catalog |
| Configuration | `localPlugins` | `plugins` |
| Source | File system | GitHub release |
| Use Case | Development | Production |

## Prerequisites

For this test to work, the plugin must be:
1. **Published**: Available as a GitHub release with proper tags
2. **Vendored**: Dependencies included in the release
3. **Catalog Listed**: Available in Traefik Plugin Catalog (or GitHub release available)

## Running the Test

### Manual Test (requires published plugin)

```bash
# Run plugin catalog test (requires published version)
make plugin-catalog-test

# Clean up test environment
make plugin-catalog-clean
```

### Development Test (before publishing)

Since the plugin may not be published yet, you can modify the test to use a specific version or simulate catalog behavior:

1. **Update Version**: Edit `docker-compose.yml` and `traefik-catalog.yml` to use your target version
2. **Test Locally**: Ensure your plugin code is committed and tagged

```bash
# Create a local tag for testing
git tag v0.1.1
git push origin v0.1.1

# Run the test
make plugin-catalog-test
```

## Test Coverage

The plugin catalog test covers:

1. **Plugin Loading**: Verifies plugin loads from catalog, not local source
2. **Exact Origin Matching**: Standard CORS origin validation
3. **Wildcard Patterns**: Confirms wildcard fix works in production
4. **Origin Blocking**: Validates rejected origins
5. **Preflight Requests**: OPTIONS request handling
6. **Mode Verification**: Confirms we're in catalog mode, not local mode

## Expected Results

All tests should pass, demonstrating:
- ✅ Plugin successfully loaded from catalog
- ✅ CORS headers set correctly
- ✅ Wildcard patterns return actual origins (not patterns)
- ✅ Blocked origins properly rejected
- ✅ Preflight requests handled correctly

## Troubleshooting

### Plugin Not Found
```
Error: plugin cors-regex not found
```
**Solution**: Ensure the plugin version exists in your repository releases.

### Version Mismatch
```
Error: version v0.1.1 not found
```
**Solution**: Update the version in both `docker-compose.yml` and `traefik-catalog.yml` to match your published release.

### Traefik Fails to Start
```
Error: failed to initialize plugin cors-regex
```
**Solution**: Check that:
1. The plugin is properly tagged in GitHub
2. Dependencies are vendored in the release
3. The `.traefik.yml` manifest is valid

## Integration with CI/CD

This test should be run:
- **After each release** to verify plugin catalog integration
- **Before publishing** to catch issues early
- **In production environments** to validate plugin behavior

The test can be integrated into GitHub Actions:

```yaml
- name: Test Plugin Catalog Mode
  run: make plugin-catalog-test
```

## Files

- `docker-compose.yml`: Service definitions for catalog mode testing
- `traefik-catalog.yml`: Traefik config for plugin catalog mode
- `plugin-catalog-test.sh`: Test script with catalog-specific validations
- `README.md`: This documentation
