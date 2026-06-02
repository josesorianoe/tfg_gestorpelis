<?php

namespace App\Models;

use CodeIgniter\Model;

class UserListModel extends Model
{
    protected $table            = 'user_lists';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'user_id',
        'name',
        'description',
        'is_public',
        'is_default',
        'media_type',
    ];

    protected $useTimestamps = true;
    protected $dateFormat    = 'datetime';
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $validationRules = [
        'name'      => 'required|min_length[1]|max_length[150]',
        'is_public' => 'permit_empty|in_list[0,1,true,false]',
    ];

    public function getByUserId(int $userId): array
    {
        return $this->db->table('user_lists ul')
            ->select('ul.id, ul.user_id, ul.name, ul.description, ul.is_public, ul.is_default, ul.media_type, ul.created_at, ul.updated_at, COUNT(li.id) as item_count')
            ->join('list_items li', 'li.list_id = ul.id', 'left')
            ->where('ul.user_id', $userId)
            ->groupBy('ul.id, ul.user_id, ul.name, ul.description, ul.is_public, ul.is_default, ul.created_at, ul.updated_at')
            ->orderBy('ul.created_at', 'DESC')
            ->get()
            ->getResultArray();
    }

    public function getWithItems(int $listId): ?array
    {
        $list = $this->find($listId);
        if (! $list) {
            return null;
        }

        $list['items'] = model(ListItemModel::class)->getByListId($listId);
        return $list;
    }

    public function belongsToUser(int $listId, int $userId): bool
    {
        return $this->where('id', $listId)
                    ->where('user_id', $userId)
                    ->countAllResults() > 0;
    }
}
