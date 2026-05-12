"""
Xóa toàn bộ database MySQL trùng tên với app (mặc định cinema_db) rồi tạo lại rỗng.
Dùng cùng biến DATABASE_URL như Flask (mysql+mysqlconnector://...).

Chạy từ thư mục gốc project:
  .venv\\Scripts\\python scripts\\reset_cinema_mysql_db.py

Sau đó tạo lại bảng (chọn một):
  mysql ... < sql/schema.sql
  hoặc để app tự migrate / create_all nếu bạn đang dùng luồng đó.
"""
from __future__ import annotations

import os
import sys

from sqlalchemy import create_engine, text
from sqlalchemy.engine.url import make_url


def main() -> int:
    raw = os.environ.get(
        "DATABASE_URL",
        "mysql+mysqlconnector://root@127.0.0.1:3306/cinema_db",
    )
    if "mysql" not in raw:
        print("DATABASE_URL phải là MySQL (mysql+mysqlconnector://...).", file=sys.stderr)
        return 1

    url = make_url(raw)
    db_name = url.database
    if not db_name:
        print("Thiếu tên database trong DATABASE_URL.", file=sys.stderr)
        return 1

    server_url = url.set(database=None)
    engine = create_engine(server_url, isolation_level="AUTOCOMMIT")
    with engine.connect() as conn:
        conn.execute(text(f"DROP DATABASE IF EXISTS `{db_name}`"))
        conn.execute(
            text(
                f"CREATE DATABASE `{db_name}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
        )
    print(f"OK: đã DROP + CREATE lại database `{db_name}` (rỗng). Chạy sql/schema.sql nếu cần bảng.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
