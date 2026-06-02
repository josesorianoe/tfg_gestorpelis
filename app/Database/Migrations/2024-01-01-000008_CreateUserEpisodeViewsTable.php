<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateUserEpisodeViewsTable extends Migration
{
    public function up(): void
    {
        $this->db->query('
            CREATE TABLE user_episode_views (
                id              SERIAL PRIMARY KEY,
                user_id         INTEGER  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                tmdb_series_id  INTEGER  NOT NULL,
                season_number   SMALLINT NOT NULL,
                episode_number  SMALLINT NOT NULL,
                watched_at      TIMESTAMP NOT NULL DEFAULT NOW(),
                UNIQUE (user_id, tmdb_series_id, season_number, episode_number)
            )
        ');
        $this->db->query(
            'CREATE INDEX idx_uev_user_series ON user_episode_views (user_id, tmdb_series_id)'
        );
    }

    public function down(): void
    {
        $this->db->query('DROP TABLE IF EXISTS user_episode_views');
    }
}
