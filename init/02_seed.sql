-- Datos mínimos para desarrollo local (NO es un dump de Neon/producción).
-- Solo se ejecuta en el primer arranque del volumen Docker.

-- Carreras (como en el catálogo compartido del equipo)
INSERT INTO carrera (id_carrera, nombrecarrera) VALUES
    (1, 'Ingeniería Informatica'),
    (2, 'Ingeniería Civil'),
    (3, 'Audio Visual')
ON CONFLICT (id_carrera) DO NOTHING;

SELECT setval(pg_get_serial_sequence('carrera', 'id_carrera'), (SELECT MAX(id_carrera) FROM carrera));

-- Tipos de usuario (GoPoliConstants: 1 pasajero, 2 conductor)
INSERT INTO tipo_usuario (id_tipousuario, nombre_tipousuario) VALUES
    (1, 'Pasajero'),
    (2, 'Conductor')
ON CONFLICT (id_tipousuario) DO NOTHING;

-- Estados de usuario (UsuarioEstado: ACTIVO=2, INHABILITADO=3)
INSERT INTO estado_usuario (id_estado, nombre_estado) VALUES
    (1, 'Pendiente'),
    (2, 'Activo'),
    (3, 'Inhabilitado')
ON CONFLICT (id_estado) DO NOTHING;

-- Tipos de servicio (GoPoliConstants: 1 grupo pasajero, 3 grupo conductor)
INSERT INTO tipo_servicio (id_tiposervicio, nombre_tiposervicio) VALUES
    (1, 'Viaje Compartido'),
    (2, 'Otro'),
    (3, 'Viaje Conductor')
ON CONFLICT (id_tiposervicio) DO NOTHING;

-- Estados de servicio (GoPoliConstants)
INSERT INTO estado_servicio (id_estadoservicio, nombre_estadoservicio) VALUES
    (1, 'Activo'),
    (2, 'Cancelado'),
    (3, 'Finalizado'),
    (4, 'En curso')
ON CONFLICT (id_estadoservicio) DO NOTHING;

-- Tipos de vehículo (referencia para id_tipovehiculo)
INSERT INTO tipo_vehiculo (id_tipovehiculo, nombre_tipovehiculo) VALUES
    (1, 'Carro'),
    (2, 'Moto')
ON CONFLICT (id_tipovehiculo) DO NOTHING;

-- Ubicaciones campus + metro (mismas coordenadas que UbicacionCoordenadasSeeder)
INSERT INTO ubicacion (nombre_ubicacion, latitud, longitud) VALUES
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

-- Usuario demo SOLO para desarrollo local (AuthController compara contraseña en texto plano).
-- Correo: demo.local@elpoli.edu.co
-- Contraseña: gopoli-local-dev
INSERT INTO usuario (
    correo, contrasena, nombre, tel,
    id_carrera, id_estado, id_tipousuario, nota
) VALUES (
    'demo.local@elpoli.edu.co',
    'gopoli-local-dev',
    'Demo Local GoPoli',
    '3000000000',
    1,
    2,
    1,
    0.0
);
