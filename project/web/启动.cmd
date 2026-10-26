@echo off
chcp 65001 >nul
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js not found. Install Node.js 18+ first.
  pause
  exit /b 1
)
start "" http://127.0.0.1:8765
node server.js
pause
