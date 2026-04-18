<?php

namespace App\Services;

use App\Models\TmdbCacheModel;

class CacheService
{
    private TmdbCacheModel $model;
    private int            $defaultTtl;

    public function __construct()
    {
        $this->model      = new TmdbCacheModel();
        $this->defaultTtl = (int) (env('TMDB_CACHE_TTL', 86400));
    }

    public function get(string $key): ?array
    {
        $entry = $this->model->getValid($key);
        return $entry ? $entry['response'] : null;
    }

    public function set(string $key, string $endpoint, array $data, ?int $ttl = null): void
    {
        $this->model->store($key, $endpoint, $data, $ttl ?? $this->defaultTtl);
    }

    public function buildKey(string ...$parts): string
    {
        return hash('sha256', implode(':', $parts));
    }

    public function purge(): int
    {
        return $this->model->purgeExpired();
    }
}
