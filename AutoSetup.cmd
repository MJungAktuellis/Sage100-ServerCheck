@echo off
setlocal enabledelayedexpansion

:: Debugging aktivieren - alle Ausgaben in Log-Datei
set "LOGFILE=%~dp0debug.log"
echo === AUTOSETUP DEBUG LOG === > "%LOGFILE%"
echo Start: %date% %time% >> "%LOGFILE%"
echo Aktueller Ordner: %CD% >> "%LOGFILE%"
echo Script-Pfad: %~dp0 >> "%LOGFILE%"

title SAGE 100 SERVER CHECK - INSTALLATION

:: Administrator-Check
echo Pruefe Admin-Rechte... >> "%LOGFILE%"
net session >nul 2>&1
if not %errorLevel% == 0 (
    echo FEHLER: Keine Admin-Rechte >> "%LOGFILE%"
    cls
    echo.
    echo [FEHLER] Keine Administrator-Rechte!
    echo.
    echo Bitte:
    echo 1. Rechtsklick auf AutoSetup.cmd
    echo 2. "Als Administrator ausfuehren" waehlen
    echo.
    echo Details: %LOGFILE%
    echo.
    pause
    exit /b 1
)
echo Admin-Rechte OK >> "%LOGFILE%"

cls
echo.
echo ================================================
echo    SAGE 100 SERVER CHECK - INSTALLATION
echo ================================================
echo.
echo Starte Installer...
echo.

:: Prüfe ob Installer existiert
echo Pruefe Installer-Dateien... >> "%LOGFILE%"
echo Suche in: %~dp0Installer\Simple-Installer.ps1 >> "%LOGFILE%"

if not exist "%~dp0Installer\Simple-Installer.ps1" (
    echo FEHLER: Installer nicht gefunden! >> "%LOGFILE%"
    echo.
    echo [FEHLER] Installer-Dateien nicht gefunden!
    echo.
    echo Erwartet: %~dp0Installer\Simple-Installer.ps1
    echo Aktueller Ordner: %CD%
    echo.
    echo Details: %LOGFILE%
    echo.
    pause
    exit /b 1
)
echo Installer gefunden >> "%LOGFILE%"

:: PowerShell-Version prüfen
echo Pruefe PowerShell... >> "%LOGFILE%"
powershell.exe -Command "$PSVersionTable.PSVersion" >> "%LOGFILE%" 2>&1

:: Starte PowerShell-Installer
echo Starte PowerShell-Installer... >> "%LOGFILE%"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0Installer\Simple-Installer.ps1" 2>> "%LOGFILE%"

set EXITCODE=%errorLevel%
echo PowerShell Exit-Code: %EXITCODE% >> "%LOGFILE%"

if %EXITCODE% == 0 (
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
    echo Exit-Code: %EXITCODE%
    echo Details: %LOGFILE%
    echo.
)

echo.
echo Debug-Log gespeichert in: %LOGFILE%
echo.
pause
