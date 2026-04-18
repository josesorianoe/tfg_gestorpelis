<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateRefreshTokensTable extends Migration
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
            'token_hash' => [
                'type'       => 'VARCHAR',
                'constraint' => 255,
                'null'       => false,
            ],
            'expires_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => false,
            ],
            'revoked' => [
                'type'    => 'BOOLEAN',
                'null'    => false,
                'default' => false,
            ],
            'created_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addKey('token_hash', false, false, 'idx_rtoken_hash');
        $this->forge->addKey('user_id', false, false, 'idx_rtoken_user_id');
        $this->forge->addKey('expires_at', false, false, 'idx_rtoken_expires_at');
        $this->forge->createTable('refresh_tokens', true);
    }

    public function down(): void
    {
        $this->forge->dropTable('refresh_tokens', true);
    }
}
