#Requires -Version 5.1

<#
.SYNOPSIS
    Sage 100 Server Check & Setup Tool - GUI Version
.DESCRIPTION
    Grafische Benutzeroberflaeche fuer System-Checks und Sage 100 Setup-Validierung
.NOTES
    Version: 2.0
    Requires: PowerShell 5.1+, .NET Framework 4.5+
#>

param(
    [string]$ConfigPath = "$PSScriptRoot\Config\Sage100Config.json"
)

# Banner
Write-Host "`n========================================"
Write-Host "   Sage 100 Server Check & Setup Tool"
Write-Host "            GUI Version 2.0"
Write-Host "========================================`n"

# Check PowerShell Version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 oder hoeher erforderlich. Aktuelle Version: $($PSVersionTable.PSVersion)"
    Read-Host "Druecke eine Taste zum Beenden"
    exit 1
}

# Load required assemblies
try {
    Write-Host "Lade Windows Forms..." -ForegroundColor Gray
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    Write-Host "Windows Forms erfolgreich geladen." -ForegroundColor Green
} catch {
    Write-Error "Fehler beim Laden von Windows Forms: $_"
    Write-Host "`nWindows Forms ist nicht verfuegbar. Stelle sicher, dass .NET Framework 4.5+ installiert ist."
    Read-Host "Druecke eine Taste zum Beenden"
    exit 1
}

# Set script root
$script:ScriptRoot = $PSScriptRoot

# Import Modules
try {
    Write-Host "Lade Module..." -ForegroundColor Gray
    
    $modulePath = Join-Path $PSScriptRoot "Modules"
    $modules = @(
        "SystemCheck.psm1",
        "NetworkCheck.psm1",
        "ComplianceCheck.psm1",
        "WorkLog.psm1",
        "ReportGenerator.psm1",
        "DebugLogger.psm1"
    )
    
    foreach ($module in $modules) {
        $fullPath = Join-Path $modulePath $module
        if (Test-Path $fullPath) {
            Import-Module $fullPath -Force -ErrorAction Stop
            Write-Host "  [OK] $module" -ForegroundColor Green
        } else {
            Write-Warning "  [FEHLT] $module nicht gefunden"
        }
    }
    
    Write-Host "Module erfolgreich geladen.`n" -ForegroundColor Green
    
} catch {
    Write-Error "Fehler beim Laden der Module: $_"
    Read-Host "Druecke eine Taste zum Beenden"
    exit 1
}

# Load GUI Class
try {
    Write-Host "Starte grafische Benutzeroberflaeche...`n"
    
    $guiPath = Join-Path $PSScriptRoot "GUI\MainWindow.ps1"
    
    if (-not (Test-Path $guiPath)) {
        throw "GUI-Datei nicht gefunden: $guiPath"
    }
    
    # Dot-source the GUI file to load the class
    . $guiPath
    
    # Create and show the GUI
    $gui = [MainWindow]::new()
    [void]$gui.Show()
    
} catch {
    Write-Error "Fehler beim Starten der GUI: $($_.Exception.Message)"
    Write-Host "`nDetails:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace
    Write-Host "`nInvocation Info:" -ForegroundColor Yellow
    Write-Host $_.InvocationInfo.PositionMessage
}

Read-Host "`nDruecke eine Taste zum Beenden"
