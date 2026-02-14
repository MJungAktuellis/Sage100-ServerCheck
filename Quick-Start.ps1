<#
.SYNOPSIS
    Sage100 ServerCheck - Quick Start (ohne Installation)
.DESCRIPTION
    Testet das Tool direkt ohne Installation
#>

$Host.UI.RawUI.WindowTitle = "Sage100 ServerCheck - Quick Start"

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SAGE 100 SERVER CHECK - QUICK START            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Aktuelles Verzeichnis
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Prüfe Verzeichnisstruktur
Write-Host "[1/5] Prüfe Verzeichnisstruktur..." -ForegroundColor Yellow

$requiredPaths = @{
    "Config-Ordner" = "$ScriptRoot\Config"
    "Modules-Ordner" = "$ScriptRoot\src\Modules"
    "Hauptprogramm" = "$ScriptRoot\src\Sage100-ServerCheck.ps1"
    "config.json" = "$ScriptRoot\Config\config.json"
}

$allOk = $true
foreach ($item in $requiredPaths.GetEnumerator()) {
    if (Test-Path $item.Value) {
        Write-Host "  ✓ $($item.Key): OK" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $($item.Key): FEHLT ($($item.Value))" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host ""
    Write-Host "FEHLER: Nicht alle benötigten Dateien gefunden!" -ForegroundColor Red
    Write-Host "Bitte führen Sie zuerst SETUP.ps1 aus." -ForegroundColor Yellow
    Write-Host ""
    pause
    exit 1
}

# 2. Prüfe PowerShell-Version
Write-Host ""
Write-Host "[2/5] Prüfe PowerShell-Version..." -ForegroundColor Yellow
if ($PSVersionTable.PSVersion.Major -ge 5) {
    Write-Host "  ✓ PowerShell $($PSVersionTable.PSVersion) OK" -ForegroundColor Green
} else {
    Write-Host "  ✗ PowerShell 5.0+ erforderlich!" -ForegroundColor Red
    pause
    exit 1
}

# 3. Lade Module
Write-Host ""
Write-Host "[3/5] Lade Module..." -ForegroundColor Yellow

$modules = @(
    "$ScriptRoot\src\Modules\Logger.ps1",
    "$ScriptRoot\src\Modules\ConfigManager.ps1",
    "$ScriptRoot\src\Modules\ResourceMonitor.ps1"
)

foreach ($module in $modules) {
    if (Test-Path $module) {
        try {
            . $module
            Write-Host "  ✓ $(Split-Path -Leaf $module)" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ $(Split-Path -Leaf $module): $_" -ForegroundColor Red
            $allOk = $false
        }
    } else {
        Write-Host "  ✗ $(Split-Path -Leaf $module): NICHT GEFUNDEN" -ForegroundColor Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host ""
    Write-Host "FEHLER: Module konnten nicht geladen werden!" -ForegroundColor Red
    pause
    exit 1
}

# 4. Lade Konfiguration
Write-Host ""
Write-Host "[4/5] Lade Konfiguration..." -ForegroundColor Yellow

try {
    $config = Get-Content "$ScriptRoot\Config\config.json" -Raw | ConvertFrom-Json
    Write-Host "  ✓ config.json geladen" -ForegroundColor Green
} catch {
    Write-Host "  ✗ config.json konnte nicht geladen werden: $_" -ForegroundColor Red
    pause
    exit 1
}

# 5. Starte Hauptprogramm
Write-Host ""
Write-Host "[5/5] Starte Hauptprogramm..." -ForegroundColor Yellow
Write-Host ""

try {
    & "$ScriptRoot\src\Sage100-ServerCheck.ps1"
} catch {
    Write-Host ""
    Write-Host "FEHLER beim Start: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    pause
    exit 1
}
