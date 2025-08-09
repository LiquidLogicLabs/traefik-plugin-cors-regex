#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLUGIN_NAME="cors-regex"
VERSION_FILE="$PROJECT_ROOT/VERSION"
DOCKER_IMAGE="liquidlogiclabs/traefik-plugin-cors-regex"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get version
get_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "0.1.0"
    fi
}

# Function to increment version
increment_version() {
    local version_type=$1
    local current_version=$(get_version)
    local major minor patch
    
    IFS='.' read -r major minor patch <<< "$current_version"
    
    case $version_type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            print_error "Invalid version type. Use: major, minor, or patch"
            exit 1
            ;;
    esac
    
    local new_version="$major.$minor.$patch"
    echo "$new_version" > "$VERSION_FILE"
    print_status "Version incremented to $new_version"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    cd "$PROJECT_ROOT"
    
    if ! go test ./src/... -v; then
        print_error "Tests failed"
        exit 1
    fi
    
    print_status "Tests passed"
}

# Function to build the plugin
build_plugin() {
    local version=$1
    print_status "Building plugin version $version..."
    
    cd "$PROJECT_ROOT"
    
    # Create build directory
    mkdir -p build
    
    # Build for multiple platforms
    local platforms=("linux/amd64" "linux/arm64" "darwin/amd64" "darwin/arm64")
    
    for platform in "${platforms[@]}"; do
        local os=$(echo "$platform" | cut -d'/' -f1)
        local arch=$(echo "$platform" | cut -d'/' -f2)
        local output_name="${PLUGIN_NAME}-${version}-${os}-${arch}"
        
        print_status "Building for $platform..."
        
        CGO_ENABLED=0 GOOS=$os GOARCH=$arch go build \
            -a -installsuffix cgo \
            -ldflags "-X main.version=$version" \
            -o "build/$output_name" \
            ./src/
    done
    
    print_status "Plugin built successfully"
}

# Function to build Docker image
build_docker() {
    local version=$1
    local tag="$DOCKER_IMAGE:$version"
    local latest_tag="$DOCKER_IMAGE:latest"
    
    print_status "Building Docker image $tag..."
    
    cd "$PROJECT_ROOT"
    
    docker build -t "$tag" -t "$latest_tag" .
    
    print_status "Docker image built successfully"
}

# Function to run Docker build
run_docker_build() {
    local version=$1
    print_status "Building with Docker..."
    
    build_docker "$version"
    
    print_status "Docker build completed"
}

# Function to create release artifacts
create_release_artifacts() {
    local version=$1
    
    print_status "Creating release artifacts for version $version..."
    
    cd "$PROJECT_ROOT"
    
    # Create release directory
    mkdir -p "release/$version"
    
    # Copy built binaries
    if [ -d "build" ]; then
        cp build/* "release/$version/"
    fi
    
    # Create checksums
    cd "release/$version"
    for file in *; do
        if [ -f "$file" ]; then
            sha256sum "$file" > "$file.sha256"
        fi
    done
    
    print_status "Release artifacts created in release/$version/"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  test                    Run tests"
    echo "  build [version]         Build the plugin"
    echo "  docker [version]        Build Docker image"
    echo "  release [version]       Create release artifacts"
    echo "  increment [type]        Increment version (major|minor|patch)"
    echo "  all [version]           Run all steps: test, build, docker, release"
    echo ""
    echo "Options:"
    echo "  --help, -h              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 test"
    echo "  $0 build 1.0.0"
    echo "  $0 increment patch"
    echo "  $0 all 1.0.0"
}

# Main script logic
main() {
    local command=$1
    local version=${2:-$(get_version)}
    
    case $command in
        test)
            run_tests
            ;;
        build)
            run_tests
            build_plugin "$version"
            ;;
        docker)
            run_docker_build "$version"
            ;;
        release)
            build_plugin "$version"
            create_release_artifacts "$version"
            ;;
        increment)
            increment_version "$version"
            ;;
        all)
            run_tests
            build_plugin "$version"
            build_docker "$version"
            create_release_artifacts "$version"
            print_status "All steps completed successfully"
            ;;
        --help|-h|help)
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Check if command is provided
if [ $# -eq 0 ]; then
    print_error "No command provided"
    show_help
    exit 1
fi

# Run main function
main "$@"
