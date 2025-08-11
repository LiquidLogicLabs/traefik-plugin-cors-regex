# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Plugin catalog support and release automation
- Plugin catalog test suite for standard Traefik mode
- Automated release workflow with GitHub Actions
- Comprehensive test coverage for both local and catalog modes

## [0.1.1] - 2025-01-XX

### Fixed
- **BREAKING FIX**: Wildcard CORS patterns now correctly return the actual requesting origin instead of the pattern itself
- This ensures CORS compliance - when `https://*.example.com` matches `https://api.example.com`, the `Access-Control-Allow-Origin` header now contains `https://api.example.com` (correct) instead of `https://*.example.com` (incorrect)

### Added
- Debug logging capability with configurable `debug` option
- Comprehensive Docker-based testing infrastructure
- Integration tests for real Traefik environment testing
- Organized project structure with `build/`, `config/`, and `tests/` directories
- Enhanced documentation with separate user and developer guides

### Changed
- Improved plugin logging using standard output/error streams
- Refactored project structure for better organization
- Enhanced test coverage with both unit and integration tests

## [0.1.0] - 2025-01-XX

### Added
- Initial release of CORS Regex Plugin
- Support for wildcard domain patterns (e.g., `https://*.example.com`)
- Support for full regex patterns in CORS origins
- Multiple origin pattern support
- Standard CORS headers support:
  - `Access-Control-Allow-Origin`
  - `Access-Control-Allow-Methods`
  - `Access-Control-Allow-Headers`
  - `Access-Control-Expose-Headers`
  - `Access-Control-Allow-Credentials`
  - `Access-Control-Max-Age`
- Automatic preflight request (OPTIONS) handling
- Traefik local plugin mode support
- Comprehensive unit tests
- GitHub Actions CI pipeline

### Technical Details
- Go 1.21+ compatibility
- Traefik v3.0+ compatibility
- Plugin Catalog ready
- Docker-based development environment
