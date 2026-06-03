#!/bin/sh
set -e

APP_DIR=/var/www/html

{
    printf 'CI_ENVIRONMENT = production\n'
    printf 'app.baseURL = %s\n' "${APP_BASE_URL}"
    printf 'encryption.key = %s\n' "${ENCRYPTION_KEY}"
    printf '\n'
    printf 'database.default.hostname = %s\n' "${DB_HOST}"
    printf 'database.default.username = %s\n' "${DB_USER}"
    printf 'database.default.password = %s\n' "${DB_PASSWORD}"
    printf 'database.default.database = %s\n' "${DB_NAME}"
    printf 'database.default.port = %s\n' "${DB_PORT:-5432}"
    printf 'database.default.DBDriver = Postgre\n'
    printf 'database.default.charset = utf8\n'
    printf '\n'
    printf 'JWT_SECRET = %s\n' "${JWT_SECRET}"
    printf 'JWT_ACCESS_TTL = %s\n' "${JWT_ACCESS_TTL:-3600}"
    printf 'JWT_REFRESH_TTL = %s\n' "${JWT_REFRESH_TTL:-2592000}"
    printf '\n'
    printf 'TMDB_API_KEY = %s\n' "${TMDB_API_KEY}"
    printf 'TMDB_BASE_URL = https://api.themoviedb.org/3\n'
    printf 'TMDB_IMAGE_BASE_URL = https://image.tmdb.org/t/p\n'
    printf 'TMDB_CACHE_TTL = %s\n' "${TMDB_CACHE_TTL:-86400}"
} > "${APP_DIR}/.env"

chmod -R 777 "${APP_DIR}/writable"
cd "${APP_DIR}"
php spark migrate --force
mkdir -p /run/nginx
envsubst '${PORT}' < /etc/nginx/templates/prod.conf.template > /etc/nginx/http.d/default.conf
exec /usr/bin/supervisord -c /etc/supervisord.conf