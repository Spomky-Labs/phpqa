# 🧪 Spomky PHP QA Docker Image & Centralized CI/CD

This repository provides:

1. **🐳 Lean Docker Image** (~800 MB, ~150 MB compressed) built on the official `php:X.Y-cli` images with:
   - ✅ Only the QA tools used by the Castor tasks (PHPStan, ECS, Rector, Deptrac, PHPUnit, Infection, parallel-lint)
   - 🛠️ [Castor](https://github.com/jolicode/castor) pre-installed as a task runner (static build, works on every PHP version)
   - 🧩 The PHP extensions needed by Symfony/Doctrine projects (intl, pdo_pgsql, redis, amqp, imagick, xdebug, ...)
   - 🧪 Enhanced PHPUnit, PHPStan, and Infection tooling

2. **🔄 Centralized Castor Tasks** for quality assurance:
   - Reusable Castor tasks across all your projects
   - Minimal configuration required per project
   - Support for Libraries, Bundles, and Applications

3. **⚙️ Reusable GitHub Actions Workflows**:
   - Single workflow configuration for all projects
   - Customizable per project type
   - Consistent CI/CD across your organization

📖 **[See Integration Guide](INTEGRATION.md) for using centralized Castor & GitHub Actions**

---

## 🚀 Quick Start

### Automatic Migration (Recommended)

```bash
# From the phpqa repository
./scripts/migrate-project.sh /path/to/your/project library

# Or for an application
./scripts/migrate-project.sh /path/to/your/project application
```

This creates everything you need:
- ✅ `castor.php` with auto-download from GitHub
- ✅ `.phpqa-config.php` configured for your project type
- ✅ `.github/workflows/ci.yml` ready to use
- ✅ `.gitignore` with `.castor-cache/`

Then just run:
```bash
cd /path/to/your/project
castor qa:all
```

### Manual Setup

Copy one of the examples:
```bash
cp examples/castor-simple.php your-project/castor.php
cd your-project
castor qa:all  # Downloads PHPQA tasks automatically
```

📖 **[Full Getting Started Guide](GETTING-STARTED.md)**

---

## 📦 Available on GitHub Container Registry

```bash
# Pull the image for your desired PHP version
docker pull ghcr.io/spomky-labs/phpqa:<version>
```

Replace `<version>` with one of the supported PHP versions below.

### Build Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `PHP_VERSION` | `8.4` | PHP version (`8.2`, `8.3`, `8.4`, `8.5`) |
| `DEBIAN_RELEASE` | `trixie` | Debian release used for both build and runtime stages |

```bash
docker build --build-arg PHP_VERSION=8.3 -t ghcr.io/spomky-labs/phpqa:8.3 .
```

The image is a two-stage build: extensions are compiled and tools are installed in a
`php:X.Y-cli` stage, then only the PHP binary, the extensions, the tools and their
runtime libraries are copied into a `debian:slim` runtime stage (no compiler, no headers).

---

## 🔢 Supported PHP Versions

The following versions are available as tags:

| PHP Version | Tags |
|-------------|------|
| 8.2 | `8.2`, `8.2-amd64`, `8.2-arm64`, `8.2-<sha>`, `8.2-latest` (main branch only) |
| 8.3 | `8.3`, `8.3-amd64`, `8.3-arm64`, `8.3-<sha>`, `8.3-latest` (main branch only) |
| 8.4 | `8.4`, `8.4-amd64`, `8.4-arm64`, `8.4-<sha>`, `8.4-latest` (main branch only) |
| 8.5 | `8.5`, `8.5-amd64`, `8.5-arm64`, `8.5-<sha>` (build may fail, experimental) |

If a release is tagged (e.g. `8.4.1`), additional tags will be pushed:
- `8.4.1`, `8.4`, `8`

---

## 🧪 Usage Example

Run PHPUnit from the container:

```bash
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 phpunit
```

---

## 🛠️ Pre-installed Tools

All tools are on the `PATH` and are found by `composer exec -- <tool>` when a project does not
ship its own copy in `vendor/bin`:

| Tool | Location |
|------|----------|
| `phpstan` (+ extensions) | `/tools/.composer/vendor-bin/phpstan` |
| `ecs` | `/tools/.composer/vendor-bin/ecs` |
| `rector` | `/tools/.composer/vendor-bin/rector` |
| `infection` | `/tools/.composer/vendor-bin/infection` |
| `deptrac`, `composer normalize` | `/tools/.composer/vendor` |
| PHPUnit helpers (slow test detector, foundry, browser-kit, ...) | `/tools/.composer/vendor-bin/phpunit` |
| `phpunit-10`, `phpunit-11`, `phpunit-12` (PHAR), `phpunit` → `phpunit-11` | `/tools` |
| `parallel-lint` (PHAR) | `/tools` |
| `composer`, `castor` | `/usr/local/bin` |

Other tools: `git`, `curl`, `wget`, `jq`, `unzip`, `openssh-client`.

PHP extensions: amqp, apcu, bcmath, brotli, bz2, exif, gd, gettext, gmp, imagick, intl, opcache,
pcntl, pcov, pdo_pgsql, pdo_sqlite, redis, sodium, uuid, xdebug, xsl, zip, zstd (plus the
extensions bundled with the official PHP image).

`XDEBUG_MODE` defaults to `off`; set `XDEBUG_MODE=coverage` when collecting coverage.

---

## 🔍 PHPStan Extensions

Additional PHPStan extensions are pre-installed for stricter analysis:

### Included Extensions

- **php-static-analysis/phpstan-extension** - Enhanced static analysis
- **staabm/phpstan-todo-by** - TODO comments with expiry dates
- **struggle-for-php/sfp-phpstan-psr-log** - PSR-3 Logger interface support
- **phpstan/phpstan-deprecation-rules** - Detect deprecated code usage
- **phpstan/phpstan-strict-rules** - Extra strict type checking rules

### Usage Example

```bash
# Run PHPStan with all extensions
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpstan analyse src --level=max

# The extensions are automatically loaded via phpstan/extension-installer
```

### Extension Features

**phpstan/phpstan-strict-rules** provides extra strict checks like:
- Disallow empty() - Use more explicit checks instead
- Require boolean in if conditions
- Disallow variable variables
- Strict comparison operators

**phpstan/phpstan-deprecation-rules** helps you:
- Find all deprecated code usage in your codebase
- Prepare for major version upgrades
- Maintain compatibility with dependencies

---

## 🧪 PHPUnit Extensions

Enhanced PHPUnit testing capabilities with additional plugins:

### Included Extensions

- **ergebnis/phpunit-slow-test-detector** - Identify slow tests
- **digitalrevolution/phpunit-extensions** - Advanced testing utilities
- **symfony/browser-kit** - Simulate browser requests
- **symfony/css-selector** - Query HTML with CSS selectors
- **symfony/panther** - End-to-end testing with real browsers
- **zenstruck/foundry** - Fixture factories for testing

### Usage Examples

#### Slow Test Detection

```bash
# Run tests and detect slow ones
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpunit --configuration phpunit.xml
```

Configure in `phpunit.xml`:
```xml
<extensions>
    <bootstrap class="Ergebnis\PHPUnit\SlowTestDetector\Extension">
        <parameter name="maximum-duration" value="500"/>
    </bootstrap>
</extensions>
```

#### Browser-Kit Testing

```php
use Symfony\Component\BrowserKit\HttpBrowser;
use Symfony\Component\HttpClient\HttpClient;

$browser = new HttpBrowser(HttpClient::create());
$crawler = $browser->request('GET', 'https://example.com');
$browser->clickLink('Products');
```

#### Digital Revolution Extensions

```php
use DigitalRevolution\PHPUnitExtensions\TestCase;

class MyTest extends TestCase
{
    // Image comparison for visual regression testing
    public function testImageMatches(): void
    {
        $this->assertImageEquals('expected.png', 'actual.png');
    }

    // Clock manipulation for time-dependent tests
    public function testWithFrozenTime(): void
    {
        $this->freezeTime('2025-01-01 12:00:00');
        // Your test code here
    }
}
```

---

## 🦠 Infection - Mutation Testing

Mutation testing framework to ensure your tests are effective.

### Usage Example

```bash
# Run mutation testing
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    infection --threads=4 --min-msi=80

# Run only on covered code
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    infection --threads=4 --only-covered
```

Configure in `infection.json5`:
```json5
{
    "source": {
        "directories": ["src"]
    },
    "mutators": {
        "@default": true
    },
    "minMsi": 80,
    "minCoveredMsi": 90
}
```

### What is Mutation Testing?

Mutation testing modifies your code (creates mutants) to verify if your tests catch the changes:
- If a test fails, the mutant is "killed" (good - your tests work)
- If tests pass, the mutant "escaped" (bad - you need better tests)
- MSI (Mutation Score Indicator) shows the percentage of killed mutants

---

## 🎯 Complete Workflow Example

Here's a complete QA workflow using all tools:

```bash
# 1. Run PHPStan with strict rules
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpstan analyse src tests --level=max

# 2. Run unit tests with slow test detection
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpunit --testsuite unit

# 3. Run mutation testing
docker run --rm -e XDEBUG_MODE=coverage -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    infection --threads=4 --min-msi=80

# 4. Run Castor tasks
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    castor qa:all
```

---

## 📄 License

This project is licensed under the MIT License.
