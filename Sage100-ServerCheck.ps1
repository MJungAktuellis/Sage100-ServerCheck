<#
.SYNOPSIS
    Sage 100 Server Check & Configuration Tool
    
.DESCRIPTION
    Automatisierte Prüfung und Dokumentation von Sage 100 Serverumgebungen.
    Prüft Systemvoraussetzungen, sammelt Informationen und generiert Kundenstammblätter.
    
.PARAMETER FullCheck
    Führt alle Prüfungen durch (System, SQL, Netzwerk, Software)
    
.PARAMETER CheckRequirements
    Prüft nur Systemvoraussetzungen gegen Sage 100 Requirements
    
.PARAMETER GenerateReport
    Generiert Kundenstammblatt im Markdown-Format
    
.PARAMETER CustomerName
    Kundenname für die Dokumentation
    
.PARAMETER AddWorkLog
    Fügt einen Eintrag zur Terminhistorie hinzu
    
.PARAMETER Technician
    Name des Technikers für Arbeitsprotokoll
    
.PARAMETER Description
    Beschreibung der durchgeführten Arbeiten
    
.PARAMETER Duration
    Dauer der Arbeiten in Minuten
    
.EXAMPLE
    .\Sage100-ServerCheck.ps1 -FullCheck
    
.EXAMPLE
    .\Sage100-ServerCheck.ps1 -GenerateReport -CustomerName "Musterfirma GmbH"
    
.EXAMPLE
    .\Sage100-ServerCheck.ps1 -AddWorkLog -Technician "Max Mustermann" -Description "Installation" -Duration 120
    
.NOTES
    Version: 1.0.0
    Author: Sage 100 Partner Team
    Requires: PowerShell 5.1+, Administrator Rights (für System-Checks)
#>

[CmdletBinding()]
param(
    [Parameter(ParameterSetName='Check')]
    [switch]$FullCheck,
    
    [Parameter(ParameterSetName='Check')]
    [switch]$CheckRequirements,
    
    [Parameter(ParameterSetName='Report')]
    [switch]$GenerateReport,
    
    [Parameter(ParameterSetName='Report')]
    [string]$CustomerName,
    
    [Parameter(ParameterSetName='WorkLog')]
    [switch]$AddWorkLog,
    
    [Parameter(ParameterSetName='WorkLog')]
    [string]$Technician,
    
    [Parameter(ParameterSetName='WorkLog')]
    [string]$Description,
    
    [Parameter(ParameterSetName='WorkLog')]
    [int]$Duration
)

# Script-Pfade
$ScriptPath = $PSScriptRoot
$ModulePath = Join-Path $ScriptPath "Modules"
$DataPath = Join-Path $ScriptPath "Data"
$ReportsPath = Join-Path $ScriptPath "Reports"
$TemplatesPath = Join-Path $ScriptPath "Templates"

# Verzeichnisse erstellen falls nicht vorhanden
@($DataPath, $ReportsPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

# Module importieren
$ModuleFiles = @(
    "SystemCheck.psm1",
    "SQLCheck.psm1",
    "NetworkCheck.psm1",
    "SoftwareInventory.psm1",
    "DirectoryStructure.psm1",
    "WorkLog.psm1",
    "ReportGenerator.psm1"
)

foreach ($ModuleFile in $ModuleFiles) {
    $ModuleFilePath = Join-Path $ModulePath $ModuleFile
    if (Test-Path $ModuleFilePath) {
        Import-Module $ModuleFilePath -Force
    } else {
        Write-Warning "Modul $ModuleFile nicht gefunden. Erstelle Placeholder..."
    }
}

#region Hilfsfunktionen

function Write-Header {
    param([string]$Title)
    
    $Width = 70
    $Line = "═" * $Width
    $TitlePadded = " $Title ".PadLeft(($Width + $Title.Length) / 2).PadRight($Width)
    
    Write-Host ""
    Write-Host "╔$Line╗" -ForegroundColor Cyan
    Write-Host "║$TitlePadded║" -ForegroundColor Cyan
    Write-Host "╚$Line╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('OK', 'Warning', 'Error', 'Info')]
        [string]$Status = 'Info'
    )
    
    $Icon = switch ($Status) {
        'OK'      { '[✓]'; $Color = 'Green' }
        'Warning' { '[!]'; $Color = 'Yellow' }
        'Error'   { '[✗]'; $Color = 'Red' }
        'Info'    { '[i]'; $Color = 'Cyan' }
    }
    
    Write-Host "$Icon $Message" -ForegroundColor $Color
}

function Show-Menu {
    Write-Header "Sage 100 Server Check v1.0"
    
    Write-Host "Wählen Sie eine Aktion:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1) Vollständiger System-Check"
    Write-Host "  2) Nur Systemvoraussetzungen prüfen"
    Write-Host "  3) Kundenstammblatt generieren"
    Write-Host "  4) Arbeitsprotokoll hinzufügen"
    Write-Host "  5) Firewall-Regeln prüfen"
    Write-Host "  6) SQL Server Check"
    Write-Host "  Q) Beenden"
    Write-Host ""
    
    $Choice = Read-Host "Ihre Wahl"
    return $Choice
}

#endregion

#region Hauptfunktionen

function Invoke-FullCheck {
    Write-Header "Vollständiger System-Check"
    
    $Results = @{
        Timestamp = Get-Date
        ServerName = $env:COMPUTERNAME
        Checks = @{}
    }
    
    # System-Check
    Write-Status "Prüfe System-Informationen..." -Status Info
    $Results.Checks.System = Get-SystemInfo
    
    # SQL Server Check
    Write-Status "Prüfe SQL Server..." -Status Info
    $Results.Checks.SQL = Get-SQLServerInfo
    
    # Netzwerk Check
    Write-Status "Prüfe Netzwerk & Firewall..." -Status Info
    $Results.Checks.Network = Get-NetworkInfo
    
    # Software Inventory
    Write-Status "Sammle Software-Informationen..." -Status Info
    $Results.Checks.Software = Get-InstalledSoftware
    
    # Directory Structure
    Write-Status "Analysiere Verzeichnisstrukturen..." -Status Info
    $Results.Checks.Directories = Get-DirectoryStructure
    
    # Ergebnisse speichern
    $ResultsFile = Join-Path $DataPath "ServerCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $Results | ConvertTo-Json -Depth 10 | Out-File $ResultsFile
    
    Write-Status "Ergebnisse gespeichert: $ResultsFile" -Status OK
    
    # Probleme anzeigen
    Show-Issues -Results $Results
    
    return $Results
}

function Test-Requirements {
    Write-Header "Systemvoraussetzungen Prüfung"
    
    $RequirementsFile = Join-Path $TemplatesPath "Sage100-Requirements.json"
    
    if (-not (Test-Path $RequirementsFile)) {
        Write-Status "Requirements-Datei nicht gefunden!" -Status Error
        return
    }
    
    $Requirements = Get-Content $RequirementsFile | ConvertFrom-Json
    $SystemInfo = Get-SystemInfo
    
    $Issues = @()
    
    # OS Version prüfen
    if ($SystemInfo.OS.Version -notin $Requirements.SupportedOS) {
        $Issues += @{
            Category = "Betriebssystem"
            Issue = "Windows Version nicht unterstützt: $($SystemInfo.OS.Version)"
            Recommendation = "Upgrade auf Windows Server 2022/2025 oder Windows 11"
            Severity = "High"
        }
    } else {
        Write-Status "Betriebssystem: $($SystemInfo.OS.Caption) - OK" -Status OK
    }
    
    # RAM prüfen
    $MinRAM = $Requirements.Hardware.MinRAM_GB
    $ActualRAM = [math]::Round($SystemInfo.Hardware.TotalRAM_GB, 0)
    
    if ($ActualRAM -lt $MinRAM) {
        $Issues += @{
            Category = "Hardware"
            Issue = "Zu wenig RAM: $ActualRAM GB (Minimum: $MinRAM GB)"
            Recommendation = "RAM auf mindestens $MinRAM GB erweitern"
            Severity = "High"
        }
    } else {
        Write-Status "RAM: $ActualRAM GB - OK" -Status OK
    }
    
    # CPU prüfen
    $MinCPUCores = $Requirements.Hardware.MinCPUCores
    if ($SystemInfo.Hardware.CPUCores -lt $MinCPUCores) {
        $Issues += @{
            Category = "Hardware"
            Issue = "Zu wenig CPU Cores: $($SystemInfo.Hardware.CPUCores) (Minimum: $MinCPUCores)"
            Recommendation = "CPU mit mindestens $MinCPUCores Cores verwenden"
            Severity = "Medium"
        }
    } else {
        Write-Status "CPU: $($SystemInfo.Hardware.CPUCores) Cores - OK" -Status OK
    }
    
    if ($Issues.Count -eq 0) {
        Write-Status "Alle Systemvoraussetzungen erfüllt!" -Status OK
    } else {
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host " Probleme gefunden: $($Issues.Count)" -ForegroundColor Red
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
        
        foreach ($Issue in $Issues) {
            Write-Host ""
            Write-Host "[$($Issue.Severity)] $($Issue.Category)" -ForegroundColor $(if ($Issue.Severity -eq 'High') { 'Red' } else { 'Yellow' })
            Write-Host "  Problem: $($Issue.Issue)"
            Write-Host "  Empfehlung: $($Issue.Recommendation)" -ForegroundColor Cyan
        }
        
        Write-Host ""
        $Fix = Read-Host "Möchten Sie Lösungsvorschläge im Detail sehen? (J/N)"
        if ($Fix -eq 'J') {
            Show-DetailedSolutions -Issues $Issues
        }
    }
    
    return $Issues
}

function New-CustomerReport {
    param([string]$CustomerName)
    
    if (-not $CustomerName) {
        $CustomerName = Read-Host "Kundenname"
    }
    
    Write-Header "Kundenstammblatt generieren: $CustomerName"
    
    # Daten sammeln
    $Data = @{
        Customer = $CustomerName
        Date = Get-Date -Format "yyyy-MM-dd"
        System = Get-SystemInfo
        SQL = Get-SQLServerInfo
        Network = Get-NetworkInfo
        Software = Get-InstalledSoftware
        Directories = Get-DirectoryStructure
        WorkLog = Get-WorkLogEntries
    }
    
    # Markdown generieren
    $Report = Generate-MarkdownReport -Data $Data
    
    # Speichern
    $SafeCustomerName = $CustomerName -replace '[^\w\s]', '' -replace '\s', '_'
    $ReportFile = Join-Path $ReportsPath "Kundenstammblatt_${SafeCustomerName}_$(Get-Date -Format 'yyyyMMdd').md"
    $Report | Out-File $ReportFile -Encoding UTF8
    
    Write-Status "Bericht erstellt: $ReportFile" -Status OK
    
    # Öffnen?
    $Open = Read-Host "Möchten Sie den Bericht öffnen? (J/N)"
    if ($Open -eq 'J') {
        Start-Process notepad.exe $ReportFile
    }
}

function Add-WorkLogEntry {
    param(
        [string]$Technician,
        [string]$Description,
        [int]$Duration
    )
    
    if (-not $Technician) {
        $Technician = Read-Host "Techniker-Name"
    }
    if (-not $Description) {
        $Description = Read-Host "Beschreibung der Arbeiten"
    }
    if (-not $Duration) {
        $Duration = Read-Host "Dauer in Minuten"
    }
    
    $Entry = @{
        Date = Get-Date -Format "yyyy-MM-dd HH:mm"
        Technician = $Technician
        Description = $Description
        Duration = $Duration
        Server = $env:COMPUTERNAME
    }
    
    Save-WorkLogEntry -Entry $Entry
    
    Write-Status "Arbeitsprotokoll-Eintrag gespeichert" -Status OK
}

function Show-Issues {
    param($Results)
    
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " Zusammenfassung" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Platzhalter für Issue-Detection
    # Dies würde in den Modulen implementiert werden
    
    Write-Status "Check abgeschlossen. Ergebnisse wurden gespeichert." -Status Info
}

#endregion

#region Main

# Admin-Check
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $IsAdmin) {
    Write-Status "WARNUNG: Nicht als Administrator ausgeführt. Einige Prüfungen sind eingeschränkt." -Status Warning
}

# Parameter-Handling
if ($FullCheck) {
    Invoke-FullCheck
}
elseif ($CheckRequirements) {
    Test-Requirements
}
elseif ($GenerateReport) {
    New-CustomerReport -CustomerName $CustomerName
}
elseif ($AddWorkLog) {
    Add-WorkLogEntry -Technician $Technician -Description $Description -Duration $Duration
}
else {
    # Interaktives Menü
    do {
        $Choice = Show-Menu
        
        switch ($Choice) {
            '1' { Invoke-FullCheck; Pause }
            '2' { Test-Requirements; Pause }
            '3' { New-CustomerReport; Pause }
            '4' { Add-WorkLogEntry; Pause }
            '5' { Write-Status "Firewall-Check wird implementiert..." -Status Info; Pause }
            '6' { Write-Status "SQL Server Check wird implementiert..." -Status Info; Pause }
            'Q' { return }
            default { Write-Status "Ungültige Auswahl" -Status Error; Pause }
        }
    } while ($Choice -ne 'Q')
}

#endregion
