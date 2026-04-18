<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

class Throttle extends BaseConfig
{
    // Max requests per minute for search endpoints
    public int $searchRequestsPerMinute = 30;
}
