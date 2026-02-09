@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ═══════════════════════════════════════════════════════════════
:: SAGE 100 SERVER CHECK - INSTALLER v2.0 (FIXED)
:: ═══════════════════════════════════════════════════════════════

title SAGE 100 SERVER CHECK - INSTALLER v2.0

cls
echo.
echo ╔══════════════════════════════════════════════════╗
echo ║  SAGE 100 SERVER CHECK - INSTALLER v2.0      ║
echo ╚══════════════════════════════════════════════════╝
echo.

:: ─────────────────────────────────────────────────────────────────
:: 1. ADMINISTRATOR-RECHTE PRÜFEN
:: ─────────────────────────────────────────────────────────────────
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [FEHLER] Dieses Skript muss als Administrator ausgefuehrt werden!
    echo.
    echo Rechtsklick auf die Datei ^> "Als Administrator ausfuehren"
    pause
    exit /b 1
)
echo [OK] Administrator-Rechte vorhanden

:: ─────────────────────────────────────────────────────────────────
:: 2. POWERSHELL-VERSION PRÜFEN
:: ─────────────────────────────────────────────────────────────────
for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set PS_VERSION=%%i
if %PS_VERSION% LSS 5 (
    echo [FEHLER] PowerShell 5.1 oder hoeher wird benoetigt!
    echo Aktuelle Version: %PS_VERSION%
    pause
    exit /b 1
)
echo [OK] PowerShell 5.1 oder hoeher erkannt

:: ─────────────────────────────────────────────────────────────────
:: 3. DATEIEN UND ORDNER PRÜFEN
:: ─────────────────────────────────────────────────────────────────
echo.
echo Pruefe Repository-Struktur...

set "FILES_MISSING=0"

:: Prüfe ALLE kritischen Dateien
if not exist "Config\config.json" (
    echo [FEHLER] Config\config.json fehlt!
    set "FILES_MISSING=1"
)

if not exist "Config\thresholds.json" (
    echo [FEHLER] Config\thresholds.json fehlt!
    set "FILES_MISSING=1"
)

if not exist "Config\email_template.html" (
    echo [FEHLER] Config\email_template.html fehlt!
    set "FILES_MISSING=1"
)

if !FILES_MISSING! equ 1 (
    echo.
    echo [FEHLER] Kritische Dateien fehlen!
    echo.
    echo Bitte stellen Sie sicher, dass Sie das komplette Repository heruntergeladen haben.
    echo.
    pause
    exit /b 1
)

echo [OK] Alle kritischen Dateien vorhanden

:: ─────────────────────────────────────────────────────────────────
:: 4. LOG-VERZEICHNIS ERSTELLEN
:: ─────────────────────────────────────────────────────────────────
if not exist "Logs" (
    mkdir "Logs" 2>nul
    if exist "Logs" (
        echo [OK] Logs-Ordner erstellt
    ) else (
        echo [WARNUNG] Logs-Ordner konnte nicht erstellt werden
    )
) else (
    echo [OK] Logs-Ordner bereits vorhanden
)

:: ─────────────────────────────────────────────────────────────────
:: 5. CONFIG.JSON VALIDIEREN
:: ─────────────────────────────────────────────────────────────────
echo.
echo Validiere Konfiguration...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"try { $config = Get-Content -Path 'Config\config.json' -Raw | ConvertFrom-Json; Write-Host '[OK] config.json ist gueltig' } catch { Write-Host '[FEHLER] config.json ist ungueltig:' $_.Exception.Message; exit 1 }"

if %errorlevel% neq 0 (
    echo.
    echo Bitte korrigieren Sie die Fehler in Config\config.json
    pause
    exit /b 1
)

:: ─────────────────────────────────────────────────────────────────
:: 6. INSTALLATION ABGESCHLOSSEN
:: ─────────────────────────────────────────────────────────────────
echo.
echo ═══════════════════════════════════════════════════
echo    INSTALLATION ERFOLGREICH ABGESCHLOSSEN!
echo ═══════════════════════════════════════════════════
echo.
echo Naechste Schritte:
echo.
echo 1. Oeffnen Sie Config\config.json und passen Sie die
echo    Einstellungen an Ihre Umgebung an
echo.
echo 2. Starten Sie das Programm mit einem der folgenden Befehle:
echo.
echo    # Einzelner Check:
echo    powershell -ExecutionPolicy Bypass -File src\Sage100-ServerCheck.ps1
echo.
echo    # Mit detailliertem Log:
echo    powershell -ExecutionPolicy Bypass -File src\Sage100-ServerCheck.ps1 -Verbose
echo.
echo 3. (Optional) Richten Sie einen Windows Task Scheduler ein
echo    fuer automatische, regelmaessige Checks
echo.
echo.
pause
