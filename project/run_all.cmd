@echo off
rem Rebuild the demo database; forward the PowerShell exit code.
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_all.ps1" %*
set "result=%ERRORLEVEL%"
echo.
echo ----- finished (exit %result%) -----
pause
exit /b %result%
