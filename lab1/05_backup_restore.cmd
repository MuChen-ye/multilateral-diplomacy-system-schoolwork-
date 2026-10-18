@echo off
rem Lab 1 step 5 - backup + restore (command line method).
rem Double-click friendly: bypasses the PowerShell execution policy for this one run.
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0\05_backup_restore.ps1"
echo.
echo ----- finished (exit %ERRORLEVEL%) -----
pause
