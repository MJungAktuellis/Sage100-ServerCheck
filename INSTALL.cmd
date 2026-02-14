@echo off
:: =========================================
:: SAGE 100 SERVER CHECK - INSTALLER
:: Einziger Einstiegspunkt für Installation
:: =========================================

title Sage 100 Server Check - Installation

echo.
echo  ========================================
echo   SAGE 100 SERVER CHECK - INSTALLATION
echo  ========================================
echo.
echo  Willkommen zur Installation!
echo.
echo  Dieser Assistent wird:
echo   [1] Systemvoraussetzungen prüfen
echo   [2] Programm installieren
echo   [3] Erstkonfiguration durchführen
echo   [4] Desktop-Verknüpfung erstellen
echo.
pause

:: Administrator-Rechte prüfen
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo.
    echo  [FEHLER] Administrator-Rechte erforderlich!
    echo.
    echo  Bitte führen Sie diese Datei als Administrator aus:
    echo  Rechtsklick auf INSTALL.cmd -^> "Als Administrator ausführen"
    echo.
    pause
    exit /b 1
)

:: PowerShell-Version prüfen
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }"
if %errorLevel% NEQ 0 (
    echo.
    echo  [FEHLER] PowerShell 5.0 oder höher erforderlich!
    echo.
    pause
    exit /b 1
)

:: Hauptinstaller starten
echo.
echo  Starte Installation...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0setup\FirstRunWizard.ps1"

if %errorLevel% EQU 0 (
    echo.
    echo  ========================================
    echo   INSTALLATION ERFOLGREICH ABGESCHLOSSEN
    echo  ========================================
    echo.
    echo  Das Programm wurde erfolgreich installiert!
    echo  Desktop-Verknüpfung wurde erstellt.
    echo.
    pause
) else (
    echo.
    echo  [FEHLER] Installation fehlgeschlagen!
    echo.
    pause
    exit /b 1
)
