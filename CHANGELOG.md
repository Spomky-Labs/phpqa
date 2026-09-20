# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Changed - Lean Docker image (3.2 GB → ~0.8 GB, 689 MB → ~150 MB compressed)

- The image is no longer based on `jakzal/phpqa`. It is a two-stage build on the official
  `php:X.Y-cli` image, with a `debian:slim` runtime stage that only contains the PHP binary,
  the compiled extensions, the QA tools and their runtime libraries (no compiler, no headers,
  no PHP sources, no unused toolbox tools).
- PHP extensions are installed with `install-php-extensions` (build deps are purged in the
  same layer); PIE and `docker-php-source` are gone.
- Only the tools used by the Castor tasks are installed: PHPStan (+ extensions), ECS, Rector,
  Deptrac, Infection, PHPUnit 10-13 PHARs (`phpunit` points to the newest one the PHP
  version supports), PHPUnit helper libraries, parallel-lint,
  composer-normalize. Identical files across tools are hard-linked to save space.
- The `/tools/.composer/vendor-bin/{phpstan,phpunit,...}` layout is preserved, so project
  configurations referencing it keep working.
- `XDEBUG_MODE` now defaults to `off` (the CI sets `coverage` for test jobs).
- `date.timezone` is `UTC` (was `Europe/London`).
- Removed: `ast` extension, `graphviz`, `make`, PIE, and every jakzal toolbox tool that the
  Castor tasks do not call (psalm, phpmd, phpcs, behat, codeception, ...).

### Fixed

- `castor` is now installed as a static binary, so it also works on the PHP 8.2 and 8.3
  images (the PHAR requires PHP >= 8.4 and was broken there).

### Added - Centralized CI/CD System

#### 🔄 Reusable Castor Tasks
- **NEW:** `.castor/phpqa.php` - Centralized Castor tasks for all projects
- All QA tasks now available in `qa:` namespace
  - `qa:phpunit` - Run PHPUnit with coverage
  - `qa:phpstan` / `qa:phpstan-baseline` - Static analysis
  - `qa:ecs` / `qa:ecs-fix` - Coding standards
  - `qa:rector` / `qa:rector-fix` - Automated refactoring
  - `qa:deptrac` - Architecture validation
  - `qa:lint` - PHP syntax checking
  - `qa:infect` - Mutation testing
  - `qa:validate` - Composer validation
  - `qa:check-licenses` - License compatibility check
  - `qa:js` - JavaScript tests
  - `qa:prepare-pr` - Prepare code for pull request
  - `qa:all` - Run all QA checks
  - `qa:install` - Install dependencies
  - `qa:update-image` - Update PHPQA Docker image
  - `qa:exec` - Execute arbitrary QA command
- Application tasks in `app:` namespace
  - `app:console` - Run Symfony console commands
- Configuration system via `.phpqa-config.php`
  - Optional configuration with sensible defaults
  - Support for library, bundle, and application projects
  - Customizable per project needs

#### ⚙️ Reusable GitHub Actions Workflow
- **NEW:** `.github/workflows/reusable-ci.yml` - Single workflow for all projects
- Configurable via workflow inputs
- Support for multiple PHP versions (matrix)
- Experimental PHP version support
- Optional features:
  - Lowest dependencies testing
  - Mutation testing (Infection)
  - Architecture checks (Deptrac)
  - License validation
  - Exported files verification
  - JavaScript tests
- Parallel job execution for faster CI
- Dependency caching

#### 📚 Documentation
- **NEW:** `INTEGRATION.md` - Complete integration guide
  - Step-by-step setup instructions
  - Configuration options reference
  - Migration guide for existing projects
  - Troubleshooting section
  - Examples for different project types
- **NEW:** `ARCHITECTURE.md` - Architecture documentation
  - Project structure explanation
  - Component descriptions
  - Data flow diagrams
  - Extension guidelines
  - Best practices
- **NEW:** `examples/` directory with ready-to-use templates
  - `.phpqa-config-library.php` - Library/bundle configuration
  - `.phpqa-config-application.php` - Application configuration
  - `castor-library.php` - Minimal castor.php for libraries
  - `castor-application.php` - Extended castor.php for applications
  - `ci-library.yml` - GitHub Actions for libraries
  - `ci-application.yml` - GitHub Actions for applications
  - `README.md` - Examples documentation

#### 🛠️ Automation Tools
- **NEW:** `scripts/migrate-project.sh` - Automated migration script
  - Backs up existing configuration
  - Creates appropriate `.phpqa-config.php`
  - Generates castor.php with correct imports
  - Sets up GitHub Actions workflow
  - Provides migration summary

#### 📖 Updated Documentation
- Updated main `README.md` with Quick Start section
- Added links to integration guide
- Documented centralized approach benefits

### Benefits

✅ **Centralization**
- Single source of truth for QA tasks
- Updates benefit all projects immediately
- Consistent tooling across organization

✅ **Simplicity**
- Minimal configuration per project
- Optional `.phpqa-config.php` with smart defaults
- No code duplication

✅ **Flexibility**
- Support for different project types
- Customizable per project
- Extensible with project-specific tasks

✅ **Maintainability**
- One place to update QA processes
- Automated migration for existing projects
- Clear separation of concerns

✅ **Performance**
- Parallel CI job execution
- Shared Composer cache
- Docker image reuse

### Migration Guide

For existing projects, see [INTEGRATION.md](INTEGRATION.md) or use the migration script:

```bash
./scripts/migrate-project.sh /path/to/your/project library
```

### Breaking Changes

None. This is an additive feature that doesn't affect existing Docker image usage.

Projects can continue using the Docker image directly without adopting the centralized tasks.

---

## Previous Releases

See git history for changes to the Docker image and previous versions.
