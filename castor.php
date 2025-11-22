<?php

declare(strict_types=1);

/**
 * This is the main castor.php for the PHPQA project itself.
 *
 * For examples of how to use PHPQA in your projects,
 * see the examples/ directory.
 */

use Castor\Attribute\AsTask;
use function Castor\import;
use function Castor\io;
use function Castor\run;

// Import our own tasks (for testing and dogfooding)
import(__DIR__ . '/.castor/phpqa.php');

#[AsTask(description: 'Build all Docker images')]
function build(): void
{
    io()->title('Building Docker images');

    $versions = ['8.2', '8.3', '8.4'];

    foreach ($versions as $version) {
        io()->section("Building PHP $version");
        run([
            'docker', 'build',
            '--build-arg', "PHP_VERSION=$version",
            '-t', "ghcr.io/spomky-labs/phpqa:$version",
            '.'
        ]);
    }

    io()->success('All images built successfully!');
}

#[AsTask(description: 'Test the migration script')]
function test_migration(string $projectPath): void
{
    io()->title('Testing migration script');

    run(['./scripts/migrate-project.sh', $projectPath, 'library']);

    io()->success('Migration script test completed!');
}

#[AsTask(description: 'Show project structure')]
function structure(): void
{
    io()->title('PHPQA Project Structure');

    run(['find', '.', '-type', 'f', '-o', '-type', 'd', '|', 'grep', '-v', '\.git\|\.idea\|\.claude', '|', 'sort']);
}
