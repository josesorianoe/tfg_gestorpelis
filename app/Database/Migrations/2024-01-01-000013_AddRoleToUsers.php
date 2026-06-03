<?php

namespace App\Database\Migrations;

use CodeIgniter\Database\Migration;

class AddRoleToUsers extends Migration
{
    public function up(): void
    {
        $this->forge->addColumn('users', [
            'role' => [
                'type'       => 'VARCHAR',
                'constraint' => 20,
                'null'       => false,
                'default'    => 'user',
                'after'      => 'name',
            ],
        ]);

        // To promote a user to superadmin, run:
        // UPDATE users SET role = 'admin' WHERE email = 'your@email.com';
    }

    public function down(): void
    {
        $this->forge->dropColumn('users', 'role');
    }
}
