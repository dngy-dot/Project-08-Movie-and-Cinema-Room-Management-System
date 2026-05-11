@echo off
if /i not "%~1"=="__stay_open__" (
  rem Dung %~nx0 + /D de tranh loi khi duong dan co dau ngoac, vi du "webdasua (2)"
  start "chay_web" /D "%~dp0" cmd /k call "%~nx0" __stay_open__
  exit /b
)
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "ADMIN_PASSWORD=dngadmin"
rem ^! trong delayed expansion de giu dung ky tu ! trong SECRET_KEY
set "SECRET_KEY=mot-chuoi-bi-mat-kho-doan-123^!@#"
set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_USER=root"
set "DB_PASSWORD=dngsql013245"
set "DB_NAME=cinema_db"
set "PYTHON_CMD="
where python >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_CMD=python"
) else (
  where py >nul 2>nul
  if not errorlevel 1 set "PYTHON_CMD=py -3"
)
if "%PYTHON_CMD%"=="" (
  echo [ERROR] Khong tim thay Python. Hay cai Python 3 va bat "Add Python to PATH".
  pause & exit /b 1
)

rem .venv copy tu may khac: pyvenv.cfg tro ve Python may cu -> xoa va tao lai
set "NEED_NEW_VENV="
if exist ".venv\pyvenv.cfg" (
  for /f "usebackq tokens=1,* delims==" %%A in (".venv\pyvenv.cfg") do (
    if /i "%%A"=="home" (
      set "HB=%%B"
      if "!HB:~0,1!"==" " set "HB=!HB:~1!"
      if not exist "!HB!\python.exe" set "NEED_NEW_VENV=1"
    )
  )
)
if exist ".venv\Scripts\python.exe" (
  ".venv\Scripts\python.exe" -c "pass" >nul 2>&1
  if errorlevel 1 set "NEED_NEW_VENV=1"
)
if defined NEED_NEW_VENV (
  echo [INFO] .venv khong hop le cho may nay - thuong do copy tu may khac. Dang xoa va tao lai...
  rmdir /s /q ".venv" 2>nul
)

if not exist ".venv\Scripts\python.exe" (
  call %PYTHON_CMD% -m venv .venv
  if errorlevel 1 ( echo [ERROR] Tao venv that bai. & pause & exit /b 1 )
)

call ".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 ( echo [ERROR] Cap nhat pip that bai. & pause & exit /b 1 )

call ".venv\Scripts\python.exe" -m pip install -r requirements.txt --quiet
if errorlevel 1 ( echo [ERROR] Cai thu vien that bai. & pause & exit /b 1 )

set "TMP_BOOTSTRAP=%TEMP%\mysql_bootstrap_%RANDOM%%RANDOM%.py"
set "TMP_DBURL=%TEMP%\webdasua_dburl_%RANDOM%%RANDOM%.tmp"
> "%TMP_BOOTSTRAP%" echo import mysql.connector
>> "%TMP_BOOTSTRAP%" echo from mysql.connector import Error
>> "%TMP_BOOTSTRAP%" echo from urllib.parse import quote_plus
>> "%TMP_BOOTSTRAP%" echo url_file = r"%TMP_DBURL%"
>> "%TMP_BOOTSTRAP%" echo host = r"%DB_HOST%"
>> "%TMP_BOOTSTRAP%" echo port = int(%DB_PORT%)
>> "%TMP_BOOTSTRAP%" echo user = r"%DB_USER%"
>> "%TMP_BOOTSTRAP%" echo primary_password = r"%DB_PASSWORD%"
>> "%TMP_BOOTSTRAP%" echo db_name = r"%DB_NAME%"
>> "%TMP_BOOTSTRAP%" echo conn = None
>> "%TMP_BOOTSTRAP%" echo last_error = None
>> "%TMP_BOOTSTRAP%" echo used_password = None
>> "%TMP_BOOTSTRAP%" echo for pwd in [primary_password, ""]:
>> "%TMP_BOOTSTRAP%" echo.    if used_password is not None and pwd == used_password:
>> "%TMP_BOOTSTRAP%" echo.        continue
>> "%TMP_BOOTSTRAP%" echo.    try:
>> "%TMP_BOOTSTRAP%" echo.        conn = mysql.connector.connect(host=host, port=port, user=user, password=pwd, autocommit=True)
>> "%TMP_BOOTSTRAP%" echo.        cur = conn.cursor()
>> "%TMP_BOOTSTRAP%" echo.        cur.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
>> "%TMP_BOOTSTRAP%" echo.        cur.close()
>> "%TMP_BOOTSTRAP%" echo.        used_password = pwd
>> "%TMP_BOOTSTRAP%" echo.        break
>> "%TMP_BOOTSTRAP%" echo.    except Error as exc:
>> "%TMP_BOOTSTRAP%" echo.        last_error = exc
>> "%TMP_BOOTSTRAP%" echo.    finally:
>> "%TMP_BOOTSTRAP%" echo.        if conn is not None and conn.is_connected():
>> "%TMP_BOOTSTRAP%" echo.            conn.close()
>> "%TMP_BOOTSTRAP%" echo.            conn = None
>> "%TMP_BOOTSTRAP%" echo if used_password is None:
>> "%TMP_BOOTSTRAP%" echo.    raise SystemExit(f"[ERROR] Khong ket noi duoc MySQL ({host}:{port}): {last_error}")
>> "%TMP_BOOTSTRAP%" echo if used_password == "":
>> "%TMP_BOOTSTRAP%" echo.    print("[INFO] Dang dung mat khau rong cho MySQL user.")
>> "%TMP_BOOTSTRAP%" echo print("[OK] Database san sang:", db_name)
>> "%TMP_BOOTSTRAP%" echo if used_password == "":
>> "%TMP_BOOTSTRAP%" echo.    db_url = f"mysql+mysqlconnector://{quote_plus(user)}@{host}:{port}/{db_name}"
>> "%TMP_BOOTSTRAP%" echo else:
>> "%TMP_BOOTSTRAP%" echo.    db_url = f"mysql+mysqlconnector://{quote_plus(user)}:{quote_plus(used_password)}@{host}:{port}/{db_name}"
>> "%TMP_BOOTSTRAP%" echo with open(url_file, "w", encoding="utf-8") as _out:
>> "%TMP_BOOTSTRAP%" echo.    _out.write(db_url)

call ".venv\Scripts\python.exe" "%TMP_BOOTSTRAP%"
set "BOOTSTRAP_EXIT=%ERRORLEVEL%"
del /q "%TMP_BOOTSTRAP%" >nul 2>nul
if not "%BOOTSTRAP_EXIT%"=="0" (
  if exist "%TMP_DBURL%" del /q "%TMP_DBURL%" >nul 2>nul
  echo [ERROR] Khong ket noi MySQL - %DB_USER%@%DB_HOST%:%DB_PORT%.
  pause & exit /b 1
)
if not exist "%TMP_DBURL%" (
  echo [ERROR] Bootstrap khong ghi duoc DATABASE_URL.
  pause & exit /b 1
)
for /f "usebackq delims=" %%A in ("%TMP_DBURL%") do set "DATABASE_URL=%%A"
del /q "%TMP_DBURL%" >nul 2>nul
if not defined DATABASE_URL (
  echo [ERROR] Khong doc duoc DATABASE_URL.
  pause & exit /b 1
)

echo Server: http://127.0.0.1:5000
call ".venv\Scripts\python.exe" app.py

pause
