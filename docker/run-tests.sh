#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if Docker Compose is available
if ! command -v docker &> /dev/null; then
    print_error "docker is not installed or not in PATH"
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    print_error "docker compose is not available"
    exit 1
fi

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    docker compose down -v
}

# Set trap for cleanup
trap cleanup EXIT

# Start the services
print_status "Starting Docker Compose services..."
docker compose up -d

# Wait a bit for services to start
print_status "Waiting for services to start..."
sleep 10

# Run the tests
print_status "Running tests..."
docker exec traefik-with-cors-plugin /usr/local/bin/test.sh

print_status "Tests completed!"
