<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateTmdbCacheTable extends Migration
{
    public function up(): void
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'BIGINT',
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'cache_key' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
                'null'       => false,
            ],
            'endpoint' => [
                'type'       => 'VARCHAR',
                'constraint' => 500,
                'null'       => false,
            ],
            'response' => [
                'type' => 'JSONB',
                'null' => false,
            ],
            'expires_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => false,
            ],
            'created_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addUniqueKey('cache_key', 'uq_cache_key');
        $this->forge->addKey('expires_at', false, false, 'idx_cache_expires_at');
        $this->forge->createTable('tmdb_cache', true);

        // GIN index for JSONB response
        $this->db->query('CREATE INDEX IF NOT EXISTS idx_cache_response ON tmdb_cache USING GIN (response)');
    }

    public function down(): void
    {
        $this->forge->dropTable('tmdb_cache', true);
    }
}
