# Project 08: Movie and Cinema Room Management System

- Quan ly phim, phong chieu, suat chieu, khach hang
- Dat ve va chon ghe
- Bao cao ve da ban, doanh thu, ti le lap day

## 1) Cai dat

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```


## 2) Dung MySQL 

Set bien moi truong `DATABASE_URL` voi driver `mysql-connector-python`:

```bash
set DATABASE_URL=mysql+mysqlconnector://root:password@localhost:3306/cinema_db
set ADMIN_PASSWORD=dngadmin
python app.py
```

Sau do mo trinh duyet:
- Trang khach hang: http://127.0.0.1:5000
- Trang quan tri:   http://127.0.0.1:5000/admin/login

## 4) Cac chuc nang chinh

- `/admin/movies`: Quan ly danh sach phim
- `/admin/rooms`: Quan ly phong chieu va suc chua
- `/admin/screenings`: Quan ly suat chieu theo ngay/gio
- `/admin/customers`: Quan ly khach hang
- `/book/<screening_id>`: Dat ghe cho suat chieu
- `/admin/reports`: Bao cao doanh thu va occupancy

## 5) Khoi tao va seed nhanh

```bash
flask --app app.py init-db
```

```bash
flask --app app.py seed-db
```

`seed-db` se reset DB va tao du lieu mau (phim, phong, khach, suat chieu, ve).

## 6) Script MySQL

Thu muc `sql/` da co:
- `sql/schema.sql`: tao bang + index + view + procedure + function + trigger + phan quyen
- `sql/sample_data.sql`: du lieu mau 10 dong moi bang

Chay tren MySQL Workbench hoac terminal:

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p < sql/sample_data.sql
```

## 7) Phan quyen nguoi dung (Database Security)

File `sql/schema.sql` da tao san 2 user MySQL:

| User           | Mat khau   | Quyen han                                              |
|----------------|------------|--------------------------------------------------------|
| cinema_admin   | Admin@123  | Toan quyen tren cinema_db                              |
| ticket_clerk   | Clerk@123  | Chi duoc xem phim/phong/suat chieu, them khach va ve   |

Kiem tra user da tao:

```sql
SELECT user, host FROM mysql.user WHERE user IN ('cinema_admin', 'ticket_clerk');
```

## 8) Backup va Recovery

### Backup thu cong

Chay lenh sau de backup toan bo database ra file .sql:

```bash
mysqldump -u root -p cinema_db > backup_cinema_db.sql
```

De them ngay thang vao ten file (Windows CMD):

```bat
mysqldump -u root -p cinema_db > backup_%date:~-4,4%%date:~-7,2%%date:~0,2%.sql
```

### Restore tu file backup

```bash
mysql -u root -p cinema_db < backup_cinema_db.sql
```

Neu database chua ton tai, tao truoc roi moi restore:

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS cinema_db CHARACTER SET utf8mb4;"
mysql -u root -p cinema_db < backup_cinema_db.sql
```

### Backup tu dong (Windows Task Scheduler)

Tao file `backup_auto.bat` voi noi dung:

```bat
@echo off
set BACKUP_DIR=C:\cinema_backups
set NGAY=%date:~-4,4%%date:~-7,2%%date:~0,2%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
mysqldump -u root -pYourPassword cinema_db > "%BACKUP_DIR%\cinema_%NGAY%.sql"
echo Backup hoan thanh: cinema_%NGAY%.sql
```

Sau do vao Task Scheduler > Create Basic Task > chon lich chay hang ngay luc 2:00 SA > tro den file backup_auto.bat.

### Chien luoc backup khuyen nghi

| Loai backup          | Tan suat   | Thoi gian giu lai    |
|----------------------|------------|----------------------|
| Backup day du        | Hang ngay  | 7 ngay gan nhat      |
| Backup truoc deploy  | Moi lan    | Vinh vien            |

## 9) Import phim tu JSON (poster + trang thai)

Do CGV co the chan truy cap tu dong theo tung moi truong mang, app co san bo import:

1. Sua file `data/cgv_movies.json` theo mau:
   - `title`
   - `genre`
   - `duration_minutes`
   - `release_status` (`now_showing` hoac `coming_soon`)
   - `poster_url`
2. Chay lenh:

```bash
flask --app app.py import-cgv-json
```

Luu y: Sau khi thay doi model, neu DB cu da tao truoc do thi nen chay lai:

```bash
flask --app app.py seed-db
```
