<?php

namespace App\Filters;

use App\Services\JWTService;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;
use Firebase\JWT\ExpiredException;
use Firebase\JWT\SignatureInvalidException;
use UnexpectedValueException;

class JWTAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null): mixed
    {
        $authHeader = $request->getHeaderLine('Authorization');

        if (empty($authHeader) || ! str_starts_with($authHeader, 'Bearer ')) {
            return response()->setStatusCode(401)->setJSON([
                'status'  => 'error',
                'message' => 'Token de autenticación requerido.',
                'data'    => null,
            ]);
        }

        $token = substr($authHeader, 7);

        try {
            $jwtService = new JWTService();
            $payload    = $jwtService->decodeAccessToken($token);

            // Store decoded payload for use in controllers
            $request->jwtPayload = $payload;

        } catch (ExpiredException $e) {
            return response()->setStatusCode(401)->setJSON([
                'status'  => 'error',
                'message' => 'El token ha expirado.',
                'data'    => null,
            ]);
        } catch (SignatureInvalidException | UnexpectedValueException $e) {
            return response()->setStatusCode(401)->setJSON([
                'status'  => 'error',
                'message' => 'Token inválido.',
                'data'    => null,
            ]);
        } catch (\Throwable $e) {
            return response()->setStatusCode(500)->setJSON([
                'status'  => 'error',
                'message' => 'Error al procesar el token.',
                'data'    => null,
            ]);
        }

        return null;
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null): mixed
    {
        return null;
    }
}
