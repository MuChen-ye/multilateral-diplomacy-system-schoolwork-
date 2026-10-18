# Lab 1 - run all SQL scripts in order (01 -> 04).
#
# Usage:
#   .\run_all.ps1                 # prompts for the MySQL root password
#   $env:MYSQL_PWD = "..."; .\run_all.ps1
#
# ASCII only on purpose: this file must parse under a GBK (cp936) console.

$ErrorActionPreference = "Stop"

$mysql = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe"
if (-not (Test-Path $mysql)) { throw "mysql.exe not found: $mysql" }

if (-not $env:MYSQL_PWD) {
    $sec = Read-Host "MySQL root password" -AsSecureString
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

$files = @(
    "01_create_database.sql",
    "02_create_tables.sql",
    "03_insert_data.sql",
    "04_alter_tables.sql"
)

foreach ($f in $files) {
    if (-not (Test-Path $f)) { throw "missing: $f" }
    Write-Host "==> $f"

    # mysql.exe is fed a copy in an ASCII-only temp dir, so a non-ASCII
    # working directory (Chinese folder names) can never break the redirect.
    $tmp = Join-Path $env:TEMP ("dblab_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item -LiteralPath $f -Destination $tmp -Force
    $dst = Join-Path $tmp $f

    & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 < `"$dst`""
    if ($LASTEXITCODE -ne 0) { throw "failed: $f (exit $LASTEXITCODE)" }

    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Host ""
Write-Host "==> verify"
& cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 -e `"show tables from library_db071; select count(*) as readers from library_db071.readers;`""
Write-Host "all scripts applied successfully"
