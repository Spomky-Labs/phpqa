<?php

declare(strict_types=1);

/**
 * Centralized PHPQA Castor Tasks
 *
 * This file provides reusable Castor tasks for PHP quality assurance.
 * Import this file in your project's castor.php:
 *
 * import(__DIR__ . '/.castor/phpqa.php');
 */

namespace phpqa;

use Castor\Attribute\AsRawTokens;
use Castor\Attribute\AsTask;
use function Castor\context;
use function Castor\fs;
use function Castor\guard_min_version;
use function Castor\io;
use function Castor\run;

guard_min_version('v1.0.0');

/**
 * Get project configuration from .phpqa-config.php or use defaults
 */
function get_config(): array
{
    $configFile = getcwd() . '/.phpqa-config.php';

    $defaults = [
        'type' => 'library', // library, bundle, application
        'php_version' => getenv('PHP_VERSION') ?: \PHP_MAJOR_VERSION . '.' . \PHP_MINOR_VERSION,
        'source_dirs' => ['src', 'tests'],
        'check_licenses' => true,
        'allowed_licenses' => ['Apache-2.0', 'BSD-2-Clause', 'BSD-3-Clause', 'ISC', 'MIT', 'MPL-2.0', 'OSL-3.0'],
        'phpstan_level' => 'max',
        'infection_enabled' => true,
        'deptrac_enabled' => true,
        'js_enabled' => false,
        'docker_enabled' => true,
        'console_path' => 'bin/console',
    ];

    if (file_exists($configFile)) {
        $config = require $configFile;
        return array_merge($defaults, $config);
    }

    return $defaults;
}

/**
 * Execute a command using PHPQA Docker container or directly
 */
function phpqa(array $command, array $dockerOptions = []): void
{
    $config = get_config();
    $inContainer = file_exists('/.dockerenv');
    $hasDocker = trim((string) shell_exec('command -v docker')) !== '';

    if (!$hasDocker || $inContainer || !$config['docker_enabled']) {
        run($command);
        return;
    }

    ensureTmpPhpqa();

    $defaultDockerOptions = [
        '--rm',
        '--init',
        '-it',
        '--user', sprintf('%s:%s', getmyuid(), getmygid()),
        '--pull', 'always',
        '-v', getcwd() . ':/project',
        '-v', getcwd() . '/tmp-phpqa:/project/tmp-phpqa',
        '-w', '/project',
        '-e', 'XDEBUG_MODE=off',
        '-e', 'PHP_INI_SCAN_DIR=/usr/local/etc/php/conf.d',
        '-e', 'PHP_INI_ENTRY=sys_temp_dir=/project/tmp-phpqa',
    ];

    run([
        'docker', 'run',
        ...$defaultDockerOptions,
        ...$dockerOptions,
        'ghcr.io/spomky-labs/phpqa:' . $config['php_version'],
        ...$command,
    ]);
}

/**
 * @param array<string> $allowedLicenses
 */
#[AsTask(description: 'Check licenses', namespace: 'qa')]
function check_licenses(array $allowedLicenses = []): void
{
    $config = get_config();

    if (!$config['check_licenses']) {
        io()->info('License check is disabled in configuration');
        return;
    }

    if (empty($allowedLicenses)) {
        $allowedLicenses = $config['allowed_licenses'];
    }

    io()->title('Checking licenses');
    $allowedExceptions = [];
    $command = ['composer', 'licenses', '-f', 'json'];
    $context = context();
    $context = $context->withEnvironment([
        'XDEBUG_MODE' => 'off',
    ]);
    $context = $context->withQuiet();
    $result = run($command, context: $context);

    if (!$result->isSuccessful()) {
        io()->error('Cannot determine licenses');
        exit(1);
    }

    $licenses = json_decode((string) $result->getOutput(), true);
    $disallowed = array_filter(
        $licenses['dependencies'],
        static fn (array $info, $name) => !in_array($name, $allowedExceptions, true)
            && count(array_diff($info['license'], $allowedLicenses)) === 1,
        \ARRAY_FILTER_USE_BOTH
    );
    $allowed = array_filter(
        $licenses['dependencies'],
        static fn (array $info, $name) => in_array($name, $allowedExceptions, true)
            || count(array_diff($info['license'], $allowedLicenses)) === 0,
        \ARRAY_FILTER_USE_BOTH
    );

    if (count($disallowed) > 0) {
        io()->table(
            ['Package', 'License'],
            array_map(
                static fn ($name, $info) => [$name, implode(', ', $info['license'])],
                array_keys($disallowed),
                $disallowed
            )
        );
        io()->error('Disallowed licenses found');
        exit(1);
    }

    io()->table(
        ['Package', 'License'],
        array_map(
            static fn ($name, $info) => [$name, implode(', ', $info['license'])],
            array_keys($allowed),
            $allowed
        )
    );
    io()->success('All licenses are allowed');
}

#[AsTask(description: 'Update the PHPQA Docker image', namespace: 'qa')]
function update_image(): void
{
    $config = get_config();
    run(['docker', 'pull', 'ghcr.io/spomky-labs/phpqa:' . $config['php_version']]);
}

#[AsTask(description: 'Install composer dependencies', namespace: 'qa')]
function install(bool $lowest = false): void
{
    $command = ['composer', 'install'];
    if ($lowest) {
        $command[] = '--prefer-lowest';
    }
    phpqa($command);
}

#[AsTask(description: 'Run PHPUnit tests with coverage', namespace: 'qa', ignoreValidationErrors: true)]
function phpunit(#[AsRawTokens] array $args = []): void
{
    phpqa(
        [
            'composer', 'exec', '--', 'phpunit-11',
            '--coverage-xml', '.ci-tools/coverage',
            '--log-junit=.ci-tools/coverage/junit.xml',
            '--configuration', '.ci-tools/phpunit.xml.dist',
            '--display-warnings',
            '--display-deprecations',
            ...$args,
        ],
        ['-e', 'XDEBUG_MODE=coverage']
    );
}

#[AsTask(description: 'Run Easy Coding Standard', namespace: 'qa')]
function ecs(): void
{
    phpqa(['composer', 'exec', '--', 'ecs', 'check', '--config', '.ci-tools/ecs.php']);
}

#[AsTask(description: 'Fix coding style with Easy Coding Standard', namespace: 'qa')]
function ecs_fix(): void
{
    phpqa(['composer', 'exec', '--', 'ecs', 'check', '--config', '.ci-tools/ecs.php', '--fix']);
}

#[AsTask(description: 'Run Rector dry-run', namespace: 'qa')]
function rector(): void
{
    phpqa(['composer', 'exec', '--', 'rector', 'process', '--dry-run', '--config', '.ci-tools/rector.php']);
}

#[AsTask(description: 'Run Rector with fix', namespace: 'qa')]
function rector_fix(): void
{
    phpqa(['composer', 'exec', '--', 'rector', 'process', '--config', '.ci-tools/rector.php']);
}

#[AsTask(description: 'Run PHPStan', namespace: 'qa')]
function phpstan(): void
{
    phpqa([
        'composer', 'exec', '--', 'phpstan', 'analyse',
        '--error-format=github',
        '--configuration=.ci-tools/phpstan.neon'
    ]);
}

#[AsTask(description: 'Generate PHPStan baseline', namespace: 'qa')]
function phpstan_baseline(): void
{
    phpqa([
        'composer', 'exec', '--', 'phpstan', 'analyse',
        '--configuration=.ci-tools/phpstan.neon',
        '--generate-baseline=.ci-tools/phpstan-baseline.neon',
    ]);
}

#[AsTask(description: 'Run Deptrac', namespace: 'qa')]
function deptrac(): void
{
    $config = get_config();

    if (!$config['deptrac_enabled']) {
        io()->info('Deptrac is disabled in configuration');
        return;
    }

    if (!file_exists('.ci-tools/deptrac.yaml')) {
        io()->warning('No deptrac.yaml configuration found');
        return;
    }

    phpqa([
        'composer', 'exec', '--', 'deptrac',
        '--config-file', '.ci-tools/deptrac.yaml',
        '--report-uncovered',
        '--report-skipped',
        '--fail-on-uncovered',
    ]);
}

#[AsTask(description: 'Run PHP parallel linter', namespace: 'qa')]
function lint(): void
{
    $config = get_config();
    phpqa(['composer', 'exec', '--', 'parallel-lint', ...$config['source_dirs']]);
}

#[AsTask(description: 'Run Infection for mutation testing', namespace: 'qa')]
function infect(int $minMsi = 0, int $minCoveredMsi = 0): void
{
    $config = get_config();

    if (!$config['infection_enabled']) {
        io()->info('Infection is disabled in configuration');
        return;
    }

    phpqa([
        'composer', 'exec', '--', 'infection',
        '--coverage=.ci-tools/coverage',
        sprintf('--min-msi=%d', $minMsi),
        sprintf('--min-covered-msi=%d', $minCoveredMsi),
        '--threads=max',
        '--logger-github',
        '-s',
        '--filter=src/',
        '--configuration=.ci-tools/infection.json.dist',
    ], ['-e', 'XDEBUG_MODE=coverage']);
}

#[AsTask(description: 'Run JS tests', namespace: 'qa')]
function js(): void
{
    $config = get_config();

    if (!$config['js_enabled']) {
        io()->info('JS tests are disabled in configuration');
        return;
    }

    io()->title('Running JS tests');
    run(['npm', 'install', '--force']);
    run(['npm', 'test']);
}

#[AsTask(description: 'Validate composer.json', namespace: 'qa')]
function validate(): void
{
    phpqa(['composer', 'dump-autoload', '--optimize', '--strict-psr']);
    phpqa(['composer', 'validate', '--strict']);
    run(['composer', 'normalize', '--dry-run', '--diff'], allowFailure: true);
}

#[AsTask(description: 'Fix code style and apply Rector rules, then run static analysis', namespace: 'qa')]
function prepare_pr(): void
{
    io()->title('Preparing code for pull request…');

    ecs_fix();
    rector_fix();

    io()->section('Running static analysis…');
    phpstan_baseline();
    deptrac();
    lint();

    io()->success('Code is ready. You may now commit and push your changes.');
}

#[AsTask(description: 'Run all QA checks', namespace: 'qa')]
function all(): void
{
    io()->title('Running all QA checks…');

    lint();
    validate();
    ecs();
    rector();
    phpstan();
    deptrac();
    phpunit();

    io()->success('All QA checks passed!');
}

#[AsTask(description: 'Run QA command', namespace: 'qa', ignoreValidationErrors: true)]
function exec(#[AsRawTokens] array $args = []): void
{
    phpqa(['composer', 'exec', '--', ...$args]);
}

/**
 * Helper: Runs a Symfony Console command
 */
#[AsTask(description: 'Runs a Symfony Console command', namespace: 'app', ignoreValidationErrors: true)]
function console(#[AsRawTokens] array $args = []): void
{
    $config = get_config();

    if ($config['type'] !== 'application') {
        io()->warning('Console commands are only available for application projects');
        return;
    }

    if (!file_exists($config['console_path'])) {
        io()->error(sprintf('Console not found at: %s', $config['console_path']));
        return;
    }

    $inContainer = file_exists('/.dockerenv');
    $hasDocker = trim((string) shell_exec('command -v docker')) !== '';

    if (!$hasDocker || $inContainer) {
        run([$config['console_path'], ...$args]);
        return;
    }

    run(['php', $config['console_path'], ...$args]);
}

/**
 * Helper functions
 */
function ensureTmpPhpqa(): void
{
    $path = getcwd() . '/tmp-phpqa';
    ensureFolder($path);
}

function ensureFolder(string $path): void
{
    try {
        if (!fs()->exists($path)) {
            io()->comment(sprintf('Creating directory %s', $path));
            fs()->mkdir($path, 0777);
        }

        if (!is_writable($path)) {
            io()->comment(sprintf('Fixing permissions on %s', $path));
            fs()->chmod($path, 0777);
        }
    } catch (\Throwable $e) {
        io()->error(sprintf('Could not create or fix %s: %s', $path, $e->getMessage()));
        exit(1);
    }
}
