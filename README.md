# 🧪 Spomky PHP QA Docker Image

This repository provides a custom Docker image based on [`jakzal/phpqa`](https://github.com/jakzal/phpqa) with:

- ✅ Additional QA tools and extensions for PHP projects
- 🛠️ [Castor](https://github.com/jolicode/castor) pre-installed as a task runner
- 📦 [PIE](https://github.com/php/pie) - PHP Installer for Extensions
- 🧪 Enhanced PHPUnit, PHPStan, and Infection tooling
- 🌐 Browser testing support with Symfony Panther (Chrome & Firefox)

---

## 📦 Available on GitHub Container Registry

```bash
# Pull the image for your desired PHP version
docker pull ghcr.io/spomky-labs/phpqa:<version>
```

Replace `<version>` with one of the supported PHP versions below.

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

This image includes:

- PHP QA tools from [`jakzal/phpqa`](https://github.com/jakzal/phpqa)
- [Castor](https://github.com/jolicode/castor) - Task runner
- [PIE](https://github.com/php/pie) - PHP Installer for Extensions
- Enhanced PHPStan, PHPUnit, and Infection extensions
- Chromium + ChromeDriver for browser testing
- Firefox ESR + GeckoDriver for browser testing

---

## 📦 PIE - PHP Installer for Extensions

PIE is the official PHP extension installer that integrates with Packagist.

### Usage Examples

```bash
# Search for available extensions
docker run --rm ghcr.io/spomky-labs/phpqa:8.4 pie search

# Install an extension from Packagist
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    pie install vendor/extension-name

# List installed extensions
docker run --rm ghcr.io/spomky-labs/phpqa:8.4 pie list

# Get information about an extension
docker run --rm ghcr.io/spomky-labs/phpqa:8.4 pie info vendor/extension-name
```

Browse available extensions at [packagist.org/extensions](https://packagist.org/extensions).

---

## 🔍 PHPStan Extensions

Additional PHPStan extensions are pre-installed for stricter analysis:

### Included Extensions

- **php-static-analysis/phpstan-extension** - Enhanced static analysis
- **staabm/phpstan-todo-by** - TODO comments with expiry dates
- **struggle-for-php/sfp-phpstan-psr-log** - PSR-3 Logger interface support
- **slam/phpstan-extensions** - Strict rules (unused variables, ::class notation)
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

**slam/phpstan-extensions** provides rules like:
- `UnusedVariableRule` - Detect unused variables
- `StringToClassRule` - Enforce `::class` notation
- `MissingClosureParameterTypehintRule` - Require closure type hints

**phpstan-deprecation-rules** helps you:
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

## 🌐 Symfony Panther - Browser Testing

End-to-end testing with real browsers (Chrome and Firefox) for JavaScript-heavy applications.

### Available Browsers

- **Chromium** + ChromeDriver (pre-configured)
- **Firefox ESR** + GeckoDriver v0.35.0 (pre-configured)

### Environment Configuration

The following environment variables are pre-configured:

```bash
PANTHER_NO_SANDBOX=1
PANTHER_CHROME_ARGUMENTS='--disable-dev-shm-usage --no-sandbox --disable-gpu --headless --window-size=1920,1080'
PANTHER_CHROME_DRIVER_BINARY=/usr/bin/chromedriver
PANTHER_FIREFOX_ARGUMENTS='-headless'
```

### Usage Examples

#### Basic Chrome Test

```php
use Symfony\Component\Panther\Client;

// Create a Chrome client
$client = Client::createChromeClient();

// Navigate to a page
$crawler = $client->request('GET', 'https://example.com');

// Interact with JavaScript
$client->executeScript('document.querySelector("#button").click()');

// Wait for AJAX to complete
$client->waitFor('#result');

// Take a screenshot
$client->takeScreenshot('screenshot.png');
```

#### Firefox Test

```php
use Symfony\Component\Panther\Client;

// Create a Firefox client
$client = Client::createFirefoxClient();

// Same API as Chrome
$crawler = $client->request('GET', 'https://example.com');
```

#### PHPUnit Integration

```php
use Symfony\Component\Panther\PantherTestCase;

class E2ETest extends PantherTestCase
{
    public function testMyApp(): void
    {
        $client = static::createPantherClient();
        $crawler = $client->request('GET', 'http://localhost:8000');

        // Fill a form
        $form = $crawler->selectButton('Submit')->form([
            'email' => 'test@example.com',
            'password' => 'secret',
        ]);
        $client->submit($form);

        // Wait for redirect and check result
        $client->waitForVisibility('#welcome-message');
        $this->assertSelectorTextContains('#welcome-message', 'Welcome');
    }
}
```

#### Advanced Features

```php
// Use specific browser
$client = Client::createChromeClient([
    'browser' => Client::CHROME,
]);

// Custom browser arguments
$client = Client::createChromeClient([], [
    'capabilities' => [
        'goog:chromeOptions' => [
            'args' => ['--window-size=1920,1080', '--disable-notifications'],
        ],
    ],
]);

// Multiple tabs
$client->request('GET', 'https://example.com');
$crawler = $client->clickLink('Open in new tab');
$client->switchTo()->window($client->getWindowHandles()[1]);

// Handle alerts
$client->switchTo()->alert()->accept();
```

### Running Panther Tests

```bash
# Run with Chrome (default)
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpunit --testsuite e2e

# With custom arguments
docker run --rm -v $(pwd):/project -w /project \
    -e PANTHER_CHROME_ARGUMENTS='--window-size=1280,720' \
    ghcr.io/spomky-labs/phpqa:8.4 phpunit
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
# 1. Install PHP extension if needed
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    pie install vendor/extension-name

# 2. Run PHPStan with strict rules
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpstan analyse src tests --level=max

# 3. Run unit tests with slow test detection
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpunit --testsuite unit

# 4. Run browser tests with Panther
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    phpunit --testsuite e2e

# 5. Run mutation testing
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    infection --threads=4 --min-msi=80

# 6. Run Castor tasks
docker run --rm -v $(pwd):/project -w /project ghcr.io/spomky-labs/phpqa:8.4 \
    castor qa:all
```

---

## 📄 License

This project is licensed under the MIT License.
