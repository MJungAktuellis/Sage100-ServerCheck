@echo off
chcp 65001 >nul
title Sage100 ServerCheck - Installation

REM ═══════════════════════════════════════════════════════════
REM   SAGE 100 SERVER CHECK - AUTOMATISCHE INSTALLATION
REM   Version: 1.0
REM   Autor: Professional DevOps Team
REM ═══════════════════════════════════════════════════════════

cls
echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║                                                           ║
echo ║     SAGE 100 SERVER CHECK - INSTALLATION                 ║
echo ║                                                           ║
echo ║     Willkommen zur automatischen Installation!           ║
echo ║                                                           ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.
echo [INFO] Starte grafische Installation...
echo.

REM Prüfe Admin-Rechte
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [FEHLER] Dieses Skript benötigt Administrator-Rechte!
    echo.
    echo Bitte:
    echo 1. Rechtsklick auf AutoSetup.cmd
    echo 2. "Als Administrator ausführen" wählen
    echo.
    pause
    exit /b 1
)

REM Prüfe PowerShell-Version
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo [FEHLER] PowerShell 5.0 oder höher erforderlich!
    echo.
    echo Bitte installieren Sie Windows Management Framework 5.1:
    echo https://www.microsoft.com/download/details.aspx?id=54616
    echo.
    pause
    exit /b 1
)

echo [OK] Administrator-Rechte vorhanden
echo [OK] PowerShell Version ausreichend
echo.
echo [INFO] Starte GUI-Installer in 3 Sekunden...
timeout /t 3 /nobreak >nul

REM Starte GUI-Installer
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0Installer\GUI-Installer.ps1"

if %errorlevel% equ 0 (
    echo.
    echo ╔═══════════════════════════════════════════════════════════╗
    echo ║                                                           ║
    echo ║     INSTALLATION ERFOLGREICH ABGESCHLOSSEN!              ║
    echo ║                                                           ║
    echo ╚═══════════════════════════════════════════════════════════╝
    echo.
) else (
    echo.
    echo [FEHLER] Installation fehlgeschlagen!
    echo Details finden Sie in: %~dp0Logs\installer.log
    echo.
)

pause
