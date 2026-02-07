# ==============================================================================
# ReportGenerator.psm1
# Erstellt Markdown- und JSON-Reports
# ==============================================================================

function New-MarkdownReport {
    param(
        [hashtable]$SystemInfo,
        [hashtable]$NetworkCheck,
        [hashtable]$ComplianceCheck,
        [string]$OutputPath = ".\Data\ServerCheck_Report.md"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $markdown = @"
# Sage 100 Server Check Report
**Erstellt am:** $timestamp

---

## System-Informationen

### Hardware
- **Betriebssystem:** $($SystemInfo.OS.Caption) ($($SystemInfo.OS.Version))
- **CPU:** $($SystemInfo.CPU.Name) ($($SystemInfo.CPU.Cores) Cores)
- **RAM:** $([math]::Round($SystemInfo.Memory.TotalGB, 2)) GB
- **Freier RAM:** $([math]::Round($SystemInfo.Memory.FreeGB, 2)) GB

### Festplatten
"@

    foreach ($disk in $SystemInfo.Disks) {
        $markdown += "`n- **$($disk.Drive):** $([math]::Round($disk.FreeGB, 2)) GB frei von $([math]::Round($disk.SizeGB, 2)) GB"
    }

    $markdown += @"

### Software
- **.NET Framework:** $($SystemInfo.DotNet.Version)
- **PowerShell:** $($SystemInfo.PowerShell.Version)
"@

    if ($SystemInfo.SQLServer) {
        $markdown += "`n- **SQL Server:** $($SystemInfo.SQLServer.Edition) $($SystemInfo.SQLServer.Version)"
    }

    # Netzwerk-Check
    $markdown += @"

---

## Netzwerk & Firewall

### Port-Status
"@

    if ($NetworkCheck -and $NetworkCheck.Ports) {
        foreach ($port in $NetworkCheck.Ports) {
            $status = if ($port.Open) { "OFFEN" } else { "GESCHLOSSEN" }
            $icon = if ($port.Open) { "checkmark" } else { "warning" }
            $markdown += "`n- **Port $($port.Port)** ($($port.Description)): $status"
        }
    }

    # Compliance
    $markdown += @"

---

## Sage 100 Compliance-Check

"@

    if ($ComplianceCheck) {
        foreach ($check in $ComplianceCheck.Checks) {
            $icon = switch ($check.Status) {
                "OK" { "checkmark" }
                "WARNING" { "warning" }
                "ERROR" { "x" }
            }
            $markdown += "`n### $($check.Name)`n"
            $markdown += "**Status:** $($check.Status)`n"
            if ($check.Message) {
                $markdown += "$($check.Message)`n"
            }
        }
    }

    # Zusammenfassung
    $errorCount = if ($ComplianceCheck) { ($ComplianceCheck.Checks | Where-Object { $_.Status -eq "ERROR" }).Count } else { 0 }
    $warningCount = if ($ComplianceCheck) { ($ComplianceCheck.Checks | Where-Object { $_.Status -eq "WARNING" }).Count } else { 0 }

    $markdown += @"

---

## Zusammenfassung

- Fehler: $errorCount
- Warnungen: $warningCount
- Checks OK: $(if ($ComplianceCheck) { ($ComplianceCheck.Checks | Where-Object { $_.Status -eq "OK" }).Count } else { 0 })

---

*Report generiert mit Sage100-ServerCheck*
"@

    # Speichern
    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Markdown-Report erstellt: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

function New-JSONSnapshot {
    param(
        [hashtable]$Data,
        [string]$OutputPath = ".\Data\ServerSnapshot.json"
    )

    $snapshot = @{
        Timestamp = Get-Date -Format "o"
        Computer = $env:COMPUTERNAME
        User = $env:USERNAME
        Data = $Data
    }

    $snapshot | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "JSON-Snapshot erstellt: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

function Export-CheckResults {
    param(
        [hashtable]$Results,
        [string]$Format = "Both"
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $baseDir = ".\Data"
    
    if (-not (Test-Path $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir | Out-Null
    }

    $exports = @()

    if ($Format -eq "Markdown" -or $Format -eq "Both") {
        $mdPath = Join-Path $baseDir "CheckReport_$timestamp.md"
        $exports += New-MarkdownReport -SystemInfo $Results.SystemInfo `
                                      -NetworkCheck $Results.NetworkCheck `
                                      -ComplianceCheck $Results.ComplianceCheck `
                                      -OutputPath $mdPath
    }

    if ($Format -eq "JSON" -or $Format -eq "Both") {
        $jsonPath = Join-Path $baseDir "CheckResult_$timestamp.json"
        $exports += New-JSONSnapshot -Data $Results -OutputPath $jsonPath
    }

    return $exports
}

Export-ModuleMember -Function New-MarkdownReport, New-JSONSnapshot, Export-CheckResults
