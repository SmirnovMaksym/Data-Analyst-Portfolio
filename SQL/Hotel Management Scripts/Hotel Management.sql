-- Add a new clients
INSERT INTO clients (first_name, last_name, passport, address, comment)
VALUES ('Jennifer', 'Lawrence', 'XX123456', 'Los Angeles', NULL);

-- Current clients
SELECT r.room_id, c.first_name, c.last_name FROM rooms r
JOIN clients c ON c.client_id = r.current_client
ORDER BY room_id ASC;

-- Current regular clients and new price
SELECT 
    c.client_id, 
    c.first_name, 
    c.last_name, 
    rc.discount AS 'discount(%)', 
    r.price AS old_price,
    ROUND(price/100*(100-rc.discount), 0) AS new_price
FROM clients c
JOIN regular_clients rc ON rc.client_id = c.client_id
JOIN rooms r ON r.current_client = c.client_id
ORDER BY price DESC;

-- Search for available rooms within a price range
SELECT * FROM rooms
WHERE price BETWEEN 2700 AND 3100 
AND current_client IS NULL;

-- All available rooms
SELECT * FROM rooms 
WHERE current_client IS NULL;

-- All occupied rooms
SELECT * FROM rooms 
WHERE current_client IS NOT NULL;

-- Minimum and maximum price for each capacity (>1) and each comfort type (>1)
SELECT capacity, comfort_id, COUNT(room_id), MAX(price), MIN(price) FROM rooms
GROUP BY capacity, comfort_id
HAVING capacity > 1 AND comfort_id > 1
ORDER BY comfort_id DESC, capacity DESC;

-- Rooms vacated in the first 9 days of 2024
SELECT * FROM attendance_log
WHERE date_of_exit LIKE '2024-01-0%';

-- Calculate the amount current clients have to pay
SELECT 
    r.room_id,
    c.first_name,
    c.last_name,
    al.date_of_entry,
    DATEDIFF(CURRENT_DATE(), al.date_of_entry) AS days_count,
    r.price,
    r.price * DATEDIFF(CURRENT_DATE(), al.date_of_entry) AS to_pay
FROM attendance_log al
JOIN rooms r ON r.room_id = al.room_id
JOIN clients c ON c.client_id = r.current_client
WHERE date_of_exit IS NULL
ORDER BY price;

-- Description of room cost depending on price
SELECT
    room_id,
    capacity,
    comfort_id,
    price,
    CASE
        WHEN price < 2500 THEN 'cheap'
        WHEN price > 3500 THEN 'expensive'
        ELSE 'normal'
    END AS price_category
FROM rooms;

-- Select all people from the hotel
(SELECT c.first_name, c.last_name, r.room_id AS place
FROM clients c
JOIN rooms r ON r.current_client = c.client_id)
UNION
SELECT first_name, last_name, position 
FROM staff;

-- Check the existence of a row satisfying the condition
SELECT *
FROM rooms
WHERE price < 2000;

-- Check if a client is a regular client
SELECT
    first_name,
    last_name,
    CASE
        WHEN client_id IN 
        (SELECT client_id FROM regular_clients) 
        THEN COALESCE(
			(SELECT discount 
            FROM regular_clients 
            WHERE regular_clients.client_id = clients.client_id), 'not regular')
        ELSE 'not regular'
    END AS discount
FROM clients;

-- View representing the amount current clients have to pay
CREATE VIEW current_clients_payment AS
SELECT 
    r.room_id,
    c.first_name,
    c.last_name,
    al.date_of_entry,
    DATEDIFF(CURRENT_DATE(), al.date_of_entry) AS days_count,
    r.price,
    r.price * DATEDIFF(CURRENT_DATE(), al.date_of_entry) AS to_pay
FROM attendance_log al
JOIN rooms r ON r.room_id = al.room_id
JOIN clients c ON c.client_id = r.current_client
WHERE date_of_exit IS NULL
ORDER BY price;
SELECT * FROM hotel.current_clients_payment;

-- Procedure with current regular clients and new prices
DELIMITER //
CREATE PROCEDURE calculate_client_prices()
BEGIN
    SELECT 
        c.client_id, 
        c.first_name, 
        c.last_name, 
        rc.discount AS 'discount(%)', 
        r.price AS old_price,
        ROUND(price/100*(100-rc.discount), 0) AS new_price
    FROM clients c
    JOIN regular_clients rc ON rc.client_id = c.client_id
    JOIN rooms r ON r.current_client = c.client_id
    ORDER BY price DESC;
END //
DELIMITER ;

CALL calculate_client_prices();

-- Trigger for updating the exit date
DELIMITER //
CREATE TRIGGER update_exit_date
AFTER UPDATE ON rooms
FOR EACH ROW
BEGIN
    IF NEW.current_client IS NULL AND OLD.current_client IS NOT NULL THEN
        UPDATE attendance_log
        SET date_of_exit = CURRENT_DATE
        WHERE room_id = NEW.room_id AND date_of_exit IS NULL;
    END IF;
END;
//
DELIMITER ;
update rooms set current_client = null where room_id = 16;

-- View presenting statistics on rooms
CREATE VIEW room_stats AS
SELECT
    COUNT(*) AS roomCount,
    MAX(price) AS maxPrice,
    MIN(price) AS minPrice,
    round(AVG(price), 2) AS avgPrice
FROM rooms;

SELECT * FROM room_stats;

-- View with all clients and rooms information
CREATE VIEW client_rooms_info AS
SELECT 
	c.client_id, c.first_name, c.last_name,
    r.room_id, r.capacity, r.price
FROM clients c
LEFT JOIN rooms r ON c.client_id = r.current_client;
SELECT * FROM client_rooms_info;

-- Procedure for calculating the average room price for each comfort type
DELIMITER //
CREATE PROCEDURE calculate_average_price_by_comfort_type(
    IN start_date DATE,
    IN end_date DATE
)
BEGIN
    CREATE TEMPORARY TABLE temp_result (
        comfort_type VARCHAR(50),
        average_price DECIMAL(10, 2)
    );
    INSERT INTO temp_result
    SELECT
        ct.name AS comfort_type,
        AVG(r.price) AS average_price
    FROM
        rooms r
    JOIN comfort_types ct ON r.comfort_id = ct.comfort_id
    JOIN attendance_log al ON r.room_id = al.room_id
    WHERE
        al.date_of_entry BETWEEN start_date AND end_date
    GROUP BY
        ct.name;
    SELECT * FROM temp_result;
    DROP TEMPORARY TABLE IF EXISTS temp_result;
END //
DELIMITER ;
CALL calculate_average_price_by_comfort_type('2023-01-01', '2023-12-31');




