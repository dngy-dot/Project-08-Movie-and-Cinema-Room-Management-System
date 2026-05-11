from __future__ import annotations

import os
import random
import string
import base64
import io
from datetime import date, datetime, time, timedelta

from flask import Flask, abort, flash, jsonify, redirect, render_template, request, session, url_for
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
from sqlalchemy import UniqueConstraint, func, inspect, text
from werkzeug.security import check_password_hash, generate_password_hash
import qrcode
import requests


app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY", "dev-key")
# Cấu trúc: mysql+mysqlconnector://[username]:[password]@[host]/[database_name]
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv(
    "DATABASE_URL",
    "mysql+mysqlconnector://root@127.0.0.1:3306/cinema_db",
)
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_pre_ping": True,
}
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# ── Admin auth ──────────────────────────────────────────────
from functools import wraps

def admin_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if not session.get("is_admin"):
            flash("Vui lòng đăng nhập để vào trang quản trị.", "warning")
            return redirect(url_for("admin_login"))
        return f(*args, **kwargs)
    return decorated

@app.route("/admin/login", methods=["GET", "POST"])
def admin_login():
    if session.get("is_admin"):
        return redirect(url_for("movies"))
    if request.method == "POST":
        password = request.form.get("password", "").strip()
        admin_pw = os.getenv("ADMIN_PASSWORD", "admin123")
        if password == admin_pw:
            session["is_admin"] = True
            flash("Đăng nhập admin thành công.", "success")
            return redirect(url_for("movies"))
        flash("Sai mật khẩu.", "danger")
    return render_template("admin_login.html")

@app.route("/admin/logout")
def admin_logout():
    session.pop("is_admin", None)
    flash("Đã đăng xuất khỏi trang quản trị.", "success")
    return redirect(url_for("index"))
# ────────────────────────────────────────────────────────────

DEFAULT_TICKET_PRICE = 90000
SCHEMA_CHECKED = False


class Cinema(db.Model):
    __tablename__ = "cinemas"

    id = db.Column("CinemaID", db.Integer, primary_key=True)
    cinema_name = db.Column("CinemaName", db.String(150), nullable=False, unique=True, index=True)
    address = db.Column("Address", db.String(255), nullable=True)


class Movie(db.Model):
    __tablename__ = "movies"

    id = db.Column("MovieID", db.Integer, primary_key=True)
    title = db.Column("MovieTitle", db.String(255), nullable=False, index=True)
    genre = db.Column("Genre", db.String(100), nullable=False)
    duration_minutes = db.Column("DurationMinutes", db.Integer, nullable=False)
    poster_url = db.Column("PosterURL", db.String(500), nullable=True)
    release_status = db.Column("ReleaseStatus", db.String(20), nullable=False, default="now_showing")


class CinemaRoom(db.Model):
    __tablename__ = "cinemarooms"

    id = db.Column("RoomID", db.Integer, primary_key=True)
    cinema_id = db.Column(
        "CinemaID", db.Integer, db.ForeignKey("cinemas.CinemaID"), nullable=False, index=True
    )
    room_name = db.Column("RoomName", db.String(100), nullable=False, unique=True)
    capacity = db.Column("Capacity", db.Integer, nullable=False)

    cinema = db.relationship("Cinema", backref="rooms")


class Screening(db.Model):
    __tablename__ = "screenings"

    id = db.Column("ScreeningID", db.Integer, primary_key=True)
    movie_id = db.Column(
        "MovieID", db.Integer, db.ForeignKey("movies.MovieID"), nullable=False
    )
    room_id = db.Column(
        "RoomID", db.Integer, db.ForeignKey("cinemarooms.RoomID"), nullable=False
    )
    screening_date = db.Column("ScreeningDate", db.Date, nullable=False, index=True)
    screening_time = db.Column("ScreeningTime", db.Time, nullable=False, index=True)

    movie = db.relationship("Movie", backref="screenings")
    room = db.relationship("CinemaRoom", backref="screenings")


class Customer(db.Model):
    __tablename__ = "customers"

    id = db.Column("CustomerID", db.Integer, primary_key=True)
    name = db.Column("CustomerName", db.String(150), nullable=False)
    phone = db.Column("PhoneNumber", db.String(30), nullable=False, unique=True)


class Member(db.Model):
    __tablename__ = "members"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(150), nullable=False)
    phone = db.Column(db.String(30), nullable=False, unique=True, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)


MEMBER_TIERS = [
    {"code": "basic", "label": "Thành viên thường", "min_spent": 0},
    {"code": "gold", "label": "Vàng", "min_spent": 1_000_000},
    {"code": "platinum", "label": "Bạch kim", "min_spent": 3_000_000},
    {"code": "diamond", "label": "Kim cương", "min_spent": 5_000_000},
]

MEMBER_BENEFITS = {
    "basic": [
        "Tích lũy điểm cho mỗi đơn vé đã thanh toán.",
        "Nhận thông báo lịch chiếu và ưu đãi mới.",
    ],
    "gold": [
        "Ưu tiên nhận voucher giảm giá định kỳ.",
        "Ưu đãi combo bắp nước trong một số khung giờ.",
    ],
    "platinum": [
        "Tăng mức hoàn điểm cho mỗi đơn hàng.",
        "Ưu tiên chọn chỗ trong sự kiện mở bán sớm.",
    ],
    "diamond": [
        "Ưu đãi cao nhất cho vé và combo theo chương trình.",
        "Quà tặng sinh nhật và ưu tiên hỗ trợ thành viên.",
    ],
}


class Ticket(db.Model):
    __tablename__ = "tickets"

    id = db.Column("TicketID", db.Integer, primary_key=True)
    customer_id = db.Column(
        "CustomerID", db.Integer, db.ForeignKey("customers.CustomerID"), nullable=False
    )
    screening_id = db.Column(
        "ScreeningID",
        db.Integer,
        db.ForeignKey("screenings.ScreeningID"),
        nullable=False,
        index=True,
    )
    seat_number = db.Column("SeatNumber", db.String(10), nullable=False)
    booking_code = db.Column("BookingCode", db.String(12), nullable=False, unique=True, index=True)
    booked_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    customer = db.relationship("Customer", backref="tickets")
    screening = db.relationship("Screening", backref="tickets")

    __table_args__ = (UniqueConstraint("ScreeningID", "SeatNumber", name="uq_seat"),)


class PaymentOrder(db.Model):
    __tablename__ = "payment_orders"

    id = db.Column(db.Integer, primary_key=True)
    order_code = db.Column(db.String(16), nullable=False, unique=True, index=True)
    screening_id = db.Column(
        db.Integer, db.ForeignKey("screenings.ScreeningID"), nullable=False, index=True
    )
    customer_name = db.Column(db.String(150), nullable=False)
    customer_phone = db.Column(db.String(30), nullable=False, index=True)
    seat_numbers = db.Column(db.String(300), nullable=False)
    original_amount = db.Column(db.Integer, nullable=False, default=0)
    voucher_code = db.Column(db.String(30), nullable=True, index=True)
    discount_percent = db.Column(db.Integer, nullable=False, default=0)
    discount_amount = db.Column(db.Integer, nullable=False, default=0)
    total_amount = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), nullable=False, default="pending", index=True)
    paid_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    screening = db.relationship("Screening")


class Voucher(db.Model):
    __tablename__ = "vouchers"

    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(30), nullable=False, unique=True, index=True)
    discount_percent = db.Column(db.Integer, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)


class VoucherUsage(db.Model):
    __tablename__ = "voucher_usages"

    id = db.Column(db.Integer, primary_key=True)
    voucher_id = db.Column(
        db.Integer, db.ForeignKey("vouchers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    phone_number = db.Column(db.String(30), nullable=False, index=True)
    order_code = db.Column(db.String(16), nullable=False, unique=True, index=True)
    used_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    voucher = db.relationship("Voucher", backref="usages")
    __table_args__ = (UniqueConstraint("voucher_id", "phone_number", name="uq_voucher_phone"),)


class InvalidatedTicket(db.Model):
    __tablename__ = "invalidated_tickets"

    id = db.Column(db.Integer, primary_key=True)
    customer_name = db.Column(db.String(150), nullable=False)
    customer_phone = db.Column(db.String(30), nullable=False, index=True)
    booking_code = db.Column(db.String(12), nullable=False, unique=True, index=True)
    movie_title = db.Column(db.String(255), nullable=False)
    room_name = db.Column(db.String(100), nullable=False)
    screening_date = db.Column(db.Date, nullable=False)
    screening_time = db.Column(db.Time, nullable=False)
    seat_number = db.Column(db.String(10), nullable=False)
    booked_at = db.Column(db.DateTime, nullable=False)
    reason = db.Column(db.String(255), nullable=False, default="Vé không còn khả dụng")
    invalidated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)


class AppSetting(db.Model):
    __tablename__ = "app_settings"

    id = db.Column(db.Integer, primary_key=True)
    key = db.Column(db.String(100), nullable=False, unique=True, index=True)
    value = db.Column(db.Text, nullable=True)


def build_seat_map(capacity: int) -> list[str]:
    seats = []
    for i in range(capacity):
        row = chr(65 + (i // 10))
        col = (i % 10) + 1
        seats.append(f"{row}{col}")
    return seats


def generate_booking_code() -> str:
    while True:
        code = "BK" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))
        exists = Ticket.query.filter_by(booking_code=code).first()
        if not exists:
            return code


def generate_order_code() -> str:
    while True:
        code = "OD" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))
        exists = PaymentOrder.query.filter_by(order_code=code).first()
        if not exists:
            return code


def generate_voucher_code() -> str:
    while True:
        code = "VC" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))
        exists = Voucher.query.filter_by(code=code).first()
        if not exists:
            return code


def compute_discount(original_amount: int, discount_percent: int) -> tuple[int, int]:
    discount_percent = max(0, min(100, discount_percent))
    discount_amount = (original_amount * discount_percent) // 100
    final_amount = max(0, original_amount - discount_amount)
    return discount_amount, final_amount


def normalize_phone(raw: str) -> str:
    return (raw or "").strip().replace(" ", "")


def get_current_member() -> Member | None:
    member_id = session.get("member_id")
    if not member_id:
        return None
    return Member.query.get(member_id)


def member_required(view_func):
    @wraps(view_func)
    def wrapped(*args, **kwargs):
        if not get_current_member():
            flash("Vui lòng đăng nhập tài khoản thành viên để đặt vé.", "warning")
            return redirect(url_for("login", next=request.full_path))
        return view_func(*args, **kwargs)

    return wrapped


def compute_member_spent(phone: str) -> int:
    if not phone:
        return 0
    total = (
        db.session.query(func.coalesce(func.sum(PaymentOrder.total_amount), 0))
        .filter(
            PaymentOrder.customer_phone == phone,
            PaymentOrder.status == "paid",
        )
        .scalar()
    )
    return int(total or 0)


def resolve_member_tier(total_spent: int) -> dict:
    chosen = MEMBER_TIERS[0]
    for tier in MEMBER_TIERS:
        if total_spent >= tier["min_spent"]:
            chosen = tier
    return chosen


@app.context_processor
def inject_current_member():
    current_member = get_current_member()
    member_profile = None
    if current_member:
        total_spent = compute_member_spent(current_member.phone)
        member_profile = {
            "total_spent": total_spent,
            "tier": resolve_member_tier(total_spent),
        }
    return {
        "current_member": current_member,
        "member_profile": member_profile,
        "member_tiers": MEMBER_TIERS,
    }


def resolve_voucher_for_phone(raw_code: str, phone: str) -> tuple[Voucher | None, str]:
    code = (raw_code or "").strip().upper()
    if not code:
        return None, ""
    voucher = Voucher.query.filter_by(code=code).first()
    if not voucher:
        return None, "Mã voucher không tồn tại hoặc đã bị xóa."
    used = VoucherUsage.query.filter_by(voucher_id=voucher.id, phone_number=phone).first()
    if used:
        return None, "Số điện thoại này đã dùng mã voucher này trước đó."
    return voucher, ""


def get_setting(key: str, default: str = "") -> str:
    item = AppSetting.query.filter_by(key=key).first()
    if item and item.value is not None:
        return item.value
    return default


def set_setting(key: str, value: str) -> None:
    item = AppSetting.query.filter_by(key=key).first()
    if item is None:
        item = AppSetting(key=key, value=value)
        db.session.add(item)
    else:
        item.value = value


def get_setting_bool(key: str, default: bool = False) -> bool:
    raw = get_setting(key, "1" if default else "0").strip().lower()
    return raw in {"1", "true", "yes", "on"}


def get_ticket_price() -> int:
    raw = get_setting("DEFAULT_TICKET_PRICE", str(DEFAULT_TICKET_PRICE)).strip()
    try:
        value = int(raw)
    except ValueError:
        return DEFAULT_TICKET_PRICE
    return value if value > 0 else DEFAULT_TICKET_PRICE


SWIFT_TO_BIN = {
    "ICBVVNVX": "970415",  # VietinBank
    "BFTVVNVX": "970418",  # BIDV
    "VCBVVNVX": "970436",  # Vietcombank
    "MSCBVNVX": "970422",  # MB
    "VTBKVNVX": "970405",  # Agribank
    "SGBLVNVX": "970403",  # Sacombank
    "EIBVVNVX": "970431",  # Eximbank
    "TCBVVNVX": "970407",  # Techcombank
    "ASCBVNVX": "970416",  # ACB
}


def resolve_bank_bin(bank_code: str) -> str:
    code = (bank_code or "").strip().upper()
    if not code:
        return ""
    if code.isdigit():
        return code
    return SWIFT_TO_BIN.get(code, "")


def parse_selected_seats(seats_raw: str) -> list[str]:
    items = [s.strip().upper() for s in seats_raw.split(",") if s.strip()]
    unique_items = []
    seen = set()
    for s in items:
        if s not in seen:
            seen.add(s)
            unique_items.append(s)
    return unique_items


def build_payment_qr_base64(order_code: str, amount: int, customer_phone: str) -> str:
    payload = (
        f"PAYMENT|RAP_PHIM_TRUC_TUYEN|ORDER:{order_code}|"
        f"AMOUNT:{amount}|PHONE:{customer_phone}"
    )
    qr = qrcode.QRCode(version=1, box_size=8, border=2)
    qr.add_data(payload)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    return base64.b64encode(buffer.getvalue()).decode("utf-8")


def build_vietqr_url(order_code: str, amount: int) -> str | None:
    bank_code = get_setting("VIETQR_BANK_CODE", "").strip()
    if not bank_code:
        bank_code = get_setting("VIETQR_BANK_BIN", os.getenv("VIETQR_BANK_BIN", "")).strip()
    bank_bin = resolve_bank_bin(bank_code)
    account_number = get_setting(
        "VIETQR_ACCOUNT_NUMBER", os.getenv("VIETQR_ACCOUNT_NUMBER", "")
    ).strip()
    account_name = get_setting(
        "VIETQR_ACCOUNT_NAME", os.getenv("VIETQR_ACCOUNT_NAME", "")
    ).strip()
    template = (
        get_setting("VIETQR_TEMPLATE", os.getenv("VIETQR_TEMPLATE", "compact2")).strip()
        or "compact2"
    )
    if not bank_bin or not account_number:
        return None

    # SePay (VietinBank) requires transfer content to start with SEVQR.
    # Keep order_code in content so automatic matching can identify exact order.
    add_info = f"SEVQR {order_code}"
    return (
        f"https://img.vietqr.io/image/{bank_bin}-{account_number}-{template}.png"
        f"?amount={amount}&addInfo={requests.utils.quote(add_info)}"
        f"&accountName={requests.utils.quote(account_name)}"
    )


def split_csv_values(raw: str) -> list[str]:
    return [item.strip() for item in raw.split(",") if item.strip()]


def parse_transaction_time(tx: dict) -> datetime | None:
    # SePay payload can vary by account type/endpoints.
    candidates = [
        tx.get("transaction_date"),
        tx.get("transaction_time"),
        tx.get("created_at"),
        tx.get("createdAt"),
        tx.get("time"),
    ]
    for value in candidates:
        if not value:
            continue
        s = str(value).strip()
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%d/%m/%Y %H:%M:%S"):
            try:
                return datetime.strptime(s[:19], fmt)
            except ValueError:
                continue
    return None


def extract_sepay_payload(data: dict) -> dict:
    # Normalize common SePay API response shapes.
    payload = data or {}
    if "data" in payload and isinstance(payload["data"], dict):
        payload = payload["data"]

    content = (
        str(
            payload.get("transaction_content")
            or payload.get("description")
            or payload.get("content")
            or ""
        )
        .strip()
    )
    amount_raw = payload.get("amount_in") or payload.get("amount") or 0
    try:
        amount = int(float(amount_raw))
    except Exception:
        amount = 0

    account_number = str(
        payload.get("account_number")
        or payload.get("accountNo")
        or payload.get("bank_account")
        or ""
    ).strip()

    tx_time = parse_transaction_time(payload)
    return {
        "content": content,
        "amount": amount,
        "account_number": account_number,
        "tx_time": tx_time,
    }


def finalize_order(order: PaymentOrder) -> bool:
    if order.status == "paid":
        return True

    screening = Screening.query.get(order.screening_id)
    if not screening:
        return False

    seats = parse_selected_seats(order.seat_numbers)
    room_seats = build_seat_map(screening.room.capacity)
    if any(seat not in room_seats for seat in seats):
        return False

    existing = {
        t.seat_number
        for t in Ticket.query.filter(
            Ticket.screening_id == screening.id,
            Ticket.seat_number.in_(seats),
        ).all()
    }
    if existing:
        return False

    customer = Customer.query.filter_by(phone=order.customer_phone).first()
    if customer is None:
        customer = Customer(name=order.customer_name, phone=order.customer_phone)
        db.session.add(customer)
        db.session.flush()
    else:
        customer.name = order.customer_name

    for seat_number in seats:
        db.session.add(
            Ticket(
                customer_id=customer.id,
                screening_id=screening.id,
                seat_number=seat_number,
                booking_code=generate_booking_code(),
            )
        )

    if order.voucher_code:
        voucher = Voucher.query.filter_by(code=order.voucher_code).first()
        if voucher:
            used = VoucherUsage.query.filter_by(
                voucher_id=voucher.id, phone_number=order.customer_phone
            ).first()
            if used:
                return False
            db.session.add(
                VoucherUsage(
                    voucher_id=voucher.id,
                    phone_number=order.customer_phone,
                    order_code=order.order_code,
                )
            )

    order.status = "paid"
    order.paid_at = datetime.utcnow()
    db.session.commit()
    return True


def maybe_auto_confirm_with_sepay(order: PaymentOrder) -> bool:
    if order.status == "paid":
        return True

    api_key = get_setting("SEPAY_API_KEY", os.getenv("SEPAY_API_KEY", "")).strip()
    if not api_key:
        return False

    endpoint = get_setting(
        "SEPAY_API_URL",
        os.getenv("SEPAY_API_URL", "https://my.sepay.vn/userapi/transactions/list"),
    ).strip()
    headers = {"Authorization": f"Bearer {api_key}"}
    params = {"limit": 30}
    try:
        response = requests.get(endpoint, headers=headers, params=params, timeout=8)
        response.raise_for_status()
        payload = response.json()
    except Exception:
        return False

    tx_list = payload.get("transactions") or payload.get("data") or []
    marker = order.order_code.upper()
    fallback_candidates = []
    for tx in tx_list:
        normalized = extract_sepay_payload(tx)
        content = normalized["content"].upper()
        amount = normalized["amount"]
        tx_time = normalized["tx_time"]
        if marker in content and amount >= order.total_amount:
            return finalize_order(order)
        # Fallback mode for fixed transfer content (e.g. "SEVQR")
        if amount == order.total_amount:
            if tx_time is None or tx_time >= (order.created_at - timedelta(minutes=2)):
                fallback_candidates.append(tx)

    if get_setting_bool("SEPAY_FALLBACK_MATCH", False):
        # Safety guard: only fallback if this amount is unique among pending recent orders.
        pending_same_amount = (
            PaymentOrder.query.filter(
                PaymentOrder.status == "pending",
                PaymentOrder.total_amount == order.total_amount,
                PaymentOrder.created_at >= (datetime.utcnow() - timedelta(minutes=30)),
            )
            .count()
        )
        if pending_same_amount == 1 and fallback_candidates:
            return finalize_order(order)
    return False


def ensure_voucher_schema() -> None:
    """Tạo bảng voucher hoặc bổ sung cột thiếu (DB dump cũ: có bảng nhưng thiếu discount_percent...)."""
    engine = db.engine
    insp = inspect(engine)
    vtab, utab = Voucher.__tablename__, VoucherUsage.__tablename__

    if not insp.has_table(vtab):
        Voucher.__table__.create(bind=engine, checkfirst=True)
        db.session.commit()
    else:
        col_names = {c["name"].lower() for c in insp.get_columns(vtab)}
        if "discount_percent" not in col_names:
            db.session.execute(
                text(
                    f"ALTER TABLE {vtab} ADD COLUMN discount_percent INTEGER NOT NULL DEFAULT 0"
                )
            )
            db.session.commit()
        col_names = {c["name"].lower() for c in inspect(engine).get_columns(vtab)}
        if "created_at" not in col_names:
            db.session.execute(
                text(
                    f"ALTER TABLE {vtab} ADD COLUMN created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
                )
            )
            db.session.commit()

    insp = inspect(engine)
    if not insp.has_table(utab):
        VoucherUsage.__table__.create(bind=engine, checkfirst=True)
        db.session.commit()
    else:
        ucols = {c["name"].lower() for c in insp.get_columns(utab)}
        if "used_at" not in ucols:
            db.session.execute(
                text(
                    f"ALTER TABLE {utab} ADD COLUMN used_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
                )
            )
            db.session.commit()


def ensure_compat_schema() -> None:
    engine = db.engine
    if engine.dialect.name != "sqlite":
        return

    inspector = inspect(engine)
    movie_cols = {col["name"] for col in inspector.get_columns("movies")}
    room_cols = {col["name"] for col in inspector.get_columns("cinemarooms")}
    ticket_cols = {col["name"] for col in inspector.get_columns("tickets")}
    payment_cols = {col["name"] for col in inspector.get_columns("payment_orders")}

    with db.session.begin():
        if "PosterURL" not in movie_cols:
            db.session.execute(text("ALTER TABLE movies ADD COLUMN PosterURL VARCHAR(500)"))
        if "ReleaseStatus" not in movie_cols:
            db.session.execute(
                text("ALTER TABLE movies ADD COLUMN ReleaseStatus VARCHAR(20) DEFAULT 'now_showing'")
            )
        if "CinemaID" not in room_cols:
            db.session.execute(text("ALTER TABLE cinemarooms ADD COLUMN CinemaID INTEGER"))
        if "BookingCode" not in ticket_cols:
            db.session.execute(text("ALTER TABLE tickets ADD COLUMN BookingCode VARCHAR(12)"))
        if "original_amount" not in payment_cols:
            db.session.execute(
                text("ALTER TABLE payment_orders ADD COLUMN original_amount INTEGER DEFAULT 0")
            )
        if "voucher_code" not in payment_cols:
            db.session.execute(
                text("ALTER TABLE payment_orders ADD COLUMN voucher_code VARCHAR(30)")
            )
        if "discount_percent" not in payment_cols:
            db.session.execute(
                text("ALTER TABLE payment_orders ADD COLUMN discount_percent INTEGER DEFAULT 0")
            )
        if "discount_amount" not in payment_cols:
            db.session.execute(
                text("ALTER TABLE payment_orders ADD COLUMN discount_amount INTEGER DEFAULT 0")
            )

    rows = db.session.execute(
        text(
            'SELECT "TicketID" FROM tickets '
            'WHERE "BookingCode" IS NULL OR TRIM("BookingCode") = \'\''
        )
    ).fetchall()
    for row in rows:
        code = "BK" + "".join(random.choices(string.ascii_uppercase + string.digits, k=8))
        db.session.execute(
            text('UPDATE tickets SET "BookingCode" = :code WHERE "TicketID" = :ticket_id'),
            {"code": code, "ticket_id": row[0]},
        )
    if rows:
        db.session.commit()

    db.session.execute(
        text(
            "INSERT INTO cinemas (CinemaName, Address) "
            "SELECT 'NMO Cinema Center', 'Trung tâm thành phố' "
            "WHERE NOT EXISTS (SELECT 1 FROM cinemas)"
        )
    )
    default_cinema_id = db.session.execute(
        text("SELECT CinemaID FROM cinemas ORDER BY CinemaID ASC LIMIT 1")
    ).scalar()
    if default_cinema_id:
        db.session.execute(
            text(
                'UPDATE cinemarooms SET "CinemaID" = :cinema_id '
                'WHERE "CinemaID" IS NULL'
            ),
            {"cinema_id": int(default_cinema_id)},
        )

    db.session.execute(
        text('CREATE INDEX IF NOT EXISTS "ix_tickets_bookingcode" ON tickets("BookingCode")')
    )
    db.session.execute(
        text(
            "CREATE TABLE IF NOT EXISTS invalidated_tickets ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "customer_name VARCHAR(150) NOT NULL, "
            "customer_phone VARCHAR(30) NOT NULL, "
            "booking_code VARCHAR(12) NOT NULL UNIQUE, "
            "movie_title VARCHAR(255) NOT NULL, "
            "room_name VARCHAR(100) NOT NULL, "
            "screening_date DATE NOT NULL, "
            "screening_time TIME NOT NULL, "
            "seat_number VARCHAR(10) NOT NULL, "
            "booked_at DATETIME NOT NULL, "
            "reason VARCHAR(255) NOT NULL DEFAULT 'Vé không còn khả dụng', "
            "invalidated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP"
            ")"
        )
    )
    db.session.execute(
        text(
            "CREATE INDEX IF NOT EXISTS ix_invalidated_tickets_customer_phone "
            "ON invalidated_tickets(customer_phone)"
        )
    )
    db.session.execute(
        text(
            "CREATE INDEX IF NOT EXISTS ix_invalidated_tickets_booking_code "
            "ON invalidated_tickets(booking_code)"
        )
    )
    db.session.execute(
        text(
            "UPDATE payment_orders "
            "SET original_amount = total_amount "
            "WHERE original_amount IS NULL OR original_amount = 0"
        )
    )
    db.session.commit()


@app.before_request
def run_schema_check_once() -> None:
    global SCHEMA_CHECKED
    if not SCHEMA_CHECKED:
        db.create_all()
        ensure_voucher_schema()
        ensure_compat_schema()
        SCHEMA_CHECKED = True


def seed_sample_data() -> None:
    cinemas = [
        Cinema(cinema_name="NMO Quận 1", address="22 Lê Lợi, Quận 1"),
        Cinema(cinema_name="NMO Thủ Đức", address="12 Võ Văn Ngân, Thủ Đức"),
    ]
    movies = [
        Movie(title="Inside Out 2", genre="Animation", duration_minutes=96, release_status="now_showing"),
        Movie(title="The Batman", genre="Action", duration_minutes=176, release_status="now_showing"),
        Movie(title="Dune: Part Two", genre="Sci-Fi", duration_minutes=166, release_status="coming_soon"),
        Movie(title="Project Hail Mary", genre="Sci-Fi", duration_minutes=157, release_status="coming_soon"),
        Movie(title="Super Mario Galaxy", genre="Animation", duration_minutes=99, release_status="now_showing"),
    ]
    customers = [
        Customer(name="Nguyen Van An", phone="0901000001"),
        Customer(name="Tran Thi Binh", phone="0901000002"),
        Customer(name="Le Quang Cuong", phone="0901000003"),
        Customer(name="Pham Thu Dung", phone="0901000004"),
        Customer(name="Hoang Minh Em", phone="0901000005"),
    ]

    db.session.add_all(cinemas + movies + customers)
    db.session.commit()
    rooms = [
        CinemaRoom(cinema_id=cinemas[0].id, room_name="Room A", capacity=50),
        CinemaRoom(cinema_id=cinemas[0].id, room_name="Room B", capacity=40),
        CinemaRoom(cinema_id=cinemas[1].id, room_name="Room C", capacity=60),
    ]
    db.session.add_all(rooms)
    db.session.commit()

    screenings = [
        Screening(
            movie_id=movies[0].id,
            room_id=rooms[0].id,
            screening_date=date.today() + timedelta(days=1),
            screening_time=time(9, 0),
        ),
        Screening(
            movie_id=movies[1].id,
            room_id=rooms[1].id,
            screening_date=date.today() + timedelta(days=1),
            screening_time=time(14, 30),
        ),
        Screening(
            movie_id=movies[2].id,
            room_id=rooms[2].id,
            screening_date=date.today() + timedelta(days=2),
            screening_time=time(19, 0),
        ),
        Screening(
            movie_id=movies[3].id,
            room_id=rooms[0].id,
            screening_date=date.today() + timedelta(days=2),
            screening_time=time(16, 0),
        ),
        Screening(
            movie_id=movies[4].id,
            room_id=rooms[1].id,
            screening_date=date.today() + timedelta(days=3),
            screening_time=time(20, 15),
        ),
    ]
    db.session.add_all(screenings)
    db.session.commit()

    tickets = [
        Ticket(customer_id=customers[0].id, screening_id=screenings[0].id, seat_number="A1", booking_code=generate_booking_code()),
        Ticket(customer_id=customers[1].id, screening_id=screenings[0].id, seat_number="A2", booking_code=generate_booking_code()),
        Ticket(customer_id=customers[2].id, screening_id=screenings[1].id, seat_number="B1", booking_code=generate_booking_code()),
        Ticket(customer_id=customers[3].id, screening_id=screenings[2].id, seat_number="C1", booking_code=generate_booking_code()),
        Ticket(customer_id=customers[4].id, screening_id=screenings[3].id, seat_number="A3", booking_code=generate_booking_code()),
        Ticket(customer_id=customers[0].id, screening_id=screenings[4].id, seat_number="D2", booking_code=generate_booking_code()),
    ]
    db.session.add_all(tickets)
    db.session.commit()


def _movie_lists_for_public_site() -> tuple[list[Movie], list[Movie]]:
    today = datetime.today().date()
    upcoming_boundary = today + timedelta(days=7)
    screenings = (
        Screening.query.join(Movie, Screening.movie_id == Movie.id)
        .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .filter(Screening.screening_date >= today)
        .order_by(Screening.screening_date.asc(), Screening.screening_time.asc())
        .all()
    )

    now_showing_ids = {
        item.movie_id
        for item in screenings
        if item.screening_date <= upcoming_boundary
    }
    coming_soon_ids = {
        item.movie_id
        for item in screenings
        if item.screening_date > upcoming_boundary
    }

    now_showing = Movie.query.filter_by(release_status="now_showing").order_by(Movie.id.desc()).all()
    coming_soon = Movie.query.filter_by(release_status="coming_soon").order_by(Movie.id.desc()).all()

    if not now_showing:
        now_showing = (
            Movie.query.filter(Movie.id.in_(now_showing_ids)).order_by(Movie.id.desc()).all()
            if now_showing_ids
            else Movie.query.order_by(Movie.id.desc()).limit(8).all()
        )
    if not coming_soon:
        coming_soon = (
            Movie.query.filter(Movie.id.in_(coming_soon_ids)).order_by(Movie.id.desc()).all()
            if coming_soon_ids
            else Movie.query.order_by(Movie.id.asc()).limit(4).all()
        )
    return now_showing, coming_soon


def _earliest_screening_date_by_movie(movie_ids: list[int]) -> dict[int, date]:
    if not movie_ids:
        return {}
    rows = (
        db.session.query(Screening.movie_id, func.min(Screening.screening_date))
        .filter(Screening.movie_id.in_(movie_ids))
        .group_by(Screening.movie_id)
        .all()
    )
    return {int(mid): d for mid, d in rows}


@app.route("/")
def index():
    today = datetime.today().date()
    screenings = (
        Screening.query.join(Movie, Screening.movie_id == Movie.id)
        .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .filter(Screening.screening_date >= today)
        .order_by(Screening.screening_date.asc(), Screening.screening_time.asc())
        .all()
    )
    now_showing, coming_soon = _movie_lists_for_public_site()

    return render_template(
        "index.html",
        screenings=screenings,
        now_showing=now_showing,
        coming_soon=coming_soon,
    )


@app.route("/rap")
def cinemas_public():
    cinemas = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    return render_template("cinemas_public.html", cinemas=cinemas)


@app.route("/phim/dang-chieu")
def movies_now_showing():
    now_showing, _coming = _movie_lists_for_public_site()
    ids = [m.id for m in now_showing]
    first_dates = _earliest_screening_date_by_movie(ids)
    return render_template(
        "movies_list.html",
        page_kind="now",
        page_title="Phim đang chiếu",
        movies=now_showing,
        first_screening_dates=first_dates,
    )


@app.route("/phim/sap-chieu")
def movies_coming_soon():
    _now, coming_soon = _movie_lists_for_public_site()
    ids = [m.id for m in coming_soon]
    first_dates = _earliest_screening_date_by_movie(ids)
    return render_template(
        "movies_list.html",
        page_kind="soon",
        page_title="Phim sắp chiếu",
        movies=coming_soon,
        first_screening_dates=first_dates,
    )


@app.route("/movie/<int:movie_id>")
def movie_detail(movie_id: int):
    movie = Movie.query.get_or_404(movie_id)
    today = datetime.today().date()
    screenings = (
        Screening.query.filter(
            Screening.movie_id == movie_id,
            Screening.screening_date >= today,
        )
        .order_by(Screening.screening_date.asc(), Screening.screening_time.asc())
        .all()
    )
    available_dates = sorted({sc.screening_date for sc in screenings})
    selected_date_str = request.args.get("date")
    selected_date = None
    if selected_date_str:
        try:
            selected_date = datetime.strptime(selected_date_str, "%Y-%m-%d").date()
        except ValueError:
            selected_date = None
    if selected_date is None and available_dates:
        selected_date = available_dates[0]

    screenings_by_date = [sc for sc in screenings if sc.screening_date == selected_date]
    available_cinemas = []
    seen_cinema_ids = set()
    for sc in screenings_by_date:
        cid = sc.room.cinema_id
        if cid not in seen_cinema_ids:
            seen_cinema_ids.add(cid)
            available_cinemas.append(sc.room.cinema)

    selected_cinema_id = None
    selected_cinema_raw = request.args.get("cinema_id", "").strip()
    if selected_cinema_raw:
        try:
            selected_cinema_id = int(selected_cinema_raw)
        except ValueError:
            selected_cinema_id = None

    available_cinema_ids = {c.id for c in available_cinemas}
    if selected_cinema_id not in available_cinema_ids:
        selected_cinema_id = available_cinemas[0].id if available_cinemas else None

    filtered_screenings = [
        sc
        for sc in screenings_by_date
        if selected_cinema_id is None or sc.room.cinema_id == selected_cinema_id
    ]
    return render_template(
        "movie_detail.html",
        movie=movie,
        available_dates=available_dates,
        available_cinemas=available_cinemas,
        selected_cinema_id=selected_cinema_id,
        selected_date=selected_date,
        screenings=filtered_screenings,
    )


@app.route("/admin")
@admin_required
def admin_home():
    return redirect(url_for("movies"))


@app.route("/admin/payment-config", methods=["GET", "POST"])
@admin_required
def payment_config():
    if request.method == "POST":
        ticket_price_raw = request.form.get("default_ticket_price", "").strip()
        try:
            ticket_price = int(ticket_price_raw)
            if ticket_price <= 0:
                raise ValueError
        except ValueError:
            flash("Giá vé phải là số nguyên dương.", "danger")
            return redirect(url_for("payment_config"))

        set_setting("DEFAULT_TICKET_PRICE", str(ticket_price))
        set_setting("VIETQR_BANK_CODE", request.form.get("vietqr_bank_code", "").strip())
        set_setting(
            "VIETQR_ACCOUNT_NUMBER", request.form.get("vietqr_account_number", "").strip()
        )
        set_setting("VIETQR_ACCOUNT_NAME", request.form.get("vietqr_account_name", "").strip())
        set_setting(
            "VIETQR_TEMPLATE",
            request.form.get("vietqr_template", "compact2").strip() or "compact2",
        )
        set_setting("SEPAY_API_KEY", request.form.get("sepay_api_key", "").strip())
        set_setting(
            "SEPAY_API_URL",
            request.form.get("sepay_api_url", "").strip()
            or "https://my.sepay.vn/userapi/transactions/list",
        )
        set_setting(
            "SEPAY_FALLBACK_MATCH",
            "1" if request.form.get("sepay_fallback_match") == "on" else "0",
        )
        db.session.commit()
        flash("Đã lưu cấu hình thanh toán.", "success")
        return redirect(url_for("payment_config"))

    data = {
        "vietqr_bank_code": get_setting(
            "VIETQR_BANK_CODE", get_setting("VIETQR_BANK_BIN", os.getenv("VIETQR_BANK_BIN", ""))
        ),
        "vietqr_account_number": get_setting(
            "VIETQR_ACCOUNT_NUMBER", os.getenv("VIETQR_ACCOUNT_NUMBER", "")
        ),
        "vietqr_account_name": get_setting(
            "VIETQR_ACCOUNT_NAME", os.getenv("VIETQR_ACCOUNT_NAME", "")
        ),
        "vietqr_template": get_setting("VIETQR_TEMPLATE", os.getenv("VIETQR_TEMPLATE", "compact2"))
        or "compact2",
        "sepay_api_key": get_setting("SEPAY_API_KEY", os.getenv("SEPAY_API_KEY", "")),
        "sepay_api_url": get_setting(
            "SEPAY_API_URL", os.getenv("SEPAY_API_URL", "https://my.sepay.vn/userapi/transactions/list")
        ),
        "sepay_fallback_match": get_setting_bool("SEPAY_FALLBACK_MATCH", False),
        "default_ticket_price": get_ticket_price(),
    }
    return render_template("payment_config.html", config=data)


@app.route("/admin/cinemas", methods=["GET", "POST"])
@admin_required
def cinemas():
    if request.method == "POST":
        cinema = Cinema(
            cinema_name=request.form["cinema_name"].strip(),
            address=request.form.get("address", "").strip() or None,
        )
        db.session.add(cinema)
        try:
            db.session.commit()
            flash("Thêm rạp thành công.", "success")
        except IntegrityError:
            db.session.rollback()
            flash("Tên rạp đã tồn tại.", "danger")
        return redirect(url_for("cinemas"))

    return render_template("cinemas.html", cinemas=Cinema.query.order_by(Cinema.id.desc()).all())


@app.route("/admin/cinemas/<int:cinema_id>/edit", methods=["GET", "POST"])
@admin_required
def edit_cinema(cinema_id: int):
    cinema = Cinema.query.get_or_404(cinema_id)
    if request.method == "POST":
        cinema.cinema_name = request.form["cinema_name"].strip()
        cinema.address = request.form.get("address", "").strip() or None
        try:
            db.session.commit()
            flash("Cập nhật rạp thành công.", "success")
            return redirect(url_for("cinemas"))
        except IntegrityError:
            db.session.rollback()
            flash("Tên rạp đã tồn tại.", "danger")
    return render_template("cinema_edit.html", cinema=cinema)


@app.route("/admin/cinemas/<int:cinema_id>/delete", methods=["POST"])
@admin_required
def delete_cinema(cinema_id: int):
    cinema = Cinema.query.get_or_404(cinema_id)
    if cinema.rooms:
        flash("Không thể xóa rạp vì vẫn còn phòng chiếu.", "danger")
        return redirect(url_for("cinemas"))
    db.session.delete(cinema)
    db.session.commit()
    flash("Xóa rạp thành công.", "success")
    return redirect(url_for("cinemas"))


@app.route("/admin/payment-config/test-sepay", methods=["POST"])
@admin_required
def test_sepay():
    api_key = request.form.get("sepay_api_key", "").strip() or get_setting(
        "SEPAY_API_KEY", os.getenv("SEPAY_API_KEY", "")
    ).strip()
    api_url = request.form.get("sepay_api_url", "").strip() or get_setting(
        "SEPAY_API_URL",
        os.getenv("SEPAY_API_URL", "https://my.sepay.vn/userapi/transactions/list"),
    ).strip()

    if not api_key:
        flash("Thiếu SePay API Key để kiểm tra.", "danger")
        return redirect(url_for("payment_config"))

    try:
        response = requests.get(
            api_url,
            headers={"Authorization": f"Bearer {api_key}"},
            params={"limit": 1},
            timeout=8,
        )
        if response.status_code == 200:
            payload = response.json()
            tx_list = payload.get("transactions") or payload.get("data") or []
            flash(
                f"Test SePay thành công. API hoạt động, lấy được {len(tx_list)} giao dịch mẫu.",
                "success",
            )
        elif response.status_code in (401, 403):
            flash("Test SePay thất bại: API Key không hợp lệ hoặc không có quyền.", "danger")
        else:
            flash(
                f"Test SePay thất bại: HTTP {response.status_code}. Vui lòng kiểm tra lại API URL.",
                "danger",
            )
    except requests.RequestException as exc:
        flash(f"Không thể kết nối SePay: {exc}", "danger")

    return redirect(url_for("payment_config"))


@app.route("/admin/vouchers", methods=["GET", "POST"])
@admin_required
def admin_vouchers():
    if request.method == "POST":
        discount_raw = request.form.get("discount_percent", "").strip()
        try:
            discount_percent = int(discount_raw)
            if discount_percent <= 0 or discount_percent > 100:
                raise ValueError
        except ValueError:
            flash("Phần trăm giảm phải là số nguyên từ 1 đến 100.", "danger")
            return redirect(url_for("admin_vouchers"))

        voucher = Voucher(code=generate_voucher_code(), discount_percent=discount_percent)
        db.session.add(voucher)
        db.session.commit()
        flash(f"Đã tạo voucher {voucher.code} giảm {discount_percent}%.", "success")
        return redirect(url_for("admin_vouchers"))

    vouchers = Voucher.query.order_by(Voucher.created_at.desc()).all()
    usage_counts = {
        item.voucher_id: item.total
        for item in db.session.query(
            VoucherUsage.voucher_id, func.count(VoucherUsage.id).label("total")
        )
        .group_by(VoucherUsage.voucher_id)
        .all()
    }
    return render_template("admin_vouchers.html", vouchers=vouchers, usage_counts=usage_counts)


@app.route("/admin/vouchers/<int:voucher_id>/delete", methods=["POST"])
@admin_required
def delete_voucher(voucher_id: int):
    voucher = Voucher.query.get_or_404(voucher_id)
    VoucherUsage.query.filter_by(voucher_id=voucher.id).delete()
    db.session.delete(voucher)
    db.session.commit()
    flash("Đã xóa voucher. Mã không còn hiệu lực.", "success")
    return redirect(url_for("admin_vouchers"))


@app.route("/admin/movies", methods=["GET", "POST"])
@admin_required
def movies():
    if request.method == "POST":
        try:
            duration = int(request.form["duration_minutes"])
            if duration <= 0:
                raise ValueError
        except ValueError:
            flash("Thời lượng phim phải là số nguyên dương.", "danger")
            return redirect(url_for("movies"))
        movie = Movie(
            title=request.form["title"].strip(),
            genre=request.form["genre"].strip(),
            duration_minutes=duration,
            poster_url=request.form.get("poster_url", "").strip() or None,
            release_status=request.form.get("release_status", "now_showing"),
            )
        db.session.add(movie)
        db.session.commit()
        flash("Thêm phim thành công.", "success")
        return redirect(url_for("movies"))

    return render_template(
        "movies.html", movies=Movie.query.order_by(Movie.id.desc()).all()
    )


@app.route("/admin/movies/<int:movie_id>/edit", methods=["GET", "POST"])
@admin_required
def edit_movie(movie_id: int):
    movie = Movie.query.get_or_404(movie_id)
    if request.method == "POST":
        movie.title = request.form["title"].strip()
        movie.genre = request.form["genre"].strip()
        movie.duration_minutes = int(request.form["duration_minutes"])
        movie.poster_url = request.form.get("poster_url", "").strip() or None
        movie.release_status = request.form.get("release_status", "now_showing")
        db.session.commit()
        flash("Cập nhật phim thành công.", "success")
        return redirect(url_for("movies"))
    return render_template("movie_edit.html", movie=movie)


@app.route("/admin/movies/<int:movie_id>/delete", methods=["POST"])
@admin_required
def delete_movie(movie_id: int):
    movie = Movie.query.get_or_404(movie_id)
    try:
        screenings = Screening.query.filter_by(movie_id=movie.id).all()
        screening_ids = [item.id for item in screenings]
        if screening_ids:
            tickets = (
                Ticket.query.join(Customer, Ticket.customer_id == Customer.id)
                .join(Screening, Ticket.screening_id == Screening.id)
                .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
                .filter(Ticket.screening_id.in_(screening_ids))
                .all()
            )
            for t in tickets:
                db.session.add(
                    InvalidatedTicket(
                        customer_name=t.customer.name,
                        customer_phone=t.customer.phone,
                        booking_code=t.booking_code,
                        movie_title=movie.title,
                        room_name=t.screening.room.room_name,
                        screening_date=t.screening.screening_date,
                        screening_time=t.screening.screening_time,
                        seat_number=t.seat_number,
                        booked_at=t.booked_at,
                        reason="Suất chiếu đã bị hủy do phim bị xóa.",
                    )
                )

            PaymentOrder.query.filter(PaymentOrder.screening_id.in_(screening_ids)).delete(
                synchronize_session=False
            )
            Ticket.query.filter(Ticket.screening_id.in_(screening_ids)).delete(
                synchronize_session=False
            )
            Screening.query.filter(Screening.id.in_(screening_ids)).delete(
                synchronize_session=False
            )

        db.session.delete(movie)
        db.session.commit()
        flash("Đã xóa phim và toàn bộ suất chiếu/vé liên quan.", "success")
    except IntegrityError:
        db.session.rollback()
        flash("Không thể xóa phim do có dữ liệu liên quan chưa xử lý được.", "danger")
    return redirect(url_for("movies"))


@app.route("/admin/rooms", methods=["GET", "POST"])
@admin_required
def rooms():
    cinemas_list = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    if request.method == "POST":
        try:
            capacity = int(request.form["capacity"])
            if capacity <= 0:
                raise ValueError
        except ValueError:
            flash("Sức chứa phòng phải là số nguyên dương.", "danger")
            return redirect(url_for("rooms"))

        room = CinemaRoom(
            cinema_id=int(request.form["cinema_id"]),
            room_name=request.form["room_name"].strip(),
            capacity=capacity,
            )
        
        db.session.add(room)
        db.session.commit()
        flash("Thêm phòng thành công.", "success")
        return redirect(url_for("rooms"))

    return render_template(
        "rooms.html",
        rooms=CinemaRoom.query.order_by(CinemaRoom.id.desc()).all(),
        cinemas=cinemas_list,
    )


@app.route("/admin/rooms/<int:room_id>/edit", methods=["GET", "POST"])
@admin_required
def edit_room(room_id: int):
    room = CinemaRoom.query.get_or_404(room_id)
    cinemas_list = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    if request.method == "POST":
        room.cinema_id = int(request.form["cinema_id"])
        room.room_name = request.form["room_name"].strip()
        room.capacity = int(request.form["capacity"])
        try:
            db.session.commit()
            flash("Cập nhật phòng thành công.", "success")
            return redirect(url_for("rooms"))
        except IntegrityError:
            db.session.rollback()
            flash("Tên phòng đã tồn tại.", "danger")
    return render_template("room_edit.html", room=room, cinemas=cinemas_list)


@app.route("/admin/rooms/<int:room_id>/delete", methods=["POST"])
@admin_required
def delete_room(room_id: int):
    room = CinemaRoom.query.get_or_404(room_id)
    try:
        db.session.delete(room)
        db.session.commit()
        flash("Xóa phòng thành công.", "success")
    except IntegrityError:
        db.session.rollback()
        flash("Không thể xóa phòng vì đã có suất chiếu liên quan.", "danger")
    return redirect(url_for("rooms"))


@app.route("/admin/customers", methods=["GET", "POST"])
@admin_required
def customers():
    if request.method == "POST":
        customer = Customer(
            name=request.form["name"].strip(),
            phone=request.form["phone"].strip(),
        )
        db.session.add(customer)
        db.session.commit()
        flash("Thêm khách hàng thành công.", "success")
        return redirect(url_for("customers"))

    members = Member.query.order_by(Member.created_at.desc()).all()
    member_rows = []
    member_by_phone = {}
    for member in members:
        total_spent = compute_member_spent(member.phone)
        tier = resolve_member_tier(total_spent)
        row = {
            "member": member,
            "total_spent": total_spent,
            "tier": tier,
        }
        member_rows.append(row)
        member_by_phone[member.phone] = row

    customers_data = []
    for customer in Customer.query.order_by(Customer.id.desc()).all():
        matched_member = member_by_phone.get(customer.phone)
        if matched_member:
            total_spent = matched_member["total_spent"]
            tier = matched_member["tier"]
            member_name = matched_member["member"].name
        else:
            total_spent = compute_member_spent(customer.phone)
            tier = resolve_member_tier(total_spent)
            member_name = None
        customers_data.append(
            {
                "customer": customer,
                "total_spent": total_spent,
                "tier": tier,
                "member_name": member_name,
            }
        )

    return render_template(
        "customers.html",
        customers=customers_data,
        member_rows=member_rows,
    )


@app.route("/admin/customers/<int:customer_id>/edit", methods=["GET", "POST"])
@admin_required
def edit_customer(customer_id: int):
    customer = Customer.query.get_or_404(customer_id)
    if request.method == "POST":
        customer.name = request.form["name"].strip()
        customer.phone = request.form["phone"].strip()
        try:
            db.session.commit()
            flash("Cập nhật khách hàng thành công.", "success")
            return redirect(url_for("customers"))
        except IntegrityError:
            db.session.rollback()
            flash("Số điện thoại đã tồn tại.", "danger")
    return render_template("customer_edit.html", customer=customer)


@app.route("/admin/customers/<int:customer_id>/delete", methods=["POST"])
@admin_required
def delete_customer(customer_id: int):
    customer = Customer.query.get_or_404(customer_id)
    try:
        db.session.delete(customer)
        db.session.commit()
        flash("Xóa khách hàng thành công.", "success")
    except IntegrityError:
        db.session.rollback()
        flash("Không thể xóa khách hàng vì đã có vé liên quan.", "danger")
    return redirect(url_for("customers"))


@app.route("/admin/screenings", methods=["GET", "POST"])
@admin_required
def screenings():
    cinemas_list = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    movies_list = (
        Movie.query.filter_by(release_status="now_showing").order_by(Movie.title.asc()).all()
    )
    if not movies_list:
        movies_list = Movie.query.order_by(Movie.title.asc()).all()
    rooms_list = CinemaRoom.query.order_by(CinemaRoom.room_name.asc()).all()
    return render_template(
        "screenings.html",
        cinemas=cinemas_list,
        movies=movies_list,
        rooms=rooms_list,
    )


@app.route("/admin/screenings/movie/<int:movie_id>", methods=["GET", "POST"])
@admin_required
def screenings_movie(movie_id: int):
    cinemas_list = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    rooms_list = CinemaRoom.query.order_by(CinemaRoom.room_name.asc()).all()
    movie = Movie.query.get_or_404(movie_id)

    if request.method == "POST":
        cinema_id = int(request.form["cinema_id"])
        room_id = int(request.form["room_id"])
        room = CinemaRoom.query.get_or_404(room_id)
        if room.cinema_id != cinema_id:
            flash("Phòng chiếu không thuộc rạp đã chọn.", "danger")
            return redirect(url_for("screenings_movie", movie_id=movie.id))

        date_value = datetime.strptime(request.form["screening_date"], "%Y-%m-%d").date()
        time_value = datetime.strptime(request.form["screening_time"], "%H:%M").time()
        db.session.add(
            Screening(
                movie_id=movie.id,
                room_id=room_id,
                screening_date=date_value,
                screening_time=time_value,
            )
        )
        db.session.commit()
        flash("Thêm suất chiếu thành công.", "success")
        return redirect(url_for("screenings_movie", movie_id=movie.id))

    data = (
        Screening.query.join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .filter(Screening.movie_id == movie.id)
        .order_by(
            CinemaRoom.cinema_id.asc(),
            Screening.screening_date.asc(),
            Screening.screening_time.asc(),
        )
        .all()
    )
    screenings_by_cinema: dict[str, list[Screening]] = {}
    for item in data:
        cinema_name = item.room.cinema.cinema_name
        screenings_by_cinema.setdefault(cinema_name, []).append(item)

    return render_template(
        "screenings_movie.html",
        movie=movie,
        cinemas=cinemas_list,
        rooms=rooms_list,
        screenings_by_cinema=screenings_by_cinema,
    )


@app.route("/admin/screenings/<int:screening_id>/edit", methods=["GET", "POST"])
@admin_required
def edit_screening(screening_id: int):
    screening = Screening.query.get_or_404(screening_id)
    cinemas_list = Cinema.query.order_by(Cinema.cinema_name.asc()).all()
    movies_list = Movie.query.order_by(Movie.title.asc()).all()
    rooms_list = CinemaRoom.query.order_by(CinemaRoom.room_name.asc()).all()

    if request.method == "POST":
        cinema_id = int(request.form["cinema_id"])
        room_id = int(request.form["room_id"])
        room = CinemaRoom.query.get_or_404(room_id)
        if room.cinema_id != cinema_id:
            flash("Phòng chiếu không thuộc rạp đã chọn.", "danger")
            return redirect(url_for("edit_screening", screening_id=screening.id))
        screening.movie_id = int(request.form["movie_id"])
        screening.room_id = room_id
        screening.screening_date = datetime.strptime(
            request.form["screening_date"], "%Y-%m-%d"
        ).date()
        screening.screening_time = datetime.strptime(
            request.form["screening_time"], "%H:%M"
        ).time()
        db.session.commit()
        flash("Cập nhật suất chiếu thành công.", "success")
        return redirect(url_for("screenings_movie", movie_id=screening.movie_id))

    return render_template(
        "screening_edit.html",
        screening=screening,
        cinemas=cinemas_list,
        movies=movies_list,
        rooms=rooms_list,
    )


@app.route("/admin/screenings/<int:screening_id>/delete", methods=["POST"])
@admin_required
def delete_screening(screening_id: int):
    screening = Screening.query.get_or_404(screening_id)
    movie_id = screening.movie_id
    try:
        db.session.delete(screening)
        db.session.commit()
        flash("Xóa suất chiếu thành công.", "success")
    except IntegrityError:
        db.session.rollback()
        flash("Không thể xóa suất chiếu vì đã có vé liên quan.", "danger")
    return redirect(url_for("screenings_movie", movie_id=movie_id))


@app.route("/book/<int:screening_id>", methods=["GET", "POST"])
@member_required
def book_ticket(screening_id: int):
    screening = Screening.query.get_or_404(screening_id)
    occupied_seats = {
        ticket.seat_number for ticket in Ticket.query.filter_by(screening_id=screening_id).all()
    }
    seats = build_seat_map(screening.room.capacity)
    member = get_current_member()

    return render_template(
        "book.html",
        screening=screening,
        seats=seats,
        occupied_seats=occupied_seats,
        ticket_price=get_ticket_price(),
        member_name=member.name if member else "",
        member_phone=member.phone if member else "",
    )


@app.route("/checkout/<int:screening_id>", methods=["POST"])
@member_required
def checkout(screening_id: int):
    screening = Screening.query.get_or_404(screening_id)
    seats = build_seat_map(screening.room.capacity)
    member = get_current_member()
    customer_name = (member.name if member else "").strip()
    customer_phone = normalize_phone(member.phone if member else "")
    selected_seats = parse_selected_seats(request.form.get("seat_number", ""))

    if not customer_name or not customer_phone:
        flash("Vui lòng nhập họ tên và số điện thoại.", "danger")
        return redirect(url_for("book_ticket", screening_id=screening_id))
    if not selected_seats:
        flash("Vui lòng chọn ít nhất 1 ghế.", "danger")
        return redirect(url_for("book_ticket", screening_id=screening_id))
    invalid = [s for s in selected_seats if s not in seats]
    if invalid:
        flash("Có ghế không hợp lệ. Vui lòng chọn lại.", "danger")
        return redirect(url_for("book_ticket", screening_id=screening_id))

    existing = {
        t.seat_number
        for t in Ticket.query.filter(
            Ticket.screening_id == screening_id,
            Ticket.seat_number.in_(selected_seats),
        ).all()
    }
    if existing:
        flash("Có ghế đã được đặt. Vui lòng chọn ghế khác.", "danger")
        return redirect(url_for("book_ticket", screening_id=screening_id))

    ticket_price = get_ticket_price()
    original_amount = ticket_price * len(selected_seats)
    voucher_code = request.form.get("voucher_code", "").strip()
    voucher = None
    discount_percent = 0
    discount_amount = 0
    total_amount = original_amount
    if voucher_code:
        voucher, voucher_error = resolve_voucher_for_phone(voucher_code, customer_phone)
        if voucher_error:
            flash(voucher_error, "danger")
            return redirect(url_for("book_ticket", screening_id=screening_id))
        discount_percent = voucher.discount_percent
        discount_amount, total_amount = compute_discount(original_amount, discount_percent)

    order_code = generate_order_code()
    order = PaymentOrder(
        order_code=order_code,
        screening_id=screening_id,
        customer_name=customer_name,
        customer_phone=customer_phone,
        seat_numbers=",".join(selected_seats),
        original_amount=original_amount,
        voucher_code=voucher.code if voucher else None,
        discount_percent=discount_percent,
        discount_amount=discount_amount,
        total_amount=total_amount,
        status="pending",
    )
    db.session.add(order)
    db.session.commit()

    vietqr_url = build_vietqr_url(order_code, total_amount)
    qr_base64 = None if vietqr_url else build_payment_qr_base64(order_code, total_amount, customer_phone)

    return render_template(
        "checkout.html",
        screening=screening,
        customer_name=customer_name,
        customer_phone=customer_phone,
        selected_seats=selected_seats,
        selected_seats_raw=",".join(selected_seats),
        order_code=order_code,
        vietqr_url=vietqr_url,
        qr_base64=qr_base64,
        original_amount=order.original_amount,
        voucher_code=order.voucher_code,
        discount_percent=order.discount_percent,
        discount_amount=order.discount_amount,
        total_amount=total_amount,
        ticket_price=ticket_price,
    )


@app.route("/confirm-payment/<int:screening_id>", methods=["POST"])
def confirm_payment(screening_id: int):
    order_code = request.form.get("order_code", "").strip()
    order = PaymentOrder.query.filter_by(order_code=order_code).first_or_404()
    verified = maybe_auto_confirm_with_sepay(order)
    if order.status != "paid" and not verified:
        flash(
            "SePay chưa xác nhận giao dịch cho mã đơn này. "
            "Vui lòng kiểm tra nội dung chuyển khoản chứa đúng mã đơn và thử lại sau vài giây.",
            "warning",
        )
        return redirect(url_for("checkout_page", order_code=order.order_code))
    return redirect(url_for("payment_success", order_code=order.order_code))


@app.route("/payment-success/<string:order_code>")
def payment_success(order_code: str):
    order = PaymentOrder.query.filter_by(order_code=order_code).first_or_404()
    if order.status != "paid":
        flash("Đơn hàng chưa thanh toán thành công.", "warning")
        return redirect(url_for("book_ticket", screening_id=order.screening_id))

    screening = Screening.query.get_or_404(order.screening_id)
    tickets = (
        Ticket.query.join(Customer, Ticket.customer_id == Customer.id)
        .filter(
            Ticket.screening_id == order.screening_id,
            Customer.phone == order.customer_phone,
            Ticket.seat_number.in_(parse_selected_seats(order.seat_numbers)),
        )
        .order_by(Ticket.id.asc())
        .all()
    )
    booking_codes = [t.booking_code for t in tickets]
    ticket_price = get_ticket_price()
    return render_template(
        "payment_success.html",
        screening=screening,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        selected_seats=parse_selected_seats(order.seat_numbers),
        booking_codes=booking_codes,
        order_code=order.order_code,
        payment_method="Chuyển khoản QR",
        ticket_price=ticket_price,
        total_amount=order.total_amount,
    )


@app.route("/checkout-order/<string:order_code>")
def checkout_page(order_code: str):
    order = PaymentOrder.query.filter_by(order_code=order_code).first_or_404()
    screening = Screening.query.get_or_404(order.screening_id)
    selected_seats = parse_selected_seats(order.seat_numbers)
    vietqr_url = build_vietqr_url(order.order_code, order.total_amount)
    qr_base64 = None
    if not vietqr_url:
        qr_base64 = build_payment_qr_base64(
            order.order_code, order.total_amount, order.customer_phone
        )
    return render_template(
        "checkout.html",
        screening=screening,
        customer_name=order.customer_name,
        customer_phone=order.customer_phone,
        selected_seats=selected_seats,
        selected_seats_raw=",".join(selected_seats),
        order_code=order.order_code,
        vietqr_url=vietqr_url,
        qr_base64=qr_base64,
        original_amount=order.original_amount or order.total_amount,
        voucher_code=order.voucher_code,
        discount_percent=order.discount_percent or 0,
        discount_amount=order.discount_amount or 0,
        total_amount=order.total_amount,
        ticket_price=get_ticket_price(),
    )


@app.route("/checkout-order/<string:order_code>/apply-voucher", methods=["POST"])
def apply_voucher(order_code: str):
    order = PaymentOrder.query.filter_by(order_code=order_code).first_or_404()
    if order.status != "pending":
        flash("Đơn hàng đã thanh toán, không thể đổi voucher.", "warning")
        return redirect(url_for("checkout_page", order_code=order.order_code))

    raw_code = request.form.get("voucher_code", "").strip()
    if not raw_code:
        order.voucher_code = None
        order.discount_percent = 0
        order.discount_amount = 0
        order.total_amount = order.original_amount or order.total_amount
        db.session.commit()
        flash("Đã gỡ voucher khỏi đơn hàng.", "success")
        return redirect(url_for("checkout_page", order_code=order.order_code))

    voucher, voucher_error = resolve_voucher_for_phone(raw_code, order.customer_phone)
    if voucher_error:
        flash(voucher_error, "danger")
        return redirect(url_for("checkout_page", order_code=order.order_code))

    base_amount = order.original_amount or order.total_amount
    discount_amount, final_amount = compute_discount(base_amount, voucher.discount_percent)
    order.voucher_code = voucher.code
    order.discount_percent = voucher.discount_percent
    order.discount_amount = discount_amount
    order.total_amount = final_amount
    db.session.commit()
    flash(f"Áp dụng voucher {voucher.code} thành công.", "success")
    return redirect(url_for("checkout_page", order_code=order.order_code))


@app.route("/api/payment-status/<string:order_code>")
def payment_status(order_code: str):
    order = PaymentOrder.query.filter_by(order_code=order_code).first()
    if not order:
        return jsonify({"ok": False, "message": "Order not found"}), 404

    maybe_auto_confirm_with_sepay(order)
    if order.status == "pending":
        if request.args.get("simulate") == "1":
            finalize_order(order)

    return jsonify(
        {
            "ok": True,
            "order_code": order.order_code,
            "status": order.status,
            "paid": order.status == "paid",
            "redirect_url": url_for("payment_success", order_code=order.order_code),
        }
    )


@app.route("/my-tickets", methods=["GET", "POST"])
def my_tickets():
    tickets = []
    invalidated_tickets = []
    phone = ""
    member = get_current_member()
    if member:
        # Logged-in members: always show tickets that belong to this account
        phone = member.phone
    elif request.method == "POST":
        phone = normalize_phone(request.form["phone"])
        if not phone:
            flash("Vui lòng nhập số điện thoại.", "danger")

    if phone:
        tickets = (
            Ticket.query.join(Customer, Ticket.customer_id == Customer.id)
            .join(Screening, Ticket.screening_id == Screening.id)
            .join(Movie, Screening.movie_id == Movie.id)
            .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
            .filter(Customer.phone == phone)
            .order_by(Ticket.booked_at.desc())
            .all()
        )
        invalidated_tickets = (
            InvalidatedTicket.query.filter(InvalidatedTicket.customer_phone == phone)
            .order_by(InvalidatedTicket.invalidated_at.desc())
            .all()
        )
    spending_summary = None
    if phone:
        total_spent = compute_member_spent(phone)
        spending_summary = {
            "total_spent": total_spent,
            "tier": resolve_member_tier(total_spent),
        }
    return render_template(
        "my_tickets.html",
        tickets=tickets,
        invalidated_tickets=invalidated_tickets,
        phone=phone,
        spending_summary=spending_summary,
    )


@app.route("/register", methods=["GET", "POST"])
def register():
    if get_current_member():
        return redirect(url_for("index"))

    if request.method == "POST":
        name = (request.form.get("name") or "").strip()
        phone = normalize_phone(request.form.get("phone"))
        password = (request.form.get("password") or "").strip()
        confirm = (request.form.get("confirm_password") or "").strip()

        if not name or not phone or not password:
            flash("Vui lòng nhập đầy đủ họ tên, số điện thoại và mật khẩu.", "danger")
            return render_template("register.html", name=name, phone=phone)
        if password != confirm:
            flash("Mật khẩu xác nhận không khớp.", "danger")
            return render_template("register.html", name=name, phone=phone)
        if len(password) < 6:
            flash("Mật khẩu tối thiểu 6 ký tự.", "danger")
            return render_template("register.html", name=name, phone=phone)

        existing = Member.query.filter_by(phone=phone).first()
        if existing:
            flash("Số điện thoại này đã đăng ký thành viên. Vui lòng đăng nhập.", "warning")
            return redirect(url_for("login"))

        member = Member(
            name=name,
            phone=phone,
            password_hash=generate_password_hash(password),
        )
        db.session.add(member)
        db.session.commit()
        session["member_id"] = member.id
        flash("Đăng ký thành công. Chào mừng bạn!", "success")
        return redirect(url_for("index"))

    return render_template("register.html", name="", phone="")


@app.route("/login", methods=["GET", "POST"])
def login():
    if get_current_member():
        return redirect(url_for("index"))

    if request.method == "POST":
        next_url = (request.args.get("next") or "").strip()
        phone = normalize_phone(request.form.get("phone"))
        password = (request.form.get("password") or "").strip()
        member = Member.query.filter_by(phone=phone).first()
        if not member or not check_password_hash(member.password_hash, password):
            flash("Sai số điện thoại hoặc mật khẩu.", "danger")
            return render_template("login.html", phone=phone)
        session["member_id"] = member.id
        flash("Đăng nhập thành công.", "success")
        if next_url and next_url.startswith("/"):
            return redirect(next_url)
        return redirect(url_for("index"))

    return render_template("login.html", phone="")


@app.route("/logout")
def logout():
    session.pop("member_id", None)
    flash("Bạn đã đăng xuất.", "success")
    return redirect(url_for("index"))


@app.route("/thanh-vien")
@member_required
def member_center():
    member = get_current_member()
    total_spent = compute_member_spent(member.phone)
    tier = resolve_member_tier(total_spent)
    return render_template(
        "member_center.html",
        member=member,
        total_spent=total_spent,
        tier=tier,
        tier_benefits=MEMBER_BENEFITS,
    )


@app.route("/admin/reports")
@admin_required
def reports():
    q = (request.args.get("q") or "").strip()
    ticket_price = get_ticket_price()

    # Vé: đếm từ bảng tickets. Doanh thu: tổng tiền đơn đã thanh toán (đã trừ voucher).
    sold_subq = (
        db.session.query(
            Screening.movie_id.label("movie_id"),
            func.count(Ticket.id).label("sold"),
        )
        .select_from(Screening)
        .join(Ticket, Ticket.screening_id == Screening.id)
        .group_by(Screening.movie_id)
        .subquery()
    )
    rev_subq = (
        db.session.query(
            Screening.movie_id.label("movie_id"),
            func.sum(PaymentOrder.total_amount).label("revenue"),
        )
        .select_from(Screening)
        .join(PaymentOrder, PaymentOrder.screening_id == Screening.id)
        .filter(PaymentOrder.status == "paid")
        .group_by(Screening.movie_id)
        .subquery()
    )
    movie_ids_sq = db.session.query(Screening.movie_id.label("movie_id")).distinct().subquery()

    movie_rows = (
        db.session.query(
            Movie.id,
            Movie.title,
            func.coalesce(sold_subq.c.sold, 0).label("sold"),
            func.coalesce(rev_subq.c.revenue, 0).label("revenue"),
        )
        .select_from(Movie)
        .join(movie_ids_sq, movie_ids_sq.c.movie_id == Movie.id)
        .outerjoin(sold_subq, sold_subq.c.movie_id == Movie.id)
        .outerjoin(rev_subq, rev_subq.c.movie_id == Movie.id)
    )
    if q:
        safe = q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        movie_rows = movie_rows.filter(Movie.title.like(f"%{safe}%", escape="\\"))
    movie_rows = movie_rows.order_by(Movie.title.asc()).all()

    total_tickets = sum(int(row.sold or 0) for row in movie_rows)
    total_revenue = sum(int(row.revenue or 0) for row in movie_rows)

    return render_template(
        "reports.html",
        movie_rows=movie_rows,
        total_tickets=total_tickets,
        total_revenue=total_revenue,
        ticket_price=ticket_price,
        search_q=q,
    )


@app.route("/admin/reports/movie/<int:movie_id>")
@admin_required
def reports_movie(movie_id: int):
    movie = Movie.query.get(movie_id)
    if not movie:
        abort(404)
    q_back = (request.args.get("q") or "").strip()
    ticket_price = get_ticket_price()

    sold_cinema_sq = (
        db.session.query(
            CinemaRoom.cinema_id.label("cinema_id"),
            func.count(Ticket.id).label("sold"),
        )
        .select_from(Screening)
        .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .join(Ticket, Ticket.screening_id == Screening.id)
        .filter(Screening.movie_id == movie_id)
        .group_by(CinemaRoom.cinema_id)
        .subquery()
    )
    rev_cinema_sq = (
        db.session.query(
            CinemaRoom.cinema_id.label("cinema_id"),
            func.sum(PaymentOrder.total_amount).label("revenue"),
        )
        .select_from(Screening)
        .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .join(PaymentOrder, PaymentOrder.screening_id == Screening.id)
        .filter(Screening.movie_id == movie_id, PaymentOrder.status == "paid")
        .group_by(CinemaRoom.cinema_id)
        .subquery()
    )
    cinema_ids_sq = (
        db.session.query(CinemaRoom.cinema_id.label("cinema_id"))
        .select_from(Screening)
        .join(CinemaRoom, Screening.room_id == CinemaRoom.id)
        .filter(Screening.movie_id == movie_id)
        .distinct()
        .subquery()
    )

    cinema_rows = (
        db.session.query(
            Cinema.id,
            Cinema.cinema_name,
            func.coalesce(sold_cinema_sq.c.sold, 0).label("sold"),
            func.coalesce(rev_cinema_sq.c.revenue, 0).label("revenue"),
        )
        .select_from(Cinema)
        .join(cinema_ids_sq, cinema_ids_sq.c.cinema_id == Cinema.id)
        .outerjoin(sold_cinema_sq, sold_cinema_sq.c.cinema_id == Cinema.id)
        .outerjoin(rev_cinema_sq, rev_cinema_sq.c.cinema_id == Cinema.id)
        .order_by(Cinema.cinema_name.asc())
        .all()
    )

    total_tickets = sum(int(row.sold or 0) for row in cinema_rows)
    total_revenue = sum(int(row.revenue or 0) for row in cinema_rows)

    return render_template(
        "reports_movie.html",
        movie=movie,
        cinema_rows=cinema_rows,
        total_tickets=total_tickets,
        total_revenue=total_revenue,
        ticket_price=ticket_price,
        search_q=q_back,
    )


@app.route("/debug/movies")
@admin_required
def debug_movies():
    total = Movie.query.count()
    now_showing = Movie.query.filter_by(release_status="now_showing").count()
    coming_soon = Movie.query.filter_by(release_status="coming_soon").count()
    sample = [
        {"id": m.id, "title": m.title, "status": m.release_status}
        for m in Movie.query.order_by(Movie.id.desc()).limit(10).all()
    ]
    return jsonify(
        {
            "total_movies": total,
            "now_showing": now_showing,
            "coming_soon": coming_soon,
            "sample_latest": sample,
        }
    )


@app.cli.command("init-db")
def init_db():
    db.drop_all()
    db.create_all()
    print("Database da duoc khoi tao.")


@app.cli.command("seed-db")
def seed_db():
    db.drop_all()
    db.create_all()
    seed_sample_data()
    print("Database da duoc seed du lieu mau.")


@app.cli.command("import-cgv-json")
def import_cgv_json():
    import json
    from pathlib import Path

    file_path = Path("data/cgv_movies.json")
    if not file_path.exists():
        print("Khong tim thay data/cgv_movies.json")
        return

    with file_path.open("r", encoding="utf-8") as fp:
        payload = json.load(fp)

    added = 0
    for item in payload:
        title = (item.get("title") or "").strip()
        if not title:
            continue

        movie = Movie.query.filter(func.lower(Movie.title) == title.lower()).first()
        if movie is None:
            movie = Movie(
                title=title,
                genre=(item.get("genre") or "Unknown").strip(),
                duration_minutes=int(item.get("duration_minutes") or 100),
            )
            db.session.add(movie)
            added += 1

        movie.poster_url = (item.get("poster_url") or "").strip() or movie.poster_url
        movie.release_status = (item.get("release_status") or movie.release_status or "now_showing").strip()
        movie.genre = (item.get("genre") or movie.genre).strip()
        movie.duration_minutes = int(item.get("duration_minutes") or movie.duration_minutes or 100)

    db.session.commit()
    print(f"Import xong. Da them moi: {added} phim.")


@app.cli.command("import-cgv-html")
def import_cgv_html():
    import re
    from html import unescape
    from pathlib import Path

    release_status = (os.getenv("CGV_RELEASE_STATUS") or "now_showing").strip() or "now_showing"
    if release_status not in {"now_showing", "coming_soon"}:
        release_status = "now_showing"

    def import_from_html_file(html_file: Path) -> tuple[int, int, int]:
        html = html_file.read_text(encoding="utf-8", errors="ignore")
        entries = re.findall(
            r'<li class="film-lists item last">(.*?)<ul class="add-to-links">',
            html,
            flags=re.DOTALL | re.IGNORECASE,
        )

        added = 0
        updated = 0

        def strip_html(value: str) -> str:
            text = re.sub(r"<[^>]+>", " ", value or "", flags=re.DOTALL)
            text = unescape(text)
            return re.sub(r"\s+", " ", text).strip()

        for block in entries:
            title_match = re.search(
                r'<h2 class="product-name"><a [^>]*>(.*?)</a></h2>',
                block,
                flags=re.DOTALL,
            )
            genre_match = re.search(
                r"Thể loại:\s*</span>\s*<span class=\"cgv-info-normal\">(.*?)</span>",
                block,
                flags=re.DOTALL,
            )
            duration_match = re.search(
                r"Thời lượng:\s*</span>\s*<span class=\"cgv-info-normal\">(.*?)</span>",
                block,
                flags=re.DOTALL,
            )
            poster_match = re.search(r'<img [^>]*src="([^"]+)"', block, flags=re.DOTALL)

            if not title_match:
                continue

            title = strip_html(title_match.group(1))
            genre = strip_html(genre_match.group(1)) if genre_match else "Unknown"
            poster_url = poster_match.group(1).strip() if poster_match else None

            duration_minutes = 100
            if duration_match:
                duration_text = strip_html(duration_match.group(1))
                number_match = re.search(r"(\d+)", duration_text)
                if number_match:
                    duration_minutes = int(number_match.group(1))

            movie = Movie.query.filter(func.lower(Movie.title) == title.lower()).first()
            if movie is None:
                movie = Movie(
                    title=title,
                    genre=genre,
                    duration_minutes=duration_minutes,
                    poster_url=poster_url,
                    release_status=release_status,
                )
                db.session.add(movie)
                added += 1
            else:
                movie.genre = genre or movie.genre
                movie.duration_minutes = duration_minutes or movie.duration_minutes
                movie.poster_url = poster_url or movie.poster_url
                movie.release_status = release_status
                updated += 1

        db.session.commit()
        return len(entries), added, updated

    env_path = (os.getenv("CGV_HTML_PATH") or "").strip()
    html_candidates = [Path(env_path)] if env_path else []
    html_candidates += [
        Path("data/cgv_now_showing.html"),
        Path("New Text Document.txt"),
    ]
    html_path = next((p for p in html_candidates if p and p.exists()), None)
    if html_path is None:
        print("Khong tim thay file HTML. Hay luu vao data/cgv_now_showing.html hoac New Text Document.txt")
        return

    blocks, added, updated = import_from_html_file(html_path)
    print(
        f"Import HTML xong tu {html_path}. Status={release_status}. "
        f"So block doc duoc: {blocks}. Them moi: {added}, cap nhat: {updated}."
    )


if __name__ == "__main__":
    from pathlib import Path
    import re
    from html import unescape

    def _auto_import_when_empty() -> None:
        html_candidates = [
            Path("data/cgv_now_showing.html"),
            Path("New Text Document.txt"),
        ]
        html_path = next((p for p in html_candidates if p.exists()), None)
        if html_path is None or Movie.query.count() > 0:
            return

        html = html_path.read_text(encoding="utf-8", errors="ignore")
        entries = re.findall(
            r'<li class="film-lists item last">(.*?)<ul class="add-to-links">',
            html,
            flags=re.DOTALL | re.IGNORECASE,
        )
        for block in entries:
            title_match = re.search(r'<h2 class="product-name"><a [^>]*>(.*?)</a></h2>', block, flags=re.DOTALL)
            if not title_match:
                continue
            title = re.sub(r"<[^>]+>", " ", title_match.group(1))
            title = unescape(re.sub(r"\s+", " ", title)).strip()
            if not title:
                continue
            movie = Movie.query.filter(func.lower(Movie.title) == title.lower()).first()
            if movie is None:
                genre_match = re.search(
                    r"Thể loại:\s*</span>\s*<span class=\"cgv-info-normal\">(.*?)</span>",
                    block,
                    flags=re.DOTALL,
                )
                duration_match = re.search(
                    r"Thời lượng:\s*</span>\s*<span class=\"cgv-info-normal\">(.*?)</span>",
                    block,
                    flags=re.DOTALL,
                )
                poster_match = re.search(r'<img [^>]*src="([^"]+)"', block, flags=re.DOTALL)
                genre = "Unknown"
                if genre_match:
                    genre = re.sub(r"<[^>]+>", " ", genre_match.group(1))
                    genre = unescape(re.sub(r"\s+", " ", genre)).strip() or "Unknown"
                duration_minutes = 100
                if duration_match:
                    duration_text = re.sub(r"<[^>]+>", " ", duration_match.group(1))
                    duration_text = unescape(re.sub(r"\s+", " ", duration_text)).strip()
                    m = re.search(r"(\d+)", duration_text)
                    if m:
                        duration_minutes = int(m.group(1))
                poster_url = poster_match.group(1).strip() if poster_match else None
                db.session.add(
                    Movie(
                        title=title,
                        genre=genre,
                        duration_minutes=duration_minutes,
                        poster_url=poster_url,
                        release_status="now_showing",
                    )
                )
        db.session.commit()

    with app.app_context():
        db.create_all()
        _auto_import_when_empty()
    app.run(debug=True)
