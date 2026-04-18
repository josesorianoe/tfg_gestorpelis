<?php

namespace App\Services;

use App\Models\RefreshTokenModel;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use RuntimeException;
use stdClass;

class JWTService
{
    private string $secret;
    private int    $accessTtl;
    private int    $refreshTtl;

    public function __construct()
    {
        $secret = env('JWT_SECRET');
        if (empty($secret)) {
            throw new RuntimeException('JWT_SECRET is not configured in .env');
        }
        $this->secret     = $secret;
        $this->accessTtl  = (int) (env('JWT_ACCESS_TTL', 3600));
        $this->refreshTtl = (int) (env('JWT_REFRESH_TTL', 2592000));
    }

    public function generateAccessToken(int $userId, string $email): string
    {
        $now     = time();
        $payload = [
            'iss' => env('app.baseURL', 'http://localhost:8080'),
            'iat' => $now,
            'exp' => $now + $this->accessTtl,
            'sub' => $userId,
            'email' => $email,
        ];

        return JWT::encode($payload, $this->secret, 'HS256');
    }

    public function generateRefreshToken(int $userId): string
    {
        $token     = bin2hex(random_bytes(40));
        $tokenHash = hash('sha256', $token);

        model(RefreshTokenModel::class)->insert([
            'user_id'    => $userId,
            'token_hash' => $tokenHash,
            'expires_at' => date('Y-m-d H:i:s', time() + $this->refreshTtl),
            'revoked'    => false,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        return $token;
    }

    public function decodeAccessToken(string $token): stdClass
    {
        return JWT::decode($token, new Key($this->secret, 'HS256'));
    }

    public function validateRefreshToken(string $token): ?array
    {
        $hash = hash('sha256', $token);
        return model(RefreshTokenModel::class)->findValid($hash);
    }

    public function revokeRefreshToken(string $token): void
    {
        $hash = hash('sha256', $token);
        model(RefreshTokenModel::class)->revoke($hash);
    }

    public function revokeAllRefreshTokens(int $userId): void
    {
        model(RefreshTokenModel::class)->revokeAllForUser($userId);
    }
}
