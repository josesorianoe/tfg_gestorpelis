<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateUserListsTable extends Migration
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
            'name' => [
                'type'       => 'VARCHAR',
                'constraint' => 150,
                'null'       => false,
            ],
            'description' => [
                'type' => 'TEXT',
                'null' => true,
            ],
            'is_public' => [
                'type'    => 'BOOLEAN',
                'null'    => false,
                'default' => false,
            ],
            'created_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
            'updated_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addForeignKey('user_id', 'users', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addKey('user_id', false, false, 'idx_ulists_user_id');
        $this->forge->createTable('user_lists', true);
    }

    public function down(): void
    {
        $this->forge->dropTable('user_lists', true);
    }
}
