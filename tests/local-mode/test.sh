#!/bin/sh

# Test script for CORS Regex Plugin
# This script tests various CORS scenarios

set -e

echo "🚀 Starting CORS Regex Plugin tests..."

# Wait for Traefik to be ready
echo "⏳ Waiting for Traefik to be ready..."
until curl -s http://traefik-with-cors-plugin:9000/ping > /dev/null; do
    echo "   Waiting for Traefik..."
    sleep 2
done
echo "✅ Traefik is ready!"

# Wait for test app to be ready
echo "⏳ Waiting for test app to be ready..."
until curl -s http://test-app:80/health > /dev/null; do
    echo "   Waiting for test app..."
    sleep 2
done
echo "✅ Test app is ready!"

echo ""
echo "🧪 Running CORS tests..."

# Test 1: Allowed origin (exact match)
echo "Test 1: Allowed origin (exact match)"
response=$(curl -s -H "Origin: https://example.com" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://example.com"; then
    echo "   ✅ PASS: Origin https://example.com is allowed"
else
    echo "   ❌ FAIL: Origin https://example.com should be allowed"
    echo "   Response headers:"
    echo "$response"
fi

# Test 2: Allowed origin (wildcard match)
echo "Test 2: Allowed origin (wildcard match)"
response=$(curl -s -H "Origin: https://api.example.com" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://api.example.com"; then
    echo "   ✅ PASS: Origin https://api.example.com is allowed via wildcard"
else
    echo "   ❌ FAIL: Origin https://api.example.com should be allowed via wildcard"
    echo "   Response headers:"
    echo "$response"
fi

# Test 3: Allowed origin (another wildcard match)
echo "Test 3: Allowed origin (another wildcard match)"
response=$(curl -s -H "Origin: https://www.example.com" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://www.example.com"; then
    echo "   ✅ PASS: Origin https://www.example.com is allowed via wildcard"
else
    echo "   ❌ FAIL: Origin https://www.example.com should be allowed via wildcard"
    echo "   Response headers:"
    echo "$response"
fi

# Test 4: Allowed origin (exact match from list)
echo "Test 4: Allowed origin (exact match from list)"
response=$(curl -s -H "Origin: https://api.example.org" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://api.example.org"; then
    echo "   ✅ PASS: Origin https://api.example.org is allowed"
else
    echo "   ❌ FAIL: Origin https://api.example.org should be allowed"
    echo "   Response headers:"
    echo "$response"
fi

# Test 5: Blocked origin
echo "Test 5: Blocked origin"
response=$(curl -s -H "Origin: https://malicious.com" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
    echo "   ❌ FAIL: Origin https://malicious.com should not be allowed"
    echo "   Response headers:"
    echo "$response"
else
    echo "   ✅ PASS: Origin https://malicious.com is blocked"
fi

# Test 6: Preflight request (OPTIONS)
echo "Test 6: Preflight request (OPTIONS)"
response=$(curl -s -X OPTIONS \
    -H "Origin: https://example.com" \
    -H "Host: localhost" \
    -H "Access-Control-Request-Method: GET" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -I http://traefik-with-cors-plugin:80/test)
if echo "$response" | grep -q "Access-Control-Allow-Origin: https://example.com"; then
    echo "   ✅ PASS: OPTIONS request handled correctly"
else
    echo "   ❌ FAIL: OPTIONS request not handled correctly"
    echo "   Response headers:"
    echo "$response"
fi

# Test 7: CORS headers presence
echo "Test 7: CORS headers presence"
response=$(curl -s -H "Origin: https://example.com" -H "Host: localhost" -I http://traefik-with-cors-plugin:80/test)

# Check for required CORS headers
required_headers="Access-Control-Allow-Methods Access-Control-Allow-Headers Access-Control-Allow-Credentials Access-Control-Max-Age"

all_headers_present=true
for header in $required_headers; do
    if echo "$response" | grep -q "$header"; then
        echo "   ✅ $header is present"
    else
        echo "   ❌ $header is missing"
        all_headers_present=false
    fi
done

if [ "$all_headers_present" = true ]; then
    echo "   ✅ PASS: All required CORS headers are present"
else
    echo "   ❌ FAIL: Some required CORS headers are missing"
fi

echo ""
echo "🎯 Test summary:"
echo "   - Traefik dashboard: http://localhost:8990"
echo "   - Test app: http://localhost:8991"
echo "   - Traefik with plugin: http://localhost:8989"
echo "   - Test endpoint: http://localhost:8989/test"

echo ""
echo "✨ CORS Regex Plugin tests completed!"
