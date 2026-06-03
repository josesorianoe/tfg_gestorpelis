<?php

namespace App\Models;

use CodeIgniter\Model;

class TmdbCacheModel extends Model
{
    protected $table            = 'tmdb_cache';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'cache_key',
        'endpoint',
        'response',
        'expires_at',
        'created_at',
    ];

    protected $useTimestamps = false;

    public function getValid(string $cacheKey): ?array
    {
        $entry = $this->where('cache_key', $cacheKey)
                      ->where('expires_at >', date('Y-m-d H:i:s'))
                      ->first();

        if ($entry) {
            $entry['response'] = is_string($entry['response'])
                ? json_decode($entry['response'], true)
                : $entry['response'];
        }

        return $entry;
    }

    public function store(string $cacheKey, string $endpoint, array $response, int $ttlSeconds): void
    {
        $expiresAt = date('Y-m-d H:i:s', time() + $ttlSeconds);
        $now       = date('Y-m-d H:i:s');

        $this->db->query(
            'INSERT INTO tmdb_cache (cache_key, endpoint, response, expires_at, created_at)
             VALUES (?, ?, ?, ?, ?)
             ON CONFLICT (cache_key)
             DO UPDATE SET endpoint = EXCLUDED.endpoint,
                           response = EXCLUDED.response,
                           expires_at = EXCLUDED.expires_at',
            [$cacheKey, $endpoint, json_encode($response), $expiresAt, $now]
        );
    }

    public function purgeExpired(): int
    {
        return $this->where('expires_at <', date('Y-m-d H:i:s'))->delete();
    }
}
