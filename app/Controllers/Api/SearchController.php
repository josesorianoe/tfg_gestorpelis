<?php

namespace App\Controllers\Api;

use App\Services\TMDBService;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Throttle\Throttler;

class SearchController extends BaseApiController
{
    private TMDBService $tmdb;

    public function __construct()
    {
        $this->tmdb = new TMDBService();
    }

    public function index(): ResponseInterface
    {
        // Basic rate limiting: 30 req/min per IP
        $throttler = \Config\Services::throttler();
        $ip        = $this->request->getIPAddress();

        if ($throttler->check($ip, 30, MINUTE) === false) {
            return $this->error('Demasiadas solicitudes. Inténtalo en un momento.', 429);
        }

        $rules = [
            'q'    => 'required|min_length[1]|max_length[200]',
            'type' => 'permit_empty|in_list[movie,tv]',
            'page' => 'permit_empty|integer|greater_than[0]',
        ];

        $input = [
            'q'    => $this->request->getGet('q'),
            'type' => $this->request->getGet('type') ?? 'movie',
            'page' => $this->request->getGet('page') ?? 1,
        ];

        if (! $this->validateData($input, $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        try {
            $results = $this->tmdb->search(
                $input['q'],
                $input['type'],
                (int) $input['page']
            );
        } catch (\RuntimeException $e) {
            log_message('error', 'TMDB search error: ' . $e->getMessage());
            return $this->error('Error al conectar con TMDB. Inténtalo de nuevo.', 502);
        }

        return $this->success($results, 'Resultados de búsqueda.');
    }

    public function show($id = null): ResponseInterface
    {
        $tmdbId = (int) $id;
        $type = $this->request->getGet('type') ?? 'movie';

        if (! in_array($type, ['movie', 'tv'], true)) {
            return $this->error('El parámetro type debe ser "movie" o "tv".', 400);
        }

        try {
            $detail = $this->tmdb->getDetail($tmdbId, $type);
        } catch (\RuntimeException $e) {
            $code = str_contains($e->getMessage(), 'HTTP 404') ? 404 : 502;
            log_message('error', 'TMDB detail error: ' . $e->getMessage());
            return $this->error($e->getMessage(), $code);
        }

        return $this->success($detail, 'Detalle del título.');
    }
}
