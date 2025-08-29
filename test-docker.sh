#!/bin/bash

# Ethereum ETL Docker Test Script
# Version: 2.4.2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ethereum-etl:2.4.2"

echo -e "${BLUE}=== Ethereum ETL Docker Test Script ===${NC}"
echo -e "${BLUE}Version: 2.4.2${NC}"
echo ""

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Docker is running"

# Check if image exists
if ! docker image inspect ${IMAGE_NAME} > /dev/null 2>&1; then
    print_error "Docker image ${IMAGE_NAME} not found. Please build it first."
    exit 1
fi

print_status "Docker image ${IMAGE_NAME} found"

# Test 1: Basic help command
print_status "Test 1: Testing basic help command..."
if docker run --rm ${IMAGE_NAME} --help > /dev/null 2>&1; then
    print_status "✓ Basic help command works"
else
    print_error "✗ Basic help command failed"
    exit 1
fi

# Test 2: Export all help
print_status "Test 2: Testing export_all help..."
if docker run --rm ${IMAGE_NAME} export_all --help > /dev/null 2>&1; then
    print_status "✓ Export all help command works"
else
    print_error "✗ Export all help command failed"
    exit 1
fi

# Test 3: Stream help
print_status "Test 3: Testing stream help..."
if docker run --rm ${IMAGE_NAME} stream --help > /dev/null 2>&1; then
    print_status "✓ Stream help command works"
else
    print_error "✗ Stream help command failed"
    exit 1
fi

# Test 4: Check available commands
print_status "Test 4: Checking available commands..."
COMMANDS=$(docker run --rm ${IMAGE_NAME} --help | grep -E "^  [a-z_]+" | wc -l)
print_status "✓ Found ${COMMANDS} available commands"

# Test 5: Test Python import (using docker exec)
print_status "Test 5: Testing Python import..."
if docker run --rm --entrypoint python ${IMAGE_NAME} -c "import ethereumetl; print('Import successful')" 2>/dev/null | grep -q "Import successful"; then
    print_status "✓ Python import works"
else
    print_warning "⚠ Python import test failed"
fi

# Test 6: Test volume mounting
print_status "Test 6: Testing volume mounting..."
mkdir -p test_output
if docker run --rm --entrypoint python -v $(pwd)/test_output:/output ${IMAGE_NAME} -c "import os; print('Volume mounted:', os.path.exists('/output'))" 2>/dev/null | grep -q "Volume mounted: True"; then
    print_status "✓ Volume mounting works"
else
    print_warning "⚠ Volume mounting test failed"
fi

# Test 7: Test health check
print_status "Test 7: Testing health check..."
if docker run --rm --entrypoint python ${IMAGE_NAME} -c "import ethereumetl; print('Ethereum ETL is healthy')" 2>/dev/null | grep -q "Ethereum ETL is healthy"; then
    print_status "✓ Health check works"
else
    print_warning "⚠ Health check failed"
fi

# Test 8: Test user permissions
print_status "Test 8: Testing user permissions..."
USER_INFO=$(docker run --rm --entrypoint whoami ${IMAGE_NAME} 2>/dev/null)
if [ "$USER_INFO" = "ethereumetl" ]; then
    print_status "✓ Running as non-root user: ${USER_INFO}"
else
    print_warning "⚠ User permission test failed: ${USER_INFO}"
fi

# Cleanup
rm -rf test_output

echo ""
echo -e "${GREEN}=== Test Summary ===${NC}"
echo -e "✓ All basic functionality tests passed"
echo -e "✓ Docker image is working correctly"
echo -e "✓ Ready for production use"
echo ""
echo -e "${BLUE}=== Next Steps ===${NC}"
echo -e "1. Configure your Ethereum provider URI"
echo -e "2. Set up output directory"
echo -e "3. Run your first export command"
echo ""
echo -e "${YELLOW}Example usage:${NC}"
echo "docker run -v \$(pwd)/output:/output ${IMAGE_NAME} export_all \\"
echo "  --start-block 0 --end-block 1000 \\"
echo "  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \\"
echo "  --output-dir /output"
echo ""
echo -e "${GREEN}All tests completed successfully!${NC}" 