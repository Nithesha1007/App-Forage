@echo off
title APK Build Server
echo.
echo ========================================
echo   APK Build Server
echo   http://localhost:3001
echo ========================================
echo.
echo Starting backend server...
echo Keep this window open while building APKs.
echo.
cd /d "%~dp0"
node build-server.js
pause
