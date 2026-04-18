<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateMediaItemsTable extends Migration
{
    public function up(): void
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'BIGINT',
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'tmdb_id' => [
                'type'     => 'INT',
                'unsigned' => true,
                'null'     => false,
            ],
            'media_type' => [
                'type'       => 'VARCHAR',
                'constraint' => 10,
                'null'       => false,
            ],
            'title' => [
                'type'       => 'VARCHAR',
                'constraint' => 500,
                'null'       => false,
            ],
            'overview' => [
                'type' => 'TEXT',
                'null' => true,
            ],
            'poster_path' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
                'null'       => true,
            ],
            'backdrop_path' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
                'null'       => true,
            ],
            'release_date' => [
                'type' => 'DATE',
                'null' => true,
            ],
            'vote_average' => [
                'type'       => 'DECIMAL',
                'constraint' => '4,2',
                'null'       => true,
                'default'    => 0,
            ],
            'genres' => [
                'type'    => 'JSONB',
                'null'    => true,
                'default' => '[]',
            ],
            'raw_data' => [
                'type'    => 'JSONB',
                'null'    => true,
                'default' => '{}',
            ],
            'cached_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addUniqueKey(['tmdb_id', 'media_type'], 'uq_tmdb_media');
        $this->forge->addKey('tmdb_id', false, false, 'idx_media_tmdb_id');
        $this->forge->addKey('media_type', false, false, 'idx_media_type');
        $this->forge->createTable('media_items', true);

        // Constraint: media_type must be 'movie' or 'tv'
        $this->db->query("ALTER TABLE media_items ADD CONSTRAINT chk_media_type CHECK (media_type IN ('movie', 'tv'))");

        // GIN index for JSONB genres search
        $this->db->query('CREATE INDEX IF NOT EXISTS idx_media_genres ON media_items USING GIN (genres)');
    }

    public function down(): void
    {
        $this->forge->dropTable('media_items', true);
    }
}
