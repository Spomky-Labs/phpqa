# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
