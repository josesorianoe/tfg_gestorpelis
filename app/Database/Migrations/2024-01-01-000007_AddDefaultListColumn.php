<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddDefaultListColumn extends Migration
{
    public function up(): void
    {
        $this->forge->addColumn('user_lists', [
            'is_default' => [
                'type'    => 'BOOLEAN',
                'null'    => false,
                'default' => false,
            ],
        ]);

        // Mark any existing list named "Pendientes por ver" as default
        $this->db->query("UPDATE user_lists SET is_default = true WHERE name = 'Pendientes por ver'");

        // Create "Pendientes por ver" for users who still don't have a default list
        $this->db->query("
            INSERT INTO user_lists (user_id, name, description, is_public, is_default, created_at, updated_at)
            SELECT u.id, 'Pendientes por ver', '', false, true, NOW(), NOW()
            FROM users u
            WHERE NOT EXISTS (
                SELECT 1 FROM user_lists ul WHERE ul.user_id = u.id AND ul.is_default = true
            )
        ");
    }

    public function down(): void
    {
        $this->db->query("DELETE FROM user_lists WHERE is_default = true");
        $this->forge->dropColumn('user_lists', 'is_default');
    }
}
