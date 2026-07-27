DO $$
DECLARE
    org_ids UUID[] := ARRAY[
        '11111111-1111-1111-1111-111111111111',
        '22222222-2222-2222-2222-222222222222',
        '33333333-3333-3333-3333-333333333333'
    ];
    cities VARCHAR[] := ARRAY['delhi', 'mumbai', 'bangalore', 'chennai', 'hyderabad'];
    statuses VARCHAR[] := ARRAY['confirmed', 'pending', 'cancelled', 'completed'];
    hotel_prefixes VARCHAR[] := ARRAY['HOTEL', 'RESORT', 'INN', 'SUITES', 'PALACE'];
    i INTEGER;
    booking_id UUID;
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO hotel_bookings (
            id, org_id, hotel_id, city, checkin_date, checkout_date, amount, status, created_at
        ) VALUES (
            uuid_generate_v4(),
            org_ids[floor(random() * array_length(org_ids, 1) + 1)],
            hotel_prefixes[floor(random() * array_length(hotel_prefixes, 1) + 1)] || '-' || floor(random() * 1000 + 1)::TEXT,
            cities[floor(random() * array_length(cities, 1) + 1)],
            NOW() - (random() * INTERVAL '90 days'),
            NOW() - (random() * INTERVAL '83 days'),
            round((random() * 500 + 100)::numeric, 2),
            statuses[floor(random() * array_length(statuses, 1) + 1)],
            NOW() - (random() * INTERVAL '90 days')
        ) RETURNING id INTO booking_id;

        IF random() < 0.3 THEN
            INSERT INTO booking_events (booking_id, event_type, payload)
            VALUES (booking_id, 'created', jsonb_build_object('source', 'web', 'timestamp', NOW()));
        END IF;
    END LOOP;
END $$;