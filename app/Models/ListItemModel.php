<?php

namespace App\Models;

use CodeIgniter\Model;

class ListItemModel extends Model
{
    protected $table            = 'list_items';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'list_id',
        'media_item_id',
        'user_note',
        'user_rating',
        'watched',
        'added_at',
    ];

    protected $useTimestamps = false;

    protected $validationRules = [
        'user_rating' => 'permit_empty|decimal|greater_than_equal_to[0]|less_than_equal_to[10]',
    ];

    public function getByListId(int $listId): array
    {
        $rows = $this->db->table('list_items li')
            ->select('li.id, li.list_id, li.media_item_id, li.user_note, li.user_rating, li.watched, li.added_at, mi.id as mi_id, mi.tmdb_id, mi.media_type, mi.title, mi.overview, mi.poster_path, mi.backdrop_path, mi.release_date, mi.vote_average, mi.genres')
            ->join('media_items mi', 'mi.id = li.media_item_id')
            ->where('li.list_id', $listId)
            ->orderBy('li.added_at', 'DESC')
            ->get()
            ->getResultArray();

        return array_map(static fn($row) => [
            'id'            => $row['id'],
            'list_id'       => $row['list_id'],
            'media_item_id' => $row['media_item_id'],
            'user_note'     => $row['user_note'],
            'user_rating'   => $row['user_rating'],
            'watched'       => $row['watched'],
            'added_at'      => $row['added_at'],
            'media_item'    => [
                'id'            => $row['mi_id'],
                'tmdb_id'       => $row['tmdb_id'],
                'media_type'    => $row['media_type'],
                'title'         => $row['title'],
                'overview'      => $row['overview'],
                'poster_path'   => $row['poster_path'],
                'backdrop_path' => $row['backdrop_path'],
                'release_date'  => $row['release_date'],
                'vote_average'  => $row['vote_average'],
                'genres'        => $row['genres'],
            ],
        ], $rows);
    }

    public function getUniqueMediaByUserId(int $userId): array
    {
        return $this->db->table('list_items li')
            ->select('mi.id, mi.tmdb_id, mi.media_type, mi.title, mi.poster_path, mi.backdrop_path, mi.release_date, mi.vote_average')
            ->join('media_items mi', 'mi.id = li.media_item_id')
            ->join('user_lists ul', 'ul.id = li.list_id')
            ->where('ul.user_id', $userId)
            ->groupBy('mi.id, mi.tmdb_id, mi.media_type, mi.title, mi.poster_path, mi.backdrop_path, mi.release_date, mi.vote_average')
            ->orderBy('MAX(li.added_at)', 'DESC')
            ->get()
            ->getResultArray();
    }

    public function existsInList(int $listId, int $mediaItemId): bool
    {
        return $this->where('list_id', $listId)
                    ->where('media_item_id', $mediaItemId)
                    ->countAllResults() > 0;
    }

    public function belongsToList(int $itemId, int $listId): bool
    {
        return $this->where('id', $itemId)
                    ->where('list_id', $listId)
                    ->countAllResults() > 0;
    }
}
