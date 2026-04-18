<?php

namespace App\Controllers;

use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\RESTful\ResourceController;

class HomeController extends ResourceController
{
    public function index(): ResponseInterface
    {
        return $this->respond([
            'status'  => 'success',
            'message' => 'Gestor Películas API v1.0',
            'data'    => [
                'version'     => '1.0.0',
                'environment' => ENVIRONMENT,
                'docs'        => 'See README.md for API documentation',
            ],
        ]);
    }

    public function health(): ResponseInterface
    {
        $db = \Config\Database::connect();

        try {
            $db->query('SELECT 1');
            $dbStatus = 'ok';
        } catch (\Throwable $e) {
            $dbStatus = 'error';
        }

        $status = $dbStatus === 'ok' ? 'success' : 'error';
        $code   = $dbStatus === 'ok' ? 200 : 503;

        return $this->respond([
            'status'  => $status,
            'message' => 'Health check',
            'data'    => [
                'api'      => 'ok',
                'database' => $dbStatus,
            ],
        ], $code);
    }
}
