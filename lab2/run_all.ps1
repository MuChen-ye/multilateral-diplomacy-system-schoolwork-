# Lab 2 - rebuild lab 1 first, then run the lab 2 scripts in guide order.
#
# 实验二基于实验一的数据库，而 04_updates.sql 会改数据（改 max_borrow、加册数、
# 还书、删测试出版社），所以这里先把实验一 01~04 重跑一遍把数据恢复到初始状态，
# 再跑实验二的 01~05，整条链可反复执行。
#
# Usage:
#   .\run_all.ps1
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

$lab1 = Join-Path (Split-Path $PSScriptRoot -Parent) "lab1"

function Invoke-Sql([string]$path, [switch]$Force, [switch]$Verbose) {
    if (-not (Test-Path $path)) { throw "missing: $path" }
    $name = Split-Path $path -Leaf
    Write-Host "==> $name"

    # mysql.exe is fed a copy in an ASCII-only temp dir, so a non-ASCII
    # working directory (Chinese folder names) can never break the redirect.
    $tmp = Join-Path $env:TEMP ("dblab2_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    Copy-Item -LiteralPath $path -Destination $tmp -Force
    $dst = Join-Path $tmp $name

    $mysqlArgs = "-u root --default-character-set=utf8mb4"
    if ($Force)   { $mysqlArgs += " -f" }
    if ($Verbose) { $mysqlArgs += " -t" }
    & cmd /c "`"$mysql`" $mysqlArgs < `"$dst`""
    $code = $LASTEXITCODE
    Remove-Item -LiteralPath $tmp -Recurse -Force
    if ($code -ne 0 -and -not $Force) { throw "failed: $name (exit $code)" }
}

Write-Host "=== step 0: rebuild lab 1 (data reset) ==="
foreach ($f in @("01_create_database.sql", "02_create_tables.sql", "03_insert_data.sql", "04_alter_tables.sql")) {
    Invoke-Sql (Join-Path $lab1 $f)
}

Write-Host ""
Write-Host "=== step 1: lab 2 queries and updates ==="
foreach ($f in @("01_queries_simple.sql", "02_queries_join.sql", "03_queries_nested.sql", "04_updates.sql")) {
    Invoke-Sql (Join-Path $PSScriptRoot $f) -Verbose
}

Write-Host ""
Write-Host "=== step 2: integrity constraints (errors below are EXPECTED) ==="
Invoke-Sql (Join-Path $PSScriptRoot "05_constraints.sql") -Verbose -Force

Write-Host ""
Write-Host "=== step 3: final check ==="
& cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 -t -e `"select (select count(*) from library_db071.readers) as readers, (select count(*) from library_db071.books) as books, (select count(*) from library_db071.borrow_records) as borrow_records;`""
Write-Host ""
Write-Host "all lab 2 scripts applied successfully"
