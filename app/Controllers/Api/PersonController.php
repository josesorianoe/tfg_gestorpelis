<?php

namespace App\Controllers\Api;

use App\Services\TMDBService;
use CodeIgniter\HTTP\ResponseInterface;

class PersonController extends BaseApiController
{
    private TMDBService $tmdb;

    public function __construct()
    {
        $this->tmdb = new TMDBService();
    }

    public function show($id = null): ResponseInterface
    {
        $personId = (int) $id;
        try {
            $data = $this->tmdb->getPerson($personId);
        } catch (\RuntimeException $e) {
            $code = str_contains($e->getMessage(), 'HTTP 404') ? 404 : 502;
            log_message('error', 'TMDB person error: ' . $e->getMessage());
            return $this->error($e->getMessage(), $code);
        }

        return $this->success($data, 'Datos de la persona.');
    }
}
