<?php

namespace Config;

use CodeIgniter\Modules\Modules as BaseModules;

class Modules extends BaseModules
{
    public $enabled            = true;
    public $discoverInComposer = false;
    public $aliases            = [];
}
