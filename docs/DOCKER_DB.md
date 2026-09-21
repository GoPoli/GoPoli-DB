# Postgres local con Docker (GoPoli)

Neon sigue siendo la opción en la nube del equipo (`DATABASE_NEON.md`). Este documento describe **solo** PostgreSQL en Docker para desarrollo en tu máquina.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) instalado y en ejecución.

## Arrancar la BD

En la raíz del repo:

```powershell
docker compose up -d
```

Comprobar:

```powershell
docker compose ps
docker exec gopoli-postgres pg_isready -U gopoli -d gopoli
```

Los scripts de `docker/postgres/init/` (esquema + seeds) se ejecutan **solo la primera vez** que se crea el volumen. Si necesitas reinicializar desde cero:

```powershell
docker compose down -v
docker compose up -d
```

`-v` borra el volumen local (pierdes datos de ese contenedor).

## Credenciales locales (Docker)

| Campo | Valor |
|-------|--------|
| Host | `localhost` |
| Puerto | `5432` |
| Base de datos | `gopoli` |
| Usuario | `gopoli` |
| Contraseña | `gopoli` |

Si ya tienes otro PostgreSQL en el puerto `5432`, detén ese servicio o cambia el mapeo en `docker-compose.yml` (ej. `"5433:5432"`) y ajusta la URL JDBC.

## Apuntar Spring Boot a Docker

Copia `backend/.env.example` → `backend/.env` (o define variables en el IDE) con:

```env
SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/gopoli
SPRING_DATASOURCE_USERNAME=gopoli
SPRING_DATASOURCE_PASSWORD=gopoli
```

Luego:

```powershell
cd backend
.\mvnw.cmd spring-boot:run
```

Prueba: `GET http://localhost:8080/carreras` y `GET http://localhost:8080/ubicaciones`.

### Diferencia con los defaults de `application.properties`

Sin variables de entorno, Spring usa `postgres` / `123456789` (útil si tienes Postgres nativo). Con Docker de este repo debes definir `gopoli` / `gopoli` como arriba.

## Usuario demo (solo local)

Sembrado en `02_seed.sql` (no es un usuario de Neon):

| Campo | Valor |
|-------|--------|
| Correo | `demo.local@elpoli.edu.co` |
| Contraseña | `gopoli-local-dev` |

La app compara contraseñas en texto plano (`AuthController`); esta clave es **solo para desarrollo local**.

## Qué incluye el seed

- Carreras: Ingeniería Informatica, Ingeniería Civil, Audio Visual
- `tipo_usuario`, `estado_usuario`, `tipo_servicio`, `estado_servicio`, `tipo_vehiculo`
- Ubicaciones campus/metro con coordenadas (misma fuente que `UbicacionCoordenadasSeeder`)
- Usuario demo anterior

No se importa ni se vuelca la BD de Neon: es un dataset inventado para que la app arranque.

## Neon vs Docker

| | Neon | Docker local |
|--|------|----------------|
| Dónde vive | Nube compartida | Tu PC |
| Config | `SPRING_DATASOURCE_*` con host Neon + `sslmode=require` | `localhost:5432` sin SSL |
| Datos | Compartidos con el equipo | Solo tuyos; se pierden con `down -v` |
| Doc | `DATABASE_NEON.md` | Este archivo |

Puedes cambiar entre Neon y Docker solo cambiando las variables `SPRING_DATASOURCE_*`. No hace falta borrar la config de Neon.

## PWA / frontend

La URL de la API (`NEXT_PUBLIC_API_URL` en la PWA) debe apuntar al **backend Spring** (ej. `http://localhost:8080` o `http://TU_IP:8080`). Eso es distinto de la URL de Postgres: Spring habla con Docker/Neon; el cliente web solo habla con Spring.
