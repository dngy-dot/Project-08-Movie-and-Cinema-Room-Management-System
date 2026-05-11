# Auto-run Flask app with MySQL pre-checks.
# Keeps assignment requirement: use mysql-connector-python.

param(
    [string]$DbHost = "127.0.0.1",
    [int]$DbPort = 3306,
    [string]$DbUser = "root",
    [string]$DbPassword = "dngsql013245",
    [string]$DbName = "cinema_db"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonExe = Join-Path $projectRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $pythonExe)) {
    throw "Khong tim thay Python virtualenv tai: $pythonExe"
}

Write-Host "==> Kiem tra MySQL service..."
$mysqlService = Get-Service | Where-Object {
    $_.Name -like "MySQL*" -or $_.DisplayName -like "MySQL*"
} | Select-Object -First 1

if ($null -ne $mysqlService) {
    if ($mysqlService.Status -ne "Running") {
        Write-Host "==> Dang bat service $($mysqlService.Name)..."
        Start-Service -Name $mysqlService.Name
        Write-Host "==> Da bat MySQL service."
    } else {
        Write-Host "==> MySQL service dang chay."
    }
} else {
    Write-Host "==> Khong tim thay MySQL service tren may. Neu ban dung Docker/XAMPP thi bo qua."
}

Write-Host "==> Tao database neu chua ton tai..."
$bootstrapScript = @"
import mysql.connector
from mysql.connector import Error

host = r"$DbHost"
port = int($DbPort)
user = r"$DbUser"
password = r"$DbPassword"
db_name = r"$DbName"

conn = None
try:
    conn = mysql.connector.connect(
        host=host,
        port=port,
        user=user,
        password=password,
        autocommit=True,
    )
    cur = conn.cursor()
    cur.execute(f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
    cur.close()
    print(f"[OK] Database san sang: {db_name}")
except Error as exc:
    raise SystemExit(f"[LOI] Khong ket noi duoc MySQL ({host}:{port}): {exc}")
finally:
    if conn is not None and conn.is_connected():
        conn.close()
"@

& $pythonExe -c $bootstrapScript
if ($LASTEXITCODE -ne 0) {
    throw "Khong the khoi tao database. Dung chuong trinh."
}

Write-Host "==> Chay app.py..."
Set-Location $projectRoot
& $pythonExe "app.py"
