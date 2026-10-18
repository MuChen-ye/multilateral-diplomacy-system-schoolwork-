@echo off
rem Lab 2 - double-click friendly launcher for run_all.ps1
rem Bypasses the PowerShell execution policy for this one run only.
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_all.ps1"
echo.
echo ----- finished (exit %ERRORLEVEL%) -----
pause
