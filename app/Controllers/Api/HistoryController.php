<?php

namespace App\Controllers\Api;

use App\Models\UserWatchHistoryModel;
use CodeIgniter\HTTP\ResponseInterface;

class HistoryController extends BaseApiController
{
    private UserWatchHistoryModel $historyModel;

    public function __construct()
    {
        $this->historyModel = new UserWatchHistoryModel();
    }

    public function index(): ResponseInterface
    {
        $entries = $this->historyModel->getByUser($this->currentUserId());
        return $this->success($entries, 'Historial de visionado.');
    }

    public function store(): ResponseInterface
    {
        $rules = [
            'tmdb_id'     => 'required|integer|greater_than[0]',
            'media_type'  => 'required|in_list[movie,tv]',
            'title'       => 'required|max_length[500]',
            'poster_path' => 'permit_empty|max_length[500]',
            'watched_on'  => 'required|valid_date[Y-m-d]',
        ];

        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $id = $this->historyModel->insert([
            'user_id'     => $this->currentUserId(),
            'tmdb_id'     => (int) $input['tmdb_id'],
            'media_type'  => $input['media_type'],
            'title'       => trim($input['title']),
            'poster_path' => $input['poster_path'] ?? null,
            'watched_on'  => $input['watched_on'],
            'created_at'  => date('Y-m-d H:i:s'),
        ], true);

        return $this->success($this->historyModel->find($id), 'Entrada añadida al historial.', 201);
    }

    public function destroy($id = null): ResponseInterface
    {
        $entry = $this->historyModel->find((int) $id);
        if (! $entry || (int) $entry['user_id'] !== $this->currentUserId()) {
            return $this->error('Entrada no encontrada.', 404);
        }
        $this->historyModel->delete((int) $id);
        return $this->success(null, 'Entrada eliminada del historial.');
    }
}
