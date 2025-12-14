#!/bin/bash

set -e

PHP_VERSION=${1:-8.4}
IMAGE_NAME="ghcr.io/spomky-labs/phpqa:${PHP_VERSION}"

echo "🧪 Testing PHPQA image: ${IMAGE_NAME}"
echo "======================================"
echo ""

# Test 1: Check if image exists
echo "✓ Test 1: Pulling image..."
docker pull "${IMAGE_NAME}" > /dev/null 2>&1
echo "  ✅ Image pulled successfully"
echo ""

# Test 2: Check essential tools
echo "✓ Test 2: Checking essential tools..."
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

# Test 3: Check tar version and functionality
echo "✓ Test 3: Testing tar functionality..."
TAR_VERSION=$(docker run --rm "${IMAGE_NAME}" tar --version | head -1)
echo "  ℹ️  $TAR_VERSION"
echo "  ✅ tar is functional"
echo ""

# Test 4: Check PHP version
echo "✓ Test 4: Checking PHP version..."
PHP_ACTUAL=$(docker run --rm "${IMAGE_NAME}" php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
echo "  ℹ️  Expected: ${PHP_VERSION}, Actual: ${PHP_ACTUAL}"
if [[ "${PHP_ACTUAL}" == "${PHP_VERSION}" ]]; then
    echo "  ✅ PHP version matches"
else
    echo "  ❌ PHP version mismatch"
    exit 1
fi
echo ""

# Test 5: Check /tools directory permissions
echo "✓ Test 5: Checking /tools directory permissions..."
TOOLS_OWNER=$(docker run --rm "${IMAGE_NAME}" stat -c '%u:%g' /tools)
if [[ "${TOOLS_OWNER}" == "1001:1001" ]]; then
    echo "  ✅ /tools directory has correct ownership (1001:1001)"
else
    echo "  ❌ /tools directory has incorrect ownership: ${TOOLS_OWNER}"
    exit 1
fi
echo ""

# Test 6: Test cache directory write permissions
echo "✓ Test 6: Testing cache directory write permissions..."
docker run --rm "${IMAGE_NAME}" sh -c 'touch /tools/.composer/cache/test-file && rm /tools/.composer/cache/test-file' > /dev/null 2>&1
echo "  ✅ User can write to /tools/.composer/cache"
echo ""

# Test 7: Test tar cache extraction simulation
echo "✓ Test 7: Testing tar cache extraction (simulated)..."
docker run --rm -v "$(pwd)/tests/fixtures:/tmp/test" "${IMAGE_NAME}" sh -c '
    mkdir -p /tmp/test-extract
    echo "test content" > /tmp/test-extract/test.txt
    cd /tmp
    tar czf test/cache.tgz test-extract/
    rm -rf test-extract
    tar xzf test/cache.tgz -C /tmp
    cat /tmp/test-extract/test.txt
    rm -rf test-extract test/cache.tgz
' > /dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo "  ✅ tar can create and extract archives"
else
    echo "  ❌ tar extraction failed"
    exit 1
fi
echo ""

# Test 8: Check PHP extensions
echo "✓ Test 8: Checking essential PHP extensions..."
EXTENSIONS=("xdebug" "intl" "zip" "gd" "pdo_pgsql" "redis" "apcu")
for ext in "${EXTENSIONS[@]}"; do
    if docker run --rm "${IMAGE_NAME}" php -m | grep -q "^${ext}$"; then
        echo "  ✅ ${ext} extension is loaded"
    else
        echo "  ❌ ${ext} extension is NOT loaded"
        exit 1
    fi
done
echo ""

echo "======================================"
echo "✅ All tests passed for ${IMAGE_NAME}!"
echo "======================================"
