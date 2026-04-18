<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

class CorsFilter implements FilterInterface
{
    /**
     * Allowed origins — includes Flutter emulator (10.0.2.2) and common dev origins.
     * In production, restrict to your actual domain.
     */
    private array $allowedOrigins = [
        'http://localhost',
        'http://localhost:8080',
        'http://127.0.0.1',
        'http://10.0.2.2',       // Android emulator
        'http://10.0.2.2:8080',
    ];

    public function before(RequestInterface $request, $arguments = null): mixed
    {
        $origin = $request->getHeaderLine('Origin');

        // Allow any origin in development; restrict in production
        $allowOrigin = ENVIRONMENT === 'development'
            ? ($origin ?: '*')
            : (in_array($origin, $this->allowedOrigins, true) ? $origin : '');

        if (strtoupper($request->getMethod()) === 'OPTIONS') {
            return response()
                ->setStatusCode(204)
                ->setHeader('Access-Control-Allow-Origin', $allowOrigin)
                ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
                ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
                ->setHeader('Access-Control-Max-Age', '86400')
                ->setHeader('Vary', 'Origin');
        }

        return null;
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null): mixed
    {
        $origin = $request->getHeaderLine('Origin');

        $allowOrigin = ENVIRONMENT === 'development'
            ? ($origin ?: '*')
            : (in_array($origin, $this->allowedOrigins, true) ? $origin : '');

        if (! empty($allowOrigin)) {
            $response
                ->setHeader('Access-Control-Allow-Origin', $allowOrigin)
                ->setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
                ->setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
                ->setHeader('Vary', 'Origin');
        }

        return null;
    }
}
