<?php

/**
 * Example castor.php for Library/Bundle Projects
 *
 * This castor.php downloads and caches PHPQA tasks from GitHub.
 * Copy this to your project root as castor.php
 */

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

// You can add project-specific tasks here if needed
// Example:
// use Castor\Attribute\AsTask;
//
// #[AsTask(description: 'Custom task for this project')]
// function custom_task(): void
// {
//     // Your custom logic here
// }
