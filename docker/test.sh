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

# Function to test CORS headers
test_cors_headers() {
    local origin=$1
    local expected_allowed=$2
    local description=$3
    
    print_status "Testing CORS for origin: $origin ($description)"
    
    # Make request with origin header and capture response headers
    response_headers=$(curl -s -I -H "Origin: $origin" http://localhost:8989/api/test)
    cors_origin=$(echo "$response_headers" | grep -i "access-control-allow-origin" | cut -d' ' -f2 | tr -d '\r' || echo "")
    
    if [ "$expected_allowed" = "true" ]; then
        if [ -n "$cors_origin" ]; then
            print_status "✅ PASS: Origin $origin is allowed (got: $cors_origin)"
        else
            print_error "❌ FAIL: Origin $origin should be allowed but was not"
            return 1
        fi
    else
        if [ -z "$cors_origin" ]; then
            print_status "✅ PASS: Origin $origin is correctly blocked"
        else
            print_error "❌ FAIL: Origin $origin should be blocked but was allowed (got: $cors_origin)"
            return 1
        fi
    fi
}

# Function to test preflight request
test_preflight() {
    local origin=$1
    local expected_allowed=$2
    
    print_status "Testing preflight request for origin: $origin"
    
    # Make OPTIONS request
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X OPTIONS \
        -H "Origin: $origin" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Content-Type" \
        http://localhost:8989/api/test)
    
    if [ "$response" = "200" ]; then
        print_status "✅ PASS: Preflight request succeeded for $origin"
    else
        print_error "❌ FAIL: Preflight request failed for $origin (status: $response)"
        return 1
    fi
}

# Function to test CORS headers in response
test_cors_response_headers() {
    local origin=$1
    
    print_status "Testing CORS response headers for origin: $origin"
    
    # Get all CORS headers
    response_headers=$(curl -s -I -H "Origin: $origin" http://localhost:8989/api/test)
    
    # Check for specific CORS headers
    cors_origin=$(echo "$response_headers" | grep -i "access-control-allow-origin" | cut -d' ' -f2 | tr -d '\r' || echo "")
    cors_methods=$(echo "$response_headers" | grep -i "access-control-allow-methods" | cut -d' ' -f2 | tr -d '\r' || echo "")
    cors_headers=$(echo "$response_headers" | grep -i "access-control-allow-headers" | cut -d' ' -f2 | tr -d '\r' || echo "")
    cors_credentials=$(echo "$response_headers" | grep -i "access-control-allow-credentials" | cut -d' ' -f2 | tr -d '\r' || echo "")
    
    print_status "CORS Headers for $origin:"
    print_status "  - Allow-Origin: $cors_origin"
    print_status "  - Allow-Methods: $cors_methods"
    print_status "  - Allow-Headers: $cors_headers"
    print_status "  - Allow-Credentials: $cors_credentials"
}

# Wait for Traefik to be ready
wait_for_traefik() {
    print_status "Waiting for Traefik to be ready..."
    for i in {1..60}; do
        if curl -s http://localhost:8990/ping > /dev/null 2>&1; then
            print_status "Traefik is ready!"
            return 0
        fi
        sleep 1
    done
    print_error "Traefik failed to start"
    return 1
}

# Wait for test app to be ready
wait_for_test_app() {
    print_status "Waiting for test app to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8991/health > /dev/null 2>&1; then
            print_status "Test app is ready!"
            return 0
        fi
        sleep 1
    done
    print_warning "Test app not ready, continuing anyway..."
}

# Main test function
main() {
    print_status "Starting CORS regex plugin tests..."
    
    # Wait for services
    wait_for_traefik
    wait_for_test_app
    
    print_status "Testing CORS functionality..."
    
    # Test allowed origins
    test_cors_headers "https://example.com" "true" "Exact match"
    test_cors_headers "https://api.example.com" "true" "Wildcard match"
    test_cors_headers "https://sub.example.com" "true" "Wildcard match"
    test_cors_headers "https://api.example.org" "true" "Exact match"
    
    # Test blocked origins
    test_cors_headers "https://example.org" "false" "Not in allowlist"
    test_cors_headers "https://malicious.com" "false" "Not in allowlist"
    test_cors_headers "http://example.com" "false" "Wrong protocol"
    
    # Test preflight requests
    test_preflight "https://example.com" "true"
    test_preflight "https://api.example.com" "true"
    
    # Test CORS response headers
    test_cors_response_headers "https://example.com"
    
    print_status "All tests completed successfully!"
}

# Run tests
main "$@"
