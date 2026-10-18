param(
    [switch]$Backup   # also run step 5 (dump + restore + compare)
)

# Lab 1 - run the SQL scripts in guide order: 01 -> 02 -> 03 -> 04, then self-check.
#
# Usage:
#   .\run_all.ps1              # steps 1-4 + self-check
#   .\run_all.ps1 -Backup      # steps 1-4 + self-check + step 5 backup/restore
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

# 01 create DB / 02 tables / 03 data / 04 alter table structure
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

# 98 negative tests: illegal writes must be rejected (-f keeps going past errors).
# Runs before the self-check on purpose: the self-check then re-proves that the
# rejected writes left the data untouched (still 10/6/6/10/10).
if (Test-Path "98_constraint_tests.sql") {
    Write-Host ""
    Write-Host "==> 98_constraint_tests.sql (errors below are EXPECTED)"
    $tmp = Join-Path $env:TEMP ("dblab_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item -LiteralPath "98_constraint_tests.sql" -Destination $tmp -Force
    $dst = Join-Path $tmp "98_constraint_tests.sql"
    & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 -t -f < `"$dst`" 2>&1"
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

# 99 read-only self-check: tables, columns, constraints, FK, rows, ALTER result
if (Test-Path "99_verify.sql") {
    Write-Host "==> 99_verify.sql"
    $tmp = Join-Path $env:TEMP ("dblab_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item -LiteralPath "99_verify.sql" -Destination $tmp -Force
    $dst = Join-Path $tmp "99_verify.sql"
    # -t : print real tables instead of tab-separated rows (readable screenshots)
    & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 -t < `"$dst`""
    if ($LASTEXITCODE -ne 0) { throw "failed: 99_verify.sql (exit $LASTEXITCODE)" }
    Remove-Item -LiteralPath $tmp -Recurse -Force
}

if ($Backup) {
    Write-Host ""
    Write-Host "==> step 5: backup / restore"
    & (Join-Path $PSScriptRoot "05_backup_restore.ps1")
    if ($LASTEXITCODE -ne 0) { throw "backup/restore failed (exit $LASTEXITCODE)" }
}

Write-Host ""
Write-Host "all scripts applied successfully"
