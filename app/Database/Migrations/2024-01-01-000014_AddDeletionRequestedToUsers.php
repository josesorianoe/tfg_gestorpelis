<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddDeletionRequestedToUsers extends Migration
{
    public function up(): void
    {
        $this->forge->addColumn('users', [
            'deletion_requested_at' => [
                'type'    => 'TIMESTAMP',
                'null'    => true,
                'default' => null,
                'after'   => 'role',
            ],
        ]);
    }

    public function down(): void
    {
        $this->forge->dropColumn('users', 'deletion_requested_at');
    }
}
