@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:start
echo.
echo ╔═══════════════════════════════════════╗
echo ║   SAGE 100 SERVER CHECK - START      ║
echo ╚═══════════════════════════════════════╝
echo.
echo Willkommen beim Sage100 Server Check Tool!
echo.
echo Was möchten Sie tun?
echo.
echo [1] Quick-Start (ohne Installation)
echo [2] Vollständige Installation
echo [3] Diagnose ausführen
echo [Q] Beenden
echo.
set /p choice="Ihre Wahl: "

if /i "%choice%"=="1" (
    echo.
    echo Starte Quick-Start...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Quick-Start.ps1"
    goto :end
)

if /i "%choice%"=="2" (
    echo.
    echo Starte Installation...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0SETUP.ps1"
    goto :end
)

if /i "%choice%"=="3" (
    echo.
    echo Starte Diagnose...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Diagnose.ps1"
    goto :end
)

if /i "%choice%"=="q" (
    echo.
    echo Auf Wiedersehen!
    goto :end
)

echo.
echo Ungültige Eingabe!
timeout /t 2 >nul
goto :start

:end
echo.
pause
