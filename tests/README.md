# PHPQA Image Tests

This directory contains automated tests to validate the PHPQA Docker images.

## Test Scripts

### `test-image.sh` - Test Published Images

Tests a published PHPQA image from the GitHub Container Registry.

**Usage:**
```bash
./tests/test-image.sh [PHP_VERSION]
```

**Examples:**
```bash
# Test PHP 8.4 image (default)
./tests/test-image.sh

# Test PHP 8.3 image
./tests/test-image.sh 8.3

# Test all versions
for version in 8.2 8.3 8.4; do
    ./tests/test-image.sh $version
done
```

### `test-local-build.sh` - Test Local Build

Builds and tests a local PHPQA image before publishing.

**Usage:**
```bash
./tests/test-local-build.sh [PHP_VERSION]
```

**Examples:**
```bash
# Build and test PHP 8.4 image
./tests/test-local-build.sh 8.4

# Build and test PHP 8.3 image
./tests/test-local-build.sh 8.3
```

## Test Coverage

Both test scripts verify:

1. **Essential Tools**: Ensures tar, git, curl, wget, composer, php, and castor are installed
2. **PHP Version**: Verifies the correct PHP version is installed
3. **Directory Permissions**: Checks that `/tools` directory has correct ownership (1001:1001)
4. **Cache Permissions**: Validates write permissions for `/tools/.composer/cache`
5. **Symfony Panther Version**: Ensures Panther 2.3+ is installed (compatible with BrowserKit 8.0)
6. **BrowserKit Compatibility**: Tests that Panther and BrowserKit can work together
7. **Tar Functionality**: Simulates cache extraction scenarios
8. **PHP Extensions**: Verifies essential PHP extensions are loaded
9. **Timestamp Operations**: Tests tar's ability to handle file timestamps (utime)

## Known Issues & Fixes

### Issue 1: Tar Cache Extraction Failure (Fixed)

**Problem:**
```
/usr/bin/tar: ../../../tools/.composer/cache: Cannot utime: Operation not permitted
```

**Root Cause:**
The `/tools` directory was owned by root, but the container runs as user 1001, preventing tar from setting file timestamps when extracting GitHub Actions caches.

**Fix:**
Added permissions fix in Dockerfile (line 116-117):
```dockerfile
RUN chown -R 1001:1001 /tools \
 && chmod -R 755 /tools
```

### Issue 2: Symfony Panther/BrowserKit Incompatibility (Fixed)

**Problem:**
```
Fatal error: Declaration of Symfony\Component\Panther\Client::doRequest($request)
must be compatible with Symfony\Component\BrowserKit\AbstractBrowser::doRequest(object $request): object
```

**Root Cause:**
Panther versions < 2.3 are incompatible with BrowserKit 8.0 due to strict type declarations.

**Fix:**
Updated Panther constraint in Dockerfile (line 82):
```dockerfile
symfony/panther:"^2.3"  # Changed from "^2.0"
```

## CI/CD Integration

The tests are automatically run in GitHub Actions after each image build:

- **Workflow:** `.github/workflows/docker.yml`
- **Job:** `test`
- **Trigger:** After the `manifest` job completes
- **Matrices:** Tests all PHP versions (8.2, 8.3, 8.4, 8.5)

## Local Development Workflow

1. Make changes to the Dockerfile
2. Build and test locally:
   ```bash
   ./tests/test-local-build.sh 8.4
   ```
3. If tests pass, commit and push
4. GitHub Actions will build and test all versions automatically

## Adding New Tests

To add new tests, edit `test-image.sh` and `test-local-build.sh`:

1. Add a new test section with clear numbering
2. Use descriptive echo statements
3. Verify the test fails appropriately when conditions aren't met
4. Ensure the test exits with code 1 on failure
5. Update this README with the new test description

## Troubleshooting

### Test fails with "Image not found"

The image hasn't been published yet. Use `test-local-build.sh` instead.

### Test fails with "Permission denied"

Make the script executable:
```bash
chmod +x tests/test-image.sh tests/test-local-build.sh
```

### Test fails with tar errors

Check the `/tools` directory permissions in the image:
```bash
docker run --rm ghcr.io/spomky-labs/phpqa:8.4 stat -c '%u:%g %a' /tools
```

Should output: `1001:1001 755`
