<?php

/**
 * Minimal castor.php for any PHP project
 *
 * This is the simplest way to use PHPQA in your project.
 * Just copy this file to your project root as castor.php
 *
 * PHPQA tasks will be downloaded automatically from GitHub
 * and cached in .castor-cache/ directory.
 */

declare(strict_types=1);

use function Castor\import;
use function Castor\io;

// Download and cache PHPQA tasks from GitHub
$phpqaFile = __DIR__ . '/.castor-cache/phpqa.php';
$phpqaVersion = __DIR__ . '/.castor-cache/phpqa.version';
$phpqaUrl = 'https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/phpqa.php';
$targetVersion = 'main';

// Create cache directory
if (!is_dir(__DIR__ . '/.castor-cache')) {
    mkdir(__DIR__ . '/.castor-cache', 0755, true);
}

// Download if not cached or outdated
if (!file_exists($phpqaFile)
    || !file_exists($phpqaVersion)
    || trim(file_get_contents($phpqaVersion)) !== $targetVersion
) {
    io()->note('Downloading PHPQA tasks from GitHub...');

    $content = @file_get_contents($phpqaUrl);

    if ($content === false) {
        if (file_exists($phpqaFile)) {
            io()->warning('Failed to download, using cached version');
        } else {
            io()->error('Failed to download PHPQA tasks and no cache available');
            exit(1);
        }
    } else {
        file_put_contents($phpqaFile, $content);
        file_put_contents($phpqaVersion, $targetVersion);
        io()->success('PHPQA tasks downloaded successfully!');
    }
}

// Import the cached file
import($phpqaFile);

// That's it! All PHPQA tasks are now available:
// - castor qa:phpunit
// - castor qa:phpstan
// - castor qa:ecs
// - castor qa:rector
// - castor qa:all
// - etc.
//
// Run 'castor list' to see all available tasks

// Add your project-specific tasks below if needed
