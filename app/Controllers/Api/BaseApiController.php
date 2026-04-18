<?php

namespace App\Controllers\Api;

use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\RESTful\ResourceController;

abstract class BaseApiController extends ResourceController
{
    protected $format = 'json';

    protected function success(mixed $data = null, string $message = 'OK', int $code = 200): ResponseInterface
    {
        return $this->respond([
            'status'  => 'success',
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    protected function error(string $message, int $code = 400, mixed $data = null): ResponseInterface
    {
        return $this->respond([
            'status'  => 'error',
            'message' => $message,
            'data'    => $data,
        ], $code);
    }

    protected function validationError(array $errors): ResponseInterface
    {
        return $this->respond([
            'status'  => 'error',
            'message' => 'Error de validación.',
            'data'    => $errors,
        ], 422);
    }

    protected function currentUserId(): int
    {
        return (int) $this->request->jwtPayload->sub;
    }
}
