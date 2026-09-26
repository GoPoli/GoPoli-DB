# PostgreSQL local con Docker

Este documento describe cómo levantar la base de GoPoli en tu máquina con Docker para desarrollo. Para una base compartida en la nube consulta [DATABASE_NEON.md](DATABASE_NEON.md).

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución, o Docker Engine con Compose v2.

## Arrancar la base

### Con Docker Compose (desde este repositorio)

```bash
cp .env.example .env
docker compose up -d --build
```

`.env` define la contraseña (`POSTGRES_PASSWORD`) y activa los datos de demostración (`GOPOLI_SEED_DEMO=true`). No se versiona.

Comprobar:

```bash
docker compose ps
docker exec gopoli-db pg_isready -h 127.0.0.1 -U gopoli -d gopoli
docker logs gopoli-db | grep GoPoli
```

La última línea muestra si se cargaron los datos de demostración.

### Con la imagen publicada

```bash
docker run -d --name gopoli-db -p 127.0.0.1:5432:5432 \
  -e POSTGRES_PASSWORD=<DB_PASSWORD> \
  -e GOPOLI_SEED_DEMO=true \
  -v gopoli_pgdata:/var/lib/postgresql/data \
  ghcr.io/gopoli/gopoli-db:latest
```

## Orden de inicialización

PostgreSQL ejecuta los scripts de `/docker-entrypoint-initdb.d/` **solo la primera vez** que se crea el volumen, en orden alfabético:

| Script | Qué hace |
| --- | --- |
| `01_schema.sql` | Crea las 13 tablas, llaves foráneas, restricciones e índices |
| `02_catalogs.sql` | Carga carreras, tipos, estados y ubicaciones con coordenadas |
| `03_demo_data.sh` | Si `GOPOLI_SEED_DEMO=true`, carga `demo_data.sql`; si no, lo omite y lo registra en el log |

Para reinicializar desde cero (por ejemplo, tras cambiar el esquema o `GOPOLI_SEED_DEMO`):

```bash
docker compose down -v
docker compose up -d --build
```

`-v` borra el volumen local y con él todos los datos del contenedor.

## Credenciales locales

| Campo | Valor |
| --- | --- |
| Host | `127.0.0.1` |
| Puerto | `5432` (cámbialo con `DB_HOST_PORT` en `.env`) |
| Base de datos | `gopoli` |
| Usuario | `gopoli` |
| Contraseña | La de `POSTGRES_PASSWORD` en `.env` |

El puerto se publica solo en `127.0.0.1`: la base no queda expuesta a la red local.

## Cuentas de demostración

| Correo | Rol |
| --- | --- |
| `demo.local@elpoli.edu.co` | Pasajera con historial y ruta habitual |
| `conductor.demo@elpoli.edu.co` | Conductor con vehículo y viaje activo |
| `pasajera.demo@elpoli.edu.co` | Pasajera unida a los viajes de ejemplo |

Contraseña de todas: `gopoli-local-dev`. Existen solo si la base se creó con `GOPOLI_SEED_DEMO=true`.

## Conectar la API

En el `.env` de [GoPoli-API](https://github.com/GoPoli/GoPoli-API):

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gopoli
SPRING_DATASOURCE_USERNAME=gopoli
SPRING_DATASOURCE_PASSWORD=<DB_PASSWORD>
SPRING_JPA_HIBERNATE_DDL_AUTO=validate
```

Luego:

```bash
./mvnw spring-boot:run
```

Prueba: `GET http://localhost:8080/health`, `GET http://localhost:8080/programs` y `GET http://localhost:8080/locations`.

La API valida el esquema al arrancar; si una entidad y una tabla no coinciden, la API no inicia. Los cambios de modelo se hacen primero aquí, en `init/01_schema.sql`.

## Neon vs Docker

| | Neon | Docker local |
| --- | --- | --- |
| Dónde vive | Nube compartida | Tu equipo |
| Configuración | `SPRING_DATASOURCE_*` con host Neon y `sslmode=require` | `localhost:5432` sin SSL |
| Datos | Compartidos con el equipo | Solo tuyos; se pierden con `down -v` |
| Guía | [DATABASE_NEON.md](DATABASE_NEON.md) | Este documento |

Cambiar entre Neon y Docker solo requiere cambiar las variables `SPRING_DATASOURCE_*` de la API.

## PWA

La PWA nunca habla con PostgreSQL. `NEXT_PUBLIC_API_URL` en [GoPoli-Web](https://github.com/GoPoli/GoPoli-Web) apunta a la API (por ejemplo `http://localhost:8080`), y es la API la que se conecta a Docker o a Neon.
