-- Esquema de GoPoli: catálogos, usuarios, viajes, mensajes y agenda.

-- Las fechas y horas se guardan en hora de Colombia, igual que las escribe la API.
DO $$
BEGIN
    EXECUTE format('ALTER DATABASE %I SET timezone TO %L', current_database(), 'America/Bogota');
END
$$;

CREATE TABLE programs (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE user_types (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE user_statuses (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE trip_types (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE trip_statuses (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE vehicle_types (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE locations (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(150) NOT NULL UNIQUE,
    latitude    DOUBLE PRECISION CHECK (latitude BETWEEN -90 AND 90),
    longitude   DOUBLE PRECISION CHECK (longitude BETWEEN -180 AND 180)
);

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) NOT NULL,
    password        VARCHAR(255) NOT NULL,
    name            VARCHAR(120) NOT NULL,
    phone           VARCHAR(20),
    program_id      INTEGER REFERENCES programs (id) ON DELETE SET NULL,
    status_id       INTEGER NOT NULL DEFAULT 2 REFERENCES user_statuses (id),
    user_type_id    INTEGER NOT NULL DEFAULT 1 REFERENCES user_types (id),
    rating          DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (rating BETWEEN 0 AND 5),
    profile_photo   TEXT,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX ux_users_email ON users (upper(email));

CREATE TABLE vehicles (
    id              SERIAL PRIMARY KEY,
    user_id         INTEGER NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
    brand           VARCHAR(60) NOT NULL,
    model           VARCHAR(60) NOT NULL,
    plate           VARCHAR(20) NOT NULL UNIQUE,
    color           VARCHAR(30) NOT NULL,
    capacity        INTEGER NOT NULL DEFAULT 4 CHECK (capacity BETWEEN 1 AND 8),
    vehicle_type_id INTEGER REFERENCES vehicle_types (id)
);

CREATE TABLE trips (
    id                      SERIAL PRIMARY KEY,
    departure_date          DATE NOT NULL,
    description             VARCHAR(500),
    departure_location_id   INTEGER NOT NULL REFERENCES locations (id),
    arrival_location_id     INTEGER NOT NULL REFERENCES locations (id),
    departure_time          TIME NOT NULL,
    creator_id              INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    trip_type_id            INTEGER NOT NULL REFERENCES trip_types (id),
    status_id               INTEGER NOT NULL REFERENCES trip_statuses (id),
    capacity                INTEGER NOT NULL CHECK (capacity BETWEEN 2 AND 4),
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (departure_location_id <> arrival_location_id)
);

CREATE INDEX ix_trips_status ON trips (status_id);
CREATE INDEX ix_trips_creator_status ON trips (creator_id, status_id);

CREATE TABLE trip_members (
    trip_id             INTEGER NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id             INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    group_role          VARCHAR(20) NOT NULL CHECK (group_role IN ('creator', 'member')),
    participation_role  VARCHAR(20) NOT NULL CHECK (participation_role IN ('passenger', 'driver')),
    joined_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (trip_id, user_id)
);

CREATE INDEX ix_trip_members_user ON trip_members (user_id);

CREATE TABLE recurring_routes (
    id                      SERIAL PRIMARY KEY,
    user_id                 INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    departure_location_id   INTEGER NOT NULL REFERENCES locations (id),
    arrival_location_id     INTEGER NOT NULL REFERENCES locations (id),
    weekdays                VARCHAR(32) NOT NULL CHECK (weekdays ~ '^[1-7](,[1-7])*$'),
    departure_time          TIME NOT NULL,
    capacity                INTEGER NOT NULL CHECK (capacity BETWEEN 2 AND 4),
    trip_type_id            INTEGER NOT NULL DEFAULT 1 REFERENCES trip_types (id),
    description             VARCHAR(500),
    CHECK (departure_location_id <> arrival_location_id)
);

CREATE INDEX ix_recurring_routes_user ON recurring_routes (user_id);

CREATE TABLE messages (
    id          SERIAL PRIMARY KEY,
    trip_id     INTEGER NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
    user_id     INTEGER NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    content     VARCHAR(1000) NOT NULL CHECK (length(btrim(content)) > 0),
    sent_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ix_messages_trip_sent ON messages (trip_id, sent_at);
