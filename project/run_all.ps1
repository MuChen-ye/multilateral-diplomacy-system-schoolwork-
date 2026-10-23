# Rebuild the demo database. SQL files contain DROP/TRUNCATE statements.
# Usage: .\run_all.ps1 [-MySqlPath "C:\path\to\mysql.exe"]
# ASCII only for Windows PowerShell consoles.
param([string]$MySqlPath)
$ErrorActionPreference = "Stop"

if (-not $MySqlPath) {
    $command = Get-Command mysql.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $command) { throw "Add MySQL bin to PATH or pass -MySqlPath." }
    $MySqlPath = $command.Source
}
if (-not (Test-Path -LiteralPath $MySqlPath -PathType Leaf)) {
    throw "mysql.exe not found: $MySqlPath"
}

$files = @(
    "01_create_database.sql", "02_create_tables.sql", "03_insert_data.sql",
    "04_views.sql", "06_routines.sql", "05_queries.sql", "07_crud_samples.sql",
    "08_course_examples.sql", "99_verify.sql"
)
foreach ($f in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $f))) { throw "Missing: $f" }
}

$prompted = -not $env:MYSQL_PWD
$tmp = $null
try {
    if ($prompted) {
        $sec = Read-Host "MySQL root password" -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try { $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("dlab_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tmp | Out-Null
    foreach ($f in $files) {
        Write-Host "==> $f"
        $dst = Join-Path $tmp $f
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $f) -Destination $dst
        & cmd /d /c "`"$MySqlPath`" -u root --default-character-set=utf8mb4 --table < `"$dst`""
        if ($LASTEXITCODE -ne 0) { throw "Failed: $f (exit $LASTEXITCODE)" }
    }
    Write-Host "All scripts applied successfully."
} finally {
    if ($tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
    if ($prompted) { Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue }
}
