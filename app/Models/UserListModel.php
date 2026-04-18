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
        return $this->where('user_id', $userId)
                    ->orderBy('created_at', 'DESC')
                    ->findAll();
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
