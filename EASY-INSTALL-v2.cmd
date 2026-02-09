@echo off
REM ============================================
REM SAGE 100 SERVER CHECK - INSTALLER v2.0
REM Verbesserte Installation mit Fehlerprüfung
REM ============================================

title Sage100-ServerCheck Installer v2.0
color 0A

echo.
echo ╔═══════════════════════════════════════════════╗
echo ║  SAGE 100 SERVER CHECK - INSTALLER v2.0      ║
echo ╚═══════════════════════════════════════════════╝
echo.

REM ============================================
REM SCHRITT 1: ADMIN-RECHTE PRÜFEN
REM ============================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [FEHLER] Keine Administrator-Rechte!
    echo.
    echo Bitte fuehren Sie dieses Skript als Administrator aus:
    echo 1. Rechtsklick auf EASY-INSTALL-v2.cmd
    echo 2. "Als Administrator ausfuehren" waehlen
    echo.
    pause
    exit /b 1
)
echo [OK] Administrator-Rechte vorhanden

REM ============================================
REM SCHRITT 2: POWERSHELL-VERSION PRÜFEN
REM ============================================
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo [FEHLER] PowerShell 5.1 oder hoeher erforderlich!
    echo.
    echo Bitte installieren Sie Windows Management Framework 5.1:
    echo https://www.microsoft.com/download/details.aspx?id=54616
    echo.
    pause
    exit /b 1
)
echo [OK] PowerShell 5.1 oder hoeher erkannt

REM ============================================
REM SCHRITT 3: MODULE IMPORTIEREN
REM ============================================
echo.
echo Importiere Module...

powershell -ExecutionPolicy Bypass -Command ^
"Import-Module '.\Modules\SystemCheck.psm1' -Force; ^
 Import-Module '.\Modules\NetworkCheck.psm1' -Force; ^
 Import-Module '.\Modules\ComplianceCheck.psm1' -Force; ^
 Import-Module '.\Modules\DebugLogger.psm1' -Force; ^
 if ($?) { exit 0 } else { exit 1 }"

if %errorlevel% neq 0 (
    echo [FEHLER] Module konnten nicht geladen werden!
    echo.
    echo Ueberpruefen Sie, ob alle Dateien vorhanden sind:
    echo - .\Modules\SystemCheck.psm1
    echo - .\Modules\NetworkCheck.psm1
    echo - .\Modules\ComplianceCheck.psm1
    echo - .\Modules\DebugLogger.psm1
    echo.
    pause
    exit /b 1
)
echo [OK] Module erfolgreich importiert

REM ============================================
REM SCHRITT 4: KONFIGURATION PRÜFEN
REM ============================================
if not exist "Config\config.json" (
    echo [WARNUNG] Konfigurationsdatei nicht gefunden!
    echo Erstelle Standard-Konfiguration...
    
    if not exist "Config" mkdir Config
    
    powershell -Command ^
    "$config = @{DNS='8.8.8.8'; TestServer='www.google.com'}; ^
     $config | ConvertTo-Json | Out-File -FilePath '.\Config\config.json' -Encoding UTF8"
    
    echo [OK] Standard-Konfiguration erstellt
) else (
    echo [OK] Konfigurationsdatei vorhanden
)

REM ============================================
REM SCHRITT 5: LOGS-VERZEICHNIS ERSTELLEN
REM ============================================
if not exist "Logs" mkdir Logs
echo [OK] Logs-Verzeichnis erstellt

REM ============================================
REM ABSCHLUSS
REM ============================================
echo.
echo ╔═══════════════════════════════════════════════╗
echo ║         INSTALLATION ABGESCHLOSSEN!          ║
echo ╚═══════════════════════════════════════════════╝
echo.
echo Starten Sie das Tool mit:
echo   .\src\Sage100-ServerCheck.ps1
echo.
echo Oder fuehren Sie einen Test aus:
echo   .\Tests\Test-Prerequisites.ps1
echo.
pause
