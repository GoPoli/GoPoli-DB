# PostgreSQL local con Docker

Neon es la opción en la nube del equipo ([DATABASE_NEON.md](DATABASE_NEON.md)). Este documento describe cómo levantar la base de GoPoli en tu máquina con Docker para desarrollo.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución, o Docker Engine con Compose v2.

## Arrancar la base

### Con la imagen publicada

```bash
docker run -d --name gopoli-db -p 5432:5432 \
  -e POSTGRES_PASSWORD=gopoli \
  -v gopoli_pgdata:/var/lib/postgresql/data \
  ghcr.io/gopoli/gopoli-db:latest
```

### Con Docker Compose (desde este repositorio)

```bash
cp .env.example .env
docker compose up -d --build
```

Comprobar:

```bash
docker compose ps
docker exec gopoli-db pg_isready -h 127.0.0.1 -U gopoli -d gopoli
```

Los scripts de `init/` (esquema y seed) se ejecutan **solo la primera vez** que se crea el volumen. Para reinicializar desde cero:

```bash
docker compose down -v
docker compose up -d --build
```

`-v` borra el volumen local y con él todos los datos del contenedor.

## Credenciales locales

| Campo | Valor |
| --- | --- |
| Host | `localhost` |
| Puerto | `5432` |
| Base de datos | `gopoli` |
| Usuario | `gopoli` |
| Contraseña | `gopoli` (definida en `.env`) |

Si ya tienes otro PostgreSQL en el puerto `5432`, detén ese servicio o cambia el mapeo en `docker-compose.yml` (por ejemplo `"5433:5432"`) y ajusta la URL JDBC de la API.

## Conectar la API

[GoPoli-API](https://github.com/GoPoli/GoPoli-API) usa por defecto `localhost:5432/gopoli` con usuario y contraseña `gopoli`, así que basta con arrancarla:

```bash
./mvnw spring-boot:run
```

Si cambiaste las credenciales, define en la API:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gopoli
SPRING_DATASOURCE_USERNAME=gopoli
SPRING_DATASOURCE_PASSWORD=gopoli
```

Prueba: `GET http://localhost:8080/carreras` y `GET http://localhost:8080/ubicaciones`.

## Usuario demo (solo local)

Sembrado en `init/02_seed.sql`; no existe en Neon:

| Campo | Valor |
| --- | --- |
| Correo | `demo.local@elpoli.edu.co` |
| Contraseña | `gopoli-local-dev` |

La contraseña se guarda en texto plano a propósito: la API la acepta mediante la compatibilidad con cuentas previas al hash BCrypt. Es **solo para desarrollo local**.

## Qué incluye el seed

- Carreras: Ingeniería Informática, Ingeniería Civil, Audio Visual.
- Catálogos `tipo_usuario`, `estado_usuario`, `tipo_servicio`, `estado_servicio` y `tipo_vehiculo`.
- Ubicaciones del campus y del metro con coordenadas (misma fuente que `UbicacionCoordenadasSeeder` de la API).
- El usuario demo.

No es un volcado de Neon ni de producción: es un dataset mínimo para que la app arranque.

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
