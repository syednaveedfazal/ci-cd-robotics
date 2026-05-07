#!/bin/bash
# Docker Build Script for Robot Fleet Image
#
# This script builds the robot Docker image and runs validation tests.
# In CI/CD (GitHub Actions), this runs automatically on every code push.

set -e  # Exit on any error

# Configuration
IMAGE_NAME="robot-fleet"
IMAGE_TAG="${1:-latest}"  # Use argument or default to 'latest'
DOCKERFILE="docker/Dockerfile"

echo "========================================="
echo "Building Robot Fleet Image"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "========================================="

# Build the Docker image
# --no-cache: Force rebuild (use for clean builds)
# --progress=plain: Show detailed output
# -f: Specify Dockerfile location
# -t: Tag the image
docker build \
    -f "${DOCKERFILE}" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    .

echo ""
echo "========================================="
echo "Build Complete!"
echo "========================================="

# Display image size
echo "Image size:"
docker images "${IMAGE_NAME}:${IMAGE_TAG}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

echo ""
echo "========================================="
echo "Running Post-Build Validation"
echo "========================================="

# Test 1: Verify the image can start
echo "Test 1: Container startup test..."
docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" echo "Container started successfully" || {
    echo "ERROR: Container failed to start"
    exit 1
}

# Test 2: Verify ROS2 is available
# Test 2: Verify ROS2 is available
# Test 2: Verify ROS2 is available
echo "Test 2: ROS2 installation test..."
docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" ros2 topic list > /dev/null 2>&1 || {
    echo "ERROR: ROS2 not found in container"
    exit 1
}
echo "ROS2 is working correctly"

# Test 3: Verify our package is installed
echo "Test 3: Package installation test..."
docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}" ros2 pkg list | grep robot_health || {
    echo "ERROR: robot_health package not found"
    exit 1
}

echo ""
echo "========================================="
echo "All validation tests passed!"
echo "========================================="
echo ""
echo "To run the robot container:"
echo "  docker run --rm ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "To push to registry (for fleet deployment):"
echo "  docker tag ${IMAGE_NAME}:${IMAGE_TAG} your-registry/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  docker push your-registry/${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
