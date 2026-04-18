<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;

class App extends BaseConfig
{
    public string $baseURL = 'http://localhost:8080/';
    public string $indexPage = '';
    public string $uriProtocol = 'REQUEST_URI';
    public string $defaultLocale = 'es';
    public bool $negotiateLocale = false;
    public array $supportedLocales = ['es', 'en'];
    public string $appTimezone = 'UTC';
    public string $charset = 'UTF-8';
    public bool $forceGlobalSecureRequests = false;
    public array $proxyIPs = [];
    public string $CSPEnabled = '';
    public string $cookiePrefix   = '';
    public string $cookieDomain   = '';
    public string $cookiePath     = '/';
    public bool $cookieSecure   = false;
    public bool $cookieHTTPOnly = true;
    public ?string $cookieSameSite = 'Lax';
    public string $salt = '';
    public bool $CSRFProtection  = false;
    public string $CSRFTokenName  = 'csrf_token_name';
    public string $CSRFHeaderName = 'X-CSRF-TOKEN';
    public string $CSRFCookieName = 'csrf_cookie_name';
    public int $CSRFExpire       = 7200;
    public bool $CSRFRegenerate  = true;
    public bool $CSRFSameSite    = true;
    public string $sessionDriver            = 'CodeIgniter\Session\Handlers\FileSessionHandler';
    public string $sessionCookieName        = 'ci_session';
    public int $sessionExpiration           = 7200;
    public string $sessionSavePath          = WRITEPATH . 'session';
    public bool $sessionMatchIP             = false;
    public int $sessionTimeToUpdate         = 300;
    public bool $sessionRegenerateDestroy   = false;
    public int $cookieLifetime   = 0;
}
