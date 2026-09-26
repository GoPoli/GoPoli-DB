# Base de datos GoPoli en Neon (PostgreSQL compartido)

Neon es PostgreSQL en la nube. Con **un solo proyecto y una rama `main`**, todo el equipo apunta a la misma base (usuarios, ubicaciones, viajes, etc.).

## 1. Crear el proyecto en Neon

1. Entra en [https://neon.tech](https://neon.tech) e inicia sesión (GitHub sirve).
2. **New Project** → nombre sugerido: `gopoli`.
3. Región: la más cercana al equipo (por ejemplo `US East`, la de menor latencia desde Colombia).
4. En el dashboard, abre **Connection details** y copia:
   - **Host** (ej. `ep-xxxx.us-east-2.aws.neon.tech`)
   - **Database** (suele ser `neondb` o la que elijas)
   - **User** / **Password**
   - **SSL** activo (obligatorio en Neon).

Neon ofrece dos URLs:

| Tipo | Cuándo usarla |
| --- | --- |
| **Pooled** (`…-pooler.…`) | API Spring Boot y varios compañeros conectados a la vez (recomendado). |
| **Direct** | `pg_dump` / `pg_restore` / pgAdmin para migración o administración. |

## 2. Variables para la API

[GoPoli-API](https://github.com/GoPoli/GoPoli-API) lee estas variables de entorno:

| Variable | Ejemplo (ajusta con tu host Neon) |
| --- | --- |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://ep-xxxx-pooler.us-east-2.aws.neon.tech/neondb?sslmode=require` |
| `SPRING_DATASOURCE_USERNAME` | `neondb_owner` |
| `SPRING_DATASOURCE_PASSWORD` | *(contraseña del dashboard Neon)* |

> [!IMPORTANT]
> La URL JDBC debe llevar `?sslmode=require`. Sin eso, la conexión a Neon falla.

Convierte la URL `postgres://` del panel Neon a JDBC así:

```text
postgres://USER:PASS@HOST/DB?sslmode=require
        ↓
jdbc:postgresql://HOST/DB?sslmode=require
```

Usuario y contraseña van en sus variables, no en la URL JDBC.

### Plantilla local (no subir a git)

En GoPoli-API copia `.env.example` → `.env` y rellena los valores. Ese archivo está en `.gitignore`.

Comparte usuario, contraseña y URL con el equipo por un canal seguro (1Password, Bitwarden, un canal privado del proyecto), **nunca** en un repositorio.

## 3. Crear el esquema en Neon

Una base nueva de Neon está vacía. Se construye con los mismos scripts de este repositorio, usando la URL **Direct**:

```bash
export NEON_DATABASE_URL="postgresql://USUARIO:PASS@ep-XXXX.region.aws.neon.tech/neondb?sslmode=require"
psql "$NEON_DATABASE_URL" -v ON_ERROR_STOP=1 -f init/01_schema.sql
psql "$NEON_DATABASE_URL" -v ON_ERROR_STOP=1 -f init/02_catalogs.sql
```

Para una base de pruebas compartida puedes cargar también los datos de demostración:

```bash
psql "$NEON_DATABASE_URL" -v ON_ERROR_STOP=1 -f demo/demo_data.sql
```

> [!WARNING]
> No cargues `demo/demo_data.sql` en una base productiva: crea cuentas con una contraseña pública.

La API nunca crea ni altera tablas (`SPRING_JPA_HIBERNATE_DDL_AUTO=validate`): si el esquema no existe o no coincide con las entidades, la API se detiene al arrancar.

## 4. Copiar una base local a Neon

Para llevar a Neon los datos de una base local existente hay **dos formas**: script automático (recomendado) o pgAdmin.

### Opción A — Script (exporta todo el esquema y los datos)

1. En Neon → **Dashboard** → **Connect** → pestaña **Direct** (no Pooled).
2. Copia la connection string; debe verse así:

   `postgresql://neondb_owner:XXXXXXXX@ep-nombre-12345678.us-east-2.aws.neon.tech/neondb?sslmode=require`

3. PowerShell en la raíz de este repositorio:

```powershell
$env:PGPASSWORD = "TU_PASSWORD_LOCAL"
$env:NEON_DATABASE_URL = "postgresql://USUARIO:PASS@ep-XXXX.region.aws.neon.tech/neondb?sslmode=require"

.\scripts\migrate_local_to_neon.ps1 -CleanNeonFirst
```

`-CleanNeonFirst` borra en Neon lo que ya exista y vuelve a crear las tablas desde el volcado.

Solo exportar:

```powershell
.\scripts\migrate_local_to_neon.ps1 -ExportOnly
```

Solo importar un `gopoli.dump` existente:

```powershell
$env:NEON_DATABASE_URL = "postgresql://..."
.\scripts\migrate_local_to_neon.ps1 -ImportOnly -CleanNeonFirst
```

Parámetros útiles del script: `-LocalHost`, `-LocalUser`, `-LocalDb` y `-DumpFile`. Si la base local es el contenedor de este repositorio, usa `-LocalUser gopoli`. En Windows, si `pg_dump` no está en el PATH, el script busca `C:\Program Files\PostgreSQL\18\bin\` y luego la versión 17.

> [!CAUTION]
> El archivo `gopoli.dump` contiene datos reales de usuarios. Está en `.gitignore`: nunca lo subas a un repositorio y bórralo al terminar la migración.

### Opción B — pgAdmin (sin terminal)

**Paso 1 — Backup local**

1. pgAdmin → servidor local → base de datos **`gopoli`** → clic derecho → **Backup…**
2. Filename: una ruta fuera de cualquier repositorio, por ejemplo `Documentos/gopoli.backup`.
3. Format: **Custom** (el mismo formato que usa el script).
4. Pestaña **Data**: esquema y datos (opción por defecto).
5. **Backup**.

**Paso 2 — Registrar Neon en pgAdmin**

1. **Register** → **Server** → nombre `Neon GoPoli`.
2. **Connection**: host y base de datos de Neon (Direct), usuario, contraseña, puerto `5432`.
3. **SSL** → SSL mode: **Require** → Save.

**Paso 3 — Restore en Neon**

1. Clic derecho en la base de datos de Neon (ej. `neondb`) → **Restore…**
2. Filename: el `.backup` generado.
3. Marca **Clean before restore** si ya había tablas en Neon.
4. **Restore**.

### Comandos manuales (equivalentes al script)

Exportar (local):

```bash
pg_dump -h localhost -U gopoli -d gopoli -F c --no-owner --no-acl -f gopoli.dump
```

Importar (Neon, URL **Direct**):

```bash
pg_restore --clean --if-exists --verbose --no-owner --no-privileges \
  -d "postgresql://USUARIO:PASS@ep-XXXX.region.aws.neon.tech/neondb?sslmode=require" gopoli.dump
```

### Verificar que llegaron todas las tablas

En el **SQL Editor** de Neon o en pgAdmin:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 1;

SELECT COUNT(*) AS users FROM users;
SELECT COUNT(*) AS locations FROM locations;
```

Deberías ver las mismas 13 tablas que en local (`users`, `locations`, `trips`, `programs`, etc.) y los mismos conteos.

## 5. Arrancar la API contra Neon

```powershell
$env:SPRING_DATASOURCE_URL="jdbc:postgresql://TU-HOST-POOLER/neondb?sslmode=require"
$env:SPRING_DATASOURCE_USERNAME="TU_USUARIO"
$env:SPRING_DATASOURCE_PASSWORD="TU_CONTRASEÑA"
.\mvnw.cmd spring-boot:run
```

Con Docker:

```bash
docker run -d -p 8080:8080 --env-file .env ghcr.io/gopoli/gopoli-api:latest
```

Prueba: `GET http://localhost:8080/health` y `GET http://localhost:8080/locations`.

En IntelliJ o VS Code define las mismas tres variables en la configuración de ejecución de `GoPoliApplication`.

## 6. pgAdmin con Neon (opcional)

1. Register → Server.
2. **Connection** → host **Direct** de Neon, puerto `5432`, base de datos, usuario y contraseña.
3. Pestaña **SSL** → SSL mode: `require`.

## 7. Checklist para el equipo

1. Clonar [GoPoli-API](https://github.com/GoPoli/GoPoli-API).
2. Recibir las tres variables `SPRING_DATASOURCE_*` por un canal seguro.
3. Copiar `.env.example` → `.env` en la API y pegar los valores.
4. Arrancar la API (variables de entorno, `--env-file` o IDE).
5. Apuntar la PWA a esa API en `.env.local` de [GoPoli-Web](https://github.com/GoPoli/GoPoli-Web):

   ```env
   NEXT_PUBLIC_API_URL=http://IP_DE_LA_API:8080
   ```

Todos leen y escriben la **misma** base en Neon; los usuarios que se creen son visibles para todos.

## 8. API en Railway + base en Neon

1. En el servicio de la API en Railway, quita el PostgreSQL de Railway si ya no se usa.
2. Agrega `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME` y `SPRING_DATASOURCE_PASSWORD` (URL con **pooler** y `sslmode=require`).
3. Redespliega la API.

La PWA sigue usando `NEXT_PUBLIC_API_URL` hacia Railway; solo cambia dónde vive PostgreSQL. Guía de Railway en [GoPoli-API](https://github.com/GoPoli/GoPoli-API/blob/main/docs/DEPLOY_RAILWAY.md).

## 9. Buenas prácticas

- **Una base compartida de desarrollo** evita el clásico “en mi máquina sí hay usuarios”.
- El esquema vive en este repositorio: cualquier cambio de modelo se hace en `init/01_schema.sql` y se aplica en Neon antes de desplegar la API.
- No versionar `.env`, volcados (`*.dump`, `*.backup`) ni contraseñas.
- Rotar la contraseña de Neon si se filtra y actualizarla en Railway y en el `.env` de cada integrante.

## Alternativa: PostgreSQL en Docker

Para una base en tu máquina sin Neon, sigue [DOCKER_DB.md](DOCKER_DB.md).
