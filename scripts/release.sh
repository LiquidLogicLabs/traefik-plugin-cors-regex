#!/bin/bash
set -e

# Traefik Plugin Release Script
# This script prepares and creates a new release

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo_error "Not in a git repository"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo_warning "There are uncommitted changes:"
    git status --short
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo_error "Aborting due to uncommitted changes"
        exit 1
    fi
fi

# Get current version
CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "0.0.0")
echo_info "Current version: $CURRENT_VERSION"

# Determine release type
echo "Select release type:"
echo "1) Patch (${CURRENT_VERSION} -> patch increment)"
echo "2) Minor (${CURRENT_VERSION} -> minor increment)"  
echo "3) Major (${CURRENT_VERSION} -> major increment)"
echo "4) Custom version"

read -p "Enter choice (1-4): " -n 1 -r
echo

case $REPLY in
    1)
        echo_info "Creating patch release..."
        make version-patch
        ;;
    2)
        echo_info "Creating minor release..."
        make version-minor
        ;;
    3)
        echo_info "Creating major release..."
        make version-major
        ;;
    4)
        read -p "Enter custom version (without 'v' prefix): " CUSTOM_VERSION
        echo "$CUSTOM_VERSION" > VERSION
        ;;
    *)
        echo_error "Invalid choice"
        exit 1
        ;;
esac

NEW_VERSION=$(cat VERSION)
echo_success "New version: $NEW_VERSION"

# Validate plugin requirements
echo_info "Validating plugin requirements..."
if [ ! -f ".traefik.yml" ]; then
    echo_error ".traefik.yml manifest file is missing"
    exit 1
fi

if [ ! -f "go.mod" ]; then
    echo_error "go.mod file is missing"
    exit 1
fi

# Run tests
echo_info "Running unit tests..."
if ! make test-unit; then
    echo_error "Unit tests failed"
    exit 1
fi

echo_info "Running local mode integration tests..."
if ! make local-test; then
    echo_error "Local mode tests failed"
    exit 1
fi

echo_success "All tests passed"

# Check plugin catalog requirements
echo_info "Checking Plugin Catalog requirements..."
echo_warning "Manual checks required:"
echo "  📌 Repository topic 'traefik-plugin' must be added in GitHub settings"
echo "  📌 Repository must be public and not a fork"
read -p "Have you completed these manual requirements? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo_error "Please complete manual requirements first"
    echo_info "See RELEASE_CHECKLIST.md for details"
    exit 1
fi

# Verify go.mod and dependencies
echo_info "Verifying dependencies..."
go mod tidy
go mod verify

# Create vendor directory (required for Traefik Plugin Catalog)
echo_info "Creating vendor directory..."
go mod vendor

# Commit version changes
echo_info "Committing version update..."
git add VERSION go.mod go.sum vendor/
git commit -m "chore: bump version to v${NEW_VERSION}"

# Create and push tag
TAG="v${NEW_VERSION}"
echo_info "Creating tag: $TAG"
git tag -a "$TAG" -m "Release $TAG"

# Push changes and tag
echo_info "Pushing changes and tag..."
git push origin main
git push origin "$TAG"

echo_success "Release $TAG created and pushed!"
echo_info "GitHub Actions will automatically create the release"
echo_info "Monitor the release at: https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/releases"

# Cleanup vendor directory (optional, keep for development)
read -p "Remove vendor directory from working tree? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf vendor/
    echo_info "Vendor directory removed from working tree"
else
    echo_info "Vendor directory kept for development"
fi

echo ""
echo_success "Release process completed!"
echo_info "Next steps:"
echo "  1. Monitor GitHub Actions: https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/actions"
echo "  2. Check release: https://github.com/liquidlogiclabs/traefik-plugin-cors-regex/releases"
echo "  3. Plugin will be discoverable by Traefik Plugin Catalog automatically"
echo "  4. Monitor inclusion at: https://plugins.traefik.io/"
