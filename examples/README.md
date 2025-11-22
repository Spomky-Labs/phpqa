# PHPQA Integration Examples

This directory contains example configurations for integrating PHPQA into your projects.

## Files

### Configuration Examples

- **`.phpqa-config-library.php`** - Configuration for PHP libraries and bundles
- **`.phpqa-config-application.php`** - Configuration for full applications

### Castor Examples

- **`castor-library.php`** - Minimal castor.php for libraries/bundles
- **`castor-application.php`** - Extended castor.php with application-specific tasks

### GitHub Actions Examples

- **`ci-library.yml`** - Workflow for libraries/bundles
- **`ci-application.yml`** - Workflow for applications

## Quick Start

### For a Library/Bundle

1. Copy `.phpqa-config-library.php` to your project root as `.phpqa-config.php`
2. Copy `castor-library.php` to your project root as `castor.php`
3. Copy `ci-library.yml` to `.github/workflows/ci.yml`
4. Adjust paths and settings as needed

### For an Application

1. Copy `.phpqa-config-application.php` to your project root as `.phpqa-config.php`
2. Copy `castor-application.php` to your project root as `castor.php`
3. Copy `ci-application.yml` to `.github/workflows/ci.yml`
4. Adjust paths and settings as needed

## Migration Script

Use the automated migration script instead:

```bash
# From the phpqa directory
./scripts/migrate-project.sh /path/to/your/project library
```

This will automatically:
- Backup existing files
- Create appropriate configuration
- Set up castor.php with correct imports
- Create GitHub Actions workflow

## Documentation

See [INTEGRATION.md](../INTEGRATION.md) for complete documentation.
