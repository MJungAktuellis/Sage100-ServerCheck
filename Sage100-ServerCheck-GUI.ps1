# Sage100-ServerCheck-GUI.ps1
# Starter-Skript für die GUI-Version des Sage 100 Server Check Tools

<#
.SYNOPSIS
    Sage 100 Server Check & Setup Tool - GUI Version

.DESCRIPTION
    Grafische Benutzeroberfläche für die Überprüfung von Sage 100 Server-Voraussetzungen.
    
    Features:
    - Dashboard mit Status-Übersicht
    - System-Informationen
    - Netzwerk & Firewall-Prüfung
    - Compliance-Check (Sage 100 Requirements)
    - Debug-Logging
    - Export-Funktionen (Markdown, JSON)

.EXAMPLE
    .\Sage100-ServerCheck-GUI.ps1
    
.NOTES
    Author: Marcel Jung
    Version: 2.0
    Requires: PowerShell 5.1+, .NET Framework 4.7.2+
#>

[CmdletBinding()]
param()

# Prüfe PowerShell-Version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 oder höher wird benötigt. Aktuelle Version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Prüfe, ob GUI-Modul vorhanden ist
$guiPath = Join-Path $PSScriptRoot "GUI\MainWindow.ps1"

if (-not (Test-Path $guiPath)) {
    Write-Error "GUI-Modul nicht gefunden: $guiPath"
    Write-Host ""
    Write-Host "Bitte stelle sicher, dass alle Dateien korrekt installiert sind:"
    Write-Host "  - GUI/MainWindow.ps1"
    Write-Host "  - Modules/*.psm1"
    exit 1
}

# Prüfe erforderliche Module
$requiredModules = @(
    "SystemCheck.psm1",
    "NetworkCheck.psm1",
    "ComplianceCheck.psm1",
    "WorkLog.psm1",
    "DebugLogger.psm1",
    "ReportGenerator.psm1"
)

$missingModules = @()
foreach ($module in $requiredModules) {
    $modulePath = Join-Path $PSScriptRoot "Modules\$module"
    if (-not (Test-Path $modulePath)) {
        $missingModules += $module
    }
}

if ($missingModules.Count -gt 0) {
    Write-Error "Fehlende Module:"
    foreach ($module in $missingModules) {
        Write-Host "  - $module" -ForegroundColor Red
    }
    exit 1
}

# Erstelle Data-Verzeichnisse (falls nicht vorhanden)
$dataFolders = @(
    "Data",
    "Data\Logs",
    "Data\Reports",
    "Data\Snapshots"
)

foreach ($folder in $dataFolders) {
    $folderPath = Join-Path $PSScriptRoot $folder
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        Write-Verbose "Verzeichnis erstellt: $folderPath"
    }
}

# Setze Arbeitsverzeichnis
Set-Location $PSScriptRoot

# Banner anzeigen
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Sage 100 Server Check & Setup Tool" -ForegroundColor Cyan
Write-Host "            GUI Version 2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starte grafische Benutzeroberfläche..." -ForegroundColor Yellow
Write-Host ""

# Starte GUI
try {
    # Lade GUI-Modul
    . $guiPath
}
catch {
    Write-Error "Fehler beim Starten der GUI: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    Write-Host "Drücke eine Taste zum Beenden..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}
