-- Vols
INSERT INTO flight (id_flight, departure_city, departure_airport, arrival_city, arrival_airport, date, departure_time, arrival_time, company, price) VALUES
(1, 'Paris',     'Charles de Gaulle', 'Rabat',      'Rabat-Sale',          '2026-11-10 00:00:00', '08:30:00', '11:45:00', 'Royal Air Maroc', 150.00),
(2, 'Paris',     'Orly',              'Casablanca', 'Mohammed V',          '2026-11-11 00:00:00', '14:00:00', '17:20:00', 'Air France',      170.00),
(3, 'Lyon',      'Saint-Exupery',     'Marrakech',  'Menara',              '2026-11-12 00:00:00', '09:15:00', '12:30:00', 'Transavia',       190.00),
(4, 'Madrid',    'Barajas',           'Rabat',      'Rabat-Sale',          '2026-11-14 00:00:00', '16:45:00', '18:10:00', 'Royal Air Maroc', 120.00),
(5, 'Casablanca','Mohammed V',        'Paris',      'Charles de Gaulle',   '2026-11-15 00:00:00', '06:50:00', '10:55:00', 'Air France',      185.00);

-- Passagers
INSERT INTO passenger (id_passenger, first_name, family_name, age, gender, passport) VALUES
(1, 'Sara',  'Benali',  28, 'F', 'P1234567'),
(2, 'Youssef','Alaoui', 35, 'M', 'P7654321'),
(3, 'Lina',  'Martin',  22, 'F', 'P1122334');

-- Un enregistrement de sieges par vol (id_flight est unique)
INSERT INTO seats (id, id_flight) VALUES
(1, 1), (2, 2), (3, 3), (4, 4), (5, 5);

-- Reservations
INSERT INTO reservation (seat, id_flight, id_passenger) VALUES
('a1', 1, 1),
('a2', 1, 2),
('b3', 2, 3);