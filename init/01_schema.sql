-- Esquema alineado con entidades JPA de GoPoli (ddl-auto=update también puede
-- completar columnas al arrancar Spring; este script deja la BD usable al instante).

CREATE TABLE IF NOT EXISTS carrera (
    id_carrera      SERIAL PRIMARY KEY,
    nombrecarrera   VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS tipo_usuario (
    id_tipousuario      INTEGER PRIMARY KEY,
    nombre_tipousuario  VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS estado_usuario (
    id_estado       INTEGER PRIMARY KEY,
    nombre_estado   VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS tipo_servicio (
    id_tiposervicio     INTEGER PRIMARY KEY,
    nombre_tiposervicio VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS estado_servicio (
    id_estadoservicio     INTEGER PRIMARY KEY,
    nombre_estadoservicio VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS tipo_vehiculo (
    id_tipovehiculo     INTEGER PRIMARY KEY,
    nombre_tipovehiculo VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS ubicacion (
    id_ubicacion        SERIAL PRIMARY KEY,
    nombre_ubicacion    VARCHAR(255),
    latitud             DOUBLE PRECISION,
    longitud            DOUBLE PRECISION
);

CREATE TABLE IF NOT EXISTS usuario (
    id_usuario      SERIAL PRIMARY KEY,
    correo          VARCHAR(255),
    contrasena      VARCHAR(255),
    nombre          VARCHAR(255),
    tel             VARCHAR(255),
    id_carrera      INTEGER,
    id_estado       INTEGER,
    id_tipousuario  INTEGER,
    nota            DOUBLE PRECISION,
    foto_perfil     TEXT
);

CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo     SERIAL PRIMARY KEY,
    id_usuario      INTEGER,
    marca           VARCHAR(60),
    modelo          VARCHAR(60),
    matricula       VARCHAR(20),
    color           VARCHAR(30),
    capacidad       INTEGER,
    id_tipovehiculo INTEGER
);

CREATE TABLE IF NOT EXISTS servicio (
    id_servicio         SERIAL PRIMARY KEY,
    fecha               DATE,
    descripcion         VARCHAR(255),
    id_lugarsalida      INTEGER,
    id_lugarllegada     INTEGER,
    hora_salida         TIME,
    id_creador          INTEGER,
    id_tiposervicio     INTEGER,
    id_estadoservicio   INTEGER,
    capacidad           INTEGER
);

CREATE TABLE IF NOT EXISTS servicio_usuario (
    id_servicio         INTEGER NOT NULL,
    id_usuario          INTEGER NOT NULL,
    rol                 VARCHAR(255),
    rol_participacion   VARCHAR(255),
    PRIMARY KEY (id_servicio, id_usuario)
);

-- Rutas habituales (Agenda): plantillas para publicar el servicio del día.
CREATE TABLE IF NOT EXISTS ruta_habitual (
    id_ruta             SERIAL PRIMARY KEY,
    id_usuario          INTEGER NOT NULL,
    id_lugar_salida     INTEGER NOT NULL,
    id_lugar_llegada    INTEGER NOT NULL,
    dias_semana         VARCHAR(32) NOT NULL,
    hora_salida         TIME NOT NULL,
    capacidad           INTEGER NOT NULL,
    id_tipo_servicio    INTEGER,
    descripcion         VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS mensaje (
    id_mensaje      SERIAL PRIMARY KEY,
    id_servicio     INTEGER NOT NULL,
    id_usuario      INTEGER NOT NULL,
    texto           VARCHAR(1000) NOT NULL,
    fecha_envio     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
