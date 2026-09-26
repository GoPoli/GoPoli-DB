FROM postgres:18-alpine

ENV POSTGRES_DB=gopoli \
    POSTGRES_USER=gopoli \
    PGDATA=/var/lib/postgresql/data/pgdata \
    GOPOLI_SEED_DEMO=false

RUN install -d -m 755 /usr/local/share/gopoli

COPY --chmod=644 init/*.sql /docker-entrypoint-initdb.d/
COPY --chmod=755 init/*.sh /docker-entrypoint-initdb.d/
COPY --chmod=644 demo/demo_data.sql /usr/local/share/gopoli/demo_data.sql

USER 70:70

EXPOSE 5432

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=5 \
    CMD pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1
