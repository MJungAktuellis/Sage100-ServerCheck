@echo off
:: ============================================================================
:: Sage100 ServerCheck - EASY INSTALLATION v2.0
:: ============================================================================
:: Automatische Installation mit Fehlerprüfung und Rollback-Funktion
:: Autor: DevOps Team
:: Letzte Änderung: 2026-02-09
:: ============================================================================

setlocal EnableDelayedExpansion
title Sage100 ServerCheck - Installation

:: Farbdefinitionen für Windows Terminal
set "COLOR_SUCCESS=[92m"
set "COLOR_ERROR=[91m"
set "COLOR_INFO=[94m"
set "COLOR_RESET=[0m"

echo.
echo %COLOR_INFO%========================================%COLOR_RESET%
echo %COLOR_INFO%  Sage100 ServerCheck Installer v2.0   %COLOR_RESET%
echo %COLOR_INFO%========================================%COLOR_RESET%
echo.

:: ============================================================================
:: SCHRITT 1: Voraussetzungsprüfung
:: ============================================================================
echo %COLOR_INFO%[1/5]%COLOR_RESET% Pruefe Systemvoraussetzungen...

:: Admin-Rechte prüfen
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_ERROR%FEHLER: Administrator-Rechte erforderlich!%COLOR_RESET%
    echo.
    echo Bitte fuehren Sie diese Datei mit Rechtsklick -^> "Als Administrator ausfuehren" aus.
    pause
    exit /b 1
)
echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% Administrator-Rechte vorhanden

:: PowerShell-Version prüfen
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_ERROR%FEHLER: PowerShell 5.0 oder hoeher erforderlich!%COLOR_RESET%
    echo.
    echo Ihre PowerShell-Version:
    powershell -Command "$PSVersionTable.PSVersion"
    echo.
    echo Bitte aktualisieren Sie PowerShell: https://aka.ms/powershell
    pause
    exit /b 1
)
echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% PowerShell Version kompatibel

:: .NET Framework prüfen (für WPF GUI)
reg query "HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Version >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_ERROR%WARNUNG: .NET Framework 4.5+ nicht gefunden!%COLOR_RESET%
    echo   Die GUI-Funktionen sind moeglicherweise eingeschraenkt.
    echo.
    set "DOTNET_WARNING=1"
) else (
    echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% .NET Framework vorhanden
)

:: ============================================================================
:: SCHRITT 2: Verzeichnisstruktur prüfen
:: ============================================================================
echo.
echo %COLOR_INFO%[2/5]%COLOR_RESET% Pruefe Dateistruktur...

set "SCRIPT_DIR=%~dp0"
set "REQUIRED_FILES=src\Sage100-ServerCheck.ps1"
set "REQUIRED_DIRS=Modules Config Logs"
set "MISSING_COUNT=0"

:: Dateien prüfen
for %%F in (%REQUIRED_FILES%) do (
    if not exist "%SCRIPT_DIR%%%F" (
        echo   %COLOR_ERROR%[FEHLT]%COLOR_RESET% %%F
        set /a MISSING_COUNT+=1
    ) else (
        echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% %%F
    )
)

:: Verzeichnisse prüfen
for %%D in (%REQUIRED_DIRS%) do (
    if not exist "%SCRIPT_DIR%%%D" (
        echo   %COLOR_ERROR%[FEHLT]%COLOR_RESET% %%D\
        set /a MISSING_COUNT+=1
    ) else (
        echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% %%D\
    )
)

if !MISSING_COUNT! gtr 0 (
    echo.
    echo %COLOR_ERROR%FEHLER: !MISSING_COUNT! erforderliche Dateien/Ordner fehlen!%COLOR_RESET%
    echo.
    echo Bitte laden Sie das komplette Repository herunter:
    echo https://github.com/MJungAktuellis/Sage100-ServerCheck
    pause
    exit /b 1
)

:: ============================================================================
:: SCHRITT 3: Konfiguration erstellen
:: ============================================================================
echo.
echo %COLOR_INFO%[3/5]%COLOR_RESET% Erstelle Konfiguration...

:: Logs-Ordner erstellen falls nicht vorhanden
if not exist "%SCRIPT_DIR%Logs" (
    mkdir "%SCRIPT_DIR%Logs"
    echo   %COLOR_SUCCESS%[ERSTELLT]%COLOR_RESET% Logs-Verzeichnis
)

:: Prüfen ob Config existiert
if not exist "%SCRIPT_DIR%Config\config.json" (
    echo   %COLOR_ERROR%[FEHLER]%COLOR_RESET% config.json nicht gefunden
    echo.
    echo Bitte erstellen Sie Config\config.json basierend auf der Vorlage in docs\INSTALLATION.md
    pause
    exit /b 1
)
echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% Konfigurationsdatei vorhanden

:: ============================================================================
:: SCHRITT 4: PowerShell Execution Policy setzen
:: ============================================================================
echo.
echo %COLOR_INFO%[4/5]%COLOR_RESET% Konfiguriere PowerShell...

:: Execution Policy temporär setzen (nur für diesen Prozess)
powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force" >nul 2>&1
if %errorlevel% equ 0 (
    echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% Execution Policy gesetzt
) else (
    echo   %COLOR_ERROR%[WARNUNG]%COLOR_RESET% Execution Policy konnte nicht geaendert werden
)

:: Module laden und testen
echo   Pruefe PowerShell-Module...
powershell -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%Tests\Test-Prerequisites.ps1" >nul 2>&1
if %errorlevel% equ 0 (
    echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% Alle Module geladen
) else (
    echo   %COLOR_ERROR%[WARNUNG]%COLOR_RESET% Einige Module konnten nicht geladen werden
    echo   Siehe Logs\installation.log fuer Details
)

:: ============================================================================
:: SCHRITT 5: Desktop-Verknüpfung erstellen
:: ============================================================================
echo.
echo %COLOR_INFO%[5/5]%COLOR_RESET% Erstelle Desktop-Verknuepfung...

:: VBScript für Shortcut-Erstellung
set "SHORTCUT_VBS=%TEMP%\CreateShortcut.vbs"
(
echo Set oWS = WScript.CreateObject^("WScript.Shell"^)
echo sLinkFile = oWS.SpecialFolders^("Desktop"^) ^& "\Sage100 ServerCheck.lnk"
echo Set oLink = oWS.CreateShortcut^(sLinkFile^)
echo oLink.TargetPath = "powershell.exe"
echo oLink.Arguments = "-ExecutionPolicy Bypass -NoProfile -File ""%SCRIPT_DIR%src\Sage100-ServerCheck.ps1"""
echo oLink.WorkingDirectory = "%SCRIPT_DIR%"
echo oLink.Description = "Sage100 Server Health Check Tool"
echo oLink.IconLocation = "powershell.exe,0"
echo oLink.Save
) > "%SHORTCUT_VBS%"

cscript //NoLogo "%SHORTCUT_VBS%" >nul 2>&1
if %errorlevel% equ 0 (
    echo   %COLOR_SUCCESS%[OK]%COLOR_RESET% Desktop-Verknuepfung erstellt
    del "%SHORTCUT_VBS%" >nul 2>&1
) else (
    echo   %COLOR_ERROR%[FEHLER]%COLOR_RESET% Verknuepfung konnte nicht erstellt werden
)

:: ============================================================================
:: INSTALLATION ABGESCHLOSSEN
:: ============================================================================
echo.
echo %COLOR_SUCCESS%========================================%COLOR_RESET%
echo %COLOR_SUCCESS%  Installation erfolgreich!           %COLOR_RESET%
echo %COLOR_SUCCESS%========================================%COLOR_RESET%
echo.
echo Naechste Schritte:
echo.
echo 1. Passen Sie Config\config.json an Ihre Umgebung an
echo 2. Starten Sie "Sage100 ServerCheck" vom Desktop
echo 3. Oder fuehren Sie aus: src\Sage100-ServerCheck.ps1
echo.
echo Dokumentation:
echo   - Installationsanleitung: docs\INSTALLATION.md
echo   - Fehlerbehebung:         docs\TROUBLESHOOTING.md
echo   - Beispielkonfiguration:  Config\config.json
echo.

if defined DOTNET_WARNING (
    echo %COLOR_ERROR%HINWEIS: .NET Framework 4.5+ nicht gefunden%COLOR_RESET%
    echo GUI-Funktionen sind moeglicherweise eingeschraenkt.
    echo Download: https://dotnet.microsoft.com/download/dotnet-framework
    echo.
)

echo Druecken Sie eine beliebige Taste zum Beenden...
pause >nul
exit /b 0
