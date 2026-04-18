<?php

declare(strict_types=1);

/*
 * CodeIgniter 4 - Public entry point
 */

// Chemin vers le répertoire de l'application
$pathsConfig = FCPATH . '../app/Config/Paths.php';

// ---------------------------------------------------------------
// LOAD THE BOOTSTRAP FILE
// ---------------------------------------------------------------
// Load our paths config here, as we need them before CodeIgniter is loaded.
if (! is_file($pathsConfig)) {
    header('HTTP/1.1 503 Service Unavailable.', true, 503);
    echo 'The application folder path does not appear to be set correctly. Please open the following file and correct this: ' . $pathsConfig;
    exit(3);
}

require $pathsConfig;
$paths = new Config\Paths();

// Location of the framework bootstrap file.
require rtrim($paths->systemDirectory, '\\/ ') . DIRECTORY_SEPARATOR . 'bootstrap.php';

// Load environment settings from .env files into $_SERVER and $_ENV
require_once SYSTEMPATH . 'Config/DotEnv.php';

(new CodeIgniter\Config\DotEnv(ROOTPATH))->load();

// Define ENVIRONMENT
if (! defined('ENVIRONMENT')) {
    define('ENVIRONMENT', env('CI_ENVIRONMENT', 'production'));
}

/*
 * ---------------------------------------------------------------
 * DEFINE FCPATH
 * ---------------------------------------------------------------
 */
// The path to the front controller (this file)
define('FCPATH', __DIR__ . DIRECTORY_SEPARATOR);

// Launch the application!
$app = Config\Services::codeigniter();
$app->initialize();
$context = is_cli() ? 'php-cli' : 'web';
$app->setContext($context);
$app->run();
