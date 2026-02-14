<#
.SYNOPSIS
    Service Monitor Modul
.DESCRIPTION
    Überwacht Windows-Dienste auf lokalen und Remote-Systemen
#>

function Get-ServiceStatus {
    <#
    .SYNOPSIS
        Prüft den Status eines Windows-Dienstes
    .PARAMETER ServerIP
        IP oder Hostname des Servers
    .PARAMETER ServiceName
        Name des zu prüfenden Dienstes
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerIP,
        
        [Parameter(Mandatory=$true)]
        [string]$ServiceName
    )
    
    try {
        if ($ServerIP -eq "localhost" -or $ServerIP -eq "127.0.0.1" -or $ServerIP -eq $env:COMPUTERNAME) {
            # Lokaler Check
            $service = Get-Service -Name $ServiceName -ErrorAction Stop
        } else {
            # Remote-Check
            $service = Get-Service -ComputerName $ServerIP -Name $ServiceName -ErrorAction Stop
        }
        
        switch ($service.Status) {
            "Running" { return "✅ Running" }
            "Stopped" { return "❌ Stopped" }
            "Paused" { return "⏸️ Paused" }
            default { return "⚠️ Unknown" }
        }
    }
    catch {
        return "❌ Error: $($_.Exception.Message)"
    }
}

function Start-ServiceMonitoring {
    <#
    .SYNOPSIS
        Startet kontinuierliche Dienst-Überwachung
    .PARAMETER ServerIP
        IP oder Hostname des Servers
    .PARAMETER ServiceList
        Array von Dienstnamen
    .PARAMETER Callback
        ScriptBlock der bei Statusänderung aufgerufen wird
    #>
    param(
        [string]$ServerIP,
        [string[]]$ServiceList,
        [scriptblock]$Callback
    )
    
    $serviceStates = @{}
    
    while ($true) {
        foreach ($service in $ServiceList) {
            $currentStatus = Get-ServiceStatus -ServerIP $ServerIP -ServiceName $service
            
            if ($serviceStates.ContainsKey($service)) {
                if ($serviceStates[$service] -ne $currentStatus) {
                    & $Callback -ServiceName $service -OldStatus $serviceStates[$service] -NewStatus $currentStatus
                }
            }
            
            $serviceStates[$service] = $currentStatus
        }
        
        Start-Sleep -Seconds 30
    }
}

function Restart-RemoteService {
    <#
    .SYNOPSIS
        Startet einen Dienst neu
    #>
    param(
        [string]$ServerIP,
        [string]$ServiceName
    )
    
    try {
        if ($ServerIP -eq "localhost" -or $ServerIP -eq "127.0.0.1") {
            Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        } else {
            Invoke-Command -ComputerName $ServerIP -ScriptBlock {
                param($svc)
                Restart-Service -Name $svc -Force
            } -ArgumentList $ServiceName -ErrorAction Stop
        }
        return $true
    }
    catch {
        Write-Error "Fehler beim Neustart von $ServiceName : $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Get-ServiceStatus, Start-ServiceMonitoring, Restart-RemoteService
