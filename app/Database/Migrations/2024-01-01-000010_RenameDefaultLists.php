<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class RenameDefaultLists extends Migration
{
    public function up(): void
    {
        $this->db->query("
            UPDATE user_lists
            SET name = 'Pendientes por ver'
            WHERE name = 'Pendientes' AND is_default = true
        ");

        $this->db->query("
            UPDATE user_lists
            SET name = 'Series que estoy viendo'
            WHERE name = 'Viendo' AND is_default = true AND media_type = 'tv'
        ");
    }

    public function down(): void
    {
        $this->db->query("
            UPDATE user_lists
            SET name = 'Pendientes'
            WHERE name = 'Pendientes por ver' AND is_default = true
        ");

        $this->db->query("
            UPDATE user_lists
            SET name = 'Viendo'
            WHERE name = 'Series que estoy viendo' AND is_default = true AND media_type = 'tv'
        ");
    }
}
