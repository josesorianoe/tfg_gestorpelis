<?php

namespace App\Controllers\Api;

use App\Models\UserModel;
use CodeIgniter\HTTP\ResponseInterface;

class AdminController extends BaseApiController
{
    private UserModel $userModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
    }

    public function listUsers(): ResponseInterface
    {
        $users = $this->userModel
            ->select('id, name, email, role, created_at')
            ->orderBy('created_at', 'ASC')
            ->findAll();

        return $this->success($users, 'Listado de usuarios.');
    }

    public function deleteUser(int $id): ResponseInterface
    {
        if ($id === $this->currentUserId()) {
            return $this->error('No puedes eliminar tu propia cuenta.', 403);
        }

        $user = $this->userModel->find($id);
        if (! $user) {
            return $this->error('Usuario no encontrado.', 404);
        }

        $this->userModel->delete($id);

        return $this->success(null, 'Usuario eliminado correctamente.');
    }
}
