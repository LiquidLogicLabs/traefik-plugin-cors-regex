# Release Checklist

Use this checklist before creating a new release to ensure all requirements are met.

## 🔍 Pre-Release Validation

### ✅ Repository Requirements
- [ ] Repository is **public** (not private)
- [ ] Repository is **not a fork**
- [ ] Repository has `traefik-plugin` topic added in GitHub settings
- [ ] All changes are committed and pushed to `main` branch

### ✅ Plugin Requirements  
- [ ] `.traefik.yml` manifest exists with all required fields
- [ ] `go.mod` file exists and is valid
- [ ] Import path in `.traefik.yml` matches `go.mod` module path
- [ ] Plugin code follows Traefik plugin patterns
- [ ] Plugin has proper `New()` and `CreateConfig()` functions

### ✅ Testing Requirements
- [ ] All unit tests pass: `make test-unit`
- [ ] Local mode integration tests pass: `make local-test`
- [ ] Plugin validation workflow passes: Check GitHub Actions
- [ ] Manual testing with real Traefik instance completed

### ✅ Documentation Requirements
- [ ] `README.md` updated with latest features and examples
- [ ] `CHANGELOG.md` updated with version changes
- [ ] Code comments are comprehensive
- [ ] Configuration examples are accurate

### ✅ Dependencies Requirements
- [ ] `go mod tidy` has been run
- [ ] No security vulnerabilities in dependencies
- [ ] Dependencies are minimal and necessary
- [ ] Vendor directory will be auto-created during release

## 🚀 Release Process

### 1. **Validate Everything**
```bash
# Run all tests
make test-all

# Check plugin validation
# (GitHub Actions will run this automatically)
```

### 2. **Update Version and Release**
```bash
# Interactive release (recommended)
make release

# OR manual version bump
make version-patch  # or version-minor, version-major
git tag v$(cat VERSION)
git push origin main && git push origin v$(cat VERSION)
```

### 3. **Verify Release**
- [ ] GitHub release was created successfully
- [ ] Release includes vendor.tar.gz
- [ ] Release notes are generated correctly
- [ ] All CI/CD workflows completed successfully

### 4. **Plugin Catalog Submission**
- [ ] Repository topic `traefik-plugin` is set
- [ ] Wait ~30 minutes for automatic discovery
- [ ] Check [plugins.traefik.io](https://plugins.traefik.io/) for plugin appearance
- [ ] Test plugin installation from catalog (optional)

## 🧪 Post-Release Testing

### Test Plugin from Catalog
```bash
# Test the released version
make catalog-test
```

### Manual Verification
1. Create a new Traefik instance
2. Configure plugin from catalog:
   ```yaml
   experimental:
     plugins:
       cors-regex:
         modulename: github.com/liquidlogiclabs/traefik-plugin-cors-regex
         version: v0.1.1  # Use your release version
   ```
3. Test CORS functionality
4. Verify wildcard patterns work correctly

## 🚨 Troubleshooting

### Plugin Not Appearing in Catalog
- Check repository has `traefik-plugin` topic
- Verify `.traefik.yml` is valid
- Ensure repository is public and not a fork
- Wait up to 60 minutes for discovery
- Check for issues created in your repository by Plugin Catalog

### Release Failed
- Check GitHub Actions logs
- Verify all tests pass locally
- Ensure clean git state before tagging
- Check vendor directory creation

### Plugin Loading Issues
- Verify import path matches exactly
- Check for Go version compatibility
- Ensure all dependencies are vendored
- Test with `testData` configuration from `.traefik.yml`

## 📚 References

- [Traefik Plugin Development](https://plugins.traefik.io/create)
- [Plugin Catalog Submission](https://plugins.traefik.io/)
- [Traefik Local Plugin Mode](https://doc.traefik.io/traefik/plugins/)
