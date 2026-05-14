# 🎬 NMO Cinemas — Movie & Cinema Room Management System

> **Project 08 — Database Management Systems**
> National Economics University · Faculty of Mathematical Economics
> Student: Nguyen Thi Duong · ID: 11245866 · Class: DSEB66B · Instructor: PhD. Tran Hung
---
## 🎥 Demo Video

[![Watch the demo](https://img.shields.io/badge/YouTube-Demo%20Video-red?logo=youtube)](YOUR_YOUTUBE_LINK_HERE)

View the full project representation video at: [YouTube Link]([YOUR_YOUTUBE_LINK_HERE](https://youtu.be/U3AR-BR3WGs))

## Tech Stack

| Layer | Technology |
|---|---|
| Database | MySQL 8.x |
| Backend | Python 3.12 + Flask 3.x |
| ORM | Flask-SQLAlchemy |
| Frontend | HTML5, CSS3, Bootstrap 5 |
| Payment | VietQR + SePay API |

---

## Project Structure

```
Project-08-Movie-and-Cinema-Room-Management-System/
├── sql/
│   ├── schema.sql          # Tables, views, indexes, SP, UDFs, trigger, user grants
│   └── sample_data.sql     # Seed data for all 12 tables          # Tables, views, indexes, SP, UDFs, trigger, user grants
│   └── ERDiagram.png   
├── static/
│   └── style.css
├── templates/              # Jinja2 HTML templates (public + admin)
├── app.py                  # Flask app — models, routes, business logic
├── requirements.txt
├── start.bat               # One-click launcher (Windows)
└── README.md
```

---

## Installation

### 1. Clone

```bash
git clone https://github.com/dngy-dot/Project-08-Movie-and-Cinema-Room-Management-System.git
cd Project-08-Movie-and-Cinema-Room-Management-System
```

### 2. Set up database

Run the two SQL files **in order** in MySQL Workbench or terminal:

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p < sql/sample_data.sql
```

### 3. Run

**Windows — double-click `start.bat`** (auto-creates venv, installs deps, starts server)

**Manual:**

```bash
python -m venv .venv
.venv\Scripts\activate        # Mac/Linux: source .venv/bin/activate
pip install -r requirements.txt

set DATABASE_URL=mysql+mysqlconnector://root:password@127.0.0.1:3306/cinema_db
set ADMIN_PASSWORD=your_password

python app.py
```

Open `http://127.0.0.1:5000`

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DATABASE_URL` | `mysql+mysqlconnector://root@127.0.0.1:3306/cinema_db` | SQLAlchemy DB URI |
| `ADMIN_PASSWORD` | `dngadmin` | Admin dashboard password |
| `SECRET_KEY` | `dev-key` | Flask session key |

---

## Database Users

Created automatically by `schema.sql`:

| User | Password | Privileges |
|---|---|---|
| `cinema_admin` | `Admin@123` | ALL PRIVILEGES on `cinema_db.*` |
| `ticket_clerk` | `Clerk@123` | SELECT on reference tables; SELECT + INSERT on customers/tickets only |

---

## Usage

### 🌐 Public Interface — `http://127.0.0.1:5000`

**Browse & book as a guest:**
1. Open the homepage → browse now-showing and coming-soon movies
2. Click a movie → select a screening date and time
3. Register an account at `/register` to proceed to booking
4. Select seats on the interactive seat map
5. Enter your details, apply a voucher code (optional), and confirm
6. Scan the VietQR code to complete payment → receive your booking codes

**Demo member account** (created via `/register` — use any phone not in sample data):
> Register at `http://127.0.0.1:5000/register` with any name, phone, and password.


---

### 🔧 Admin Dashboard — `http://127.0.0.1:5000/admin/login`

**Login credentials:**

| Field | Value |
|---|---|
| Password | `dngadmin` (or the value set in `ADMIN_PASSWORD`) |

**What you can do:**
- **Movies** — add, edit, delete movies; upload poster URLs
- **Cinemas / Rooms** — manage branches and screening rooms
- **Screenings** — assign movies to rooms at specific dates and times
- **Vouchers** — create discount codes and view usage history
- **Reports** — view occupancy rate and revenue per screening
- **Settings** — configure ticket price, VietQR bank details, SePay API key

---

### 🗄️ MySQL Direct Access

Connect as `ticket_clerk` to verify role-based access control:

```bash
mysql -u ticket_clerk -p'Clerk@123' cinema_db
```

```sql
-- Allowed: read reference data
SELECT * FROM movies LIMIT 5;

-- Blocked: write operations raise Access Denied
DELETE FROM movies WHERE MovieID = 1;   -- ERROR 1142
UPDATE screenings SET ScreeningDate = '2026-01-01';  -- ERROR 1142
```

---

## References

1. [Flask Documentation](https://flask.palletsprojects.com)
2. [SQLAlchemy ORM](https://docs.sqlalchemy.org)
3. [MySQL 8.0 Reference Manual](https://dev.mysql.com/doc/refman/8.0/en/)
4. [VietQR API](https://www.vietqr.io/danh-sach-api)
5. [SePay API](https://my.sepay.vn)
6. [Bootstrap 5](https://getbootstrap.com/docs/5.3/)
