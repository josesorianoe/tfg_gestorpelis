<?php

namespace App\Services;

use App\Models\MediaItemModel;
use CodeIgniter\HTTP\CURLRequest;
use RuntimeException;

class TMDBService
{
    private CURLRequest   $client;
    private CacheService  $cache;
    private MediaItemModel $mediaModel;
    private string        $baseUrl;
    private string        $apiKey;
    private int           $cacheTtl;

    public function __construct()
    {
        $this->apiKey     = env('TMDB_API_KEY', '');
        $this->baseUrl    = rtrim(env('TMDB_BASE_URL', 'https://api.themoviedb.org/3'), '/');
        $this->cacheTtl   = (int) (env('TMDB_CACHE_TTL', 86400));
        $this->cache      = new CacheService();
        $this->mediaModel = new MediaItemModel();

        if (empty($this->apiKey)) {
            throw new RuntimeException('TMDB_API_KEY is not configured in .env');
        }

        $this->client = \Config\Services::curlrequest([
            'timeout' => 10,
        ]);
    }

    public function search(string $query, string $type = 'movie', int $page = 1): array
    {
        $cacheKey = $this->cache->buildKey('search', $type, $query, (string) $page);
        $endpoint = "/search/{$type}";

        if ($cached = $this->cache->get($cacheKey)) {
            return $cached;
        }

        $response = $this->get($endpoint, [
            'query'    => $query,
            'page'     => $page,
            'language' => 'es-ES',
        ]);

        $this->cache->set($cacheKey, $endpoint, $response, $this->cacheTtl);
        return $response;
    }

    public function getDetail(int $tmdbId, string $type = 'movie'): array
    {
        // Check local media_items first
        $local = $this->mediaModel->findByTmdbId($tmdbId, $type);
        if ($local && $local['cached_at']) {
            $cachedAt  = strtotime($local['cached_at']);
            $expiresAt = $cachedAt + $this->cacheTtl;
            if (time() < $expiresAt) {
                return $local['raw_data'] ?? $local;
            }
        }

        $cacheKey = $this->cache->buildKey('detail', $type, (string) $tmdbId);
        $endpoint = "/{$type}/{$tmdbId}";

        if ($cached = $this->cache->get($cacheKey)) {
            return $cached;
        }

        $response = $this->get($endpoint, [
            'language'           => 'es-ES',
            'append_to_response' => 'credits,videos,images',
        ]);

        $this->cache->set($cacheKey, $endpoint, $response, $this->cacheTtl);
        $this->storeMediaItem($response, $type);

        return $response;
    }

    public function getPopular(string $type = 'movie', int $page = 1): array
    {
        $cacheKey = $this->cache->buildKey('popular', $type, (string) $page);
        $endpoint = "/{$type}/popular";

        if ($cached = $this->cache->get($cacheKey)) {
            return $cached;
        }

        $response = $this->get($endpoint, [
            'language' => 'es-ES',
            'page'     => $page,
        ]);

        $this->cache->set($cacheKey, $endpoint, $response, $this->cacheTtl);
        return $response;
    }

    public function getPerson(int $personId): array
    {
        $cacheKey = $this->cache->buildKey('person', (string) $personId);
        $endpoint = "/person/{$personId}";

        if ($cached = $this->cache->get($cacheKey)) {
            return $cached;
        }

        $response = $this->get($endpoint, [
            'language'           => 'es-ES',
            'append_to_response' => 'combined_credits',
        ]);

        $this->cache->set($cacheKey, $endpoint, $response, $this->cacheTtl);
        return $response;
    }

    private function get(string $endpoint, array $params = []): array
    {
        $params['api_key'] = $this->apiKey;

        try {
            $response = $this->client->get($this->baseUrl . $endpoint, ['query' => $params]);
        } catch (\Throwable $e) {
            throw new RuntimeException('TMDB API request failed: ' . $e->getMessage(), 0, $e);
        }

        $statusCode = $response->getStatusCode();
        if ($statusCode !== 200) {
            throw new RuntimeException("TMDB API error: HTTP {$statusCode}");
        }

        $body = json_decode($response->getBody(), true);
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new RuntimeException('TMDB API returned invalid JSON');
        }

        return $body;
    }

    public function storeMediaItem(array $tmdbData, string $mediaType): ?int
    {
        $tmdbId = $tmdbData['id'] ?? null;
        if (! $tmdbId) {
            return null;
        }

        $genres = array_map(
            fn($g) => ['id' => $g['id'], 'name' => $g['name']],
            $tmdbData['genres'] ?? []
        );

        $releaseDate = $tmdbData['release_date']    // movie
                    ?? $tmdbData['first_air_date']   // tv
                    ?? null;

        $id = $this->mediaModel->upsert([
            'tmdb_id'       => $tmdbId,
            'media_type'    => $mediaType,
            'title'         => $tmdbData['title'] ?? $tmdbData['name'] ?? '',
            'overview'      => $tmdbData['overview'] ?? '',
            'poster_path'   => $tmdbData['poster_path'] ?? null,
            'backdrop_path' => $tmdbData['backdrop_path'] ?? null,
            'release_date'  => $releaseDate ?: null,
            'vote_average'  => $tmdbData['vote_average'] ?? 0,
            'genres'        => $genres,
            'raw_data'      => $tmdbData,
            'cached_at'     => date('Y-m-d H:i:s'),
        ]);

        return (int) $id;
    }
}
