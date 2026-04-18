<?php

use CodeIgniter\Boot;

define('FCPATH', __DIR__ . DIRECTORY_SEPARATOR);

if (getcwd() . DIRECTORY_SEPARATOR !== FCPATH) {
    chdir(FCPATH);
}

require FCPATH . '../vendor/autoload.php';

require FCPATH . '../app/Config/Paths.php';
$paths = new Config\Paths();

Boot::bootWeb($paths);
