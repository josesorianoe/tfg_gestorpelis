<?php

namespace App\Models;

use CodeIgniter\Model;

class RefreshTokenModel extends Model
{
    protected $table            = 'refresh_tokens';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'user_id',
        'token_hash',
        'expires_at',
        'revoked',
        'created_at',
    ];

    protected $useTimestamps = false;

    public function findValid(string $tokenHash): ?array
    {
        return $this->where('token_hash', $tokenHash)
                    ->where('revoked', false)
                    ->where('expires_at >', date('Y-m-d H:i:s'))
                    ->first();
    }

    public function revoke(string $tokenHash): void
    {
        $this->where('token_hash', $tokenHash)->set(['revoked' => true])->update();
    }

    public function revokeAllForUser(int $userId): void
    {
        $this->where('user_id', $userId)->set(['revoked' => true])->update();
    }

    public function purgeExpired(): int
    {
        return $this->where('expires_at <', date('Y-m-d H:i:s'))->delete();
    }
}
