# Build the multilateral-diplomacy database from scratch and verify it.
#
#   .\run_all.ps1                     # prompts for the MySQL root password
#   $env:MYSQL_PWD = "..."; .\run_all.ps1
#
# ASCII only on purpose: this file must parse under a GBK (cp936) console.

$ErrorActionPreference = "Stop"

# -File does not change the working directory; anchor to the script folder so
# the numbered .sql files resolve no matter where the caller starts from.
Set-Location -LiteralPath $PSScriptRoot

$mysql = "C:\Program Files\MySQL\MySQL Server 9.4\bin\mysql.exe"
if (-not (Test-Path $mysql)) { throw "mysql.exe not found: $mysql" }

if (-not $env:MYSQL_PWD) {
    $sec = Read-Host "MySQL root password" -AsSecureString
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

# 01 build  -> 02 tables -> 03 data -> 04 views -> 06 triggers/procs -> 05 queries -> 99 verify
$files = @(
    "01_create_database.sql",
    "02_create_tables.sql",
    "03_insert_data.sql",
    "04_views.sql",
    "06_routines.sql",
    "05_queries.sql",
    "07_crud_samples.sql",
    "99_verify.sql"
)

foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath $f)) { throw "missing: $f" }
    Write-Host "==> $f"

    # mysql.exe is fed a copy in an ASCII-only temp dir, so a non-ASCII
    # working directory (Chinese folder names) can never break the redirect.
    $tmp = Join-Path $env:TEMP ("dlab_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item -LiteralPath $f -Destination $tmp -Force
    $dst = Join-Path $tmp $f

    if ($f -eq "99_verify.sql" -or $f -eq "05_queries.sql") {
        & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 --table < `"$dst`""
    } else {
        & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 < `"$dst`""
    }
    if ($LASTEXITCODE -ne 0) { throw "failed: $f (exit $LASTEXITCODE)" }

    Remove-Item -LiteralPath $tmp -Recurse -Force
}

Write-Host ""
Write-Host "all scripts applied successfully"
