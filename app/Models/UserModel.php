<?php

namespace App\Models;

use CodeIgniter\Model;

class UserModel extends Model
{
    protected $table            = 'users';
    protected $primaryKey       = 'id';
    protected $useAutoIncrement = true;
    protected $returnType       = 'array';
    protected $useSoftDeletes   = false;
    protected $protectFields    = true;

    protected $allowedFields = [
        'email',
        'password',
        'name',
        'avatar_url',
    ];

    protected $useTimestamps = true;
    protected $dateFormat    = 'datetime';
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $validationRules = [
        'email'    => 'required|valid_email|max_length[255]|is_unique[users.email,id,{id}]',
        'password' => 'required|min_length[8]|max_length[255]',
        'name'     => 'required|min_length[2]|max_length[150]',
    ];

    protected $validationMessages = [
        'email' => [
            'is_unique' => 'Este email ya está registrado.',
        ],
    ];

    protected $skipValidation = false;

    public function findByEmail(string $email): ?array
    {
        return $this->where('email', $email)->first();
    }

    public function safeFields(array $user): array
    {
        unset($user['password']);
        return $user;
    }
}
