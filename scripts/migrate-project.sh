#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   PHPQA Project Migration Script                      ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if a project path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No project path provided${NC}"
    echo "Usage: $0 <project-path> [project-type]"
    echo ""
    echo "Project types: library, bundle, application"
    echo ""
    echo "Example: $0 /path/to/my-project library"
    exit 1
fi

PROJECT_PATH="$1"
PROJECT_TYPE="${2:-library}"

# Validate project path
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Validate project type
if [[ ! "$PROJECT_TYPE" =~ ^(library|bundle|application)$ ]]; then
    echo -e "${RED}Error: Invalid project type: $PROJECT_TYPE${NC}"
    echo "Valid types: library, bundle, application"
    exit 1
fi

cd "$PROJECT_PATH"

echo -e "${YELLOW}Project path:${NC} $PROJECT_PATH"
echo -e "${YELLOW}Project type:${NC} $PROJECT_TYPE"
echo ""

# Step 1: Backup existing castor.php
if [ -f "castor.php" ]; then
    echo -e "${YELLOW}[1/5]${NC} Backing up existing castor.php..."
    mv castor.php castor.php.backup
    echo -e "${GREEN}✓${NC} Backed up to castor.php.backup"
else
    echo -e "${YELLOW}[1/5]${NC} No existing castor.php found, skipping backup"
fi
echo ""

# Step 2: Create .phpqa-config.php
echo -e "${YELLOW}[2/5]${NC} Creating .phpqa-config.php..."

if [ -f ".phpqa-config.php" ]; then
    echo -e "${YELLOW}⚠${NC}  .phpqa-config.php already exists, skipping"
else
    if [ "$PROJECT_TYPE" = "application" ]; then
        cat > .phpqa-config.php << 'EOF'
<?php

return [
    'type' => 'application',
    'check_licenses' => false,
    'infection_enabled' => false,
    'js_enabled' => true,
    'console_path' => 'bin/console',
];
EOF
    else
        cat > .phpqa-config.php << 'EOF'
<?php

return [
    'type' => 'library',
    'check_licenses' => true,
    'infection_enabled' => true,
    'deptrac_enabled' => true,
];
EOF
    fi
    echo -e "${GREEN}✓${NC} Created .phpqa-config.php"
fi
echo ""

# Step 3: Create new castor.php with GitHub download
echo -e "${YELLOW}[3/5]${NC} Creating new castor.php..."

if [ "$PROJECT_TYPE" = "application" ]; then
    cat > castor.php << 'EOF'
<?php

declare(strict_types=1);

use Castor\Attribute\AsTask;
use function Castor\import;
use function Castor\io;
use function Castor\notify;
use function Castor\run;

// Download and cache PHPQA tasks from GitHub
$phpqaFile = __DIR__ . '/.castor-cache/phpqa.php';
$phpqaVersion = __DIR__ . '/.castor-cache/phpqa.version';
$phpqaUrl = 'https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/phpqa.php';
$targetVersion = 'main';

if (!is_dir(__DIR__ . '/.castor-cache')) {
    mkdir(__DIR__ . '/.castor-cache', 0755, true);
}

if (!file_exists($phpqaFile)
    || !file_exists($phpqaVersion)
    || trim(file_get_contents($phpqaVersion)) !== $targetVersion
) {
    io()->note('Downloading PHPQA tasks...');
    $content = @file_get_contents($phpqaUrl);
    if ($content !== false) {
        file_put_contents($phpqaFile, $content);
        file_put_contents($phpqaVersion, $targetVersion);
        io()->success('PHPQA tasks downloaded!');
    } elseif (!file_exists($phpqaFile)) {
        io()->error('Failed to download PHPQA tasks');
        exit(1);
    }
}

import($phpqaFile);

// Add your project-specific tasks below
// Example tasks for applications:

#[AsTask(description: 'Start the application containers')]
function start(): void
{
    run(['docker', 'compose', 'up', '-d']);
    notify('Application started');
}

#[AsTask(description: 'Stop the application containers')]
function stop(): void
{
    run(['docker', 'compose', 'down']);
}

#[AsTask(description: 'Restart the application containers')]
function restart(): void
{
    stop();
    start();
}
EOF
else
    cat > castor.php << 'EOF'
<?php

declare(strict_types=1);

use function Castor\import;
use function Castor\io;

// Download and cache PHPQA tasks from GitHub
$phpqaFile = __DIR__ . '/.castor-cache/phpqa.php';
$phpqaVersion = __DIR__ . '/.castor-cache/phpqa.version';
$phpqaUrl = 'https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/phpqa.php';
$targetVersion = 'main';

if (!is_dir(__DIR__ . '/.castor-cache')) {
    mkdir(__DIR__ . '/.castor-cache', 0755, true);
}

if (!file_exists($phpqaFile)
    || !file_exists($phpqaVersion)
    || trim(file_get_contents($phpqaVersion)) !== $targetVersion
) {
    io()->note('Downloading PHPQA tasks...');
    $content = @file_get_contents($phpqaUrl);
    if ($content !== false) {
        file_put_contents($phpqaFile, $content);
        file_put_contents($phpqaVersion, $targetVersion);
        io()->success('PHPQA tasks downloaded!');
    } elseif (!file_exists($phpqaFile)) {
        io()->error('Failed to download PHPQA tasks');
        exit(1);
    }
}

import($phpqaFile);

// Add your project-specific tasks below
EOF
fi

echo -e "${GREEN}✓${NC} Created castor.php with GitHub download"
echo ""

# Step 3.5: Add .castor-cache to .gitignore
echo -e "${YELLOW}[3.5/5]${NC} Updating .gitignore..."
if [ -f ".gitignore" ]; then
    if ! grep -q "^\.castor-cache" .gitignore; then
        echo "" >> .gitignore
        echo "# PHPQA cache" >> .gitignore
        echo ".castor-cache/" >> .gitignore
        echo -e "${GREEN}✓${NC} Added .castor-cache to .gitignore"
    else
        echo -e "${YELLOW}⚠${NC}  .castor-cache already in .gitignore"
    fi
else
    cat > .gitignore << 'EOF'
# PHPQA cache
.castor-cache/
EOF
    echo -e "${GREEN}✓${NC} Created .gitignore with .castor-cache"
fi
echo ""

# Step 4: Create GitHub Actions workflow
echo -e "${YELLOW}[4/5]${NC} Creating GitHub Actions workflow..."

mkdir -p .github/workflows

if [ -f ".github/workflows/ci.yml" ]; then
    echo -e "${YELLOW}⚠${NC}  .github/workflows/ci.yml already exists"
    mv .github/workflows/ci.yml .github/workflows/ci.yml.backup
    echo -e "${GREEN}✓${NC} Backed up to ci.yml.backup"
fi

if [ "$PROJECT_TYPE" = "application" ]; then
    cat > .github/workflows/ci.yml << 'EOF'
name: 📁 PHP CI

on:
  push:
    branches: ['main', 'develop']
    tags: ['*']
  pull_request: ~
  workflow_dispatch: ~

jobs:
  ci:
    uses: Spomky-Labs/phpqa/.github/workflows/reusable-ci.yml@main
    with:
      project_type: 'application'
      php_versions: '["8.4"]'
      enable_lowest_deps: false
      enable_infection: false
      enable_license_check: false
      enable_exported_files_check: false
      enable_js_tests: true
EOF
else
    cat > .github/workflows/ci.yml << 'EOF'
name: 📁 PHP CI

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
EOF
fi

echo -e "${GREEN}✓${NC} Created .github/workflows/ci.yml"
echo ""

# Step 5: Summary
echo -e "${YELLOW}[5/5]${NC} Migration complete!"
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Migration Summary                                   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Files created:"
echo -e "  ${GREEN}✓${NC} .phpqa-config.php"
echo -e "  ${GREEN}✓${NC} castor.php (with GitHub download)"
echo -e "  ${GREEN}✓${NC} .github/workflows/ci.yml"
echo -e "  ${GREEN}✓${NC} .gitignore (updated)"
echo ""

if [ -f "castor.php.backup" ]; then
    echo -e "${YELLOW}⚠${NC}  Old castor.php backed up as castor.php.backup"
    echo -e "   Review it to migrate any custom tasks to the new castor.php"
    echo ""
fi

echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Review and customize .phpqa-config.php if needed"
echo -e "  2. Test Castor tasks: ${BLUE}castor list${NC}"
echo -e "  3. Run QA checks: ${BLUE}castor qa:all${NC}"
echo -e "  4. Commit the changes (including .gitignore)"
echo ""
echo -e "${YELLOW}Note:${NC} .castor-cache/ is gitignored (it contains downloaded PHPQA tasks)"
echo ""
echo -e "${GREEN}✓ Migration complete!${NC}"
