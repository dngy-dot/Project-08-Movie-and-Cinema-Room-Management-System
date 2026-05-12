<<<<<<< HEAD
=======
-- ================================================================
-- SAMPLE DATA for cinema_db
-- Dựa trên dữ liệu thực từ CGV Việt Nam (tháng 05/2026)
-- Bao gồm: phim đang chiếu, sắp chiếu, ngừng chiếu
-- Mỗi bảng có đa dạng trạng thái & tình huống thực tế
-- ================================================================

USE cinema_db;

-- ================================================================
-- 1. MOVIES
-- ReleaseStatus: 'now_showing' | 'coming_soon' |
-- ================================================================

INSERT INTO Movies (MovieTitle, Genre, DurationMinutes, PosterURL, ReleaseStatus) VALUES

-- === ĐANG CHIẾU (now_showing) ===
('YÊU NỮ THÍCH HÀNG HIỆU 2',
 'Hài, Tâm Lý', 119,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/o/poster_payoff_yeu_nu_thich_hang_hieu_2_3.jpg',
 'now_showing'),

('MORTAL KOMBAT: CUỘC CHIẾN SINH TỬ II',
 'Hành Động, Phiêu Lưu, Thần thoại', 116,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/o/poster_mortal_kombat_cuoc_chien_sinh_tu_1_.jpg',
 'now_showing'),

('HEO NĂM MÓNG',
 'Hồi hộp, Kinh Dị', 103,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/3/5/350x495-heo5mong.jpg',
 'now_showing'),

('PHÍ PHÔNG: QUỶ MÁU RỪNG THIÊNG',
 'Hồi hộp, Kinh Dị', 120,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/h/phi_pho_ng_teaser_2_-_social_size_4wx5h.jpg',
 'now_showing'),

('THẨM MỸ VIỆN ÂM PHỦ',
 'Hồi hộp, Kinh Dị', 100,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/4/7/470wx700h-tmv.jpg',
 'now_showing'),

('THE SHEEP DETECTIVES',
 'Bí ẩn, Hài, Hành Động', 109,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/3/5/350x495-sheep.jpg',
 'now_showing'),

('ANH HÙNG',
 'Gia đình, Tâm Lý', 122,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/4/7/470wx700h-anhhung.jpg',
 'now_showing'),

('ĐẠI TIỆC TRĂNG MÁU 8',
 'Hài, Kinh Dị, Tâm Lý', 130,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/3/5/350x495-dttm.jpg',
 'now_showing'),

('LÚC ĐÓ TÔI ĐÃ CHUYỂN SINH THÀNH SLIME: NƯỚC MẮT ĐẠI DƯƠNG',
 'Hoạt Hình', 105,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/o/poster_luc_do_toi_da_chuyen_thanh_slime_nuoc_mat_dai_duong_2.jpg',
 'now_showing'),

('GẤU BOONIE: KUNGFU ẨN SĨ',
 'Hoạt Hình', 113,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/7/0/700x1000_4.jpg',
 'now_showing'),

('PHỔI SẮT',
 'Hồi hộp, Kinh Dị', 125,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/3/5/350x495-iron.jpg',
 'now_showing'),

('PHI VỤ THANH TOÁN HÀO MÔN',
 'Hài, Hồi hộp, Tâm Lý', 105,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/h/t/htmak_280x416.png',
 'now_showing'),

('PHIM SHIN - CẬU BÉ BÚT CHÌ: QUẬY TUNG! VƯƠNG QUỐC NGUỆCH NGOẠC',
 'Gia đình, Hài, Hoạt Hình, Phiêu Lưu', 104,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/o/poster_shin_2020_4x5.jpg',
 'now_showing'),

-- === SẮP CHIẾU (coming_soon) ===
('PHI CÔNG SIÊU ĐẲNG MAVERICK (CHIẾU LẠI)',
 'Hành Động, Phiêu Lưu', 130,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/4/7/470x700-topgun.jpg',
 'coming_soon'),

('TẠM BIỆT GOHAN',
 'Gia đình', 140,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/2/_/2.2._gohan_-_main_poster_-_size_web_app.jpg',
 'coming_soon'),

('DORAEMON: NOBITA VÀ LÂU ĐÀI DƯỚI ĐÁY BIỂN (PHIÊN BẢN MỚI)',
 'Hoạt Hình, Phiêu Lưu', 101,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/p/o/poster_doraemon_movie_2026_g_c.jpg',
 'coming_soon'),

('MISSION: IMPOSSIBLE – THE FINAL RECKONING',
 'Hành Động, Phiêu Lưu', 169,
 'https://upload.wikimedia.org/wikipedia/en/thumb/7/71/Mission_Impossible_The_Final_Reckoning_poster.jpg/220px-Mission_Impossible_The_Final_Reckoning_poster.jpg',
 'coming_soon'),

('HOA MAI',
 'Hài, Gia đình', 128,
 'https://iguov8nhvyobj.vcdn.cloud/media/catalog/product/cache/1/thumbnail/190x260/2e2b8cd282892c71872b9e67d2cb5039/h/o/hoa_mai_poster.jpg',
 'coming_soon'),
  
-- ================================================================
-- 2. CINEMAS
-- ================================================================

INSERT INTO Cinemas (CinemaName, Address) VALUES
('CGV Vincom Center Bà Triệu',    '191 Bà Triệu, Hai Bà Trưng, Hà Nội'),
('CGV Hà Đông',                   'Tầng 4, TTTM Hà Đông, 1A Quang Trung, Hà Đông, Hà Nội'),
('CGV Aeon Mall Long Biên',       'Tầng 4, Aeon Mall Long Biên, Long Biên, Hà Nội'),
('CGV Vincom Plaza Trần Duy Hưng','Tầng 5, Vincom Plaza, 37 Trần Duy Hưng, Cầu Giấy, Hà Nội'),
('CGV Landmark 81',               'Tầng B1, Vincom Mega Mall, 720A Điện Biên Phủ, Bình Thạnh, TP.HCM'),
('CGV Giga Mall Thủ Đức',         'Tầng 5, Giga Mall, 240 Phạm Văn Đồng, Thủ Đức, TP.HCM');

-- ================================================================
-- 3. CINEMA ROOMS
-- Mỗi rạp có phòng chiếu thường + ít nhất 1 phòng đặc biệt
-- ================================================================

INSERT INTO CinemaRooms (CinemaID, RoomName, Capacity) VALUES
-- CGV Vincom Center Bà Triệu (CinemaID=1)
(1, 'Phòng 1 - Standard',    120),
(1, 'Phòng 2 - Standard',    100),
(1, 'Phòng 3 - IMAX',        200),
(1, 'Phòng 4 - 4DX',          60),
(1, 'Phòng 5 - Standard',     90),

-- CGV Hà Đông (CinemaID=2)
(2, 'Phòng A - Standard',    110),
(2, 'Phòng B - Standard',     95),
(2, 'Phòng C - Starium',     150),

-- CGV Aeon Mall Long Biên (CinemaID=3)
(3, 'Phòng 01 - Standard',   100),
(3, 'Phòng 02 - Standard',   100),
(3, 'Phòng 03 - 4DX',         60),

-- CGV Vincom Plaza Trần Duy Hưng (CinemaID=4)
(4, 'Phòng Gold 1',           80),
(4, 'Phòng Gold 2',           80),
(4, 'Phòng Platinum',         40),

-- CGV Landmark 81 (CinemaID=5)
(5, 'Phòng L1 - Standard',   130),
(5, 'Phòng L2 - Standard',   130),
(5, 'Phòng L3 - IMAX',       220),
(5, 'Phòng L4 - ScreenX',    180),

-- CGV Giga Mall Thủ Đức (CinemaID=6)
(6, 'Phòng G1 - Standard',   110),
(6, 'Phòng G2 - Standard',   110),
(6, 'Phòng G3 - 4DX',         60);

-- ================================================================
-- 4. SCREENINGS
-- Lịch chiếu: ngày 07~11/05/2026, đa dạng suất sáng/chiều/tối
-- MovieID mapping:
--  1=Yêu nữ thích hàng hiệu 2     2=Mortal Kombat II      3=Heo Năm Móng
--  4=Phí Phông                     5=Thẩm Mỹ Viện Âm Phủ  6=The Sheep Detectives
--  7=Anh Hùng                      8=Đại Tiệc Trăng Máu    9=Slime
-- 10=Gấu Boonie                   11=Phổi Sắt             12=Phi Vụ Thanh Toán
-- 13=Shin                         14=Top Gun (coming soon) -- không tạo screening cho coming_soon/stopped
-- ================================================================

INSERT INTO Screenings (MovieID, RoomID, ScreeningDate, ScreeningTime) VALUES

-- === Thứ 5, 08/05/2026 ===
-- Phòng 1 Standard - Vincom Bà Triệu
(1,  1, '2026-05-08', '09:00:00'),  -- Yêu Nữ, sáng sớm
(3,  1, '2026-05-08', '11:30:00'),  -- Heo Năm Móng
(5,  1, '2026-05-08', '14:00:00'),  -- Thẩm Mỹ Viện Âm Phủ
(8,  1, '2026-05-08', '16:30:00'),  -- Đại Tiệc Trăng Máu
(12, 1, '2026-05-08', '19:00:00'),  -- Phi Vụ Thanh Toán
(4,  1, '2026-05-08', '21:30:00'),  -- Phí Phông, suất khuya

-- Phòng 3 IMAX - Vincom Bà Triệu
(2,  3, '2026-05-08', '10:00:00'),  -- Mortal Kombat IMAX
(2,  3, '2026-05-08', '13:00:00'),
(2,  3, '2026-05-08', '16:00:00'),
(2,  3, '2026-05-08', '19:00:00'),
(2,  3, '2026-05-08', '22:00:00'),  -- suất khuya đặc biệt

-- Phòng 4 4DX - Vincom Bà Triệu
(2,  4, '2026-05-08', '11:00:00'),
(4,  4, '2026-05-08', '14:30:00'),
(2,  4, '2026-05-08', '18:00:00'),

-- Phòng A - Hà Đông
(6,  6, '2026-05-08', '09:30:00'),  -- Sheep Detectives
(7,  6, '2026-05-08', '12:00:00'),  -- Anh Hùng
(10, 6, '2026-05-08', '14:30:00'),  -- Gấu Boonie
(9,  6, '2026-05-08', '17:00:00'),  -- Slime
(11, 6, '2026-05-08', '19:30:00'),  -- Phổi Sắt
(4,  6, '2026-05-08', '22:00:00'),

-- Phòng C Starium - Hà Đông
(2,  8, '2026-05-08', '10:30:00'),
(2,  8, '2026-05-08', '14:00:00'),
(2,  8, '2026-05-08', '20:00:00'),

-- === Thứ 6, 09/05/2026 (hôm nay - nhiều suất hơn) ===
-- Phòng 1 Standard - Vincom Bà Triệu
(1,  1, '2026-05-09', '09:15:00'),
(5,  1, '2026-05-09', '11:45:00'),
(3,  1, '2026-05-09', '14:15:00'),
(12, 1, '2026-05-09', '16:45:00'),
(8,  1, '2026-05-09', '19:15:00'),
(11, 1, '2026-05-09', '21:45:00'),

-- Phòng 3 IMAX - Vincom Bà Triệu
(2,  3, '2026-05-09', '09:30:00'),
(2,  3, '2026-05-09', '12:30:00'),
(2,  3, '2026-05-09', '15:30:00'),
(2,  3, '2026-05-09', '18:30:00'),
(2,  3, '2026-05-09', '21:30:00'),

-- Phòng 4 4DX - Vincom Bà Triệu
(4,  4, '2026-05-09', '10:00:00'),
(2,  4, '2026-05-09', '13:00:00'),
(4,  4, '2026-05-09', '16:30:00'),
(2,  4, '2026-05-09', '20:00:00'),

-- Phòng 5 Standard - Vincom Bà Triệu
(13, 5, '2026-05-09', '10:00:00'),  -- Shin cậu bé bút chì
(7,  5, '2026-05-09', '12:30:00'),
(10, 5, '2026-05-09', '15:00:00'),
(6,  5, '2026-05-09', '17:30:00'),
(9,  5, '2026-05-09', '20:00:00'),

-- Phòng A - Hà Đông
(1,  6, '2026-05-09', '09:00:00'),
(3,  6, '2026-05-09', '11:30:00'),
(5,  6, '2026-05-09', '14:00:00'),
(8,  6, '2026-05-09', '16:30:00'),
(12, 6, '2026-05-09', '19:00:00'),
(4,  6, '2026-05-09', '21:30:00'),

-- Phòng B - Hà Đông
(13, 7, '2026-05-09', '10:00:00'),
(10, 7, '2026-05-09', '12:30:00'),
(7,  7, '2026-05-09', '15:00:00'),
(6,  7, '2026-05-09', '17:30:00'),
(11, 7, '2026-05-09', '20:00:00'),

-- Phòng C Starium - Hà Đông
(2,  8, '2026-05-09', '10:00:00'),
(2,  8, '2026-05-09', '13:00:00'),
(2,  8, '2026-05-09', '16:00:00'),
(2,  8, '2026-05-09', '19:00:00'),
(2,  8, '2026-05-09', '22:00:00'),

-- Phòng 01 - Aeon Long Biên
(1,  9, '2026-05-09', '09:30:00'),
(5,  9, '2026-05-09', '12:00:00'),
(3,  9, '2026-05-09', '14:30:00'),
(8,  9, '2026-05-09', '17:00:00'),
(12, 9, '2026-05-09', '19:30:00'),

-- Phòng 02 - Aeon Long Biên
(7,  10, '2026-05-09', '09:00:00'),
(9,  10, '2026-05-09', '11:30:00'),
(6,  10, '2026-05-09', '14:00:00'),
(11, 10, '2026-05-09', '16:30:00'),
(4,  10, '2026-05-09', '19:00:00'),

-- Phòng 03 4DX - Aeon Long Biên
(2,  11, '2026-05-09', '11:00:00'),
(4,  11, '2026-05-09', '14:00:00'),
(2,  11, '2026-05-09', '17:00:00'),
(4,  11, '2026-05-09', '20:00:00'),

-- Phòng L1 - Landmark 81 TP.HCM
(1,  15, '2026-05-09', '09:00:00'),
(5,  15, '2026-05-09', '11:30:00'),
(12, 15, '2026-05-09', '14:00:00'),
(8,  15, '2026-05-09', '16:30:00'),
(4,  15, '2026-05-09', '19:00:00'),
(11, 15, '2026-05-09', '21:30:00'),

-- Phòng L3 IMAX - Landmark 81
(2,  17, '2026-05-09', '09:30:00'),
(2,  17, '2026-05-09', '12:30:00'),
(2,  17, '2026-05-09', '15:30:00'),
(2,  17, '2026-05-09', '18:30:00'),
(2,  17, '2026-05-09', '21:30:00'),

-- Phòng L4 ScreenX - Landmark 81
(2,  18, '2026-05-09', '10:00:00'),
(2,  18, '2026-05-09', '13:30:00'),
(4,  18, '2026-05-09', '17:00:00'),
(2,  18, '2026-05-09', '20:30:00'),

-- === Thứ 7, 10/05/2026 (cuối tuần - full suất) ===
(1,  1, '2026-05-10', '09:00:00'),
(2,  3, '2026-05-10', '09:30:00'),
(2,  3, '2026-05-10', '12:30:00'),
(2,  3, '2026-05-10', '15:30:00'),
(2,  3, '2026-05-10', '18:30:00'),
(2,  3, '2026-05-10', '21:30:00'),
(4,  4, '2026-05-10', '10:00:00'),
(2,  4, '2026-05-10', '13:00:00'),
(4,  4, '2026-05-10', '16:30:00'),
(5,  1, '2026-05-10', '11:30:00'),
(8,  1, '2026-05-10', '14:00:00'),
(12, 1, '2026-05-10', '16:30:00'),
(4,  1, '2026-05-10', '19:00:00'),
(11, 1, '2026-05-10', '21:30:00'),
(6,  6, '2026-05-10', '09:30:00'),
(7,  6, '2026-05-10', '12:00:00'),
(10, 6, '2026-05-10', '14:30:00'),
(9,  6, '2026-05-10', '17:00:00'),
(3,  6, '2026-05-10', '19:30:00'),
(2,  8, '2026-05-10', '10:00:00'),
(2,  8, '2026-05-10', '13:00:00'),
(2,  8, '2026-05-10', '16:00:00'),
(2,  8, '2026-05-10', '19:00:00'),
(13, 9, '2026-05-10', '10:00:00'),
(10, 9, '2026-05-10', '12:30:00'),
(7,  9, '2026-05-10', '15:00:00'),
(6,  9, '2026-05-10', '17:30:00'),
(12, 9, '2026-05-10', '20:00:00'),
(1,  15, '2026-05-10', '09:00:00'),
(2,  17, '2026-05-10', '09:30:00'),
(2,  17, '2026-05-10', '12:30:00'),
(2,  17, '2026-05-10', '15:30:00'),
(2,  17, '2026-05-10', '18:30:00'),
(2,  17, '2026-05-10', '21:30:00'),

-- === Chủ nhật, 11/05/2026 ===
(1,  1, '2026-05-11', '09:00:00'),
(2,  3, '2026-05-11', '10:00:00'),
(2,  3, '2026-05-11', '13:00:00'),
(2,  3, '2026-05-11', '16:00:00'),
(2,  3, '2026-05-11', '19:00:00'),
(5,  1, '2026-05-11', '11:30:00'),
(12, 1, '2026-05-11', '14:00:00'),
(8,  1, '2026-05-11', '16:30:00'),
(4,  1, '2026-05-11', '19:00:00'),
(7,  6, '2026-05-11', '09:30:00'),
(10, 6, '2026-05-11', '12:00:00'),
(9,  6, '2026-05-11', '14:30:00'),
(3,  6, '2026-05-11', '17:00:00'),
(11, 6, '2026-05-11', '19:30:00'),
(2,  8, '2026-05-11', '10:30:00'),
(2,  8, '2026-05-11', '14:00:00'),
(2,  8, '2026-05-11', '20:00:00');

-- ================================================================
-- 5. CUSTOMERS
-- ================================================================

INSERT INTO Customers (CustomerName, PhoneNumber) VALUES
('Nguyễn Văn An',        '0901234567'),
('Trần Thị Bích',        '0912345678'),
('Lê Hoàng Cường',       '0923456789'),
('Phạm Minh Dũng',       '0934567890'),
('Hoàng Thị Emly',       '0945678901'),
('Vũ Đức Phong',         '0956789012'),
('Đặng Thị Giang',       '0967890123'),
('Bùi Quốc Huy',         '0978901234'),
('Ngô Thị Hoa',          '0989012345'),
('Đinh Văn Khải',        '0990123456'),
('Lý Thị Lan',           '0901122334'),
('Trương Minh Long',     '0912233445'),
('Đỗ Thị Mai',           '0923344556'),
('Phan Văn Nam',         '0934455667'),
('Chu Thị Oanh',         '0945566778'),
('Võ Đức Quân',          '0956677889'),
('Hồ Thị Ry',            '0967788990'),
('Tô Minh Sơn',          '0978899001'),
('Lưu Thị Trang',        '0989900112'),
('Mai Văn Uy',           '0990011223');

-- ================================================================
-- 6. VOUCHERS
-- ================================================================

INSERT INTO Vouchers (Code, DiscountPercent, CreatedAt) VALUES
('SUMMER2026',   20, '2026-04-01 08:00:00'),
('WELCOME10',    10, '2026-01-01 00:00:00'),
('MORTAL50',     50, '2026-05-01 09:00:00'),  -- voucher ra mắt Mortal Kombat
('CGVBDAY30',    30, '2026-03-15 10:00:00'),
('FLASH15',      15, '2026-05-09 06:00:00'),  -- flash sale hôm nay
('STUDENT25',    25, '2026-02-01 08:00:00');

-- ================================================================
-- 7. TICKETS
-- Vé đã đặt thành công cho các suất đã chiếu và đang chiếu
-- BookingCode: format BCxxxxxx (12 ký tự)
-- Covering: nhiều ghế/suất, vé của nhiều khách hàng
-- ================================================================

INSERT INTO Tickets (CustomerID, ScreeningID, SeatNumber, BookingCode, booked_at) VALUES
-- Suất ScreeningID=1 (Yêu Nữ, Phòng 1, 08/05 09:00) - phòng 120 ghế, 8 vé bán
(1,  1,  'A01', 'BC0000000001', '2026-05-06 10:15:00'),
(2,  1,  'A02', 'BC0000000002', '2026-05-06 10:16:00'),
(3,  1,  'C05', 'BC0000000003', '2026-05-07 14:00:00'),
(4,  1,  'C06', 'BC0000000004', '2026-05-07 14:01:00'),
(5,  1,  'E10', 'BC0000000005', '2026-05-07 20:30:00'),
(6,  1,  'E11', 'BC0000000006', '2026-05-07 20:31:00'),
(7,  1,  'G08', 'BC0000000007', '2026-05-08 07:00:00'),
(8,  1,  'G09', 'BC0000000008', '2026-05-08 07:01:00'),

-- Suất ScreeningID=2 (Heo Năm Móng, Phòng 1, 08/05 11:30) - 5 vé
(1,  2,  'B03', 'BC0000000009', '2026-05-07 09:00:00'),
(9,  2,  'B04', 'BC0000000010', '2026-05-07 09:05:00'),
(10, 2,  'D07', 'BC0000000011', '2026-05-08 08:00:00'),
(11, 2,  'D08', 'BC0000000012', '2026-05-08 08:01:00'),
(12, 2,  'F12', 'BC0000000013', '2026-05-08 08:30:00'),

-- Suất ScreeningID=10 (Mortal Kombat IMAX, Phòng 3, 08/05 22:00) - gần full (suất khuya đặc biệt)
(1,  10, 'A01', 'BC0000000014', '2026-05-05 09:00:00'),
(2,  10, 'A02', 'BC0000000015', '2026-05-05 09:01:00'),
(3,  10, 'A03', 'BC0000000016', '2026-05-05 09:02:00'),
(4,  10, 'B01', 'BC0000000017', '2026-05-06 12:00:00'),
(5,  10, 'B02', 'BC0000000018', '2026-05-06 12:01:00'),
(6,  10, 'C01', 'BC0000000019', '2026-05-07 18:00:00'),
(7,  10, 'C02', 'BC0000000020', '2026-05-07 18:01:00'),
(8,  10, 'C03', 'BC0000000021', '2026-05-07 18:02:00'),
(9,  10, 'D01', 'BC0000000022', '2026-05-08 06:00:00'),
(10, 10, 'D02', 'BC0000000023', '2026-05-08 06:01:00'),
(11, 10, 'E01', 'BC0000000024', '2026-05-08 06:30:00'),
(12, 10, 'E02', 'BC0000000025', '2026-05-08 06:31:00'),

-- Suất ScreeningID=13 (Mortal Kombat 4DX, Phòng 4, 08/05 11:00) - 60 ghế, bán 25 vé (đặc thù 4DX đắt)
(1,  13, 'A01', 'BC0000000026', '2026-05-04 10:00:00'),
(2,  13, 'A02', 'BC0000000027', '2026-05-04 10:01:00'),
(3,  13, 'B03', 'BC0000000028', '2026-05-05 14:00:00'),
(13, 13, 'B04', 'BC0000000029', '2026-05-05 14:01:00'),
(14, 13, 'C05', 'BC0000000030', '2026-05-06 09:00:00'),
(15, 13, 'C06', 'BC0000000031', '2026-05-06 09:01:00'),
(16, 13, 'D07', 'BC0000000032', '2026-05-07 11:00:00'),
(17, 13, 'D08', 'BC0000000033', '2026-05-07 11:01:00'),

-- Suất ScreeningID=30 (Mortal Kombat IMAX, Phòng 3, 09/05 09:30) - hôm nay, vé mới đặt
(1,  30, 'A01', 'BC0000000034', '2026-05-08 22:00:00'),
(2,  30, 'A02', 'BC0000000035', '2026-05-08 22:01:00'),
(18, 30, 'B01', 'BC0000000036', '2026-05-09 07:30:00'),
(19, 30, 'B02', 'BC0000000037', '2026-05-09 07:31:00'),
(20, 30, 'C01', 'BC0000000038', '2026-05-09 08:00:00'),

-- Suất ScreeningID=25 (Yêu Nữ, Phòng 1, 09/05 09:15) - vài vé
(3,  25, 'E03', 'BC0000000039', '2026-05-09 07:00:00'),
(4,  25, 'E04', 'BC0000000040', '2026-05-09 07:01:00'),
(5,  25, 'F05', 'BC0000000041', '2026-05-09 08:30:00'),

-- Suất ScreeningID=47 (Gấu Boonie, Phòng B Hà Đông, 09/05 12:30) - gia đình
(13, 47, 'D01', 'BC0000000042', '2026-05-08 19:00:00'),
(13, 47, 'D02', 'BC0000000043', '2026-05-08 19:00:00'), -- sai: cùng customer khác ghế, ổn
(14, 47, 'D03', 'BC0000000044', '2026-05-08 19:05:00'),
(15, 47, 'D04', 'BC0000000045', '2026-05-08 19:06:00'),

-- Suất ScreeningID=55 (Phổi Sắt, Phòng 02 Aeon, 09/05 16:30) - 3 vé
(16, 55, 'G10', 'BC0000000046', '2026-05-09 10:00:00'),
(17, 55, 'G11', 'BC0000000047', '2026-05-09 10:01:00'),
(18, 55, 'G12', 'BC0000000048', '2026-05-09 10:02:00');

-- ================================================================
-- 8. PAYMENT ORDERS
-- Đa dạng trạng thái: paid, pending, cancelled
-- Có order dùng voucher, không dùng voucher
-- ================================================================

INSERT INTO PaymentOrders
  (OrderCode, ScreeningID, CustomerName, CustomerPhone, SeatNumbers,
   OriginalAmount, VoucherCode, DiscountPercent, DiscountAmount, TotalAmount,
   Status, PaidAt, CreatedAt)
VALUES

-- Đã thanh toán, không voucher (2 ghế, 90k/ghế)
('ORD2026050001', 1,  'Nguyễn Văn An',    '0901234567', 'A01,A02',
  180000, NULL,  0, 0,      180000, 'paid',      '2026-05-06 10:20:00', '2026-05-06 10:15:00'),

-- Đã thanh toán, không voucher
('ORD2026050002', 1,  'Lê Hoàng Cường',   '0923456789', 'C05,C06',
  180000, NULL,  0, 0,      180000, 'paid',      '2026-05-07 14:05:00', '2026-05-07 14:00:00'),

-- Đã thanh toán, dùng voucher WELCOME10 (10%)
('ORD2026050003', 1,  'Hoàng Thị Emly',   '0945678901', 'E10,E11',
  180000, 'WELCOME10', 10, 18000, 162000, 'paid', '2026-05-07 20:35:00', '2026-05-07 20:30:00'),

-- Đã thanh toán, không voucher
('ORD2026050004', 1,  'Vũ Đức Phong',     '0956789012', 'G08,G09',
  180000, NULL,  0, 0,      180000, 'paid',      '2026-05-08 07:05:00', '2026-05-08 07:00:00'),

-- Đã thanh toán
('ORD2026050005', 2,  'Nguyễn Văn An',    '0901234567', 'B03',
   90000, NULL,  0, 0,       90000, 'paid',      '2026-05-07 09:05:00', '2026-05-07 09:00:00'),

-- Đã thanh toán
('ORD2026050006', 2,  'Ngô Thị Hoa',      '0989012345', 'B04',
   90000, NULL,  0, 0,       90000, 'paid',      '2026-05-07 09:10:00', '2026-05-07 09:05:00'),

-- Đã thanh toán, voucher MORTAL50 (50%) - suất khuya Mortal Kombat IMAX
('ORD2026050007', 10, 'Nguyễn Văn An',    '0901234567', 'A01',
   90000, 'MORTAL50', 50, 45000, 45000,  'paid',  '2026-05-05 09:05:00', '2026-05-05 09:00:00'),

-- Đã thanh toán - nhóm lớn Mortal Kombat IMAX khuya
('ORD2026050008', 10, 'Trần Thị Bích',    '0912345678', 'A02,B01,B02',
  270000, NULL,  0, 0,      270000, 'paid',      '2026-05-06 12:05:00', '2026-05-06 12:00:00'),

('ORD2026050009', 10, 'Phạm Minh Dũng',   '0934567890', 'A03',
   90000, NULL,  0, 0,       90000, 'paid',      '2026-05-05 09:10:00', '2026-05-05 09:05:00'),

-- Đã thanh toán 4DX (cùng giá mẫu 90k, thực tế có thể đắt hơn)
('ORD2026050010', 13, 'Nguyễn Văn An',    '0901234567', 'A01,A02',
  180000, 'SUMMER2026', 20, 36000, 144000, 'paid', '2026-05-04 10:05:00', '2026-05-04 10:00:00'),

('ORD2026050011', 13, 'Lê Hoàng Cường',   '0923456789', 'B03,B04',
  180000, NULL,  0, 0,      180000, 'paid',      '2026-05-05 14:05:00', '2026-05-05 14:00:00'),

-- Đã thanh toán - hôm nay
('ORD2026050012', 30, 'Nguyễn Văn An',    '0901234567', 'A01,A02',
  180000, 'FLASH15', 15, 27000, 153000, 'paid',   '2026-05-08 22:05:00', '2026-05-08 22:00:00'),

('ORD2026050013', 30, 'Tô Minh Sơn',      '0978899001', 'B01,B02',
  180000, NULL,  0, 0,      180000, 'paid',      '2026-05-09 07:35:00', '2026-05-09 07:31:00'),

-- Đang chờ thanh toán (pending) - order mới tạo hôm nay
('ORD2026050014', 30, 'Lưu Thị Trang',    '0989900112', 'C01',
   90000, NULL,  0, 0,       90000, 'pending',   NULL,                   '2026-05-09 08:00:00'),

('ORD2026050015', 25, 'Lê Hoàng Cường',   '0923456789', 'E03,E04',
  180000, 'CGVBDAY30', 30, 54000, 126000, 'pending', NULL,              '2026-05-09 07:00:00'),

-- Pending - chờ thanh toán
('ORD2026050016', 25, 'Hoàng Thị Emly',   '0945678901', 'F05',
   90000, NULL,  0, 0,       90000, 'pending',   NULL,                   '2026-05-09 08:30:00'),

-- Đã hủy (cancelled)
('ORD2026050017', 2,  'Đinh Văn Khải',    '0990123456', 'H01,H02',
  180000, NULL,  0, 0,      180000, 'cancelled', NULL,                   '2026-05-06 15:00:00'),

('ORD2026050018', 13, 'Đặng Thị Giang',   '0967890123', 'E05,E06',
  180000, 'WELCOME10', 10, 18000, 162000, 'cancelled', NULL,            '2026-05-05 11:00:00'),

-- Đã thanh toán - gia đình (Gấu Boonie, 4 vé)
('ORD2026050019', 47, 'Trương Minh Long',  '0912233445', 'D01,D02,D03,D04',
  360000, 'STUDENT25', 25, 90000, 270000, 'paid', '2026-05-08 19:10:00', '2026-05-08 19:00:00'),

-- Đã thanh toán - Phổi Sắt
('ORD2026050020', 55, 'Võ Đức Quân',      '0956677889', 'G10,G11,G12',
  270000, NULL,  0, 0,      270000, 'paid',      '2026-05-09 10:05:00', '2026-05-09 10:00:00');

-- ================================================================
-- 9. VOUCHER USAGES
-- Theo dõi mỗi voucher đã được dùng bởi ai
-- ================================================================

INSERT INTO VoucherUsages (VoucherID, PhoneNumber, OrderCode, UsedAt) VALUES
-- WELCOME10 (VoucherID=2)
(2, '0945678901', 'ORD2026050003', '2026-05-07 20:35:00'),
-- MORTAL50 (VoucherID=3)
(3, '0901234567', 'ORD2026050007', '2026-05-05 09:05:00'),
-- SUMMER2026 (VoucherID=1)
(1, '0901234567', 'ORD2026050010', '2026-05-04 10:05:00'),
-- CGVBDAY30 (VoucherID=4)
(4, '0923456789', 'ORD2026050015', '2026-05-09 07:00:00'),
-- FLASH15 (VoucherID=5)
(5, '0901234567', 'ORD2026050012', '2026-05-08 22:05:00'),
-- STUDENT25 (VoucherID=6)
(6, '0912233445', 'ORD2026050019', '2026-05-08 19:10:00');

-- ================================================================
-- 10. INVALIDATED TICKETS
-- Vé bị vô hiệu hóa: đổi suất, hủy booking, lỗi hệ thống, v.v.
-- ================================================================

INSERT INTO InvalidatedTickets
  (CustomerName, CustomerPhone, BookingCode, MovieTitle, RoomName,
   ScreeningDate, ScreeningTime, SeatNumber, BookedAt, Reason, InvalidatedAt)
VALUES

-- Khách hủy vé (hủy order, vé bị thu hồi)
('Đinh Văn Khải',  '0990123456', 'BC0000INV01',
 'HEO NĂM MÓNG', 'Phòng 1 - Standard',
 '2026-05-08', '11:30:00', 'H01',
 '2026-05-06 15:00:00', 'Khách hủy đặt vé', '2026-05-06 15:05:00'),

('Đinh Văn Khải',  '0990123456', 'BC0000INV02',
 'HEO NĂM MÓNG', 'Phòng 1 - Standard',
 '2026-05-08', '11:30:00', 'H02',
 '2026-05-06 15:00:00', 'Khách hủy đặt vé', '2026-05-06 15:05:00'),

-- Vé bị hủy do đổi suất chiếu (rạp thay đổi lịch)
('Đặng Thị Giang', '0967890123', 'BC0000INV03',
 'MORTAL KOMBAT: CUỘC CHIẾN SINH TỬ II', 'Phòng 4 - 4DX',
 '2026-05-08', '14:30:00', 'E05',
 '2026-05-05 11:00:00', 'Khách hủy đặt vé', '2026-05-05 11:10:00'),

('Đặng Thị Giang', '0967890123', 'BC0000INV04',
 'MORTAL KOMBAT: CUỘC CHIẾN SINH TỬ II', 'Phòng 4 - 4DX',
 '2026-05-08', '14:30:00', 'E06',
 '2026-05-05 11:00:00', 'Khách hủy đặt vé', '2026-05-05 11:10:00'),

-- Vé bị vô hiệu do sự cố kỹ thuật phòng chiếu (phòng 4DX hỏng máy)
('Vũ Đức Phong',   '0956789012', 'BC0000INV05',
 'PHÍ PHÔNG: QUỶ MÁU RỪNG THIÊNG', 'Phòng 4 - 4DX',
 '2026-05-07', '20:00:00', 'A03',
 '2026-05-07 12:00:00', 'Suất chiếu bị hủy do sự cố kỹ thuật', '2026-05-07 17:00:00'),

('Bùi Quốc Huy',   '0978901234', 'BC0000INV06',
 'PHÍ PHÔNG: QUỶ MÁU RỪNG THIÊNG', 'Phòng 4 - 4DX',
 '2026-05-07', '20:00:00', 'B01',
 '2026-05-07 13:00:00', 'Suất chiếu bị hủy do sự cố kỹ thuật', '2026-05-07 17:00:00'),

-- Vé hết hạn (khách không đến xem, quá giờ chiếu)
('Lý Thị Lan',     '0901122334', 'BC0000INV07',
 'ĐẠI TIỆC TRĂNG MÁU 8', 'Phòng 1 - Standard',
 '2026-05-05', '19:00:00', 'J05',
 '2026-05-04 20:00:00', 'Vé không còn khả dụng', '2026-05-05 21:00:00'),

-- Vé trùng do lỗi hệ thống (duplicate booking đã bị catch)
('Trương Minh Long','0912233445','BC0000INV08',
 'GẤU BOONIE: KUNGFU ẨN SĨ', 'Phòng B - Standard',
 '2026-05-09', '12:30:00', 'D01',
 '2026-05-08 19:00:00', 'Phát hiện đặt vé trùng, hoàn tiền tự động', '2026-05-08 19:02:00');

-- ================================================================
-- KIỂM TRA NHANH
-- ================================================================
-- SELECT * FROM vw_daily_screenings WHERE ScreeningDate = '2026-05-09' ORDER BY ScreeningTime;
-- SELECT * FROM vw_available_seats ORDER BY AvailableSeats ASC;
-- SELECT fn_occupancy_rate(10);   -- suất Mortal Kombat IMAX khuya 22:00
-- SELECT fn_total_revenue(10);
>>>>>>> 111d0f6566135f4c40562dbe5c569e0c5fd1be1c
