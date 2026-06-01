<?php

namespace App\Controllers\Api;

use App\Models\MediaItemModel;
use App\Services\CacheService;
use App\Services\TMDBService;
use CodeIgniter\HTTP\ResponseInterface;

class CatalogController extends BaseApiController
{
    private MediaItemModel $mediaModel;
    private CacheService   $cache;

    public function __construct()
    {
        $this->mediaModel = new MediaItemModel();
        $this->cache      = new CacheService();
    }

    public function index(): ResponseInterface
    {
        $page    = max(1, (int) ($this->request->getGet('page') ?? 1));
        $perPage = min(50, max(1, (int) ($this->request->getGet('per_page') ?? 20)));

        $items = $this->mediaModel->paginated($page, $perPage);
        $total = $this->mediaModel->countAll();

        return $this->success([
            'items'      => $items,
            'pagination' => [
                'page'     => $page,
                'per_page' => $perPage,
                'total'    => $total,
                'pages'    => (int) ceil($total / $perPage),
            ],
        ], 'Catálogo local.');
    }

    public function discover(): ResponseInterface
    {
        $type = $this->request->getGet('type') ?? 'movie';
        $page = max(1, (int) ($this->request->getGet('page') ?? 1));

        if (! in_array($type, ['movie', 'tv'], true)) {
            return $this->error('El parámetro type debe ser "movie" o "tv".', 400);
        }

        try {
            $tmdb    = new TMDBService();
            $results = $tmdb->getPopular($type, $page);
            return $this->success($results, 'Títulos populares de TMDB.');
        } catch (\RuntimeException $e) {
            log_message('error', 'TMDB discover error: ' . $e->getMessage());
            return $this->error('Error al obtener títulos populares.', 502);
        }
    }

    public function popular(): ResponseInterface
    {
        $cacheKey = $this->cache->buildKey('catalog', 'popular');

        if ($cached = $this->cache->get($cacheKey)) {
            return $this->success($cached, 'Títulos populares (caché).');
        }

        $items = $this->mediaModel->popular(20);

        $this->cache->set($cacheKey, 'catalog:popular', ['items' => $items], 3600);

        return $this->success(['items' => $items], 'Títulos populares.');
    }
}
