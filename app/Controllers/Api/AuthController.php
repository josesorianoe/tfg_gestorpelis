<?php

namespace App\Controllers\Api;

use App\Models\UserModel;
use App\Services\JWTService;
use CodeIgniter\HTTP\ResponseInterface;

class AuthController extends BaseApiController
{
    private UserModel  $userModel;
    private JWTService $jwtService;

    public function __construct()
    {
        $this->userModel  = new UserModel();
        $this->jwtService = new JWTService();
    }

    public function register(): ResponseInterface
    {
        $rules = [
            'name'     => 'required|min_length[2]|max_length[150]',
            'email'    => 'required|valid_email|max_length[255]|is_unique[users.email]',
            'password' => 'required|min_length[8]|max_length[100]',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $userId = $this->userModel->insert([
            'name'     => trim($input['name']),
            'email'    => strtolower(trim($input['email'])),
            'password' => password_hash($input['password'], PASSWORD_BCRYPT),
        ], true);

        if (! $userId) {
            return $this->error('No se pudo crear el usuario.', 500);
        }

        $user         = $this->userModel->find($userId);
        $accessToken  = $this->jwtService->generateAccessToken($userId, $user['email']);
        $refreshToken = $this->jwtService->generateRefreshToken($userId);

        return $this->success([
            'user'          => $this->userModel->safeFields($user),
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'token_type'    => 'Bearer',
            'expires_in'    => (int) env('JWT_ACCESS_TTL', 3600),
        ], 'Usuario registrado correctamente.', 201);
    }

    public function login(): ResponseInterface
    {
        $rules = [
            'email'    => 'required|valid_email',
            'password' => 'required',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $user = $this->userModel->findByEmail(strtolower(trim($input['email'])));

        if (! $user || ! password_verify($input['password'], $user['password'])) {
            return $this->error('Credenciales incorrectas.', 401);
        }

        $accessToken  = $this->jwtService->generateAccessToken($user['id'], $user['email']);
        $refreshToken = $this->jwtService->generateRefreshToken($user['id']);

        return $this->success([
            'user'          => $this->userModel->safeFields($user),
            'access_token'  => $accessToken,
            'refresh_token' => $refreshToken,
            'token_type'    => 'Bearer',
            'expires_in'    => (int) env('JWT_ACCESS_TTL', 3600),
        ], 'Login exitoso.');
    }

    public function refresh(): ResponseInterface
    {
        $input = $this->request->getJSON(true) ?? $this->request->getPost();
        $token = $input['refresh_token'] ?? null;

        if (empty($token)) {
            return $this->error('refresh_token requerido.', 400);
        }

        $tokenRecord = $this->jwtService->validateRefreshToken($token);
        if (! $tokenRecord) {
            return $this->error('Refresh token inválido o expirado.', 401);
        }

        $user = $this->userModel->find($tokenRecord['user_id']);
        if (! $user) {
            return $this->error('Usuario no encontrado.', 404);
        }

        // Rotate refresh token
        $this->jwtService->revokeRefreshToken($token);
        $newAccessToken  = $this->jwtService->generateAccessToken($user['id'], $user['email']);
        $newRefreshToken = $this->jwtService->generateRefreshToken($user['id']);

        return $this->success([
            'access_token'  => $newAccessToken,
            'refresh_token' => $newRefreshToken,
            'token_type'    => 'Bearer',
            'expires_in'    => (int) env('JWT_ACCESS_TTL', 3600),
        ], 'Token renovado.');
    }

    public function logout(): ResponseInterface
    {
        $input = $this->request->getJSON(true) ?? $this->request->getPost();
        $token = $input['refresh_token'] ?? null;

        if ($token) {
            $this->jwtService->revokeRefreshToken($token);
        }

        return $this->success(null, 'Sesión cerrada correctamente.');
    }
}
