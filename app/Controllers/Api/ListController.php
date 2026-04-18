<?php

namespace App\Controllers\Api;

use App\Models\ListItemModel;
use App\Models\MediaItemModel;
use App\Models\UserListModel;
use App\Services\TMDBService;
use CodeIgniter\HTTP\ResponseInterface;

class ListController extends BaseApiController
{
    private UserListModel  $listModel;
    private ListItemModel  $itemModel;
    private MediaItemModel $mediaModel;

    public function __construct()
    {
        $this->listModel  = new UserListModel();
        $this->itemModel  = new ListItemModel();
        $this->mediaModel = new MediaItemModel();
    }

    public function index(): ResponseInterface
    {
        $lists = $this->listModel->getByUserId($this->currentUserId());
        return $this->success($lists, 'Listas del usuario.');
    }

    public function create(): ResponseInterface
    {
        $rules = [
            'name'        => 'required|min_length[1]|max_length[150]',
            'description' => 'permit_empty|max_length[1000]',
            'is_public'   => 'permit_empty',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $listId = $this->listModel->insert([
            'user_id'     => $this->currentUserId(),
            'name'        => trim($input['name']),
            'description' => trim($input['description'] ?? ''),
            'is_public'   => filter_var($input['is_public'] ?? false, FILTER_VALIDATE_BOOLEAN),
        ], true);

        if (! $listId) {
            return $this->error('No se pudo crear la lista.', 500);
        }

        $list = $this->listModel->find($listId);
        return $this->success($list, 'Lista creada.', 201);
    }

    public function show($id = null): ResponseInterface
    {
        $listId = (int) $id;
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        $list = $this->listModel->getWithItems($listId);
        return $this->success($list, 'Detalle de la lista.');
    }

    public function update($id = null): ResponseInterface
    {
        $listId = (int) $id;
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        $rules = [
            'name'        => 'permit_empty|min_length[1]|max_length[150]',
            'description' => 'permit_empty|max_length[1000]',
            'is_public'   => 'permit_empty',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getRawInput();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $updateData = array_filter([
            'name'        => isset($input['name'])      ? trim($input['name'])        : null,
            'description' => isset($input['description']) ? trim($input['description']) : null,
        ], fn($v) => $v !== null);

        if (isset($input['is_public'])) {
            $updateData['is_public'] = filter_var($input['is_public'], FILTER_VALIDATE_BOOLEAN);
        }

        if (empty($updateData)) {
            return $this->error('No se proporcionaron campos para actualizar.', 400);
        }

        $this->listModel->update($listId, $updateData);

        return $this->success($this->listModel->find($listId), 'Lista actualizada.');
    }

    public function delete($id = null): ResponseInterface
    {
        $listId = (int) $id;
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        $this->listModel->delete($listId);
        return $this->success(null, 'Lista eliminada.');
    }

    // -----------------------------------------------------------------------
    // Items
    // -----------------------------------------------------------------------

    public function addItem(int $listId): ResponseInterface
    {
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        $rules = [
            'tmdb_id'    => 'required|integer|greater_than[0]',
            'media_type' => 'required|in_list[movie,tv]',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $tmdbId    = (int) $input['tmdb_id'];
        $mediaType = $input['media_type'];

        // Ensure media_item exists locally (fetch from TMDB if not)
        $mediaItem = $this->mediaModel->findByTmdbId($tmdbId, $mediaType);

        if (! $mediaItem) {
            try {
                $tmdb      = new TMDBService();
                $detail    = $tmdb->getDetail($tmdbId, $mediaType);
                $mediaId   = $tmdb->storeMediaItem($detail, $mediaType);
                $mediaItem = $this->mediaModel->find($mediaId);
            } catch (\Throwable $e) {
                log_message('error', 'TMDB fetch for list item: ' . $e->getMessage());
                return $this->error('No se pudo obtener información del título.', 502);
            }
        }

        if ($this->itemModel->existsInList($listId, $mediaItem['id'])) {
            return $this->error('Este título ya está en la lista.', 409);
        }

        $itemId = $this->itemModel->insert([
            'list_id'       => $listId,
            'media_item_id' => $mediaItem['id'],
            'watched'       => false,
            'added_at'      => date('Y-m-d H:i:s'),
        ], true);

        $item = $this->itemModel->find($itemId);
        return $this->success($item, 'Título añadido a la lista.', 201);
    }

    public function updateItem(int $listId, int $itemId): ResponseInterface
    {
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        if (! $this->itemModel->belongsToList($itemId, $listId)) {
            return $this->error('Item no encontrado en esta lista.', 404);
        }

        $rules = [
            'user_note'   => 'permit_empty|max_length[1000]',
            'user_rating' => 'permit_empty|decimal|greater_than_equal_to[0]|less_than_equal_to[10]',
            'watched'     => 'permit_empty',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getRawInput();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $updateData = [];
        if (isset($input['user_note']))   $updateData['user_note']   = trim($input['user_note']);
        if (isset($input['user_rating'])) $updateData['user_rating'] = $input['user_rating'];
        if (isset($input['watched']))     $updateData['watched']     = filter_var($input['watched'], FILTER_VALIDATE_BOOLEAN);

        if (empty($updateData)) {
            return $this->error('No se proporcionaron campos para actualizar.', 400);
        }

        $this->itemModel->update($itemId, $updateData);
        return $this->success($this->itemModel->find($itemId), 'Item actualizado.');
    }

    public function removeItem(int $listId, int $itemId): ResponseInterface
    {
        if (! $this->listModel->belongsToUser($listId, $this->currentUserId())) {
            return $this->error('Lista no encontrada.', 404);
        }

        if (! $this->itemModel->belongsToList($itemId, $listId)) {
            return $this->error('Item no encontrado en esta lista.', 404);
        }

        $this->itemModel->delete($itemId);
        return $this->success(null, 'Título eliminado de la lista.');
    }
}
