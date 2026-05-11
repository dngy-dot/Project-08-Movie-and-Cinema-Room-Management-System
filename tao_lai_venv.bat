@echo off
setlocal
cd /d "%~dp0"
echo === Tao lai virtual environment (.venv) ===
echo.

if exist ".venv\" (
  echo Dang xoa .venv cu...
  rmdir /s /q ".venv"
  if exist ".venv\" (
    echo [ERROR] Khong xoa duoc .venv. Hay dong Cursor/IDE dang dung Python trong .venv roi chay lai.
    pause & exit /b 1
  )
)

set "PYTHON_CMD="
where python >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_CMD=python"
) else (
  where py >nul 2>nul
  if not errorlevel 1 set "PYTHON_CMD=py -3"
)
if "%PYTHON_CMD%"=="" (
  echo [ERROR] Khong tim thay Python. Cai Python 3 va bat "Add Python to PATH".
  pause & exit /b 1
)

echo Tao .venv bang: %PYTHON_CMD%
call %PYTHON_CMD% -m venv .venv
if errorlevel 1 (
  echo [ERROR] Tao venv that bai.
  pause & exit /b 1
)

call ".venv\Scripts\python.exe" -m pip install --upgrade pip
if errorlevel 1 ( echo [ERROR] pip that bai. & pause & exit /b 1 )

call ".venv\Scripts\python.exe" -m pip install -r requirements.txt
if errorlevel 1 ( echo [ERROR] Cai requirements that bai. & pause & exit /b 1 )

echo.
echo [OK] .venv moi da san sang tren may nay.
echo Chay chay_web.bat de khoi dong web.
pause
