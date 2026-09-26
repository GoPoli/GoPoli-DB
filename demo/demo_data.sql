-- Datos de demostración para desarrollo y pruebas. Contraseña de todas las cuentas: gopoli-local-dev

SET TIME ZONE 'America/Bogota';

INSERT INTO users (email, password, name, phone, program_id, status_id, user_type_id, rating) VALUES
    ('demo.local@elpoli.edu.co', '$2a$10$GTIOr2ujHlEe6XhKM9BTDOGcWs6T2LIWuAZ4a6sw4eqWmlNnlJSPi',
        'Laura Gómez', '3001234567', 1, 2, 1, 4.6),
    ('conductor.demo@elpoli.edu.co', '$2a$10$tyHcHPSSsAo.uLahzSJZHeWqfCCMGXlSeFw169jo1lUfLz7.IKaH2',
        'Andrés Restrepo', '3109876543', 2, 2, 2, 4.8),
    ('pasajera.demo@elpoli.edu.co', '$2a$10$GTIOr2ujHlEe6XhKM9BTDOGcWs6T2LIWuAZ4a6sw4eqWmlNnlJSPi',
        'Valentina Ríos', '3155550123', 3, 2, 1, 4.3);

INSERT INTO vehicles (user_id, brand, model, plate, color, capacity, vehicle_type_id)
SELECT id, 'Mazda', '2 Sedán', 'GPL123', 'Gris', 4, 1
FROM users WHERE email = 'conductor.demo@elpoli.edu.co';

INSERT INTO trips (departure_date, description, departure_location_id, arrival_location_id,
                   departure_time, creator_id, trip_type_id, status_id, capacity)
SELECT CURRENT_DATE + 1, 'Salgo puntual desde la estación, espero máximo 5 minutos.',
       (SELECT id FROM locations WHERE name = 'Estación Poblado'),
       (SELECT id FROM locations WHERE name = 'Salida Principal'),
       TIME '07:00', u.id, 3, 1, 4
FROM users u WHERE u.email = 'conductor.demo@elpoli.edu.co';

INSERT INTO trips (departure_date, description, departure_location_id, arrival_location_id,
                   departure_time, creator_id, trip_type_id, status_id, capacity)
SELECT CURRENT_DATE - 3, 'Regreso después de clases.',
       (SELECT id FROM locations WHERE name = 'Salida Principal'),
       (SELECT id FROM locations WHERE name = 'Estación Envigado'),
       TIME '18:30', u.id, 1, 3, 3
FROM users u WHERE u.email = 'demo.local@elpoli.edu.co';

INSERT INTO trip_members (trip_id, user_id, group_role, participation_role)
SELECT t.id, u.id, m.group_role, m.participation_role
FROM (VALUES
        ('conductor.demo@elpoli.edu.co', 'conductor.demo@elpoli.edu.co', 'creator', 'driver'),
        ('conductor.demo@elpoli.edu.co', 'pasajera.demo@elpoli.edu.co', 'member', 'passenger'),
        ('demo.local@elpoli.edu.co', 'demo.local@elpoli.edu.co', 'creator', 'passenger'),
        ('demo.local@elpoli.edu.co', 'pasajera.demo@elpoli.edu.co', 'member', 'passenger')
     ) AS m (creator_email, member_email, group_role, participation_role)
JOIN users c ON c.email = m.creator_email
JOIN trips t ON t.creator_id = c.id
JOIN users u ON u.email = m.member_email;

INSERT INTO messages (trip_id, user_id, content, sent_at)
SELECT t.id, u.id, m.content, LOCALTIMESTAMP - make_interval(mins => m.minutes_ago)
FROM (VALUES
        ('conductor.demo@elpoli.edu.co', '¡Hola! Nos vemos en la entrada de la estación.', 10),
        ('pasajera.demo@elpoli.edu.co', 'Perfecto, allá estaré a las 6:55.', 4)
     ) AS m (author_email, content, minutes_ago)
JOIN users c ON c.email = 'conductor.demo@elpoli.edu.co'
JOIN trips t ON t.creator_id = c.id
JOIN users u ON u.email = m.author_email
ORDER BY m.minutes_ago DESC;

INSERT INTO recurring_routes (user_id, departure_location_id, arrival_location_id, weekdays,
                              departure_time, capacity, trip_type_id, description)
SELECT u.id,
       (SELECT id FROM locations WHERE name = 'Estación Envigado'),
       (SELECT id FROM locations WHERE name = 'Salida Principal'),
       '1,3,5', TIME '06:30', 3, 1, 'Clases de la mañana'
FROM users u WHERE u.email = 'demo.local@elpoli.edu.co';
