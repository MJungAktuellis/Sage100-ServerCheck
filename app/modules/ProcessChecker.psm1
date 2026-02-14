<#
.SYNOPSIS
    Process Checker Modul
.DESCRIPTION
    Überwacht Windows-Prozesse auf lokalen und Remote-Systemen
#>

function Get-ProcessInfo {
    <#
    .SYNOPSIS
        Ruft Informationen über einen laufenden Prozess ab
    .PARAMETER ServerIP
        IP oder Hostname des Servers
    .PARAMETER ProcessName
        Name des Prozesses (ohne .exe)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerIP,
        
        [Parameter(Mandatory=$true)]
        [string]$ProcessName
    )
    
    try {
        if ($ServerIP -eq "localhost" -or $ServerIP -eq "127.0.0.1" -or $ServerIP -eq $env:COMPUTERNAME) {
            # Lokaler Check
            $process = Get-Process -Name $ProcessName -ErrorAction Stop | Select-Object -First 1
        } else {
            # Remote-Check
            $process = Invoke-Command -ComputerName $ServerIP -ScriptBlock {
                param($pName)
                Get-Process -Name $pName -ErrorAction Stop | Select-Object -First 1
            } -ArgumentList $ProcessName -ErrorAction Stop
        }
        
        return $process
    }
    catch {
        return $null
    }
}

function Test-ProcessRunning {
    <#
    .SYNOPSIS
        Prüft ob ein Prozess läuft
    .OUTPUTS
        Boolean
    #>
    param(
        [string]$ServerIP,
        [string]$ProcessName
    )
    
    $proc = Get-ProcessInfo -ServerIP $ServerIP -ProcessName $ProcessName
    return ($null -ne $proc)
}

function Get-ProcessMetrics {
    <#
    .SYNOPSIS
        Ruft detaillierte Metriken eines Prozesses ab
    #>
    param(
        [string]$ServerIP,
        [string]$ProcessName
    )
    
    try {
        if ($ServerIP -eq "localhost" -or $ServerIP -eq "127.0.0.1") {
            $processes = Get-Process -Name $ProcessName -ErrorAction Stop
        } else {
            $processes = Invoke-Command -ComputerName $ServerIP -ScriptBlock {
                param($pName)
                Get-Process -Name $pName -ErrorAction Stop
            } -ArgumentList $ProcessName -ErrorAction Stop
        }
        
        $metrics = @{
            Count = $processes.Count
            TotalMemoryMB = [math]::Round(($processes | Measure-Object -Property WS -Sum).Sum / 1MB, 2)
            AvgCPU = ($processes | Measure-Object -Property CPU -Average).Average
            PIDs = $processes.Id
        }
        
        return $metrics
    }
    catch {
        return @{
            Count = 0
            TotalMemoryMB = 0
            AvgCPU = 0
            PIDs = @()
        }
    }
}

function Stop-RemoteProcess {
    <#
    .SYNOPSIS
        Beendet einen Prozess
    #>
    param(
        [string]$ServerIP,
        [string]$ProcessName,
        [switch]$Force
    )
    
    try {
        if ($ServerIP -eq "localhost" -or $ServerIP -eq "127.0.0.1") {
            if ($Force) {
                Stop-Process -Name $ProcessName -Force -ErrorAction Stop
            } else {
                Stop-Process -Name $ProcessName -ErrorAction Stop
            }
        } else {
            Invoke-Command -ComputerName $ServerIP -ScriptBlock {
                param($pName, $forceStop)
                if ($forceStop) {
                    Stop-Process -Name $pName -Force
                } else {
                    Stop-Process -Name $pName
                }
            } -ArgumentList $ProcessName, $Force.IsPresent -ErrorAction Stop
        }
        return $true
    }
    catch {
        Write-Error "Fehler beim Beenden von $ProcessName : $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Get-ProcessInfo, Test-ProcessRunning, Get-ProcessMetrics, Stop-RemoteProcess
