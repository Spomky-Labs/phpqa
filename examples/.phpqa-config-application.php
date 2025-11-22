<?php

/**
 * PHPQA Configuration Example for Application Projects
 *
 * Copy this file to your project root as .phpqa-config.php
 * and customize according to your needs.
 */

return [
    // Project type: library, bundle, or application
    'type' => 'application',

    // PHP version to use (defaults to current PHP version)
    'php_version' => '8.4',

    // Source directories to analyze
    'source_dirs' => ['src', 'tests'],

    // License checking (often disabled for applications)
    'check_licenses' => false,

    // Tools configuration
    'phpstan_level' => 'max',
    'infection_enabled' => false, // Often disabled for apps
    'deptrac_enabled' => true,
    'js_enabled' => true, // Applications often have JS

    // Docker configuration
    'docker_enabled' => true,

    // Symfony console path
    'console_path' => 'bin/console',
];
