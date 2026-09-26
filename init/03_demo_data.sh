#!/bin/sh
set -e

# Precarga opcional de datos de demostración; solo corre en el primer arranque del volumen.
if [ "${GOPOLI_SEED_DEMO:-false}" = "true" ]; then
    echo "GoPoli: cargando datos de demostración..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
        -f /usr/local/share/gopoli/demo_data.sql
    echo "GoPoli: datos de demostración cargados."
else
    echo "GoPoli: datos de demostración omitidos (GOPOLI_SEED_DEMO=${GOPOLI_SEED_DEMO:-false})."
fi
