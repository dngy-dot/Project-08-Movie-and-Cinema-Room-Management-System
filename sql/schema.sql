CREATE DATABASE IF NOT EXISTS cinema_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE cinema_db;

-- Tắt kiểm tra FK tạm thời để DROP an toàn
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS VoucherUsages;
DROP TABLE IF EXISTS Vouchers;
DROP TABLE IF EXISTS InvalidatedTickets;
DROP TABLE IF EXISTS Tickets;
DROP TABLE IF EXISTS PaymentOrders;
DROP TABLE IF EXISTS Screenings;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS CinemaRooms;
DROP TABLE IF EXISTS Cinemas;
DROP TABLE IF EXISTS Movies;

-- Bật lại kiểm tra FK
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Movies (
  MovieID INT AUTO_INCREMENT PRIMARY KEY,
  MovieTitle VARCHAR(255) NOT NULL,
  Genre VARCHAR(100) NOT NULL,
  DurationMinutes INT NOT NULL CHECK (DurationMinutes > 0),
  PosterURL VARCHAR(500) NULL,
  ReleaseStatus VARCHAR(20) NOT NULL DEFAULT 'now_showing'
);

CREATE TABLE Cinemas (
  CinemaID INT AUTO_INCREMENT PRIMARY KEY,
  CinemaName VARCHAR(150) NOT NULL UNIQUE,
  Address VARCHAR(255) NULL
);

CREATE TABLE CinemaRooms (
  RoomID INT AUTO_INCREMENT PRIMARY KEY,
  CinemaID INT NOT NULL,
  RoomName VARCHAR(100) NOT NULL UNIQUE,
  Capacity INT NOT NULL CHECK (Capacity > 0),
  FOREIGN KEY (CinemaID) REFERENCES Cinemas(CinemaID)
);

CREATE TABLE Screenings (
  ScreeningID INT AUTO_INCREMENT PRIMARY KEY,
  MovieID INT NOT NULL,
  RoomID INT NOT NULL,
  ScreeningDate DATE NOT NULL,
  ScreeningTime TIME NOT NULL,
  FOREIGN KEY (MovieID) REFERENCES Movies(MovieID),
  FOREIGN KEY (RoomID) REFERENCES CinemaRooms(RoomID)
);

CREATE TABLE Customers (
  CustomerID INT AUTO_INCREMENT PRIMARY KEY,
  CustomerName VARCHAR(150) NOT NULL,
  PhoneNumber VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE Tickets (
  TicketID INT AUTO_INCREMENT PRIMARY KEY,
  CustomerID INT NOT NULL,
  ScreeningID INT NOT NULL,
  SeatNumber VARCHAR(10) NOT NULL,
  BookingCode VARCHAR(12) NOT NULL UNIQUE,
  booked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
  FOREIGN KEY (ScreeningID) REFERENCES Screenings(ScreeningID),
  CONSTRAINT uq_screening_seat UNIQUE (ScreeningID, SeatNumber)
);

CREATE TABLE PaymentOrders (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  OrderCode VARCHAR(16) NOT NULL UNIQUE,
  ScreeningID INT NOT NULL,
  CustomerName VARCHAR(150) NOT NULL,
  CustomerPhone VARCHAR(30) NOT NULL,
  SeatNumbers VARCHAR(300) NOT NULL,
  OriginalAmount INT NOT NULL DEFAULT 0,
  VoucherCode VARCHAR(30) NULL,
  DiscountPercent INT NOT NULL DEFAULT 0,
  DiscountAmount INT NOT NULL DEFAULT 0,
  TotalAmount INT NOT NULL,
  Status VARCHAR(20) NOT NULL DEFAULT 'pending',
  PaidAt DATETIME NULL,
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ScreeningID) REFERENCES Screenings(ScreeningID)
);

CREATE TABLE Vouchers (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  Code VARCHAR(30) NOT NULL UNIQUE,
  DiscountPercent INT NOT NULL CHECK (DiscountPercent BETWEEN 1 AND 100),
  CreatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE VoucherUsages (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  VoucherID INT NOT NULL,
  PhoneNumber VARCHAR(30) NOT NULL,
  OrderCode VARCHAR(16) NOT NULL UNIQUE,
  UsedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (VoucherID) REFERENCES Vouchers(ID) ON DELETE CASCADE,
  CONSTRAINT uq_voucher_phone UNIQUE (VoucherID, PhoneNumber)
);

CREATE TABLE InvalidatedTickets (
  ID INT AUTO_INCREMENT PRIMARY KEY,
  CustomerName VARCHAR(150) NOT NULL,
  CustomerPhone VARCHAR(30) NOT NULL,
  BookingCode VARCHAR(12) NOT NULL UNIQUE,
  MovieTitle VARCHAR(255) NOT NULL,
  RoomName VARCHAR(100) NOT NULL,
  ScreeningDate DATE NOT NULL,
  ScreeningTime TIME NOT NULL,
  SeatNumber VARCHAR(10) NOT NULL,
  BookedAt DATETIME NOT NULL,
  Reason VARCHAR(255) NOT NULL DEFAULT 'Vé không còn khả dụng',
  InvalidatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_movies_title ON Movies(MovieTitle);
CREATE INDEX idx_screenings_datetime ON Screenings(ScreeningDate, ScreeningTime);

DROP VIEW IF EXISTS vw_daily_screenings;
CREATE VIEW vw_daily_screenings AS
SELECT
  s.ScreeningDate,
  s.ScreeningTime,
  ci.CinemaName,
  m.MovieTitle,
  c.RoomName
FROM Screenings s
JOIN Movies m ON s.MovieID = m.MovieID
JOIN CinemaRooms c ON s.RoomID = c.RoomID
JOIN Cinemas ci ON c.CinemaID = ci.CinemaID;

DROP VIEW IF EXISTS vw_available_seats;
CREATE VIEW vw_available_seats AS
SELECT
  s.ScreeningID,
  c.RoomName,
  c.Capacity,
  COUNT(t.TicketID) AS SoldSeats,
  (c.Capacity - COUNT(t.TicketID)) AS AvailableSeats
FROM Screenings s
JOIN CinemaRooms c ON s.RoomID = c.RoomID
LEFT JOIN Tickets t ON t.ScreeningID = s.ScreeningID
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
  FROM Screenings s
  JOIN CinemaRooms c ON s.RoomID = c.RoomID
  WHERE s.ScreeningID = p_screening_id;

  SELECT COUNT(*) INTO v_sold
  FROM Tickets
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
  FROM Tickets
  WHERE ScreeningID = p_screening_id
    AND SeatNumber = p_seat_number;

  IF v_exists > 0 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Seat already booked for this screening';
  ELSE
    INSERT INTO Tickets(CustomerID, ScreeningID, SeatNumber)
    VALUES (p_customer_id, p_screening_id, p_seat_number);
  END IF;
END //
DELIMITER ;

DROP TRIGGER IF EXISTS trg_validate_ticket;
DELIMITER //
CREATE TRIGGER trg_validate_ticket
BEFORE INSERT ON Tickets
FOR EACH ROW
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  SELECT COUNT(*) INTO v_exists
  FROM Tickets
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
  FROM Tickets
  WHERE ScreeningID = p_screening_id;

  RETURN v_ticket_count * v_price;
END //
DELIMITER ;

-- ---------------------------------------------------------------
-- Phân quyền user (đề yêu cầu roles: admin, ticket_clerk)
-- ---------------------------------------------------------------

-- Admin: toàn quyền
CREATE USER IF NOT EXISTS 'cinema_admin'@'localhost' IDENTIFIED BY 'Admin@123';
GRANT ALL PRIVILEGES ON cinema_db.* TO 'cinema_admin'@'localhost';

-- Ticket clerk: chỉ được xem và đặt vé
CREATE USER IF NOT EXISTS 'ticket_clerk'@'localhost' IDENTIFIED BY 'Clerk@123';
GRANT SELECT ON cinema_db.Movies      TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.Cinemas     TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.CinemaRooms TO 'ticket_clerk'@'localhost';
GRANT SELECT ON cinema_db.Screenings  TO 'ticket_clerk'@'localhost';
GRANT SELECT, INSERT ON cinema_db.Customers TO 'ticket_clerk'@'localhost';
GRANT SELECT, INSERT ON cinema_db.Tickets   TO 'ticket_clerk'@'localhost';

FLUSH PRIVILEGES;