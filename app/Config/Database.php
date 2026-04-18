<?php

namespace Config;

use CodeIgniter\Database\Config;

class Database extends Config
{
    public string $filesPath = APPPATH . 'Database' . DIRECTORY_SEPARATOR;

    public string $defaultGroup = 'default';

    public array $default = [
        'DSN'          => '',
        'hostname'     => 'db',
        'username'     => 'movies_user',
        'password'     => 'movies_pass',
        'database'     => 'movies_db',
        'DBDriver'     => 'Postgre',
        'DBPrefix'     => '',
        'pConnect'     => false,
        'DBDebug'      => true,
        'charset'      => 'utf8',
        'DBCollat'     => 'utf8_general_ci',
        'swapPre'      => '',
        'encrypt'      => false,
        'compress'     => false,
        'strictOn'     => false,
        'failover'     => [],
        'port'         => 5432,
        'numberNative' => false,
        'dateFormat'   => [
            'date'     => 'Y-m-d',
            'datetime' => 'Y-m-d H:i:s',
            'time'     => 'H:i:s',
        ],
    ];

    public array $tests = [
        'DSN'      => '',
        'hostname' => 'localhost',
        'username' => '',
        'password' => '',
        'database' => ':memory:',
        'DBDriver' => 'SQLite3',
        'DBPrefix' => 'db_',
        'pConnect' => false,
        'DBDebug'  => true,
        'charset'  => 'utf8',
        'DBCollat' => 'utf8_general_ci',
        'swapPre'  => '',
        'encrypt'  => false,
        'compress' => false,
        'strictOn' => false,
        'failover' => [],
        'port'     => 3306,
    ];

    public function __construct()
    {
        parent::__construct();

        // Override from environment variables
        if ($hostname = env('database.default.hostname')) {
            $this->default['hostname'] = $hostname;
        }
        if ($database = env('database.default.database')) {
            $this->default['database'] = $database;
        }
        if ($username = env('database.default.username')) {
            $this->default['username'] = $username;
        }
        if ($password = env('database.default.password')) {
            $this->default['password'] = $password;
        }
        if ($port = env('database.default.port')) {
            $this->default['port'] = (int) $port;
        }
        if ($driver = env('database.default.DBDriver')) {
            $this->default['DBDriver'] = $driver;
        }
    }
}
