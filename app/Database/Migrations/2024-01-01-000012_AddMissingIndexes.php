<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddMissingIndexes extends Migration
{
    public function up(): void
    {
        // Composite index for the one-list-per-title constraint query
        // Used by ListItemModel::getByUserAndMediaItem and existsInList
        $this->db->query('CREATE INDEX IF NOT EXISTS idx_litems_list_media
            ON list_items (list_id, media_item_id)');

        // Composite index for filtering user lists by default status
        // Used by _AddToListSheet and list ordering queries
        $this->db->query('CREATE INDEX IF NOT EXISTS idx_ulists_user_default
            ON user_lists (user_id, is_default)');
    }

    public function down(): void
    {
        $this->db->query('DROP INDEX IF EXISTS idx_litems_list_media');
        $this->db->query('DROP INDEX IF EXISTS idx_ulists_user_default');
    }
}
