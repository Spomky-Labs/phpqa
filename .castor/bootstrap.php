<?php

declare(strict_types=1);

/**
 * PHPQA Bootstrap
 *
 * This file handles the automatic download and import of PHPQA tasks.
 * Just import this file in your castor.php and it will handle everything.
 *
 * Usage in your castor.php:
 *
 *   import('https://raw.githubusercontent.com/Spomky-Labs/phpqa/main/.castor/bootstrap.php');
 *
 * Or if you want to use a local cache:
 *
 *   use function phpqa\bootstrap;
 *   require __DIR__ . '/.castor/phpqa-bootstrap.php';
 *   bootstrap();
 */

namespace phpqa;

use function Castor\cache;
use function Castor\import;
use function Castor\io;

const PHPQA_GITHUB_REPO = 'Spomky-Labs/phpqa';
const PHPQA_GITHUB_RAW_URL = 'https://raw.githubusercontent.com/' . PHPQA_GITHUB_REPO;
const PHPQA_CACHE_DIR = '.castor-cache';
const PHPQA_CACHE_FILE = self::PHPQA_CACHE_DIR . '/phpqa.php';
const PHPQA_VERSION_FILE = self::PHPQA_CACHE_DIR . '/phpqa.version';

/**
 * Bootstrap PHPQA tasks
 *
 * Downloads and imports the latest PHPQA tasks from GitHub
 */
function bootstrap(string $version = 'main', bool $forceUpdate = false): void
{
    $cacheDir = getcwd() . '/' . PHPQA_CACHE_DIR;
    $cacheFile = getcwd() . '/' . PHPQA_CACHE_FILE;
    $versionFile = getcwd() . '/' . PHPQA_VERSION_FILE;

    // Create cache directory if it doesn't exist
    if (!is_dir($cacheDir)) {
        mkdir($cacheDir, 0755, true);
    }

    // Check if we need to update
    $needsUpdate = $forceUpdate
        || !file_exists($cacheFile)
        || !file_exists($versionFile)
        || trim(file_get_contents($versionFile)) !== $version;

    if ($needsUpdate) {
        downloadPhpqa($version, $cacheFile, $versionFile);
    }

    // Import the cached file
    import($cacheFile);
}

/**
 * Download PHPQA tasks from GitHub
 */
function downloadPhpqa(string $version, string $cacheFile, string $versionFile): void
{
    $url = PHPQA_GITHUB_RAW_URL . '/' . $version . '/.castor/phpqa.php';

    io()->note(sprintf('Downloading PHPQA tasks from: %s', $url));

    $content = @file_get_contents($url);

    if ($content === false) {
        $error = error_get_last();
        io()->error(sprintf('Failed to download PHPQA tasks: %s', $error['message'] ?? 'Unknown error'));
        io()->warning('Using cached version if available');

        if (!file_exists($cacheFile)) {
            io()->error('No cached version available. Please check your internet connection and try again.');
            exit(1);
        }

        return;
    }

    // Save to cache
    file_put_contents($cacheFile, $content);
    file_put_contents($versionFile, $version);

    io()->success('PHPQA tasks downloaded successfully!');
}

/**
 * Clear the PHPQA cache
 */
function clearCache(): void
{
    $cacheDir = getcwd() . '/' . PHPQA_CACHE_DIR;

    if (is_dir($cacheDir)) {
        array_map('unlink', glob($cacheDir . '/*'));
        rmdir($cacheDir);
        io()->success('PHPQA cache cleared!');
    } else {
        io()->note('No cache to clear');
    }
}

/**
 * Update PHPQA to the latest version
 */
function updatePhpqa(string $version = 'main'): void
{
    io()->title('Updating PHPQA tasks...');
    clearCache();
    bootstrap($version, true);
    io()->success('PHPQA tasks updated successfully!');
}

// Auto-bootstrap if this file is imported directly
if (basename(debug_backtrace()[0]['file'] ?? '') !== 'bootstrap.php') {
    bootstrap();
}
