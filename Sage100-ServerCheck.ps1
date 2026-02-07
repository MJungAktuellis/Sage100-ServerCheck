<#
.SYNOPSIS
    Sage 100 Server Check & Configuration Tool
    
.DESCRIPTION
    Automatisches PowerShell-Tool zur Validierung und Konfiguration von Sage 100 Server-Installationen.
    Prüft Systemvoraussetzungen, Ports, SQL Server und erstellt Dokumentation.
    
.PARAMETER Mode
    Betriebsmodus:
    - Check: Nur Systemprüfung (Standard)
    - Fix: Prüfung + Interaktive Behebung
    - Export: Markdown-Export erstellen
    - Full: Alles (Check + Fix + Export)
    - WorkLog: Arbeitsprotokoll verwalten
    
.PARAMETER OutputPath
    Pfad für Markdown-Export (Standard: .\reports\)
    
.PARAMETER Silent
    Keine interaktiven Prompts (nur für Automation)
    
.EXAMPLE
    .\Sage100-ServerCheck.ps1 -Mode Check
    
.EXAMPLE
    .\Sage100-ServerCheck.ps1 -Mode Full -OutputPath "C:\Reports\Kunde_XYZ.md"
    
.NOTES
    Version: 1.0
    Author: M. Jung / Aktuellis
    
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Check', 'Fix', 'Export', 'Full', 'WorkLog')]
    [string]$Mode = 'Check',
    
    [Parameter()]
    [string]$OutputPath = ".\reports\",
    
    [Parameter()]
    [switch]$Silent
)

# ═══════════════════════════════════════════════════════════════════════════
# INITIALISIERUNG
# ═══════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = 'Stop'
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModulePath = Join-Path $ScriptPath "modules"
$ConfigPath = Join-Path $ScriptPath "config"
$LogPath = Join-Path $ScriptPath "logs"

# Verzeichnisse erstellen
@($OutputPath, $LogPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Module laden
$RequiredModules = @(
    'SystemCheck',
    'PortCheck',
    'SQLCheck',
    'DirectorySetup',
    'WorkLog',
    'MarkdownExport'
)

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Sage 100 Server-Check v1.0                          ║" -ForegroundColor Cyan
Write-Host "║   Server: $env:COMPUTERNAME".PadRight(56) + "║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Admin-Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Dieses Skript benötigt Administrator-Rechte für vollständige Funktionalität."
    if (-not $Silent) {
        $continue = Read-Host "Trotzdem fortfahren? (J/N)"
        if ($continue -ne 'J') { exit }
    }
}

Write-Host "[i] Lade Module..." -ForegroundColor Gray

foreach ($module in $RequiredModules) {
    $modulePath = Join-Path $ModulePath "$module.psm1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ $module geladen" -ForegroundColor Green
    } else {
        Write-Warning "  ! Modul $module nicht gefunden - erstelle Platzhalter..."
        # Platzhalter-Modul erstellen (wird später durch echte Module ersetzt)
        $placeholderContent = @"
function Get-$module {
    Write-Host "[$module] Platzhalter - wird implementiert..." -ForegroundColor Yellow
    return @{ Status = 'NotImplemented'; Warnings = @(); Errors = @() }
}
Export-ModuleMember -Function *
"@
        $placeholderContent | Out-File -FilePath $modulePath -Encoding UTF8
        Import-Module $modulePath -Force
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# KONFIGURATION LADEN
# ═══════════════════════════════════════════════════════════════════════════

$SysReqFile = Join-Path $ConfigPath "SystemRequirements.json"
$PortsFile = Join-Path $ConfigPath "Ports.json"

if (Test-Path $SysReqFile) {
    $SystemRequirements = Get-Content $SysReqFile | ConvertFrom-Json
} else {
    Write-Warning "Konfiguration nicht gefunden - verwende Standard-Werte"
    $SystemRequirements = @{
        MinRAM = 8
        RecommendedRAM = 32
        MinCPUCores = 4
        MinDiskSpaceGB = 50
    }
}

if (Test-Path $PortsFile) {
    $PortConfig = Get-Content $PortsFile | ConvertFrom-Json
} else {
    $PortConfig = @{
        SQL = @{ TCP = @(1433); UDP = @(1434) }
        ApplicationServer = @{ HTTPS_Basic = @(5493); HTTPS_Windows = @(5494) }
        Blobstorage = @{ HTTPS_Basic = @(4000); HTTPS_Windows = @(4010) }
    }
}

# ═══════════════════════════════════════════════════════════════════════════
# HAUPT-LOGIK
# ═══════════════════════════════════════════════════════════════════════════

$Results = @{
    System = $null
    Ports = $null
    SQL = $null
    Directory = $null
    Timestamp = Get-Date
    Server = $env:COMPUTERNAME
}

# CHECK-MODUS
if ($Mode -in @('Check', 'Fix', 'Full')) {
    
    Write-Host "`n[1/4] Hardware & Betriebssystem prüfen..." -ForegroundColor Cyan
    $Results.System = Get-SystemCheck
    
    Write-Host "`n[2/4] Netzwerk & Firewall prüfen..." -ForegroundColor Cyan
    $Results.Ports = Get-PortCheck -PortConfig $PortConfig
    
    Write-Host "`n[3/4] SQL Server prüfen..." -ForegroundColor Cyan
    $Results.SQL = Get-SQLCheck
    
    Write-Host "`n[4/4] Ordnerstruktur prüfen..." -ForegroundColor Cyan
    $Results.Directory = Get-DirectorySetup
    
    # Zusammenfassung
    Write-Host "`n════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Zusammenfassung:" -ForegroundColor White
    
    $totalChecks = 0
    $successChecks = 0
    $warnings = 0
    $errors = 0
    
    foreach ($key in $Results.Keys) {
        if ($key -notin @('Timestamp', 'Server') -and $Results[$key]) {
            $totalChecks++
            if ($Results[$key].Status -eq 'OK') { $successChecks++ }
            $warnings += $Results[$key].Warnings.Count
            $errors += $Results[$key].Errors.Count
        }
    }
    
    Write-Host "  ✓ $successChecks/$totalChecks Checks erfolgreich" -ForegroundColor Green
    if ($warnings -gt 0) {
        Write-Host "  ⚠ $warnings Warnungen (Benutzereingriff empfohlen)" -ForegroundColor Yellow
    }
    if ($errors -gt 0) {
        Write-Host "  ✗ $errors Kritische Fehler" -ForegroundColor Red
    }
    Write-Host "════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
}

# FIX-MODUS
if ($Mode -in @('Fix', 'Full') -and -not $Silent) {
    Write-Host "`n[!] Fix-Modus aktiviert - Probleme können interaktiv behoben werden.`n" -ForegroundColor Yellow
    
    # Hier würde die interaktive Problemlösung implementiert
    # (wird in den einzelnen Modulen umgesetzt)
}

# EXPORT-MODUS
if ($Mode -in @('Export', 'Full')) {
    Write-Host "`n[Export] Erstelle Markdown-Dokumentation..." -ForegroundColor Cyan
    
    $exportFile = if ($OutputPath -like "*.md") {
        $OutputPath
    } else {
        Join-Path $OutputPath "Kundenstammblatt_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    }
    
    Export-Markdown -Results $Results -OutputPath $exportFile
    Write-Host "  ✓ Exportiert nach: $exportFile" -ForegroundColor Green
}

# WORKLOG-MODUS
if ($Mode -eq 'WorkLog') {
    Show-WorkLogMenu
}

# Log erstellen
$logFile = Join-Path $LogPath "check_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$Results | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8

Write-Host "`n[i] Prüfung abgeschlossen. Log: $logFile" -ForegroundColor Gray
Write-Host ""
