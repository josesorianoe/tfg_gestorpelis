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

Al registrarte se crean automáticamente dos listas por defecto: **"Pendientes por ver"** para guardar contenido que quieres ver próximamente, y **"Series que estoy viendo"** para las series en curso.

### 2. Buscar películas y series

Usa la pestaña **Buscar** (icono de lupa) para buscar cualquier película o serie por título. Puedes filtrar los resultados por **película**, **serie** o **persona**. Pulsa sobre un resultado para ver su ficha completa.

### 3. Ver el detalle de un título

En la pantalla de detalle encontrarás:
- Sinopsis, géneros, fecha de estreno y valoración media.
- En el caso de series, lista de temporadas y episodios con toggle para marcarlos como vistos.
- Botón **"Añadir a lista"** para guardarlo en tu colección.

### 4. Gestionar tus listas

Desde la pestaña **Mis listas** puedes:
- Ver tus listas existentes. Las dos listas por defecto (*Pendientes por ver* y *Series que estoy viendo*) aparecen siempre al inicio con la etiqueta "Por defecto".
- Crear listas nuevas pulsando el botón **+**.
- Pulsar sobre una lista para ver su contenido, editar ítems o eliminarlos deslizando.

Al añadir un título a una lista puedes indicar si ya lo has visto, añadir una puntuación y escribir una reseña personal.

### 5. Seguimiento de episodios

En el detalle de una serie, selecciona una temporada para ver sus episodios. Marca cada episodio como visto con el toggle de la derecha. El progreso se guarda automáticamente.

### 6. Tu perfil

En la pestaña **Perfil** puedes:
- Consultar tu historial de visionado agrupado por mes.
- Editar tu nombre o cambiar tu contraseña.
- Solicitar la eliminación de tu cuenta.

---

## Capturas de pantalla

| | | |
|:---:|:---:|:---:|
| ![Login](screenshots/1.jpeg) | ![Registro](screenshots/2.jpeg) | ![Inicio](screenshots/3.jpeg) |
| Inicio de sesión | Registro | Pantalla principal |
| ![Búsqueda](screenshots/4.jpeg) | ![Detalle película](screenshots/5.jpeg) | ![Detalle serie](screenshots/6.jpeg) |
| Búsqueda | Detalle de película | Detalle de serie y episodios |
| ![Listas](screenshots/7.jpeg) | ![Detalle lista](screenshots/8.jpeg) | ![Perfil](screenshots/9.1.jpeg) |
| Mis listas | Detalle de lista | Perfil |

---

## Estructura del repositorio

```
├── app/               # Backend — CodeIgniter 4 (API REST)
├── mobile/            # Frontend — Flutter (código fuente Android)
├── screenshots/       # Capturas de pantalla de la aplicación
├── docker/            # Configuración Docker (desarrollo local)
├── Dockerfile.prod    # Imagen de producción (Railway)
└── README.md
```

---

## API en producción

`https://tfggestorpelis-production.up.railway.app`
