# Lab 1 - step 5: backup and restore (method 1, command line, automated).
#
# What it does:
#   1) mysqldump library_db071  ->  backup\library_db071_full.sql
#   2) create an empty DB library_db071_restore (drop + create)
#   3) import the dump into it
#   4) compare row count AND a content digest per table between the two DBs
#
# Usage:
#   .\05_backup_restore.ps1
#   $env:MYSQL_PWD = "..."; .\05_backup_restore.ps1
#
# ASCII only on purpose: this file must parse under a GBK (cp936) console.
# Method 2 (Navicat GUI) is documented in README.md and is done by hand for screenshots.

$ErrorActionPreference = "Stop"

$binDir  = "C:\Program Files\MySQL\MySQL Server 9.4\bin"
$mysql   = Join-Path $binDir "mysql.exe"
$dumpExe = Join-Path $binDir "mysqldump.exe"
foreach ($exe in @($mysql, $dumpExe)) {
    if (-not (Test-Path $exe)) { throw "not found: $exe" }
}

if (-not $env:MYSQL_PWD) {
    $sec = Read-Host "MySQL root password" -AsSecureString
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}

$srcDb  = "library_db071"
$dstDb  = "library_db071_restore"
$tables = @("readers", "publishers", "book_categories", "books", "borrow_records")

# ---- per-table identity column + column list, used for the content digest ----
$meta = @{
    readers         = @{ key = "reader_id";   cols = @("reader_id","name","card_no","gender","phone","birthday","reader_type","max_borrow","registered") }
    publishers      = @{ key = "publisher_id";cols = @("publisher_id","name","city","founded_year") }
    book_categories = @{ key = "category_id"; cols = @("category_id","name","location") }
    books           = @{ key = "book_id";     cols = @("book_id","isbn","title","author","publisher_id","category_id","price","total_copies","available") }
    borrow_records  = @{ key = "record_id";   cols = @("record_id","reader_id","book_id","borrow_date","due_date","return_date","status") }
}

$work = Join-Path $env:TEMP ("dblab_restore_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work | Out-Null

function Invoke-SqlFile([string]$sqlText) {
    # mysql.exe is fed a temp file in an ASCII-only dir, so Chinese paths can
    # never break the stdin redirect.
    $q = Join-Path $work ("q_" + [guid]::NewGuid().ToString("N") + ".sql")
    Set-Content -LiteralPath $q -Value $sqlText -Encoding ascii
    $out = & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 -N -B < `"$q`""
    if ($LASTEXITCODE -ne 0) { throw "mysql failed (exit $LASTEXITCODE)" }
    return $out
}

$backupDir = Join-Path (Get-Location) "backup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
$backupFile = Join-Path $backupDir ($srcDb + "_full.sql")

try {
    # ---------- 1. dump ----------
    Write-Host "==> 1/4 mysqldump $srcDb"
    & $dumpExe -u root --default-character-set=utf8mb4 --single-transaction `
        --set-gtid-purged=OFF --result-file="$backupFile" $srcDb
    if ($LASTEXITCODE -ne 0) { throw "mysqldump failed (exit $LASTEXITCODE)" }
    $size = (Get-Item -LiteralPath $backupFile).Length
    Write-Host ("    saved: {0} ({1:N0} bytes)" -f $backupFile, $size)

    # ---------- 2. recreate the restore DB ----------
    Write-Host "==> 2/4 recreate empty $dstDb"
    Invoke-SqlFile "DROP DATABASE IF EXISTS ``$dstDb``; CREATE DATABASE ``$dstDb`` DEFAULT CHARACTER SET utf8mb4;" | Out-Null

    # ---------- 3. import ----------
    Write-Host "==> 3/4 import dump into $dstDb"
    $tmpDump = Join-Path $work "dump.sql"
    Copy-Item -LiteralPath $backupFile -Destination $tmpDump -Force
    $null = & cmd /c "`"$mysql`" -u root --default-character-set=utf8mb4 $dstDb < `"$tmpDump`""
    if ($LASTEXITCODE -ne 0) { throw "restore failed (exit $LASTEXITCODE)" }

    # ---------- 4. compare ----------
    Write-Host "==> 4/4 compare source and restored"
    $union = @()
    foreach ($db in @($srcDb, $dstDb)) {
        foreach ($t in $tables) {
            $expr = ($meta[$t].cols | ForEach-Object { "IFNULL(CAST(``$_`` AS CHAR), '~')" }) -join ", "
            $sql  = "SELECT '$db', '$t', COUNT(*), " +
                    "COALESCE(MD5(GROUP_CONCAT(CONCAT_WS('|', $expr) ORDER BY ``$($meta[$t].key)`` SEPARATOR ';')), '-') " +
                    "FROM ``$db``.``$t``"
            $union += $sql
        }
    }
    $raw = Invoke-SqlFile ("SET SESSION group_concat_max_len = 1048576;`n" + ($union -join "`nUNION ALL`n") + ";`n")

    $facts = @{}
    foreach ($line in $raw) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $p = $line -split "`t"
        if ($p.Count -lt 4) { continue }
        $facts["$($p[0])|$($p[1])"] = @{ rows = [int]$p[2]; digest = $p[3] }
    }

    $ok = $true
    Write-Host ""
    Write-Host ("{0,-18}{1,10}{2,12}{3,10}" -f "table", "source", "restored", "content")
    Write-Host ("{0,-18}{1,10}{2,12}{3,10}" -f "------------------", "----------", "------------", "----------")
    foreach ($t in $tables) {
        $a = $facts["$srcDb|$t"]
        $b = $facts["$dstDb|$t"]
        $same = ($a -and $b -and $a.rows -eq $b.rows -and $a.digest -eq $b.digest)
        if (-not $same) { $ok = $false }
        Write-Host ("{0,-18}{1,10}{2,12}{3,10}" -f $t, $(if ($a) { $a.rows } else { "?" }), $(if ($b) { $b.rows } else { "?" }), $(if ($same) { "SAME" } else { "DIFF" }))
    }

    # Chinese text survived the round trip?
    $sample = Invoke-SqlFile "SELECT name, card_no, phone FROM ``$dstDb``.readers ORDER BY reader_id LIMIT 3;"
    Write-Host ""
    Write-Host "sample rows in restored DB (check for mojibake):"
    $sample | ForEach-Object { Write-Host ("    " + $_) }

    Write-Host ""
    if ($ok) {
        Write-Host "RESULT: PASS - restored DB matches the source table by table."
    } else {
        Write-Host "RESULT: FAIL - source and restored DB differ, see the table above."
        exit 1
    }
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
