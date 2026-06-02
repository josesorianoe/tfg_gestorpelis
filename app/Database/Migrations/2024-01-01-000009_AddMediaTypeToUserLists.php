<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddMediaTypeToUserLists extends Migration
{
    public function up(): void
    {
        $this->forge->addColumn('user_lists', [
            'media_type' => [
                'type'       => 'VARCHAR',
                'constraint' => 10,
                'null'       => true,
                'default'    => null,
            ],
        ]);

        // Create "Series que estoy viendo" list for existing users who don't have one
        $this->db->query("
            INSERT INTO user_lists (user_id, name, description, is_public, is_default, media_type, created_at, updated_at)
            SELECT u.id, 'Series que estoy viendo', '', false, true, 'tv', NOW(), NOW()
            FROM users u
            WHERE NOT EXISTS (
                SELECT 1 FROM user_lists ul WHERE ul.user_id = u.id AND ul.name = 'Series que estoy viendo'
            )
        ");
    }

    public function down(): void
    {
        $this->db->query("DELETE FROM user_lists WHERE name = 'Series que estoy viendo' AND media_type = 'tv' AND is_default = true");
        $this->forge->dropColumn('user_lists', 'media_type');
    }
}
