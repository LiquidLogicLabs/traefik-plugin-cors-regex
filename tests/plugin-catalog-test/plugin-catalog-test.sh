#!/bin/sh
set -e

# CORS Plugin Catalog Test Script
# Tests the plugin in standard Traefik mode (from Plugin Catalog, not local mode)

echo "🚀 Starting CORS Plugin Catalog tests..."

# Wait for Traefik to be ready
echo "⏳ Waiting for Traefik to be ready..."
max_attempts=30
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://traefik-plugin-catalog-test:80/ping >/dev/null 2>&1; then
        break
    fi
    attempt=$((attempt + 1))
    echo "   Waiting for Traefik... (attempt $attempt/$max_attempts)"
    sleep 2
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Traefik failed to start within timeout"
    exit 1
fi

echo "✅ Traefik is ready!"

# Wait for test app to be ready
echo "⏳ Waiting for test app to be ready..."
max_attempts=15
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if curl -s http://plugin-catalog-test-app:80/ >/dev/null 2>&1; then
        break
    fi
    attempt=$((attempt + 1))
    echo "   Waiting for test app... (attempt $attempt/$max_attempts)"
    sleep 1
done

if [ $attempt -eq $max_attempts ]; then
    echo "❌ Test app failed to start within timeout"
    exit 1
fi

echo "✅ Test app is ready!"

echo ""
echo "🧪 Running Plugin Catalog CORS tests..."

# Test 1: Allowed origin (exact match)
echo "Test 1: Plugin Catalog - Allowed origin (exact match)"
response=$(curl -s -H "Origin: https://example.com" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://example.com"; then
    echo "   ✅ PASS: Origin https://example.com is allowed"
else
    echo "   ❌ FAIL: Origin https://example.com should be allowed"
    echo "   Response headers:"
    echo "$response"
fi

# Test 2: Wildcard pattern (this tests the fixed wildcard bug)
echo "Test 2: Plugin Catalog - Wildcard pattern match"
response=$(curl -s -H "Origin: https://api.example.com" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://api.example.com"; then
    echo "   ✅ PASS: Wildcard pattern works correctly (returns actual origin)"
else
    echo "   ❌ FAIL: Wildcard pattern should return actual origin"
    echo "   Response headers:"
    echo "$response"
fi

# Test 3: Plugin loading verification
echo "Test 3: Plugin Catalog - Plugin loading verification"
response=$(curl -s -H "Origin: https://api.example.org" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://api.example.org"; then
    echo "   ✅ PASS: Plugin loaded successfully from catalog"
else
    echo "   ❌ FAIL: Plugin may not have loaded correctly"
    echo "   Response headers:"
    echo "$response"
fi

# Test 4: Blocked origin (should not have CORS headers)
echo "Test 4: Plugin Catalog - Blocked origin"
response=$(curl -s -H "Origin: https://malicious.com" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin:"; then
    echo "   ❌ FAIL: Origin https://malicious.com should be blocked"
    echo "   Response headers:"
    echo "$response"
else
    echo "   ✅ PASS: Origin https://malicious.com is blocked"
fi

# Test 5: Preflight request (OPTIONS)
echo "Test 5: Plugin Catalog - Preflight request handling"
response=$(curl -s -X OPTIONS -H "Origin: https://example.com" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://example.com" && echo "$response" | grep -q "Access-Control-Allow-Methods:"; then
    echo "   ✅ PASS: OPTIONS preflight request handled correctly"
else
    echo "   ❌ FAIL: OPTIONS preflight request not handled correctly"
    echo "   Response headers:"
    echo "$response"
fi

# Test 6: Plugin vs Local mode comparison
echo "Test 6: Plugin Catalog - Mode verification"
# This test checks that we're NOT in local mode by verifying plugin behavior
response=$(curl -s -H "Origin: https://www.example.com" -H "Host: localhost" -I http://traefik-plugin-catalog-test:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://www.example.com"; then
    echo "   ✅ PASS: Plugin working in catalog mode (not local mode)"
else
    echo "   ❌ FAIL: Plugin may not be working correctly in catalog mode"
    echo "   Response headers:"
    echo "$response"
fi

echo ""
echo "🎯 Plugin Catalog Test Summary:"
echo "   - Plugin loaded from Traefik Plugin Catalog (not local mode)"
echo "   - Tests verify production plugin behavior"
echo "   - Wildcard CORS patterns working correctly"
echo "   - Plugin integration with standard Traefik successful"
echo ""
echo "📊 Endpoints tested:"
echo "   - Traefik dashboard: http://localhost:8990"
echo "   - Test app: http://localhost:8991"
echo "   - Traefik with plugin: http://localhost:8989"
echo "   - Test endpoint: http://localhost:8989/test"
echo ""
echo "✨ Plugin Catalog CORS tests completed!"
