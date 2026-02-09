# ============================================================================
# SAGE 100 SERVER CHECK - VORAUSSETZUNGSPRÜFUNG
# ============================================================================
# Datei: Test-Prerequisites.ps1
# Zweck: Prüft alle Voraussetzungen vor der Installation
# Autor: KI-Projektmanagement
# ============================================================================

#Requires -Version 5.1

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SAGE 100 SERVER CHECK - VORAUSSETZUNGSPRÜFUNG          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"
$AllChecksPassed = $true

# ============================================================================
# FUNKTION: Test-Requirement
# ============================================================================
function Test-Requirement {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$SuccessMessage,
        [string]$FailureMessage
    )
    
    Write-Host "[PRÜFE] $Name... " -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "[✓] $SuccessMessage" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[✗] $FailureMessage" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[✗] Fehler: $_" -ForegroundColor Red
        return $false
    }
}

# ============================================================================
# CHECK 1: PowerShell-Version
# ============================================================================
$check1 = Test-Requirement `
    -Name "PowerShell-Version" `
    -Test { $PSVersionTable.PSVersion.Major -ge 5 } `
    -SuccessMessage "PowerShell $($PSVersionTable.PSVersion) erkannt" `
    -FailureMessage "PowerShell 5.1 oder höher erforderlich (aktuell: $($PSVersionTable.PSVersion))"

$AllChecksPassed = $AllChecksPassed -and $check1

# ============================================================================
# CHECK 2: Administrator-Rechte
# ============================================================================
$check2 = Test-Requirement `
    -Name "Administrator-Rechte" `
    -Test { 
        $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
        $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } `
    -SuccessMessage "Administrator-Rechte vorhanden" `
    -FailureMessage "Bitte als Administrator ausführen!"

$AllChecksPassed = $AllChecksPassed -and $check2

# ============================================================================
# CHECK 3: Module vorhanden
# ============================================================================
$requiredModules = @("SystemCheck", "NetworkCheck", "ComplianceCheck", "DebugLogger")
$modulePath = Join-Path $PSScriptRoot "Modules"

Write-Host "[PRÜFE] Module... " -NoNewline

$missingModules = @()
foreach ($module in $requiredModules) {
    $moduleFile = Join-Path $modulePath "$module.psm1"
    if (-not (Test-Path $moduleFile)) {
        $missingModules += $module
    }
}

if ($missingModules.Count -eq 0) {
    Write-Host "[✓] Alle Module gefunden" -ForegroundColor Green
    $check3 = $true
} else {
    Write-Host "[✗] Fehlende Module: $($missingModules -join ', ')" -ForegroundColor Red
    $check3 = $false
}

$AllChecksPassed = $AllChecksPassed -and $check3

# ============================================================================
# CHECK 4: Konfigurationsdatei
# ============================================================================
$configPath = Join-Path $PSScriptRoot "Config\config.json"

$check4 = Test-Requirement `
    -Name "Konfigurationsdatei" `
    -Test { Test-Path $configPath } `
    -SuccessMessage "config.json gefunden" `
    -FailureMessage "config.json fehlt in Config\"

$AllChecksPassed = $AllChecksPassed -and $check4

# ============================================================================
# CHECK 5: Execution Policy
# ============================================================================
Write-Host "[PRÜFE] Execution Policy... " -NoNewline
$policy = Get-ExecutionPolicy -Scope CurrentUser

if ($policy -eq "Unrestricted" -or $policy -eq "RemoteSigned" -or $policy -eq "Bypass") {
    Write-Host "[✓] Execution Policy: $policy" -ForegroundColor Green
    $check5 = $true
} else {
    Write-Host "[!] Warnung: Execution Policy ist $policy" -ForegroundColor Yellow
    Write-Host "    Empfohlen: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned" -ForegroundColor Yellow
    $check5 = $true  # Nur Warnung, kein Fehler
}

# ============================================================================
# ERGEBNIS
# ============================================================================
Write-Host "`n" + ("═" * 60) -ForegroundColor Cyan

if ($AllChecksPassed) {
    Write-Host "`n[✓] ALLE VORAUSSETZUNGEN ERFÜLLT!" -ForegroundColor Green
    Write-Host "`nDu kannst jetzt die Installation starten:" -ForegroundColor White
    Write-Host "  1. Führe EASY-INSTALL-v2.cmd als Administrator aus" -ForegroundColor Cyan
    Write-Host "  2. Oder starte direkt: .\src\Sage100-ServerCheck.ps1`n" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "`n[✗] VORAUSSETZUNGEN NICHT ERFÜLLT!" -ForegroundColor Red
    Write-Host "`nBitte behebe die oben genannten Fehler." -ForegroundColor Yellow
    Write-Host "Siehe: docs\INSTALLATION.md für Details`n" -ForegroundColor Yellow
    exit 1
}
