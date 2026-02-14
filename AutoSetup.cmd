@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: === DEBUG LOGGING ===
set "LOGFILE=%~dp0debug.log"
echo === AUTOSETUP DEBUG LOG === > "%LOGFILE%"
echo Start: %date% %time% >> "%LOGFILE%"
echo Aktueller Ordner: %CD% >> "%LOGFILE%"
echo Script-Pfad: %~dp0 >> "%LOGFILE%"

:: === ALTERNATIVE ADMIN-PRÜFUNG (funktioniert auf allen Windows-Versionen) ===
echo Pruefe Admin-Rechte... >> "%LOGFILE%"

:: Methode: Versuche in System32 zu schreiben
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if %errorlevel% neq 0 (
    echo [FEHLER] Admin-Pruefung fehlgeschlagen - ErrorLevel: %errorlevel% >> "%LOGFILE%"
    cls
    echo.
    echo ================================================
    echo    SAGE 100 SERVER CHECK - INSTALLATION
    echo ================================================
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

echo [OK] Administrator-Rechte vorhanden >> "%LOGFILE%"

:: === INSTALLER SUCHEN ===
echo Suche Installer... >> "%LOGFILE%"

set "INSTALLER_PATH=%~dp0Installer\Simple-Installer.ps1"
echo Installer-Pfad: %INSTALLER_PATH% >> "%LOGFILE%"

if not exist "%INSTALLER_PATH%" (
    echo [FEHLER] Installer nicht gefunden: %INSTALLER_PATH% >> "%LOGFILE%"
    cls
    echo.
    echo ================================================
    echo    SAGE 100 SERVER CHECK - INSTALLATION
    echo ================================================
    echo.
    echo [FEHLER] Installer nicht gefunden
    echo.
    echo Erwartet: %INSTALLER_PATH%
    echo.
    echo Bitte komplettes Repository herunterladen:
    echo https://github.com/MJungAktuellis/Sage100-ServerCheck/archive/refs/heads/main.zip
    echo.
    pause
    exit /b 1
)

echo [OK] Installer gefunden >> "%LOGFILE%"

:: === POWERSHELL STARTEN ===
cls
echo.
echo ================================================
echo    SAGE 100 SERVER CHECK - INSTALLATION
echo ================================================
echo.
echo Starte Installer...
echo.

echo Starte PowerShell... >> "%LOGFILE%"
echo Befehl: PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER_PATH%" >> "%LOGFILE%"

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER_PATH%"

echo PowerShell beendet - ErrorLevel: %errorlevel% >> "%LOGFILE%"
echo Ende: %date% %time% >> "%LOGFILE%"

if %errorlevel% neq 0 (
    echo.
    echo [FEHLER] Installation fehlgeschlagen (ErrorLevel: %errorlevel%)
    echo.
    echo Details in: %LOGFILE%
    echo.
    pause
    exit /b %errorlevel%
)

echo.
echo Installation abgeschlossen
echo.
pause
exit /b 0
