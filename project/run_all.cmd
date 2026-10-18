@echo off
rem Build and verify the multilateral-diplomacy database from scratch.
rem Bypasses the PowerShell execution policy for this one run only.
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_all.ps1" %*
echo.
echo ----- finished (exit %ERRORLEVEL%) -----
pause
