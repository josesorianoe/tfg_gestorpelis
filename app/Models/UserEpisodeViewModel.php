<?php

namespace App\Models;

use CodeIgniter\Model;

class UserEpisodeViewModel extends Model
{
    protected $table            = 'user_episode_views';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;
    protected $useTimestamps    = false;

    protected $allowedFields = [
        'user_id',
        'tmdb_series_id',
        'season_number',
        'episode_number',
        'watched_at',
    ];

    public function getProgress(int $userId, int $tmdbSeriesId): array
    {
        return $this->select('season_number, episode_number')
                    ->where('user_id', $userId)
                    ->where('tmdb_series_id', $tmdbSeriesId)
                    ->findAll();
    }

    public function getWatchedKeys(int $userId, int $tmdbSeriesId): array
    {
        $rows = $this->select('season_number, episode_number')
                     ->where('user_id', $userId)
                     ->where('tmdb_series_id', $tmdbSeriesId)
                     ->findAll();

        $keys = [];
        foreach ($rows as $r) {
            $keys[(int) $r['season_number'] . '_' . (int) $r['episode_number']] = true;
        }
        return $keys;
    }

    public function findEntry(int $userId, int $tmdbSeriesId, int $seasonNumber, int $episodeNumber): ?array
    {
        return $this->where('user_id', $userId)
                    ->where('tmdb_series_id', $tmdbSeriesId)
                    ->where('season_number', $seasonNumber)
                    ->where('episode_number', $episodeNumber)
                    ->first();
    }
}
