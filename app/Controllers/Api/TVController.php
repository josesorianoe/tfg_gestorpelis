<?php

namespace App\Controllers\Api;

use App\Models\UserEpisodeViewModel;
use App\Services\TMDBService;
use CodeIgniter\HTTP\ResponseInterface;

class TVController extends BaseApiController
{
    private TMDBService          $tmdb;
    private UserEpisodeViewModel $episodeModel;

    public function __construct()
    {
        $this->tmdb         = new TMDBService();
        $this->episodeModel = new UserEpisodeViewModel();
    }

    public function getSeason($tmdbId = null, $seasonNumber = null): ResponseInterface
    {
        try {
            $data = $this->tmdb->getSeason((int) $tmdbId, (int) $seasonNumber);
        } catch (\RuntimeException $e) {
            $code = str_contains($e->getMessage(), 'HTTP 404') ? 404 : 502;
            return $this->error($e->getMessage(), $code);
        }
        return $this->success($data, 'Temporada.');
    }

    public function getProgress($tmdbId = null): ResponseInterface
    {
        $progress = $this->episodeModel->getProgress($this->currentUserId(), (int) $tmdbId);
        return $this->success($progress, 'Progreso de la serie.');
    }

    public function markAllWatched($tmdbId = null): ResponseInterface
    {
        $userId   = $this->currentUserId();
        $seriesId = (int) $tmdbId;

        try {
            $detail  = $this->tmdb->getDetail($seriesId, 'tv');
            $seasons = $detail['seasons'] ?? [];
        } catch (\RuntimeException) {
            return $this->error('No se pudo obtener la información de la serie.', 502);
        }

        // Pre-fetch all already-watched episodes in one query, then batch-insert only the new ones.
        $watched = $this->episodeModel->getWatchedKeys($userId, $seriesId);
        $batch   = [];
        $now     = date('Y-m-d H:i:s');

        foreach ($seasons as $season) {
            $seasonNumber = (int) ($season['season_number'] ?? 0);
            $episodeCount = (int) ($season['episode_count']  ?? 0);

            if ($seasonNumber === 0 || $episodeCount === 0) continue;

            for ($ep = 1; $ep <= $episodeCount; $ep++) {
                if (! isset($watched["{$seasonNumber}_{$ep}"])) {
                    $batch[] = [
                        'user_id'        => $userId,
                        'tmdb_series_id' => $seriesId,
                        'season_number'  => $seasonNumber,
                        'episode_number' => $ep,
                        'watched_at'     => $now,
                    ];
                }
            }
        }

        if (! empty($batch)) {
            $this->episodeModel->insertBatch($batch);
        }

        return $this->success(null, 'Todos los episodios marcados como vistos.');
    }

    public function toggleEpisode($tmdbId = null): ResponseInterface
    {
        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        $rules = [
            'season_number'  => 'required|integer|greater_than[0]',
            'episode_number' => 'required|integer|greater_than[0]',
        ];

        if (! $this->validateData($input ?? [], $rules)) {
            return $this->validationError($this->validator->getErrors());
        }

        $userId   = $this->currentUserId();
        $seriesId = (int) $tmdbId;
        $season   = (int) $input['season_number'];
        $episode  = (int) $input['episode_number'];

        $existing = $this->episodeModel->findEntry($userId, $seriesId, $season, $episode);

        if ($existing) {
            $this->episodeModel->delete($existing['id']);
            return $this->success(['watched' => false], 'Episodio marcado como no visto.');
        }

        $this->episodeModel->insert([
            'user_id'        => $userId,
            'tmdb_series_id' => $seriesId,
            'season_number'  => $season,
            'episode_number' => $episode,
            'watched_at'     => date('Y-m-d H:i:s'),
        ]);

        return $this->success(['watched' => true], 'Episodio marcado como visto.');
    }
}
