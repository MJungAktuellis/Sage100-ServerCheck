@echo off
REM ============================================================================
REM Sage100 Server Check - ONE-CLICK INSTALLER
REM 
REM For users without programming knowledge:
REM   1. Double-click this file
REM   2. Click "Yes" when Windows asks for Administrator permissions
REM   3. Wait for installation to complete
REM   4. Done!
REM
REM Compatible with: Windows 7, 8, 10, 11, Server 2012-2022
REM ============================================================================

title Sage100 Server Check - Easy Installer

echo.
echo ========================================================================
echo   Sage100 Server Check - One-Click Installation
echo ========================================================================
echo.
echo   This will automatically:
echo     - Download the latest version
echo     - Install all files
echo     - Create desktop shortcut
echo     - Set up automated monitoring
echo.
echo   Press any key to start installation...
echo   (or close this window to cancel)
echo.
pause >nul

REM Check for Administrator rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ERROR: Administrator rights required!
    echo.
    echo Please right-click this file and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

echo.
echo [1/4] Checking system requirements...
echo.

REM Check PowerShell version
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 } else { exit 0 }"
if %errorLevel% neq 0 (
    echo ERROR: PowerShell 5.1 or higher required!
    echo.
    echo Please update Windows or install PowerShell 7
    echo Download: https://aka.ms/powershell
    echo.
    pause
    exit /b 1
)

echo OK - PowerShell 5.1+ detected

echo.
echo [2/4] Downloading latest version from GitHub...
echo.

REM Set download URL
set "DOWNLOAD_URL=https://github.com/MJungAktuellis/Sage100-ServerCheck/archive/refs/heads/main.zip"
set "TEMP_DIR=%TEMP%\Sage100-ServerCheck-Installer"
set "ZIP_FILE=%TEMP_DIR%\Sage100-ServerCheck.zip"
set "EXTRACT_DIR=%TEMP_DIR%\Extract"

REM Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"
if not exist "%EXTRACT_DIR%" mkdir "%EXTRACT_DIR%"

REM Download using PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing}"

if not exist "%ZIP_FILE%" (
    echo ERROR: Download failed!
    echo.
    echo Please check your internet connection
    echo.
    pause
    exit /b 1
)

echo OK - Download completed

echo.
echo [3/4] Extracting files...
echo.

REM Extract ZIP using PowerShell
powershell -Command "& {Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force}"

if not exist "%EXTRACT_DIR%\Sage100-ServerCheck-main" (
    echo ERROR: Extraction failed!
    echo.
    pause
    exit /b 1
)

echo OK - Files extracted

echo.
echo [4/4] Running installation wizard...
echo.

REM Run installer
cd /d "%EXTRACT_DIR%\Sage100-ServerCheck-main"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Install.ps1" -CreateScheduledTask -CreateDesktopShortcut

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Installation failed!
    echo.
    echo Check log file: %TEMP%\Sage100-ServerCheck-Install.log
    echo.
    pause
    exit /b 1
)

REM Cleanup
rd /s /q "%TEMP_DIR%" 2>nul

echo.
echo ========================================================================
echo   Installation completed successfully!
echo ========================================================================
echo.
echo   You can now find "Sage100 Server Check" on your desktop
echo.
echo   Next steps:
echo     1. Double-click the desktop icon
echo     2. Configure your Sage 100 server settings
echo     3. Start monitoring
echo.
echo   Press any key to exit...
echo.
pause >nul

exit /b 0
