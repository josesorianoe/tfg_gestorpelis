<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class CreateListItemsTable extends Migration
{
    public function up(): void
    {
        $this->forge->addField([
            'id' => [
                'type'           => 'BIGINT',
                'unsigned'       => true,
                'auto_increment' => true,
            ],
            'list_id' => [
                'type'     => 'BIGINT',
                'unsigned' => true,
                'null'     => false,
            ],
            'media_item_id' => [
                'type'     => 'BIGINT',
                'unsigned' => true,
                'null'     => false,
            ],
            'user_note' => [
                'type' => 'TEXT',
                'null' => true,
            ],
            'user_rating' => [
                'type'       => 'DECIMAL',
                'constraint' => '3,1',
                'null'       => true,
            ],
            'watched' => [
                'type'    => 'BOOLEAN',
                'null'    => false,
                'default' => false,
            ],
            'added_at' => [
                'type' => 'TIMESTAMPTZ',
                'null' => true,
            ],
        ]);

        $this->forge->addPrimaryKey('id');
        $this->forge->addForeignKey('list_id', 'user_lists', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addForeignKey('media_item_id', 'media_items', 'id', 'CASCADE', 'CASCADE');
        $this->forge->addUniqueKey(['list_id', 'media_item_id'], 'uq_list_media');
        $this->forge->addKey('list_id', false, false, 'idx_litems_list_id');
        $this->forge->addKey('media_item_id', false, false, 'idx_litems_media_id');
        $this->forge->createTable('list_items', true);

        // Constraint: user_rating between 0 and 10
        $this->db->query('ALTER TABLE list_items ADD CONSTRAINT chk_user_rating CHECK (user_rating IS NULL OR (user_rating >= 0 AND user_rating <= 10))');
    }

    public function down(): void
    {
        $this->forge->dropTable('list_items', true);
    }
}
