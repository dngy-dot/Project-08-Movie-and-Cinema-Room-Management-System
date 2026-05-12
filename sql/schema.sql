-- cinema_db: tên bảng/cột khớp Flask-SQLAlchemy (app.py).
-- Tránh import file cũ tạo paymentorders / voucherusages — Flask tạo thêm payment_orders / voucher_usages → trùng bảng, tab Voucher lỗi.

CREATE DATABASE IF NOT EXISTS cinema_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cinema_db;

SET FOREIGN_KEY_CHECKS = 0;

DROP VIEW IF EXISTS vw_daily_screenings;
DROP VIEW IF EXISTS vw_available_seats;
DROP TRIGGER IF EXISTS trg_validate_ticket;
DROP PROCEDURE IF EXISTS sp_book_ticket;
DROP FUNCTION IF EXISTS fn_occupancy_rate;
DROP FUNCTION IF EXISTS fn_total_revenue;

DROP TABLE IF EXISTS voucher_usages;
DROP TABLE IF EXISTS voucherusages;
DROP TABLE IF EXISTS VoucherUsages;
DROP TABLE IF EXISTS vouchers;
DROP TABLE IF EXISTS Vouchers;
DROP TABLE IF EXISTS invalidated_tickets;
DROP TABLE IF EXISTS invalidatedtickets;
DROP TABLE IF EXISTS InvalidatedTickets;
DROP TABLE IF EXISTS payment_orders;
DROP TABLE IF EXISTS paymentorders;
DROP TABLE IF EXISTS PaymentOrders;
DROP TABLE IF EXISTS tickets;
DROP TABLE IF EXISTS Tickets;
DROP TABLE IF EXISTS screenings;
DROP TABLE IF EXISTS Screenings;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS app_settings;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS cinemarooms;
DROP TABLE IF EXISTS CinemaRooms;
DROP TABLE IF EXISTS cinemas;
DROP TABLE IF EXISTS Cinemas;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS Movies;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE movies (
  MovieID INT AUTO_INCREMENT PRIMARY KEY,
  MovieTitle VARCHAR(255) NOT NULL,
  Genre VARCHAR(100) NOT NULL,
  DurationMinutes INT NOT NULL CHECK (DurationMinutes > 0),
  PosterURL VARCHAR(500) NULL,
  ReleaseStatus VARCHAR(20) NOT NULL DEFAULT 'now_showing'
);

CREATE TABLE cinemas (
  CinemaID INT AUTO_INCREMENT PRIMARY KEY,
  CinemaName VARCHAR(150) NOT NULL UNIQUE,
  Address VARCHAR(255) NULL
);

CREATE TABLE cinemarooms (
  RoomID INT AUTO_INCREMENT PRIMARY KEY,
  CinemaID INT NOT NULL,
  RoomName VARCHAR(100) NOT NULL UNIQUE,
  Capacity INT NOT NULL CHECK (Capacity > 0),
  FOREIGN KEY (CinemaID) REFERENCES cinemas(CinemaID)
);

CREATE TABLE screenings (
  ScreeningID INT AUTO_INCREMENT PRIMARY KEY,
  MovieID INT NOT NULL,
  RoomID INT NOT NULL,
  ScreeningDate DATE NOT NULL,
  ScreeningTime TIME NOT NULL,
  FOREIGN KEY (MovieID) REFERENCES movies(MovieID),
  FOREIGN KEY (RoomID) REFERENCES cinemarooms(RoomID)
);

CREATE TABLE customers (
  CustomerID INT AUTO_INCREMENT PRIMARY KEY,
  CustomerName VARCHAR(150) NOT NULL,
  PhoneNumber VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE members (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  phone VARCHAR(30) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_members_phone (phone)
);

CREATE TABLE app_settings (
  id INT AUTO_INCREMENT PRIMARY KEY,
  `key` VARCHAR(100) NOT NULL UNIQUE,
  value TEXT NULL
);

CREATE TABLE tickets (
  TicketID INT AUTO_INCREMENT PRIMARY KEY,
  CustomerID INT NOT NULL,
  ScreeningID INT NOT NULL,
  SeatNumber VARCHAR(10) NOT NULL,
  BookingCode VARCHAR(12) NOT NULL UNIQUE,
  booked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID),
  FOREIGN KEY (ScreeningID) REFERENCES screenings(ScreeningID),
  CONSTRAINT uq_screening_seat UNIQUE (ScreeningID, SeatNumber)
);

CREATE TABLE payment_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  order_code VARCHAR(16) NOT NULL UNIQUE,
  screening_id INT NOT NULL,
  customer_name VARCHAR(150) NOT NULL,
  customer_phone VARCHAR(30) NOT NULL,
  seat_numbers VARCHAR(300) NOT NULL,
  original_amount INT NOT NULL DEFAULT 0,
  voucher_code VARCHAR(30) NULL,
  discount_percent INT NOT NULL DEFAULT 0,
  discount_amount INT NOT NULL DEFAULT 0,
  total_amount INT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  paid_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (screening_id) REFERENCES screenings(ScreeningID),
  INDEX ix_payment_orders_screening_id (screening_id),
  INDEX ix_payment_orders_status (status),
  INDEX ix_payment_orders_customer_phone (customer_phone)
);

CREATE TABLE vouchers (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(30) NOT NULL UNIQUE,
  discount_percent INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE voucher_usages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  voucher_id INT NOT NULL,
  phone_number VARCHAR(30) NOT NULL,
  order_code VARCHAR(16) NOT NULL UNIQUE,
  used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (voucher_id) REFERENCES vouchers(id) ON DELETE CASCADE,
  UNIQUE KEY uq_voucher_phone (voucher_id, phone_number)
);

CREATE TABLE invalidated_tickets (
  id INT AUTO_INCREMENT PRIMARY KEY,
  customer_name VARCHAR(150) NOT NULL,
  customer_phone VARCHAR(30) NOT NULL,
  booking_code VARCHAR(12) NOT NULL UNIQUE,
  movie_title VARCHAR(255) NOT NULL,
  room_name VARCHAR(100) NOT NULL,
  screening_date DATE NOT NULL,
  screening_time TIME NOT NULL,
  seat_number VARCHAR(10) NOT NULL,
  booked_at DATETIME NOT NULL,
  reason VARCHAR(255) NOT NULL DEFAULT 'Vé không còn khả dụng',
  invalidated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX ix_invalidated_tickets_customer_phone (customer_phone),
  INDEX ix_invalidated_tickets_booking_code (booking_code)
);

CREATE INDEX idx_movies_title ON movies(MovieTitle);
CREATE INDEX idx_screenings_datetime ON screenings(ScreeningDate, ScreeningTime);

DROP VIEW IF EXISTS vw_daily_screenings;
CREATE VIEW vw_daily_screenings AS
SELECT
  s.ScreeningDate,
  s.ScreeningTime,
  ci.CinemaName,
  m.MovieTitle,
  c.RoomName
FROM screenings s
JOIN movies m ON s.MovieID = m.MovieID
JOIN cinemarooms c ON s.RoomID = c.RoomID
JOIN cinemas ci ON c.CinemaID = ci.CinemaID;

DROP VIEW IF EXISTS vw_available_seats;
CREATE VIEW vw_available_seats AS
SELECT
  s.ScreeningID,
  c.RoomName,
  c.Capacity,
  COUNT(t.TicketID) AS SoldSeats,
  (c.Capacity - COUNT(t.TicketID)) AS AvailableSeats
FROM screenings s
JOIN cinemarooms c ON s.RoomID = c.RoomID
LEFT JOIN tickets t ON t.ScreeningID = s.ScreeningID
GROUP BY s.ScreeningID, c.RoomName, c.Capacity;

DROP FUNCTION IF EXISTS fn_occupancy_rate;
DELIMITER //
CREATE FUNCTION fn_occupancy_rate(p_screening_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
  DECLARE v_capacity INT;
  DECLARE v_sold INT;
  DECLARE v_rate DECIMAL(5,2);

  SELECT c.Capacity INTO v_capacity
  FROM screenings s
  JOIN cinemarooms c ON s.RoomID = c.RoomID
  WHERE s.ScreeningID = p_screening_id;

  SELECT COUNT(*) INTO v_sold
  FROM tickets
  WHERE ScreeningID = p_screening_id;

  IF v_capacity IS NULL OR v_capacity = 0 THEN
    RETURN 0.00;
  END IF;

  SET v_rate = (v_sold * 100.0) / v_capacity;
  RETURN v_rate;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS sp_book_ticket;
DELIMITER //
CREATE PROCEDURE sp_book_ticket(
  IN p_customer_id INT,
  IN p_screening_id INT,
  IN p_seat_number VARCHAR(10)
)
BEGIN
  DECLARE v_exists INT DEFAULT 0;

  SELECT COUNT(*) INTO v_exists
  FROM tickets
  WHERE ScreeningID = p_screening_id
    AND SeatNumber = p_seat_number;

  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Seat already booked for this screening';
  ELSE
    INSERT INTO tickets(CustomerID, ScreeningID, SeatNumber, BookingCode, booked_at)
    VALUES (
      p_customer_id,
      p_screening_id,
      p_seat_number,
      CONCAT('BK', UPPER(SUBSTRING(REPLACE(UUID(), '-', ''), 1, 10))),
      NOW()
    );
  END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trg_validate_ticket;
DELIMITER //
CREATE TRIGGER trg_validate_ticket
BEFORE INSERT ON tickets
FOR EACH ROW
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  SELECT COUNT(*) INTO v_exists
  FROM tickets
  WHERE ScreeningID = NEW.ScreeningID
    AND SeatNumber = NEW.SeatNumber;

  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Duplicate seat booking is not allowed';
  END IF;
END //
DELIMITER ;

DROP FUNCTION IF EXISTS fn_total_revenue;

DELIMITER //
CREATE FUNCTION fn_total_revenue(p_screening_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_ticket_count INT;
  DECLARE v_price        INT DEFAULT 90000;

  SELECT COUNT(*) INTO v_ticket_count
  FROM tickets
  WHERE ScreeningID = p_screening_id;

  RETURN v_ticket_count * v_price;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- Phân quyền user (đề yêu cầu roles: admin, ticket_clerk)
-- ---------------------------------------------------------------

CREATE USER IF NOT EXISTS 'cinema_admin'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON cinema_db.* TO 'cinema_admin'@'localhost';

CREATE USER IF NOT EXISTS 'ticket_clerk'@'localhost' IDENTIFIED BY 'Clerk@123';
GRANT SELECT ON cinema_db.movies TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.cinemas TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.cinemarooms TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.screenings TO 'ticket_clerk'@'localhost';
GRANT SELECT, INSERT ON cinema_db.customers TO 'ticket_clerk'@'localhost';
GRANT SELECT, INSERT ON cinema_db.tickets TO 'ticket_clerk'@'localhost';

FLUSH PRIVILEGES;
