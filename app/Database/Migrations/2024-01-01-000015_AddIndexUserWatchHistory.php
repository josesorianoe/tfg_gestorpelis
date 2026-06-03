<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddIndexUserWatchHistory extends Migration
{
    public function up(): void
    {
        $this->db->query(
            'CREATE INDEX IF NOT EXISTS idx_watch_history_user_date
             ON user_watch_history (user_id, watched_on DESC)'
        );
    }

    public function down(): void
    {
        $this->db->query('DROP INDEX IF EXISTS idx_watch_history_user_date');
    }
}
