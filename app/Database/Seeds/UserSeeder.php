<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name'       => 'Usuario Demo',
                'email'      => 'demo@example.com',
                'password'   => password_hash('password123', PASSWORD_BCRYPT),
                'avatar_url' => null,
                'created_at' => date('Y-m-d H:i:s'),
                'updated_at' => date('Y-m-d H:i:s'),
            ],
            [
                'name'       => 'Admin',
                'email'      => 'admin@example.com',
                'password'   => password_hash('admin1234', PASSWORD_BCRYPT),
                'avatar_url' => null,
                'created_at' => date('Y-m-d H:i:s'),
                'updated_at' => date('Y-m-d H:i:s'),
            ],
        ];

        foreach ($users as $user) {
            // Avoid duplicate email on re-seed
            $exists = $this->db->table('users')->where('email', $user['email'])->get()->getRow();
            if (! $exists) {
                $this->db->table('users')->insert($user);
            }
        }

        echo "UserSeeder: usuarios creados.\n";
    }
}
