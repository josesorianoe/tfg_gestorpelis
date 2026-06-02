<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */

$routes->setDefaultNamespace('App\Controllers');
$routes->setDefaultController('Home');
$routes->setDefaultMethod('index');
$routes->setTranslateURIDashes(false);
$routes->set404Override();
$routes->setAutoRoute(false);

// Health check (público)
$routes->get('/', 'HomeController::index');
$routes->get('health', 'HomeController::health');

// -----------------------------------------------------------------------
// API routes
// -----------------------------------------------------------------------
$routes->group('api', ['namespace' => 'App\Controllers\Api'], static function ($routes) {

    // Auth (público)
    $routes->group('auth', static function ($routes) {
        $routes->post('register', 'AuthController::register');
        $routes->post('login',    'AuthController::login');
        $routes->post('refresh',  'AuthController::refresh');
        $routes->post('logout',   'AuthController::logout', ['filter' => 'jwt']);
    });

    // Search (protegido + throttle)
    $routes->get('search', 'SearchController::index', ['filter' => 'jwt']);
    $routes->get('media/(:num)', 'SearchController::show/$1', ['filter' => 'jwt']);

    // Person (protegido)
    $routes->get('person/(:num)', 'PersonController::show/$1', ['filter' => 'jwt']);

    // Catalog (protegido)
    $routes->group('catalog', ['filter' => 'jwt'], static function ($routes) {
        $routes->get('/',        'CatalogController::index');
        $routes->get('popular',  'CatalogController::popular');
        $routes->get('discover', 'CatalogController::discover');
    });

    // User lists (protegido)
    $routes->group('lists', ['filter' => 'jwt'], static function ($routes) {
        $routes->get('/',              'ListController::index');
        $routes->post('/',             'ListController::create');
        $routes->get('(:num)',         'ListController::show/$1');
        $routes->put('(:num)',         'ListController::update/$1');
        $routes->delete('(:num)',      'ListController::delete/$1');

        // Items dentro de una lista
        $routes->post('(:num)/items',              'ListController::addItem/$1');
        $routes->put('(:num)/items/(:num)',         'ListController::updateItem/$1/$2');
        $routes->delete('(:num)/items/(:num)',      'ListController::removeItem/$1/$2');
    });

    // User profile (protegido)
    $routes->group('user', ['filter' => 'jwt'], static function ($routes) {
        $routes->get('me',           'UserController::me');
        $routes->put('me',           'UserController::update');
        $routes->put('password',     'UserController::changePassword');
        $routes->get('media',        'UserController::media');
        $routes->get('media/(:num)',    'UserController::mediaStatus/$1');
        $routes->put('media/(:num)',    'UserController::updateMediaReview/$1');
        $routes->delete('media/(:num)', 'UserController::removeFromAllLists/$1');
    });
});
