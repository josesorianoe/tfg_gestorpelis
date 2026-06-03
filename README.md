# GestorPelis — Gestor de películas y series

Aplicación móvil para gestionar tu catálogo personal de películas y series.  
Permite buscar contenido mediante la API de TMDB, organizarlo en listas personalizadas, registrar valoraciones y hacer seguimiento de episodios.

**Backend:** CodeIgniter 4 · PHP 8.2 · PostgreSQL · Docker · Railway  
**Frontend:** Flutter (Android)

---

## Descargar la aplicación

[**Descargar APK — GestorPelis v1.0**](https://github.com/josesorianoe/tfg_gestorpelis/releases/download/v1.0.0/app-release.apk)

Requisitos: dispositivo Android 8.0 o superior.

### Instalación

1. Descarga el APK desde el enlace anterior.
2. En el móvil, ve a **Ajustes → Seguridad** y activa **"Instalar aplicaciones de fuentes desconocidas"** (o "Instalar apps desconocidas" según el modelo).
3. Abre el archivo descargado y pulsa **Instalar**.
4. Una vez instalada, abre **GestorPelis** desde el cajón de aplicaciones.

---

## Tutorial de uso

### 1. Crear una cuenta

Al abrir la app por primera vez, pulsa **"Crear cuenta"**, introduce tu nombre, correo y contraseña y pulsa **Registrarse**. Si ya tienes cuenta, introduce tus datos en la pantalla de inicio de sesión.

### 2. Buscar películas y series

Usa la pestaña **Buscar** (icono de lupa) para buscar cualquier película o serie por título. Puedes filtrar los resultados por **película** o **serie**. Pulsa sobre un resultado para ver su ficha completa.

### 3. Ver el detalle de un título

En la pantalla de detalle encontrarás:
- Sinopsis, géneros, fecha de estreno y valoración media.
- En el caso de series, lista de temporadas y episodios.
- Botón **"Añadir a lista"** para guardarlo en tu colección.

### 4. Gestionar tus listas

Desde la pestaña **Listas** puedes:
- Ver tus listas existentes (por defecto: *Pendientes por ver* y *Series que estoy viendo*).
- Crear listas nuevas con nombre y descripción.
- Pulsar sobre una lista para ver su contenido, editar ítems o eliminarlos.

Al añadir un título a una lista puedes indicar si ya lo has visto, añadir una puntuación y escribir una reseña personal.

### 5. Seguimiento de episodios

En el detalle de una serie, entra en una temporada para ver sus episodios. Marca cada episodio como visto con el botón de la derecha. El progreso se guarda automáticamente.

### 6. Tu perfil

En la pestaña **Perfil** puedes:
- Consultar tu historial de visionado agrupado por mes.
- Cambiar tu nombre o contraseña.
- Solicitar la eliminación de tu cuenta.

---

## Capturas de pantalla

<!-- Próximamente -->

---

## Estructura del repositorio

```
├── app/               # Backend — CodeIgniter 4 (API REST)
├── mobile/            # Frontend — Flutter (código fuente Android)
├── docker/            # Configuración Docker (desarrollo local)
├── Dockerfile.prod    # Imagen de producción (Railway)
└── README.md
```

---

## API en producción

`https://tfggestorpelis-production.up.railway.app`
