<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

class Migrations extends BaseConfig
{
    public bool   $enabled   = true;
    public string $table     = 'migrations';
    public bool   $timestampFormat = true;
    public string $dateFormat = 'Y-m-d-His';
}
