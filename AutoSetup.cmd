@echo off
setlocal enabledelayedexpansion

title SAGE 100 SERVER CHECK - INSTALLATION

net session >nul 2>&1
if not %errorLevel% == 0 (
    echo.
    echo [FEHLER] Keine Administrator-Rechte
    echo.
    echo Bitte:
    echo 1. Rechtsklick auf AutoSetup.cmd
    echo 2. "Als Administrator ausfuehren" waehlen
    echo.
    pause
    exit /b 1
)

cls
echo.
echo ================================================
echo    SAGE 100 SERVER CHECK - INSTALLATION
echo ================================================
echo.
echo Starte Installer...
echo.

if not exist "Installer\Simple-Installer.ps1" (
    echo [FEHLER] Installer nicht gefunden!
    echo.
    echo Erwartet: Installer\Simple-Installer.ps1
    echo Aktuell: %CD%
    echo.
    pause
    exit /b 1
)

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "Installer\Simple-Installer.ps1"

if %errorLevel% == 0 (
    echo.
    echo ================================================
    echo   INSTALLATION ERFOLGREICH!
    echo ================================================
    echo.
) else (
    echo.
    echo ================================================
    echo   INSTALLATION FEHLGESCHLAGEN
    echo ================================================
    echo.
)

pause
