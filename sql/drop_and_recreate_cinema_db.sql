-- Xóa toàn bộ database cinema_db rồi tạo lại rỗng (mất hết bảng và dữ liệu).
-- Sau đó chạy lại: mysql -u root -p < sql/schema.sql
-- (và sample_data.sql nếu cần dữ liệu mẫu).

DROP DATABASE IF EXISTS cinema_db;
CREATE DATABASE cinema_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
