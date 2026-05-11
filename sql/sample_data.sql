USE cinema_db;

-- 1. Movies (10 Phim)
INSERT INTO Movies (MovieTitle, Genre, DurationMinutes) VALUES
('Avengers: Endgame', 'Hành động', 181),
('Inception', 'Khoa học viễn tưởng', 148),
('The Lion King', 'Hoạt hình', 118),
('Parasite', 'Tâm lý', 132),
('Interstellar', 'Khoa học viễn tưởng', 169),
('The Godfather', 'Hình sự', 175),
('Spirited Away', 'Hoạt hình', 125),
('The Dark Knight', 'Hành động', 152),
('Your Name', 'Anime', 107),
('Dune: Part Two', 'Hành động', 166);

-- 2. Cinemas (10 Rạp)
INSERT INTO Cinemas (CinemaName, Address) VALUES
('CGV Vincom Bà Triệu',    '191 Bà Triệu, Hai Bà Trưng, Hà Nội'),
('Lotte Cinema Gò Vấp',    '242 Nguyễn Văn Lượng, Gò Vấp, HCM'),
('Galaxy Nguyễn Du',       '116 Nguyễn Du, Quận 1, HCM'),
('BHD Star Thảo Điền',     'Tầng 5 Vincom Mega Mall, Quận 2, HCM'),
('Beta Cinemas Mỹ Đình',   'Tầng 4 Mỹ Đình Plaza, Nam Từ Liêm, Hà Nội'),
('Cinestar Quốc Thanh',    '271 Nguyễn Trãi, Quận 1, HCM'),
('Mega GS Cao Thắng',      '19 Cao Thắng, Quận 3, HCM'),
('DCine Bến Thành',        '6 Mạc Đĩnh Chi, Quận 1, HCM'),
('Starlight Đà Nẵng',      'Tầng 4 TTTM Nguyễn Kim, Đà Nẵng'),
('Rio Cinema Thái Bình',   'Lý Thường Kiệt, TP. Thái Bình');

-- 3. CinemaRooms (10 Phòng)
-- FIX: phòng cuối dùng CinemaID=10 (Rio Cinema) để Screening số 9 dùng RoomID=10 không bị lỗi FK
INSERT INTO CinemaRooms (CinemaID, RoomName, Capacity) VALUES
(1,  'Room 01 - IMAX',   200),
(1,  'Room 02 - Gold',    50),
(2,  'Lotte Room A',     150),
(3,  'Galaxy Premium',   180),
(4,  'BHD 04',           120),
(5,  'Beta Hall',        100),
(6,  'Cinestar 01',      140),
(7,  'Mega VIP',          40),
(8,  'DCine Standard',    90),
(10, 'Rio Hall',         110);

-- 4. Screenings (10 Suất chiếu)
INSERT INTO Screenings (MovieID, RoomID, ScreeningDate, ScreeningTime) VALUES
(1,  1,  DATE_ADD(CURDATE(), INTERVAL 1 DAY), '19:00:00'),
(2,  1,  DATE_ADD(CURDATE(), INTERVAL 1 DAY), '22:30:00'),
(3,  3,  DATE_ADD(CURDATE(), INTERVAL 2 DAY), '09:00:00'),
(4,  4,  DATE_ADD(CURDATE(), INTERVAL 2 DAY), '14:00:00'),
(5,  1,  DATE_ADD(CURDATE(), INTERVAL 3 DAY), '20:00:00'),
(6,  2,  DATE_ADD(CURDATE(), INTERVAL 3 DAY), '18:00:00'),
(7,  7,  DATE_ADD(CURDATE(), INTERVAL 4 DAY), '10:00:00'),
(8,  5,  DATE_ADD(CURDATE(), INTERVAL 4 DAY), '21:00:00'),
(9,  10, DATE_ADD(CURDATE(), INTERVAL 5 DAY), '15:30:00'),
(10, 4,  DATE_ADD(CURDATE(), INTERVAL 5 DAY), '19:30:00');

-- 5. Customers (10 Khách hàng)
INSERT INTO Customers (CustomerName, PhoneNumber) VALUES
('Nguyễn Văn A', '0901234567'),
('Trần Thị B',   '0912345678'),
('Lê Văn C',     '0923456789'),
('Phạm Minh D',  '0934567890'),
('Hoàng Gia E',  '0945678901'),
('Vũ Thị F',     '0956789012'),
('Đặng Văn G',   '0967890123'),
('Bùi Minh H',   '0978901234'),
('Ngô Thanh I',  '0989012345'),
('Đỗ Hoàng J',   '0990123456');

-- 6. Vouchers (10 Voucher)
INSERT INTO Vouchers (Code, DiscountPercent) VALUES
('GIAM20',    20),
('WELCOME50', 50),
('SUMMER10',  10),
('MOVIEFAN',  15),
('WEEKEND25', 25),
('STUDENT',   30),
('FAMILY40',  40),
('VIPONLY',   45),
('FREESHIP',   5),
('LUCKY99',   99);

-- 7. PaymentOrders (10 Đơn hàng)
INSERT INTO PaymentOrders (OrderCode, ScreeningID, CustomerName, CustomerPhone, SeatNumbers, OriginalAmount, VoucherCode, DiscountPercent, DiscountAmount, TotalAmount, Status, PaidAt) VALUES
('ORD001', 1,  'Nguyễn Văn A', '0901234567', 'A01,A02', 200000, 'GIAM20',    20, 40000, 160000, 'paid',    NOW()),
('ORD002', 1,  'Trần Thị B',   '0912345678', 'B05',     100000, NULL,         0,     0, 100000, 'paid',    NOW()),
('ORD003', 3,  'Lê Văn C',     '0923456789', 'C10',     100000, 'WELCOME50', 50, 50000,  50000, 'paid',    NOW()),
('ORD004', 4,  'Phạm Minh D',  '0934567890', 'D01',     100000, NULL,         0,     0, 100000, 'pending', NULL),
('ORD005', 5,  'Hoàng Gia E',  '0945678901', 'F12',     100000, 'SUMMER10',  10, 10000,  90000, 'paid',    NOW()),
('ORD006', 6,  'Vũ Thị F',     '0956789012', 'A01',     150000, NULL,         0,     0, 150000, 'pending', NULL),
('ORD007', 7,  'Đặng Văn G',   '0967890123', 'H05',     100000, 'MOVIEFAN',  15, 15000,  85000, 'paid',    NOW()),
('ORD008', 8,  'Bùi Minh H',   '0978901234', 'K09',     100000, NULL,         0,     0, 100000, 'paid',    NOW()),
('ORD009', 9,  'Ngô Thanh I',  '0989012345', 'B01',     100000, 'WEEKEND25', 25, 25000,  75000, 'paid',    NOW()),
('ORD010', 10, 'Đỗ Hoàng J',   '0990123456', 'L04',     100000, NULL,         0,     0, 100000, 'paid',    NOW());

-- 8. Tickets (10 Vé - dùng stored procedure để trigger hoạt động)
CALL sp_book_ticket(1,  1,  'A01');
CALL sp_book_ticket(1,  1,  'A02');
CALL sp_book_ticket(2,  1,  'B05');
CALL sp_book_ticket(3,  3,  'C10');
CALL sp_book_ticket(5,  5,  'F12');
CALL sp_book_ticket(7,  7,  'H05');
CALL sp_book_ticket(8,  8,  'K09');
CALL sp_book_ticket(8,  8,  'K10');
CALL sp_book_ticket(9,  9,  'B01');
CALL sp_book_ticket(10, 10, 'L04');

-- 9. VoucherUsages (5 lần dùng - chỉ dùng OrderCode đã tồn tại trong PaymentOrders)
-- FIX: bỏ ORD011-ORD015 vì không có trong PaymentOrders → lỗi FK
INSERT INTO VoucherUsages (VoucherID, PhoneNumber, OrderCode) VALUES
(1, '0901234567', 'ORD001'),
(2, '0923456789', 'ORD003'),
(3, '0945678901', 'ORD005'),
(4, '0967890123', 'ORD007'),
(5, '0989012345', 'ORD009');

-- 10. InvalidatedTickets (10 Vé bị hủy)
INSERT INTO InvalidatedTickets (CustomerName, CustomerPhone, BookingCode, MovieTitle, RoomName, ScreeningDate, ScreeningTime, SeatNumber, BookedAt, Reason) VALUES
('Nguyễn Văn Hủy', '0900000001', 'BK001', 'Inception',       'Room 01 - IMAX', '2024-05-20', '22:30:00', 'A05', NOW(), 'Khách hàng yêu cầu hủy'),
('Trần Thị Lỗi',   '0900000002', 'BK002', 'Avengers',        'Room 01 - IMAX', '2024-05-20', '19:00:00', 'C09', NOW(), 'Suất chiếu bị đổi giờ'),
('Lê Văn Sai',     '0900000003', 'BK003', 'Parasite',        'Galaxy Premium', '2024-05-21', '14:00:00', 'D04', NOW(), 'Thanh toán thất bại'),
('Phạm Văn A',     '0900000004', 'BK004', 'Dune: Part Two',  'BHD 04',         '2024-05-24', '19:30:00', 'E01', NOW(), 'Lỗi hệ thống'),
('Hoàng Thị B',    '0900000005', 'BK005', 'Dune: Part Two',  'BHD 04',         '2024-05-24', '19:30:00', 'E02', NOW(), 'Lỗi hệ thống'),
('Vũ Văn C',       '0900000006', 'BK006', 'The Lion King',   'Lotte Room A',   '2024-05-21', '09:00:00', 'F01', NOW(), 'Vé không còn khả dụng'),
('Đặng Văn D',     '0900000007', 'BK007', 'Your Name',       'Rio Hall',       '2024-05-23', '15:30:00', 'G05', NOW(), 'Khách hàng đổi phim'),
('Bùi Văn E',      '0900000008', 'BK008', 'The Dark Knight', 'Beta Hall',      '2024-05-23', '21:00:00', 'H01', NOW(), 'Phòng chiếu bảo trì'),
('Ngô Văn F',      '0900000009', 'BK009', 'Interstellar',    'Room 01 - IMAX', '2024-05-21', '20:00:00', 'I10', NOW(), 'Hết hạn thanh toán'),
('Đỗ Văn G',       '0900000010', 'BK010', 'The Godfather',   'Room 02 - Gold', '2024-05-22', '18:00:00', 'J01', NOW(), 'Khách hàng yêu cầu hoàn tiền');