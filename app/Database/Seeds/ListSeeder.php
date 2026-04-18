<?php

namespace App\Database\Seeds;

use CodeIgniter\Database\Seeder;

class ListSeeder extends Seeder
{
    public function run(): void
    {
        $user = $this->db->table('users')->where('email', 'demo@example.com')->get()->getRowArray();

        if (! $user) {
            echo "ListSeeder: usuario demo no encontrado. Ejecuta UserSeeder primero.\n";
            return;
        }

        $lists = [
            [
                'user_id'     => $user['id'],
                'name'        => 'Favoritas',
                'description' => 'Mis películas y series favoritas de todos los tiempos',
                'is_public'   => true,
                'created_at'  => date('Y-m-d H:i:s'),
                'updated_at'  => date('Y-m-d H:i:s'),
            ],
            [
                'user_id'     => $user['id'],
                'name'        => 'Por ver',
                'description' => 'Títulos que quiero ver próximamente',
                'is_public'   => false,
                'created_at'  => date('Y-m-d H:i:s'),
                'updated_at'  => date('Y-m-d H:i:s'),
            ],
            [
                'user_id'     => $user['id'],
                'name'        => 'Vistas',
                'description' => 'Historial de lo que ya he visto',
                'is_public'   => false,
                'created_at'  => date('Y-m-d H:i:s'),
                'updated_at'  => date('Y-m-d H:i:s'),
            ],
        ];

        foreach ($lists as $list) {
            $exists = $this->db->table('user_lists')
                               ->where('user_id', $list['user_id'])
                               ->where('name', $list['name'])
                               ->get()->getRow();
            if (! $exists) {
                $this->db->table('user_lists')->insert($list);
            }
        }

        echo "ListSeeder: listas creadas para usuario demo.\n";
    }
}
