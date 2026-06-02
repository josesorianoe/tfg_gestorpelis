<?php

namespace App\Models;

use CodeIgniter\Model;

class UserWatchHistoryModel extends Model
{
    protected $table            = 'user_watch_history';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useTimestamps    = false;

    protected $allowedFields = [
        'user_id',
        'tmdb_id',
        'media_type',
        'title',
        'poster_path',
        'watched_on',
        'created_at',
    ];

    public function getByUser(int $userId): array
    {
        return $this->where('user_id', $userId)
                    ->orderBy('watched_on', 'DESC')
                    ->orderBy('created_at', 'DESC')
                    ->findAll();
    }
}
