#!/bin/bash

# Ethereum ETL Docker Build Script
# Version: 2.4.2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="ethereum-etl"
VERSION="2.4.2"
FULL_IMAGE_NAME="${IMAGE_NAME}:${VERSION}"
LATEST_TAG="${IMAGE_NAME}:latest"

echo -e "${BLUE}=== Ethereum ETL Docker Build Script ===${NC}"
echo -e "${BLUE}Version: ${VERSION}${NC}"
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

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    print_error "Dockerfile not found. Please run this script from the ethereum-etl directory."
    exit 1
fi

print_status "Building Docker image: ${FULL_IMAGE_NAME}"

# Build the Docker image
print_status "Starting Docker build..."
if docker build \
    --build-arg VERSION=${VERSION} \
    --tag ${FULL_IMAGE_NAME} \
    --tag ${LATEST_TAG} \
    --file Dockerfile \
    .; then
    print_status "Docker build completed successfully!"
else
    print_error "Docker build failed!"
    exit 1
fi

# Display image information
print_status "Docker image created:"
docker images | grep ${IMAGE_NAME}

# Create output directory if it doesn't exist
if [ ! -d "output" ]; then
    print_status "Creating output directory..."
    mkdir -p output
    chmod 755 output
fi

# Test the image
print_status "Testing the Docker image..."
if docker run --rm ${FULL_IMAGE_NAME} --help > /dev/null 2>&1; then
    print_status "Docker image test passed!"
else
    print_warning "Docker image test failed, but image was built successfully."
fi

echo ""
echo -e "${GREEN}=== Build Summary ===${NC}"
echo -e "Image Name: ${FULL_IMAGE_NAME}"
echo -e "Latest Tag: ${LATEST_TAG}"
echo -e "Output Directory: ./output"
echo ""
echo -e "${BLUE}=== Usage Examples ===${NC}"
echo ""
echo -e "${YELLOW}1. Export blocks and transactions:${NC}"
echo "docker run -v \$(pwd)/output:/output ${FULL_IMAGE_NAME} export_all \\"
echo "  --start-block 0 --end-block 1000000 \\"
echo "  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \\"
echo "  --output-dir /output"
echo ""
echo -e "${YELLOW}2. Stream blockchain data:${NC}"
echo "docker run -v \$(pwd)/output:/output ${FULL_IMAGE_NAME} stream \\"
echo "  --start-block 500000 \\"
echo "  --entity-types block,transaction,log,token_transfer \\"
echo "  --provider-uri https://mainnet.infura.io/v3/YOUR_PROJECT_ID \\"
echo "  --output /output/stream_output.json"
echo ""
echo -e "${YELLOW}3. Using docker-compose:${NC}"
echo "docker-compose up ethereum-etl"
echo ""
echo -e "${GREEN}Build completed successfully!${NC}" 