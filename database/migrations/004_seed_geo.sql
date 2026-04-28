-- 004_seed_geo.sql — Add demo coordinates to existing professionals so geo-search works out of the box

-- Sarah Miller (pro1@demo.com) — Hyderabad
UPDATE professionals SET latitude = 17.3850, longitude = 78.4867, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro1@demo.com');

-- Mike Chen (pro2@demo.com) — 12 km away
UPDATE professionals SET latitude = 17.4400, longitude = 78.3900, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro2@demo.com');

-- Emily Davis (pro3@demo.com) — 25 km away
UPDATE professionals SET latitude = 17.5600, longitude = 78.5300, availability_status = 'busy'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro3@demo.com');

-- David Wilson (pro4@demo.com) — 40 km away
UPDATE professionals SET latitude = 17.7000, longitude = 78.6500, availability_status = 'offline'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro4@demo.com');

-- Jessica Brown (pro5@demo.com) — 8 km away
UPDATE professionals SET latitude = 17.3650, longitude = 78.5400, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro5@demo.com');

-- pro6 through pro10 if they exist — scatter in ring
UPDATE professionals SET latitude = 17.4100, longitude = 78.4200, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro6@demo.com');

UPDATE professionals SET latitude = 17.3400, longitude = 78.5600, availability_status = 'busy'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro7@demo.com');

UPDATE professionals SET latitude = 17.4800, longitude = 78.4100, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro8@demo.com');

UPDATE professionals SET latitude = 17.3100, longitude = 78.5100, availability_status = 'available'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro9@demo.com');

UPDATE professionals SET latitude = 17.4500, longitude = 78.5500, availability_status = 'offline'
WHERE user_id = (SELECT id FROM users WHERE email = 'pro10@demo.com');
