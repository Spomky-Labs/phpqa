<?php

/**
 * Example castor.php for Application Projects
 *
 * This castor.php downloads PHPQA tasks from GitHub and adds
 * application-specific tasks like Docker management.
 */

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

// Application-specific tasks

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

#[AsTask(description: 'Build the Docker images')]
function build(): void
{
    run(['docker', 'compose', 'build', '--no-cache', '--pull']);
}

#[AsTask(description: 'Clean the infrastructure')]
function destroy(bool $force = false): void
{
    if (!$force) {
        io()->warning('This will permanently remove all containers, volumes, networks...');
        if (!io()->confirm('Are you sure?', false)) {
            io()->comment('Aborted.');
            return;
        }
    }

    run('docker-compose down -v --remove-orphans --volumes --rmi=local');
    notify('Infrastructure destroyed.');
}

#[AsTask(description: 'Update dependencies and run migrations')]
function update(): void
{
    run(['composer', 'update']);

    // Run Symfony console commands if available
    $commands = [
        'doctrine:migrations:migrate' => ['--no-interaction'],
        'doctrine:schema:validate' => [],
        'cache:clear' => [],
    ];

    foreach ($commands as $command => $arguments) {
        try {
            \phpqa\console([$command, ...$arguments]);
        } catch (\Throwable) {
            // Command might not exist, skip
        }
    }
}
