<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateUserWatchHistoryTable extends Migration
{
    public function up(): void
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'BIGINT',
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'user_id' => [
                'type'     => 'BIGINT',
                'unsigned' => true,
                'null'     => false,
            ],
            'tmdb_id' => [
                'type' => 'INTEGER',
                'null' => false,
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
            'poster_path' => [
                'type'       => 'VARCHAR',
                'constraint' => 500,
                'null'       => true,
            ],
            'watched_on' => [
                'type' => 'DATE',
                'null' => false,
            ],
            'created_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addKey('user_id', false, false, 'idx_uwh_user_id');
        $this->forge->createTable('user_watch_history', true);
    }

    public function down(): void
    {
        $this->forge->dropTable('user_watch_history', true);
    }
}
