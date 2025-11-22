# Getting Started with PHPQA

## 🎯 What is PHPQA?

PHPQA is a centralized quality assurance system for PHP projects that provides:
- Reusable Castor tasks for all QA operations
- Reusable GitHub Actions workflows
- Automatic download from GitHub (no path dependencies)
- Minimal configuration per project
- Support for libraries, bundles, and applications

## 🚀 Quick Start

### Option 1: Automatic Migration (Recommended)

Use the migration script to automatically set up everything:

```bash
cd ~/Projects/phpqa

# For a library or bundle
./scripts/migrate-project.sh /path/to/your/project library

# For an application
./scripts/migrate-project.sh /path/to/your/app application
```

This creates:
- ✅ `castor.php` with GitHub auto-download (~40 lines)
- ✅ `.phpqa-config.php` configured for your project type
- ✅ `.github/workflows/ci.yml` with reusable workflow
- ✅ `.gitignore` entry for `.castor-cache/`

Then test it:

```bash
cd /path/to/your/project
castor list          # Downloads PHPQA tasks (first time only)
castor qa:all        # Run all QA checks
```

### Option 2: Manual Setup

1. **Copy an example castor.php:**

```bash
cp ~/Projects/phpqa/examples/castor-simple.php your-project/castor.php
```

2. **Optional: Add configuration:**

```bash
cp ~/Projects/phpqa/examples/.phpqa-config-library.php your-project/.phpqa-config.php
```

3. **Add to .gitignore:**

```bash
echo "/.castor-cache/" >> your-project/.gitignore
```

4. **Test:**

```bash
cd your-project
castor list      # Downloads PHPQA tasks automatically
castor qa:lint   # Quick test
```

## 📁 Project Structure

After setup, your project will have:

```
your-project/
├── .castor-cache/          # Cache directory (gitignored)
│   ├── phpqa.php          # Downloaded from GitHub
│   └── phpqa.version      # Cached version marker
├── .phpqa-config.php      # Configuration (optional)
├── castor.php             # ~40 lines with auto-download
├── .gitignore             # Contains: .castor-cache/
└── .github/
    └── workflows/
        └── ci.yml         # Reusable workflow configuration
```

## 🎯 How It Works

### First Run

```bash
$ castor list

  Downloading PHPQA tasks from GitHub...
  ✓ PHPQA tasks downloaded successfully!

Available commands:
  qa:phpunit          Run PHPUnit tests with coverage
  qa:phpstan          Run PHPStan
  qa:ecs              Run Easy Coding Standard
  ...
```

### Subsequent Runs

```bash
$ castor list

Available commands:
  qa:phpunit          Run PHPUnit tests with coverage
  ...
```

The downloaded tasks are cached in `.castor-cache/` and reused.

### Update PHPQA Tasks

```bash
# Force re-download of latest version
rm -rf .castor-cache/
castor list
```

## 📋 Available Commands

### Quality Assurance Commands (namespace: `qa:`)

```bash
# Testing
castor qa:phpunit              # Run PHPUnit with coverage
castor qa:infect               # Mutation testing with Infection

# Static Analysis
castor qa:phpstan              # Run PHPStan
castor qa:phpstan-baseline     # Generate PHPStan baseline

# Code Style
castor qa:ecs                  # Check coding standards
castor qa:ecs-fix              # Fix coding standards automatically

# Refactoring
castor qa:rector               # Check Rector rules
castor qa:rector-fix           # Apply Rector refactorings

# Architecture & Quality
castor qa:deptrac              # Validate architecture layers
castor qa:lint                 # Check PHP syntax
castor qa:validate             # Validate composer.json
castor qa:check-licenses       # Check dependency licenses

# JavaScript
castor qa:js                   # Run JavaScript tests (if enabled)

# Combined
castor qa:prepare-pr           # Prepare code for PR (fix + analyze)
castor qa:all                  # Run all QA checks

# Utilities
castor qa:install              # Install composer dependencies
castor qa:update-image         # Update PHPQA Docker image
castor qa:exec [command]       # Execute custom QA command
```

### Application Commands (namespace: `app:`)

For application projects:

```bash
castor app:console [command]   # Run Symfony console commands
```

## 🔧 Configuration

### Optional `.phpqa-config.php`

Create this file in your project root to customize behavior:

```php
<?php

return [
    // Project type: library, bundle, or application
    'type' => 'library',

    // PHP version for Docker (default: current PHP version)
    'php_version' => '8.4',

    // Source directories to analyze
    'source_dirs' => ['src', 'tests'],

    // Enable/disable specific features
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
    'js_enabled' => false,
    'docker_enabled' => true,

    // Symfony console path (for applications)
    'console_path' => 'bin/console',

    // Allowed licenses
    'allowed_licenses' => [
        'Apache-2.0',
        'BSD-2-Clause',
        'BSD-3-Clause',
        'ISC',
        'MIT',
        'MPL-2.0',
        'OSL-3.0',
    ],
];
```

**Note:** This file is optional. If not present, sensible defaults are used.

### Example Configurations

**For a Library/Bundle:**

```php
<?php
return [
    'type' => 'library',
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
];
```

**For an Application:**

```php
<?php
return [
    'type' => 'application',
    'check_licenses' => false,
    'infection_enabled' => false,
    'js_enabled' => true,
    'console_path' => 'bin/console',
];
```

## 🌐 GitHub Actions

### Using the Reusable Workflow

Create `.github/workflows/ci.yml`:

**For a Library:**

```yaml
name: PHP CI

on:
  push:
    branches: ['*.x']
    tags: ['*']
  pull_request: ~
  workflow_dispatch: ~

jobs:
  ci:
    uses: Spomky-Labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'library'
      php_versions: '["8.2", "8.3", "8.4"]'
      experimental_php_versions: '["8.5"]'
      enable_infection: true
      enable_deptrac: true
      enable_license_check: true
```

**For an Application:**

```yaml
name: PHP CI

on:
  push:
    branches: ['main', 'develop']
    tags: ['*']
  pull_request: ~

jobs:
  ci:
    uses: Spomky-Labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'application'
      php_versions: '["8.4"]'
      enable_lowest_deps: false
      enable_infection: false
      enable_license_check: false
      enable_js_tests: true
```

### Workflow Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `project_type` | `'library'` | Project type (library/bundle/application) |
| `php_versions` | `'["8.2","8.3","8.4"]'` | PHP versions to test |
| `experimental_php_versions` | `'["8.5"]'` | Experimental PHP versions |
| `default_php_version` | `'8.4'` | PHP version for QA checks |
| `enable_lowest_deps` | `true` | Test with lowest dependencies |
| `enable_infection` | `true` | Enable mutation testing |
| `enable_deptrac` | `true` | Enable architecture checks |
| `enable_license_check` | `true` | Enable license validation |
| `enable_js_tests` | `false` | Enable JavaScript tests |

## 🎨 Common Workflows

### Daily Development

```bash
# Before committing
castor qa:prepare-pr

# Quick checks
castor qa:lint
castor qa:phpstan

# Run tests
castor qa:phpunit
```

### Fixing Issues

```bash
# Auto-fix code style
castor qa:ecs-fix

# Apply refactorings
castor qa:rector-fix

# Re-run checks
castor qa:all
```

### Pull Request Preparation

```bash
# One command to prepare everything
castor qa:prepare-pr

# This runs:
# - ecs-fix (auto-fix code style)
# - rector-fix (apply refactorings)
# - phpstan-baseline (update baseline)
# - deptrac (check architecture)
# - lint (syntax check)
```

### CI Simulation

```bash
# Run all checks locally (like CI)
castor qa:all
```

## 🔄 Versioning

You can use different PHPQA versions by changing the `$targetVersion` in your `castor.php`:

```php
// Latest version (default)
$targetVersion = 'main';

// Specific tagged version
$targetVersion = 'v1.0.0';

// Development branch
$targetVersion = 'develop';
```

After changing the version, delete the cache to download the new version:

```bash
rm -rf .castor-cache/
castor list
```

## 📦 Customization

### Adding Project-Specific Tasks

You can add your own tasks after the PHPQA import in `castor.php`:

```php
<?php

use function Castor\import;
use function Castor\io;

// PHPQA auto-download code...
import($phpqaFile);

// Your custom tasks below:

use Castor\Attribute\AsTask;
use function Castor\run;

#[AsTask(description: 'My custom task')]
function my_task(): void
{
    io()->title('Running my custom task');
    run(['echo', 'Hello from my task!']);
}
```

### Application-Specific Tasks

For applications, add Docker management tasks:

```php
#[AsTask(description: 'Start Docker containers')]
function start(): void
{
    run(['docker', 'compose', 'up', '-d']);
}

#[AsTask(description: 'Stop Docker containers')]
function stop(): void
{
    run(['docker', 'compose', 'down']);
}
```

See `examples/castor-application.php` for a complete example.

## 🐛 Troubleshooting

### "Failed to download PHPQA tasks"

**Solution 1: Check internet connection**

```bash
curl https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/phpqa.php
```

**Solution 2: Use cached version**

If you've downloaded before, the cache will be used automatically even without internet.

**Solution 3: Manual download**

```bash
mkdir -p .castor-cache
curl -o .castor-cache/phpqa.php \
  https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/phpqa.php
```

### Cache Not Working

Check cache files exist and have correct permissions:

```bash
ls -la .castor-cache/
stat .castor-cache/phpqa.php
```

### Force Update

```bash
# Delete entire cache
rm -rf .castor-cache/

# Or just the version marker
rm .castor-cache/phpqa.version

# Then run castor again
castor list
```

### Castor Command Not Found

Install Castor:

```bash
# Via Composer
composer global require castor/castor

# Or download binary from
# https://github.com/jolicode/castor/releases
```

## 🎓 Examples

Complete examples are available in the `examples/` directory:

- **`castor-simple.php`** - Minimal setup (just PHPQA tasks)
- **`castor-library.php`** - For PHP libraries/bundles
- **`castor-application.php`** - For applications with Docker tasks
- **`.phpqa-config-library.php`** - Library configuration example
- **`.phpqa-config-application.php`** - Application configuration example
- **`ci-library.yml`** - GitHub Actions for libraries
- **`ci-application.yml`** - GitHub Actions for applications

## ✅ Migration Checklist

When migrating an existing project:

- [ ] Run `./scripts/migrate-project.sh /path/to/project type`
- [ ] Verify `.phpqa-config.php` was created
- [ ] Verify `castor.php` contains GitHub download code
- [ ] Verify `.castor-cache/` is in `.gitignore`
- [ ] Test: `castor list`
- [ ] Test: `castor qa:lint`
- [ ] Test: `castor qa:phpstan`
- [ ] Test: `castor qa:all`
- [ ] Review `castor.php.backup` for custom tasks
- [ ] Copy any custom tasks to new `castor.php`
- [ ] Review `.github/workflows/ci.yml`
- [ ] Commit changes
- [ ] Push and verify CI passes
- [ ] Delete `castor.php.backup` once validated

## 📚 Next Steps

1. **Read [INTEGRATION.md](INTEGRATION.md)** for detailed integration guide
2. **Read [ARCHITECTURE.md](ARCHITECTURE.md)** for technical details
3. **Check [examples/](examples/)** for ready-to-use templates
4. **See [SUMMARY.md](SUMMARY.md)** for complete overview

## 🎉 Success!

You now have:
- ✅ PHPQA tasks automatically downloaded from GitHub
- ✅ Minimal configuration in your project
- ✅ All QA commands available via Castor
- ✅ Reusable GitHub Actions workflow
- ✅ Works anywhere, no path dependencies

Start using it:

```bash
castor qa:all
```

Happy coding! 🚀
