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
        return $this->db->table('list_items li')
            ->select('li.*, mi.tmdb_id, mi.media_type, mi.title, mi.overview, mi.poster_path, mi.backdrop_path, mi.release_date, mi.vote_average, mi.genres')
            ->join('media_items mi', 'mi.id = li.media_item_id')
            ->where('li.list_id', $listId)
            ->orderBy('li.added_at', 'DESC')
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
