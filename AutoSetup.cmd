@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================
:: SAGE 100 SERVER CHECK - AUTO SETUP
:: ============================================

title SAGE 100 SERVER CHECK - INSTALLATION

:: Administrator-Check
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [FEHLER] Keine Administrator-Rechte!
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

:: Prüfe ob Installer-Ordner existiert
if not exist "Installer\Simple-Installer.ps1" (
    echo [FEHLER] Installer-Dateien nicht gefunden!
    echo.
    echo Erwartet: Installer\Simple-Installer.ps1
    echo Aktueller Ordner: %CD%
    echo.
    pause
    exit /b 1
)

:: Starte PowerShell-Installer
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "Installer\Simple-Installer.ps1"

if %errorLevel% equ 0 (
    echo.
    echo ================================================
    echo   INSTALLATION ERFOLGREICH ABGESCHLOSSEN!
    echo ================================================
    echo.
) else (
    echo.
    echo ================================================
    echo   [FEHLER] Installation fehlgeschlagen!
    echo ================================================
    echo.
    echo Details finden Sie in: %CD%\Logs\installer.log
    echo.
)

pause