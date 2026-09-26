FROM postgres:16-alpine

ENV POSTGRES_DB=gopoli
ENV POSTGRES_USER=gopoli

COPY init/ /docker-entrypoint-initdb.d/

EXPOSE 5432

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=5 \
  CMD pg_isready -h 127.0.0.1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" || exit 1
