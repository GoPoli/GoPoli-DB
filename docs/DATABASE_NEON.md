# Base de datos GoPoli en Neon (PostgreSQL compartido)

Neon es PostgreSQL en la nube. Con **un solo proyecto y una rama `main`**, todo el equipo apunta al mismo `gopoli` (usuarios, ubicaciones, servicios, etc.).

## 1) Crear el proyecto en Neon

1. Entra en [https://neon.tech](https://neon.tech) e inicia sesión (GitHub sirve).
2. **New Project** → nombre sugerido: `gopoli`.
3. Región: la más cercana al equipo (p. ej. `US East` o la que ofrezca menor latencia desde Colombia).
4. En el dashboard, abre **Connection details** y copia:
   - **Host** (ej. `ep-xxxx.us-east-2.aws.neon.tech`)
   - **Database** (suele ser `neondb` o el que elijas)
   - **User** / **Password**
   - Activa **SSL** (obligatorio en Neon).

Neon ofrece dos URLs:

| Tipo | Cuándo usarla |
|------|----------------|
| **Pooled** (`…-pooler.…`) | Backend Spring Boot y varios compañeros conectados a la vez (recomendado). |
| **Direct** | `pg_dump` / `pg_restore` / pgAdmin para migración o administración. |

## 2) Variables para Spring Boot

El backend ya lee estas variables (ver `backend/src/main/resources/application.properties`):

| Variable | Ejemplo (ajusta con tu host Neon) |
|----------|-----------------------------------|
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://ep-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require` |
| `SPRING_DATASOURCE_USERNAME` | `neondb_owner` |
| `SPRING_DATASOURCE_PASSWORD` | *(contraseña del dashboard Neon)* |

**Importante:** la URL JDBC debe llevar `?sslmode=require`. Sin eso, la conexión a Neon suele fallar.

Convierte la URL `postgres://` del panel Neon a JDBC así:

```
postgres://USER:PASS@HOST/DB?sslmode=require
        ↓
jdbc:postgresql://HOST/DB?sslmode=require
```

(user y password van en las variables aparte, no en la URL JDBC.)

### Plantilla local (no subir a git)

Copia `backend/.env.example` → `backend/.env` y rellena los valores. Ese archivo está en `.gitignore`.

Comparte usuario/contraseña/URL con el equipo por un canal seguro (1Password, Bitwarden, Discord privado del proyecto, etc.), **nunca** en el repositorio.

## 3) Migrar tu BD local (`gopoli`) a Neon (todas las tablas)

Tienes **dos formas**: script automático (recomendado) o pgAdmin (clic a clic).

### Opción A — Script (exporta todo el esquema + datos)

1. En Neon → **Dashboard** → **Connect** → pestaña que diga **Direct** (no Pooled).
2. Copia la connection string, debe verse así:

   `postgresql://neondb_owner:XXXXXXXX@ep-nombre-12345678.us-east-2.aws.neon.tech/neondb?sslmode=require`

3. PowerShell en la raíz del repo:

```powershell
$env:PGPASSWORD = "123456789"   # tu password local de postgres (pgAdmin)
$env:NEON_DATABASE_URL = "postgresql://USUARIO:PASS@ep-XXXX.region.aws.neon.tech/neondb?sslmode=require"

.\backend\scripts\migrate_local_to_neon.ps1 -CleanNeonFirst
```

`-CleanNeonFirst` borra en Neon lo que ya exista y vuelve a crear tablas desde tu dump (útil si ya arrancaste el backend contra Neon y Hibernate creó tablas vacías).

Solo exportar de nuevo:

```powershell
.\backend\scripts\migrate_local_to_neon.ps1 -ExportOnly
```

Solo importar un `gopoli.dump` que ya tengas:

```powershell
$env:NEON_DATABASE_URL = "postgresql://..."
.\backend\scripts\migrate_local_to_neon.ps1 -ImportOnly -CleanNeonFirst
```

En Windows, si `pg_dump` no está en el PATH, el script usa `C:\Program Files\PostgreSQL\18\bin\`.

### Opción B — pgAdmin (sin terminal)

**Paso 1 — Backup local**

1. pgAdmin → servidor **PostgreSQL 18** → base de datos **`gopoli`** → clic derecho → **Backup…**
2. Filename: `C:\Users\jorge\GoPoli\gopoli.backup`
3. Format: **Custom** o **Plain** (Custom = mismo que el script).
4. Pestaña **Data** → activa datos y esquema (por defecto suele ir todo).
5. **Backup**.

**Paso 2 — Registrar Neon en pgAdmin**

1. **Register** → **Server** → nombre `Neon GoPoli`.
2. **Connection**: Host y Database de Neon (Direct), User, Password, port `5432`.
3. **SSL** → SSL mode: **Require** → Save.

**Paso 3 — Restore en Neon**

1. Clic derecho en la base de datos de Neon (ej. `neondb`) → **Restore…**
2. Filename: el `.backup` que generaste.
3. Opciones: marca **Clean before restore** si ya había tablas en Neon.
4. **Restore**.

### Comandos manuales (equivalente al script)

Exportar (local):

```powershell
$env:PGPASSWORD = "TU_PASSWORD_LOCAL"
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -h localhost -U postgres -d gopoli -F c --no-owner --no-acl -f gopoli.dump
```

Importar (Neon, URL **directa**):

```powershell
& "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe" --clean --if-exists --verbose --no-owner --no-privileges -d "postgresql://USUARIO:PASS@ep-XXXX.region.aws.neon.tech/neondb?sslmode=require" gopoli.dump
```

### Verificar que llegaron todas las tablas

En Neon **SQL Editor** o pgAdmin conectado a Neon:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 1;

SELECT COUNT(*) AS usuarios FROM usuario;
SELECT COUNT(*) AS ubicaciones FROM ubicacion;
```

Deberías ver las mismas tablas que en local (`usuario`, `ubicacion`, `servicio`, `carrera`, etc.) y los mismos conteos de filas.

## 4) Arrancar el backend contra Neon

PowerShell:

```powershell
cd backend
$env:SPRING_DATASOURCE_URL="jdbc:postgresql://TU-HOST-POOLER/neondb?sslmode=require"
$env:SPRING_DATASOURCE_USERNAME="TU_USUARIO"
$env:SPRING_DATASOURCE_PASSWORD="TU_CONTRASEÑA"
.\mvnw.cmd spring-boot:run
```

Prueba: `GET http://localhost:8080/ubicaciones`

En IntelliJ / VS Code: define las mismas tres variables en la configuración de ejecución de `GoPoliApplication`.

## 5) pgAdmin con Neon (opcional)

1. Register → Server.
2. **Connection** → Host = host **directo** Neon, Port `5432`, Database, Username, Password.
3. Pestaña **SSL** → SSL mode: `require`.

Así ves las mismas tablas (`usuario`, `ubicacion`, `servicio`, …) que usa la app.

## 6) Compañeros: checklist rápido

1. Clonar el repo.
2. Recibir las 3 variables `SPRING_DATASOURCE_*` (canal seguro).
3. Copiar `backend/.env.example` → `backend/.env` y pegar valores.
4. Arrancar backend (variables de entorno o `.env` según su IDE).
5. PWA apuntando al backend de cada uno o a uno compartido (`web/.env.local`):

   ```env
   NEXT_PUBLIC_API_URL=http://IP_DEL_BACKEND:8080
   ```

   Luego `cd web && npm run dev`.

Todos leen/escriben la **misma** BD en Neon; los usuarios que creéis serán visibles para todos.

## 7) Backend en Railway + BD en Neon

Si el API sigue en Railway pero la BD pasa a Neon:

1. En el servicio **backend** de Railway, quita el Postgres de Railway si ya no lo usáis.
2. Añade las mismas variables `SPRING_DATASOURCE_URL`, `USERNAME`, `PASSWORD` (URL con **pooler** y `sslmode=require`).
3. Redespliega el backend.

La PWA sigue usando `NEXT_PUBLIC_API_URL` hacia Railway; solo cambia dónde vive PostgreSQL.

## 8) Buenas prácticas en equipo

- **Una BD compartida de desarrollo** evita “en mi máquina sí hay usuarios”.
- `spring.jpa.hibernate.ddl-auto=update` altera el esquema al arrancar; coordinad cambios de entidades.
- No commitear `.env`, dumps (`gopoli.dump`) ni contraseñas.
- Rotar la contraseña Neon si se filtra; actualizar variables en Railway y en el `.env` de cada uno.

## Alternativa: Postgres en Docker (solo local)

Si prefieres una BD en tu máquina sin Neon, usa `docker compose up -d` y apunta Spring a `gopoli`/`gopoli` en `localhost:5432`. Detalle completo: **`backend/DOCKER_DB.md`**. Neon no se reemplaza: solo cambias las variables `SPRING_DATASOURCE_*`.

## Referencias en el repo

- Config Spring: `backend/src/main/resources/application.properties`
- Seeds de coordenadas: `UbicacionCoordenadasSeeder` + `backend/scripts/seed_ubicaciones_metro_poli.sql`
- Postgres Docker local: `backend/DOCKER_DB.md`, `docker-compose.yml`
- Deploy API: `DEPLOY_RAILWAY.md`
