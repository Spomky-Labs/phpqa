#!/bin/bash

set -e

PHP_VERSION=${1:-8.4}
IMAGE_NAME="phpqa-test:${PHP_VERSION}"

echo "🏗️  Building and testing local PHPQA image for PHP ${PHP_VERSION}"
echo "================================================================"
echo ""

# Build the image
echo "✓ Building image..."
docker build \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --tag "${IMAGE_NAME}" \
    .

if [[ $? -eq 0 ]]; then
    echo "  ✅ Image built successfully"
else
    echo "  ❌ Image build failed"
    exit 1
fi
echo ""

# Run tests on the local image
echo "✓ Running tests on local image..."
echo ""

# Test 1: Check essential tools
echo "✓ Test 1: Checking essential tools..."
TOOLS=("tar" "git" "curl" "wget" "composer" "php" "castor")
for tool in "${TOOLS[@]}"; do
    if docker run --rm "${IMAGE_NAME}" which "$tool" > /dev/null 2>&1; then
        echo "  ✅ $tool is installed"
    else
        echo "  ❌ $tool is NOT installed"
        exit 1
    fi
done
echo ""

# Test 2: Check /tools directory permissions
echo "✓ Test 2: Checking /tools directory permissions..."
TOOLS_OWNER=$(docker run --rm "${IMAGE_NAME}" stat -c '%u:%g' /tools)
if [[ "${TOOLS_OWNER}" == "1001:1001" ]]; then
    echo "  ✅ /tools directory has correct ownership (1001:1001)"
else
    echo "  ❌ /tools directory has incorrect ownership: ${TOOLS_OWNER}"
    exit 1
fi
echo ""

# Test 3: Test cache directory write permissions
echo "✓ Test 3: Testing cache directory write permissions..."
docker run --rm "${IMAGE_NAME}" sh -c 'touch /tools/.composer/cache/test-file && rm /tools/.composer/cache/test-file' > /dev/null 2>&1
echo "  ✅ User can write to /tools/.composer/cache"
echo ""

# Test 4: Test tar functionality with utime operations
echo "✓ Test 4: Testing tar with utime operations (cache scenario)..."
docker run --rm "${IMAGE_NAME}" sh -c '
    mkdir -p /tmp/test-cache
    echo "test" > /tmp/test-cache/file.txt
    touch -t 202301010000 /tmp/test-cache/file.txt
    tar czf /tmp/cache.tgz -C /tmp test-cache
    rm -rf /tmp/test-cache
    tar xzf /tmp/cache.tgz -C /tmp
    if [ -f /tmp/test-cache/file.txt ]; then
        echo "Success"
    else
        echo "Failed"
        exit 1
    fi
' > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo "  ✅ tar can handle timestamp operations correctly"
else
    echo "  ❌ tar failed with timestamp operations"
    exit 1
fi
echo ""

echo "================================================================"
echo "✅ All local tests passed for ${IMAGE_NAME}!"
echo "================================================================"
echo ""
echo "You can now push this image or test it further."
echo "To run the full test suite: ./tests/test-image.sh ${PHP_VERSION}"
