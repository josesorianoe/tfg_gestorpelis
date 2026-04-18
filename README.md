# Gestor Películas y Series — API REST

Backend de la aplicación de gestión de películas y series, desarrollado como TFG.  
Stack: **CodeIgniter 4 · PHP 8.2 · PostgreSQL 16 · Docker · JWT · TMDB API**

---

## Requisitos

| Herramienta | Versión mínima |
|---|---|
| Docker | 24.x |
| Docker Compose | v2.x (plugin) |

> No necesitas instalar PHP, Composer ni PostgreSQL en tu máquina.

---

## Instalación paso a paso

```bash
# 1. Clona el repositorio
git clone <url-del-repo> gestor_pelis
cd gestor_pelis

# 2. Copia el archivo de entorno
cp .env.example .env

# 3. Edita .env:
#    - Añade tu TMDB_API_KEY  (ver sección TMDB más abajo)
#    - Cambia JWT_SECRET por un string largo y aleatorio
#    - Ajusta UID/GID si usas Linux (ejecuta `id -u` e `id -g`)

# 4. Levanta los contenedores
docker compose up -d

# 5. Instala dependencias PHP (solo la primera vez)
docker compose exec app composer install

# 6. Ejecuta las migraciones
docker compose exec app php spark migrate

# 7. (Opcional) Carga datos de prueba
docker compose exec app php spark db:seed DatabaseSeeder
```

La API estará disponible en **http://localhost:8080**

---

## Cómo obtener la API key de TMDB

1. Crea una cuenta en [https://www.themoviedb.org](https://www.themoviedb.org)
2. Ve a **Configuración → API** (o directamente a `https://www.themoviedb.org/settings/api`)
3. Solicita una API key de tipo **Developer**
4. Copia la clave (v3 auth) y pégala en `TMDB_API_KEY` del `.env`

---

## Comandos útiles

```bash
# Levantar entorno
docker compose up -d

# Levantar entorno con pgAdmin
docker compose --profile tools up -d

# Parar contenedores
docker compose down

# Ver logs en tiempo real
docker compose logs -f app
docker compose logs -f nginx

# Ejecutar migraciones
docker compose exec app php spark migrate

# Deshacer última migración
docker compose exec app php spark migrate:rollback

# Cargar seeders
docker compose exec app php spark db:seed DatabaseSeeder

# Instalar/actualizar dependencias
docker compose exec app composer install
docker compose exec app composer update

# Acceder a shell del contenedor app
docker compose exec app bash

# Limpiar caché de CI4
docker compose exec app php spark cache:clear
```

### pgAdmin

Con `--profile tools` activo, accede a **http://localhost:5050**  
- Email: `admin@admin.com`  
- Password: `admin`  

Para conectarte a la base de datos desde pgAdmin:
- Host: `db`
- Puerto: `5432`
- Base de datos: `movies_db`
- Usuario: `movies_user`
- Password: `movies_pass`

---

## Estructura del proyecto

```
├── app/
│   ├── Config/             # Configuración CI4 (Routes, Database, Filters…)
│   ├── Controllers/Api/    # AuthController, SearchController, etc.
│   ├── Database/
│   │   ├── Migrations/     # 6 migraciones (users, media_items, etc.)
│   │   └── Seeds/          # DatabaseSeeder, UserSeeder, ListSeeder
│   ├── Filters/            # JWTAuthFilter, CorsFilter
│   ├── Models/             # 6 modelos
│   └── Services/           # JWTService, TMDBService, CacheService
├── docker/
│   ├── php/                # Dockerfile + php.ini
│   ├── nginx/              # default.conf
│   └── postgres/           # init.sql
├── public/                 # Entry point (index.php)
├── writable/               # Logs, caché, sesiones
├── docker-compose.yml
├── composer.json
└── .env.example
```

---

## Endpoints de la API

### Base URL: `http://localhost:8080`

Todas las respuestas tienen el formato:
```json
{ "status": "success|error", "data": {…}, "message": "…" }
```

### Autenticación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/auth/register` | — | Registro de usuario |
| POST | `/api/auth/login` | — | Login, devuelve JWT |
| POST | `/api/auth/refresh` | — | Renueva access token |
| POST | `/api/auth/logout` | JWT | Cierra sesión |

### Búsqueda

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/search?query=…&type=movie\|tv&page=N` | JWT | Busca en TMDB |
| GET | `/api/media/{tmdb_id}?type=movie\|tv` | JWT | Detalle completo |

### Catálogo

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/catalog?page=N&per_page=20` | JWT | Catálogo local paginado |
| GET | `/api/catalog/popular` | JWT | Títulos populares |

### Listas de usuario

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/lists` | JWT | Listas del usuario |
| POST | `/api/lists` | JWT | Crear lista |
| GET | `/api/lists/{id}` | JWT | Detalle + items |
| PUT | `/api/lists/{id}` | JWT | Actualizar lista |
| DELETE | `/api/lists/{id}` | JWT | Eliminar lista |
| POST | `/api/lists/{id}/items` | JWT | Añadir título |
| PUT | `/api/lists/{id}/items/{item_id}` | JWT | Actualizar item |
| DELETE | `/api/lists/{id}/items/{item_id}` | JWT | Quitar título |

### Perfil de usuario

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/api/user/me` | JWT | Datos del usuario |
| PUT | `/api/user/me` | JWT | Actualizar perfil |
| PUT | `/api/user/password` | JWT | Cambiar contraseña |

---

## Ejemplos con curl

### Registro
```bash
curl -s -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Juan García","email":"juan@example.com","password":"mipassword123"}' | jq
```

### Login
```bash
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@example.com","password":"password123"}' | jq

# Guarda el token:
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@example.com","password":"password123"}' | jq -r '.data.access_token')
```

### Buscar películas
```bash
curl -s "http://localhost:8080/api/search?query=inception&type=movie" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Detalle de una película
```bash
curl -s "http://localhost:8080/api/media/27205?type=movie" \
  -H "Authorization: Bearer $TOKEN" | jq
```

### Crear una lista
```bash
curl -s -X POST http://localhost:8080/api/lists \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Mi lista","description":"Películas que me gustaron","is_public":true}' | jq
```

### Añadir título a una lista
```bash
curl -s -X POST http://localhost:8080/api/lists/1/items \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tmdb_id":27205,"media_type":"movie"}' | jq
```

### Marcar como visto con nota
```bash
curl -s -X PUT http://localhost:8080/api/lists/1/items/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"watched":true,"user_rating":9.5,"user_note":"Obra maestra"}' | jq
```

### Renovar token
```bash
curl -s -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"TU_REFRESH_TOKEN"}' | jq
```

---

## Troubleshooting

### Permisos en Linux (writable/)
```bash
# Si ves errores de permisos en logs o caché:
sudo chown -R $USER:$USER writable/
# O establece UID/GID en .env antes de levantar los contenedores:
echo "UID=$(id -u)" >> .env
echo "GID=$(id -g)" >> .env
docker compose up -d --build
```

### Puerto ocupado
```bash
# Cambia el puerto en .env:
NGINX_PORT=8081
POSTGRES_PORT=5433
```

### El contenedor app no arranca
```bash
docker compose logs app
# Comprueba que composer install se ejecutó
docker compose exec app composer install
```

### Error "JWT_SECRET is not configured"
Asegúrate de que tu `.env` tiene `JWT_SECRET` con al menos 32 caracteres.  
Genera uno con: `php -r "echo bin2hex(random_bytes(64));"`

### Error de conexión a la base de datos
```bash
# Comprueba que el contenedor db está sano
docker compose ps
# Fuerza recreación
docker compose down -v && docker compose up -d
```

### TMDB API key inválida
El endpoint `/api/search` devolverá HTTP 502. Verifica que `TMDB_API_KEY` en `.env`  
es correcta y que tu cuenta de TMDB tiene acceso a la API v3.
