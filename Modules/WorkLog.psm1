# WorkLog.psm1
# Arbeitsprotokollierung fuer Sage 100 Server Check

$script:WorkLogPath = Join-Path $PSScriptRoot "..\Data\WorkLog.json"

function Initialize-WorkLog {
    $dataPath = Join-Path $PSScriptRoot "..\Data"
    
    if (-not (Test-Path $dataPath)) {
        New-Item -ItemType Directory -Path $dataPath -Force | Out-Null
    }

    if (-not (Test-Path $script:WorkLogPath)) {
        $initialLog = @{
            Created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            Entries = @()
        }
        $initialLog | ConvertTo-Json -Depth 10 | Set-Content $script:WorkLogPath -Encoding UTF8
        Write-Host "Arbeitsprotokoll initialisiert: $script:WorkLogPath" -ForegroundColor Green
    }
}

function Add-WorkLogEntry {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Category = "Allgemein",
        
        [Parameter(Mandatory=$false)]
        [string]$Action = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Details = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Technician = $env:USERNAME,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warnung", "Fehler", "Erfolg")]
        [string]$Type = "Info"
    )

    Initialize-WorkLog

    if ([string]::IsNullOrWhiteSpace($Action)) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "   Arbeitsprotokoll-Eintrag hinzufuegen" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Kategorie waehlen:" -ForegroundColor Yellow
        Write-Host "  [1] Installation"
        Write-Host "  [2] Konfiguration"
        Write-Host "  [3] Wartung"
        Write-Host "  [4] Fehlerbehebung"
        Write-Host "  [5] Update/Upgrade"
        Write-Host "  [6] Sonstiges"
        Write-Host ""
        $categoryChoice = Read-Host "Ihre Wahl (1-6)"

        $Category = switch ($categoryChoice) {
            "1" { "Installation" }
            "2" { "Konfiguration" }
            "3" { "Wartung" }
            "4" { "Fehlerbehebung" }
            "5" { "Update/Upgrade" }
            default { "Sonstiges" }
        }

        Write-Host ""
        $Action = Read-Host "Durchgefuehrte Aktion"
        Write-Host ""
        $Details = Read-Host "Details/Notizen (optional)"
        Write-Host ""

        Write-Host "Typ:" -ForegroundColor Yellow
        Write-Host "  [1] Info"
        Write-Host "  [2] Warnung"
        Write-Host "  [3] Fehler"
        Write-Host "  [4] Erfolg"
        Write-Host ""
        $typeChoice = Read-Host "Ihre Wahl (1-4)"

        $Type = switch ($typeChoice) {
            "1" { "Info" }
            "2" { "Warnung" }
            "3" { "Fehler" }
            "4" { "Erfolg" }
            default { "Info" }
        }
    }

    $entry = @{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        Category = $Category
        Action = $Action
        Details = $Details
        Technician = $Technician
        Type = $Type
        ComputerName = $env:COMPUTERNAME
    }

    try {
        $workLog = Get-Content $script:WorkLogPath -Raw | ConvertFrom-Json
        $workLog.Entries += $entry
        $workLog | ConvertTo-Json -Depth 10 | Set-Content $script:WorkLogPath -Encoding UTF8

        Write-Host ""
        Write-Host "Eintrag erfolgreich hinzugefuegt!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Kategorie: $Category" -ForegroundColor Gray
        Write-Host "  Aktion: $Action" -ForegroundColor Gray
        if ($Details) {
            Write-Host "  Details: $Details" -ForegroundColor Gray
        }
        Write-Host "  Techniker: $Technician" -ForegroundColor Gray
        Write-Host "  Typ: $Type" -ForegroundColor Gray
        Write-Host ""

        return $entry

    } catch {
        Write-Host ""
        Write-Host "FEHLER beim Speichern des Eintrags: $_" -ForegroundColor Red
        Write-Host ""
        return $null
    }
}

function Get-WorkLogEntries {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Last = 0,
        
        [Parameter(Mandatory=$false)]
        [string]$Category = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Type = ""
    )

    if (-not (Test-Path $script:WorkLogPath)) {
        Write-Host "Kein Arbeitsprotokoll vorhanden." -ForegroundColor Yellow
        return @()
    }

    try {
        $workLog = Get-Content $script:WorkLogPath -Raw | ConvertFrom-Json
        $entries = $workLog.Entries

        if ($Category) {
            $entries = $entries | Where-Object { $_.Category -eq $Category }
        }

        if ($Type) {
            $entries = $entries | Where-Object { $_.Type -eq $Type }
        }

        if ($Last -gt 0) {
            $entries = $entries | Select-Object -Last $Last
        }

        return $entries

    } catch {
        Write-Host "Fehler beim Lesen des Arbeitsprotokolls: $_" -ForegroundColor Red
        return @()
    }
}

function Show-WorkLog {
    param(
        [Parameter(Mandatory=$false)]
        [int]$Last = 10
    )

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   Arbeitsprotokoll (letzte $Last)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $entries = Get-WorkLogEntries -Last $Last

    if ($entries.Count -eq 0) {
        Write-Host "Keine Eintraege vorhanden." -ForegroundColor Yellow
        return
    }

    foreach ($entry in $entries) {
        $color = switch ($entry.Type) {
            "Info" { "White" }
            "Warnung" { "Yellow" }
            "Fehler" { "Red" }
            "Erfolg" { "Green" }
            default { "Gray" }
        }

        Write-Host "[$($entry.Timestamp)] " -NoNewline -ForegroundColor Gray
        Write-Host "$($entry.Category) - " -NoNewline -ForegroundColor Cyan
        Write-Host "$($entry.Action)" -ForegroundColor $color
        
        if ($entry.Details) {
            Write-Host "  Details: $($entry.Details)" -ForegroundColor Gray
        }
        Write-Host "  Techniker: $($entry.Technician) | Computer: $($entry.ComputerName)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

Export-ModuleMember -Function Initialize-WorkLog, Add-WorkLogEntry, Get-WorkLogEntries, Show-WorkLog
