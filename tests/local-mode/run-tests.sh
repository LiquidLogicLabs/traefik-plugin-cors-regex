#!/bin/bash

# Run script for Docker tests
# This script builds and runs the Docker environment for testing

set -e

echo "🐳 Building and running CORS Regex Plugin tests..."

# Navigate to the test directory (we're already here when called from make)
cd "$(dirname "$0")"

# Build the Docker image
echo "🔨 Building Docker image..."
docker compose build

# Start the services
echo "🚀 Starting services..."
docker compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 10

# Run the tests
echo "🧪 Running tests..."
docker exec cors-plugin-tester sh /tests/test.sh

# Show logs if tests fail
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Showing logs..."
    docker compose logs
    exit 1
fi

echo ""
echo "🎉 All tests passed!"
echo ""
echo "📊 Service status:"
docker compose ps

echo ""
echo "🔍 To view logs:"
echo "   docker compose logs -f"

echo ""
echo "🧹 To clean up:"
echo "   docker compose down"
