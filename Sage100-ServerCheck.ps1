<#
.SYNOPSIS
    Sage 100 Server Check & Setup Tool
.DESCRIPTION
    Prueft Systemvoraussetzungen fuer Sage 100 und erstellt Dokumentation
.NOTES
    Version: 1.1
    Author: Sage 100 Support Team
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$FullCheck,
    
    [Parameter(Mandatory=$false)]
    [switch]$QuickScan,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExportReport
)

# Konfiguration
$Script:BaseDir = $PSScriptRoot
$Script:ModulesDir = Join-Path $BaseDir "Modules"
$Script:ConfigDir = Join-Path $BaseDir "Config"
$Script:DataDir = Join-Path $BaseDir "Data"
$Script:ReportsDir = Join-Path $DataDir "Reports"

# Stelle sicher, dass Verzeichnisse existieren
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}
if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

# Banner
function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "   Sage 100 Server Check & Setup Tool  " -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
}

# Hauptmenue
function Show-Menu {
    Write-Host ""
    Write-Host "[1] Vollstaendige System-Pruefung" -ForegroundColor Cyan
    Write-Host "[2] Nur System-Informationen sammeln" -ForegroundColor Cyan
    Write-Host "[3] Netzwerk & Firewall pruefen" -ForegroundColor Cyan
    Write-Host "[4] Compliance-Check (Sage 100 Voraussetzungen)" -ForegroundColor Cyan
    Write-Host "[5] Arbeitsprotokoll hinzufuegen" -ForegroundColor Cyan
    Write-Host "[6] Markdown-Report erstellen" -ForegroundColor Cyan
    Write-Host "[7] JSON-Snapshot erstellen" -ForegroundColor Cyan
    Write-Host "[8] Debug-Log anzeigen" -ForegroundColor Magenta
    Write-Host "[0] Beenden" -ForegroundColor Yellow
    Write-Host ""
}

# Lade Module
function Import-RequiredModules {
    Write-Host "Lade Module..." -ForegroundColor Gray
    
    $modules = @(
        "DebugLogger",
        "SystemCheck",
        "NetworkCheck",
        "ComplianceCheck",
        "WorkLog",
        "ReportGenerator"
    )
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $ModulesDir "$module.psm1"
        if (Test-Path $modulePath) {
            try {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-Host "  [OK] $module geladen" -ForegroundColor Green
                
                # Log successful module load
                if (Get-Command Write-LogAction -ErrorAction SilentlyContinue) {
                    Write-LogAction -FunctionName "Import-Module" -Status "Success" -Message "Modul $module erfolgreich geladen"
                }
            } catch {
                Write-Host "  [FEHLER] $module konnte nicht geladen werden: $_" -ForegroundColor Red
                
                # Log module load error
                if (Get-Command Write-LogAction -ErrorAction SilentlyContinue) {
                    Write-LogAction -FunctionName "Import-Module" -Status "Error" -Message "Fehler beim Laden von $module" -ErrorRecord $_
                }
            }
        } else {
            Write-Host "  [FEHLER] $module nicht gefunden!" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Pruefe Administrator-Rechte
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Hauptprogramm
function Start-Sage100Check {
    Show-Banner
    
    # Pruefe Admin-Rechte
    if (-not (Test-IsAdmin)) {
        Write-Host "WARNUNG: Skript wird nicht als Administrator ausgefuehrt!" -ForegroundColor Yellow
        Write-Host "Einige Funktionen sind eventuell eingeschraenkt." -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Trotzdem fortfahren? (J/N)"
        if ($continue -ne "J" -and $continue -ne "j") {
            exit
        }
    }
    
    # Lade Module
    Import-RequiredModules
    
    # Initialize Debug Logger
    if (Get-Command Initialize-DebugLog -ErrorAction SilentlyContinue) {
        Initialize-DebugLog
    }
    
    # Hauptschleife
    do {
        Show-Banner
        Show-Menu
        
        $choice = Read-Host "Bitte waehlen Sie eine Option"
        
        switch ($choice) {
            "1" {
                Write-Host "`nStarte vollstaendige Pruefung..." -ForegroundColor Cyan
                Invoke-FullSystemCheck
            }
            "2" {
                Write-Host "`nSammle System-Informationen..." -ForegroundColor Cyan
                Get-SystemInformation
            }
            "3" {
                Write-Host "`nPruefe Netzwerk & Firewall..." -ForegroundColor Cyan
                Test-NetworkConfiguration
            }
            "4" {
                Write-Host "`nPruefe Sage 100 Voraussetzungen..." -ForegroundColor Cyan
                Test-Sage100Compliance
            }
            "5" {
                Write-Host "`nArbeitsprotokoll hinzufuegen..." -ForegroundColor Cyan
                Add-WorkLogEntry
            }
            "6" {
                Write-Host "`nErstelle Markdown-Report..." -ForegroundColor Cyan
                New-MarkdownReport
            }
            "7" {
                Write-Host "`nErstelle JSON-Snapshot..." -ForegroundColor Cyan
                New-JSONSnapshot
            }
            "8" {
                if (Get-Command Get-DebugLogSummary -ErrorAction SilentlyContinue) {
                    Get-DebugLogSummary
                    $exportLog = Read-Host "`nDebug-Log exportieren? (J/N)"
                    if ($exportLog -eq "J" -or $exportLog -eq "j") {
                        $logPath = Export-DebugLog
                        if ($logPath) {
                            Write-Host "`nLog gespeichert: $logPath" -ForegroundColor Green
                            Write-Host "Bitte sende diese Datei zur Analyse." -ForegroundColor Cyan
                        }
                    }
                } else {
                    Write-Host "`nDebug-Logger nicht verfuegbar!" -ForegroundColor Red
                }
            }
            "0" {
                # Export debug log on exit
                if (Get-Command Export-DebugLog -ErrorAction SilentlyContinue) {
                    $logPath = Export-DebugLog
                    if ($logPath) {
                        Write-Host "`nDebug-Log automatisch gespeichert: $logPath" -ForegroundColor Gray
                    }
                }
                Write-Host "`nAuf Wiedersehen!" -ForegroundColor Green
                exit
            }
            default {
                Write-Host "`nUngueltige Auswahl!" -ForegroundColor Red
            }
        }
        
        if ($choice -ne "0") {
            Write-Host "`nDruecken Sie eine Taste zum Fortfahren..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
    } while ($choice -ne "0")
}

# Vollstaendige Pruefung
function Invoke-FullSystemCheck {
    $operation = Start-LoggedOperation -OperationName "Invoke-FullSystemCheck"
    
    try {
        $results = @{
            Timestamp = Get-Date
            SystemInfo = @{}
            NetworkCheck = @{}
            ComplianceCheck = @{}
            Issues = @()
            Warnings = @()
        }
        
        Write-Host "`n=== SYSTEM-INFORMATIONEN ===" -ForegroundColor Yellow
        $systemInfo = Get-SystemInformation
        $results.SystemInfo = $systemInfo
        
        Write-Host "`n=== NETZWERK-PRUEFUNG ===" -ForegroundColor Yellow
        $networkCheck = Test-NetworkConfiguration
        $results.NetworkCheck = $networkCheck
        
        Write-Host "`n=== COMPLIANCE-CHECK ===" -ForegroundColor Yellow
        $complianceCheck = Test-Sage100Compliance
        $results.ComplianceCheck = $complianceCheck
        
        # Zusammenfassung
        Write-Host "`n========================================" -ForegroundColor Green
        Write-Host "ZUSAMMENFASSUNG" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        
        $errorCount = 0
        $warningCount = 0
        
        if ($complianceCheck.Issues) {
            $errorCount = $complianceCheck.Issues.Count
        }
        if ($complianceCheck.Warnings) {
            $warningCount = $complianceCheck.Warnings.Count
        }
        
        Write-Host "`nFEHLER: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
        Write-Host "WARNUNGEN: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
        
        # Speichere Ergebnisse
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $resultFile = Join-Path $DataDir "CheckResult_$timestamp.json"
        $results | ConvertTo-Json -Depth 10 | Out-File $resultFile
        Write-Host "`nErgebnisse gespeichert: $resultFile" -ForegroundColor Gray
        
        # Frage nach Report-Erstellung
        Write-Host ""
        $createReport = Read-Host "Markdown-Report jetzt erstellen? (J/N)"
        if ($createReport -eq "J" -or $createReport -eq "j") {
            New-MarkdownReport -Data $results
        }
        
        Stop-LoggedOperation -Operation $operation -Status "Success" -Result $results
        
    } catch {
        Stop-LoggedOperation -Operation $operation -Status "Error" -ErrorRecord $_
        throw
    }
}

# Starte Tool
if ($FullCheck) {
    Show-Banner
    Import-RequiredModules
    Invoke-FullSystemCheck
} elseif ($QuickScan) {
    Show-Banner
    Import-RequiredModules
    Get-SystemInformation
} elseif ($ExportReport) {
    Show-Banner
    Import-RequiredModules
    New-MarkdownReport
} else {
    Start-Sage100Check
}
