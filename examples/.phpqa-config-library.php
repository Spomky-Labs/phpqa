<?php

/**
 * PHPQA Configuration Example for Library/Bundle Projects
 *
 * Copy this file to your project root as .phpqa-config.php
 * and customize according to your needs.
 */

return [
    // Project type: library, bundle, or application
    'type' => 'library',

    // PHP version to use (defaults to current PHP version)
    'php_version' => '8.4',

    // Source directories to analyze
    'source_dirs' => ['src', 'tests'],

    // License checking
    'check_licenses' => true,
    'allowed_licenses' => [
        'Apache-2.0',
        'BSD-2-Clause',
        'BSD-3-Clause',
        'ISC',
        'MIT',
        'MPL-2.0',
        'OSL-3.0',
    ],

    // Tools configuration
    'phpstan_level' => 'max',
    'infection_enabled' => true,
    'deptrac_enabled' => true,
    'js_enabled' => false,

    // Docker configuration
    'docker_enabled' => true,
];
