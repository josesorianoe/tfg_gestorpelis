<?php

namespace App\Models;

use CodeIgniter\Model;

class MediaItemModel extends Model
{
    protected $table            = 'media_items';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'tmdb_id',
        'media_type',
        'title',
        'overview',
        'poster_path',
        'backdrop_path',
        'release_date',
        'vote_average',
        'genres',
        'raw_data',
        'cached_at',
    ];

    protected $useTimestamps = false;

    public function findByTmdbId(int $tmdbId, string $mediaType): ?array
    {
        $item = $this->where('tmdb_id', $tmdbId)
                     ->where('media_type', $mediaType)
                     ->first();

        if ($item) {
            $item['genres']   = is_string($item['genres'])   ? json_decode($item['genres'], true)   : $item['genres'];
            $item['raw_data'] = is_string($item['raw_data']) ? json_decode($item['raw_data'], true) : $item['raw_data'];
        }

        return $item;
    }

    public function upsert(array $data): int|string
    {
        $data['genres']   = is_array($data['genres'])   ? json_encode($data['genres'])   : ($data['genres'] ?? '[]');
        $data['raw_data'] = is_array($data['raw_data']) ? json_encode($data['raw_data']) : ($data['raw_data'] ?? '{}');

        $existing = $this->where('tmdb_id', $data['tmdb_id'])
                         ->where('media_type', $data['media_type'])
                         ->first();

        if ($existing) {
            $this->update($existing['id'], $data);
            return $existing['id'];
        }

        return $this->insert($data, true);
    }

    public function paginated(int $page = 1, int $perPage = 20): array
    {
        $offset = ($page - 1) * $perPage;
        $items  = $this->orderBy('cached_at', 'DESC')
                       ->findAll($perPage, $offset);

        return array_map(fn($i) => $this->decodeJsonFields($i), $items);
    }

    public function popular(int $limit = 20): array
    {
        $items = $this->orderBy('vote_average', 'DESC')
                      ->findAll($limit);

        return array_map(fn($i) => $this->decodeJsonFields($i), $items);
    }

    private function decodeJsonFields(array $item): array
    {
        $item['genres']   = is_string($item['genres'])   ? json_decode($item['genres'], true)   : $item['genres'];
        $item['raw_data'] = is_string($item['raw_data']) ? json_decode($item['raw_data'], true) : $item['raw_data'];
        return $item;
    }
}
