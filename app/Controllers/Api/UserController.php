<?php

namespace App\Controllers\Api;

use App\Models\ListItemModel;
use App\Models\MediaItemModel;
use App\Models\UserModel;
use CodeIgniter\HTTP\ResponseInterface;

class UserController extends BaseApiController
{
    private UserModel $userModel;
    private ListItemModel $listItemModel;
    private MediaItemModel $mediaModel;

    public function __construct()
    {
        $this->userModel     = new UserModel();
        $this->listItemModel = new ListItemModel();
        $this->mediaModel    = new MediaItemModel();
    }

    public function media(): ResponseInterface
    {
        $items = $this->listItemModel->getUniqueMediaByUserId($this->currentUserId());
        return $this->success($items, 'Biblioteca del usuario.');
    }

    public function mediaStatus(int $tmdbId): ResponseInterface
    {
        $type      = $this->request->getGet('type') ?? 'movie';
        $userId    = $this->currentUserId();
        $mediaItem = $this->mediaModel->findByTmdbId($tmdbId, $type);

        if (! $mediaItem) {
            return $this->success(['in_list' => false, 'user_rating' => null, 'user_note' => null], 'Estado del título.');
        }

        $items = $this->listItemModel->getByUserAndMediaItem($userId, (int) $mediaItem['id']);

        return $this->success([
            'in_list'     => ! empty($items),
            'user_rating' => $items[0]['user_rating'] ?? null,
            'user_note'   => $items[0]['user_note']   ?? null,
        ], 'Estado del título.');
    }

    public function updateMediaReview(int $tmdbId): ResponseInterface
    {
        $userId = $this->currentUserId();
        $input  = $this->request->getJSON(true) ?? [];
        $type   = $input['type'] ?? 'movie';

        $rules = [
            'user_rating' => 'permit_empty|decimal|greater_than_equal_to[0]|less_than_equal_to[10]',
            'user_note'   => 'permit_empty|max_length[1000]',
        ];

        if (! $this->validateData($input, $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $mediaItem = $this->mediaModel->findByTmdbId($tmdbId, $type);
        if (! $mediaItem) {
            return $this->error('Título no encontrado.', 404);
        }

        $items = $this->listItemModel->getByUserAndMediaItem($userId, (int) $mediaItem['id']);
        if (empty($items)) {
            return $this->error('Este título no está en ninguna lista.', 403);
        }

        $updateData = [];
        if (array_key_exists('user_rating', $input)) {
            $updateData['user_rating'] = $input['user_rating'] !== '' ? $input['user_rating'] : null;
        }
        if (array_key_exists('user_note', $input)) {
            $updateData['user_note'] = trim($input['user_note'] ?? '');
        }

        foreach ($items as $item) {
            $this->listItemModel->update((int) $item['id'], $updateData);
        }

        return $this->success(null, 'Reseña actualizada.');
    }

    public function me(): ResponseInterface
    {
        $user = $this->userModel->find($this->currentUserId());

        if (! $user) {
            return $this->error('Usuario no encontrado.', 404);
        }

        return $this->success($this->userModel->safeFields($user), 'Perfil del usuario.');
    }

    public function update($id = null): ResponseInterface
    {
        $userId = $this->currentUserId();

        $rules = [
            'name'       => 'permit_empty|min_length[2]|max_length[150]',
            'email'      => "permit_empty|valid_email|max_length[255]|is_unique[users.email,id,{$userId}]",
            'avatar_url' => 'permit_empty|valid_url|max_length[500]',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getRawInput();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $updateData = [];
        if (isset($input['name']))       $updateData['name']       = trim($input['name']);
        if (isset($input['email']))      $updateData['email']      = strtolower(trim($input['email']));
        if (isset($input['avatar_url'])) $updateData['avatar_url'] = $input['avatar_url'];

        if (empty($updateData)) {
            return $this->error('No se proporcionaron campos para actualizar.', 400);
        }

        $this->userModel->update($userId, $updateData);

        $user = $this->userModel->find($userId);
        return $this->success($this->userModel->safeFields($user), 'Perfil actualizado.');
    }

    public function changePassword(): ResponseInterface
    {
        $rules = [
            'current_password' => 'required',
            'new_password'     => 'required|min_length[8]|max_length[100]',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getRawInput();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $user = $this->userModel->find($this->currentUserId());

        if (! password_verify($input['current_password'], $user['password'])) {
            return $this->error('La contraseña actual es incorrecta.', 422);
        }

        if ($input['current_password'] === $input['new_password']) {
            return $this->error('La nueva contraseña debe ser diferente a la actual.', 422);
        }

        $this->userModel->update($this->currentUserId(), [
            'password' => password_hash($input['new_password'], PASSWORD_BCRYPT),
        ]);

        return $this->success(null, 'Contraseña cambiada correctamente.');
    }
}
