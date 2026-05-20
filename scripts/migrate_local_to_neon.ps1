# Migra la BD local "gopoli" (PostgreSQL) a Neon.
# Uso:
#   1. En Neon: Connection details -> copia la URL "Direct" (postgres://...)
#   2. PowerShell:
#        $env:PGPASSWORD = "TU_PASSWORD_LOCAL_POSTGRES"
#        $env:NEON_DATABASE_URL = "postgresql://usuario:password@ep-xxx.region.aws.neon.tech/neondb?sslmode=require"
#        .\backend\scripts\migrate_local_to_neon.ps1
#
# Opcional: solo exportar o solo importar
#   .\migrate_local_to_neon.ps1 -ExportOnly
#   .\migrate_local_to_neon.ps1 -ImportOnly

param(
    [string]$LocalHost = "localhost",
    [string]$LocalUser = "postgres",
    [string]$LocalDb = "gopoli",
    [string]$DumpFile = "",
    [switch]$ExportOnly,
    [switch]$ImportOnly,
    [switch]$CleanNeonFirst
)

$ErrorActionPreference = "Stop"
$PgBin = "C:\Program Files\PostgreSQL\18\bin"
if (-not (Test-Path "$PgBin\pg_dump.exe")) {
    $PgBin = "C:\Program Files\PostgreSQL\17\bin"
}
if (-not (Test-Path "$PgBin\pg_dump.exe")) {
    throw "No se encontro pg_dump. Instala PostgreSQL o ajusta `$PgBin en el script."
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
if (-not $DumpFile) {
    $DumpFile = Join-Path $RepoRoot "gopoli.dump"
}

function Export-Local {
    if (-not $env:PGPASSWORD) {
        $sec = Read-Host "Password PostgreSQL local (usuario $LocalUser)" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    }
    Write-Host "Exportando $LocalDb -> $DumpFile ..."
    & "$PgBin\pg_dump.exe" -h $LocalHost -U $LocalUser -d $LocalDb -F c --no-owner --no-acl -f $DumpFile
    $size = (Get-Item $DumpFile).Length
    Write-Host "OK. Dump: $DumpFile ($size bytes)"
}

function Import-Neon {
    if (-not $env:NEON_DATABASE_URL) {
        throw "Define NEON_DATABASE_URL con la URL Direct de Neon (postgres://...?sslmode=require)"
    }
    if ($env:NEON_DATABASE_URL -match "pooler") {
        Write-Warning "Usa la conexion DIRECT de Neon para pg_restore, no la pooled (-pooler)."
    }
    if (-not (Test-Path $DumpFile)) {
        throw "No existe el dump: $DumpFile. Ejecuta sin -ImportOnly primero."
    }
    $args = @(
        "--verbose",
        "--no-owner",
        "--no-privileges",
        "-d", $env:NEON_DATABASE_URL,
        $DumpFile
    )
    if ($CleanNeonFirst) {
        $args = @("--clean", "--if-exists") + $args
    }
    Write-Host "Importando a Neon..."
    & "$PgBin\pg_restore.exe" @args
    Write-Host "Importacion terminada. Revisa arriba si hubo errores (objetos duplicados son comunes si ya existian tablas)."
}

if (-not $ImportOnly) { Export-Local }
if (-not $ExportOnly) { Import-Neon }

Write-Host @"

Siguiente:
  - Neon SQL Editor o pgAdmin: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
  - Backend: variables SPRING_DATASOURCE_* (ver DATABASE_NEON.md)

"@
