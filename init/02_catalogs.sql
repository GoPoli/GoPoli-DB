-- Catálogos y ubicaciones que la aplicación necesita desde el primer arranque.

INSERT INTO programs (id, name) VALUES
    (1, 'Ingeniería Informática'),
    (2, 'Ingeniería Civil'),
    (3, 'Audio Visual')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('programs', 'id'), (SELECT MAX(id) FROM programs));

INSERT INTO user_types (id, name) VALUES
    (1, 'Pasajero'),
    (2, 'Conductor')
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_statuses (id, name) VALUES
    (1, 'Pendiente'),
    (2, 'Activo'),
    (3, 'Inhabilitado')
ON CONFLICT (id) DO NOTHING;

INSERT INTO trip_types (id, name) VALUES
    (1, 'Viaje Compartido'),
    (2, 'Otro'),
    (3, 'Viaje Conductor')
ON CONFLICT (id) DO NOTHING;

INSERT INTO trip_statuses (id, name) VALUES
    (1, 'Activo'),
    (2, 'Cancelado'),
    (3, 'Finalizado'),
    (4, 'En curso')
ON CONFLICT (id) DO NOTHING;

INSERT INTO vehicle_types (id, name) VALUES
    (1, 'Carro'),
    (2, 'Moto')
ON CONFLICT (id) DO NOTHING;

INSERT INTO locations (name, latitude, longitude) VALUES
    ('Salida Principal', 6.1960, -75.5863),
    ('Salida Parqueadero', 6.1945, -75.5872),
    ('Estación Niquía', 6.33764, -75.37808),
    ('Estación Bello', 6.32583, -75.55778),
    ('Estación Madera', 6.31361, -75.55750),
    ('Estación Acevedo', 6.30194, -75.55917),
    ('Estación Tricentenario', 6.29750, -75.55472),
    ('Estación Caribe', 6.28972, -75.55972),
    ('Estación Universidad', 6.26972, -75.56833),
    ('Estación Hospital', 6.26472, -75.56611),
    ('Estación Prado', 6.25778, -75.56444),
    ('Estación Parque Berrío', 6.25194, -75.56583),
    ('Estación San Antonio', 6.25306, -75.56528),
    ('Estación Alpujarra', 6.24667, -75.57222),
    ('Estación Exposiciones', 6.24056, -75.57583),
    ('Estación Industriales', 6.22972, -75.57528),
    ('Estación Poblado', 6.20806, -75.56694),
    ('Estación Aguacatala', 6.19472, -75.58028),
    ('Estación Ayurá', 6.18500, -75.59639),
    ('Estación Envigado', 6.16917, -75.59111),
    ('Estación Itagüí', 6.17167, -75.61028),
    ('Estación Sabaneta', 6.15056, -75.61639),
    ('Estación La Estrella', 6.15639, -75.64278),
    ('Estación Cisneros', 6.28470, -75.55140),
    ('Estación Suramericana', 6.24472, -75.59417),
    ('Estación Estadio', 6.25611, -75.59139),
    ('Estación Floresta', 6.26306, -75.59861),
    ('Estación Santa Lucía', 6.27000, -75.60389),
    ('Estación San Javier', 6.25583, -75.62222);
