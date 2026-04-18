<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call('UserSeeder');
        $this->call('ListSeeder');

        echo "\nDatabaseSeeder completado.\n";
        echo "Usuario demo: demo@example.com / password123\n";
        echo "Admin:        admin@example.com / admin1234\n";
    }
}
