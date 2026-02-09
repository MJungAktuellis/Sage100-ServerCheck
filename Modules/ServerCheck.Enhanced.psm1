# Modules/ServerCheck.Enhanced.psm1
<#
.SYNOPSIS
    Erweiterte Server-Check-Funktionen mit Async-Support und Performance-Monitoring
.DESCRIPTION
    Optimierte Version mit parallelen Checks und detailliertem Performance-Tracking
#>

using namespace System.Collections.Concurrent
using namespace System.Diagnostics

function Invoke-ParallelChecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxThreads = 5
    )
    
    $Results = [ConcurrentBag[PSCustomObject]]::new()
    $Jobs = @()
    
    # SQL Server Check (Async)
    $Jobs += Start-Job -Name "SqlServerCheck" -ScriptBlock {
        param($Config)
        
        $Stopwatch = [Stopwatch]::StartNew()
        
        $Result = @{
            CheckName = "SQL Server Status"
            Status = "OK"
            Details = @()
            Timestamp = Get-Date
            Duration = 0
            ErrorCode = $null
        }
        
        try {
            # Service Check
            $SqlService = Get-Service -Name $Config.ServiceName -ErrorAction Stop
            
            if ($SqlService.Status -ne "Running") {
                $Result.Status = "CRITICAL"
                $Result.ErrorCode = "SQL-001"
                $Result.Details += "SQL Server Service ist gestoppt: $($SqlService.Status)"
            } else {
                $Result.Details += "✓ SQL Server Service läuft"
            }
            
            # Connection Check mit Timeout
            $ConnectionString = "Server=$($Config.ServerName);Database=master;Integrated Security=True;Connection Timeout=5"
            $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            
            try {
                $Connection.Open()
                $Result.Details += "✓ Datenbankverbindung erfolgreich"
                
                # Datenbank-Abfrage
                $Query = @"
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    (SUM(size) * 8.0 / 1024) AS SizeMB,
    state_desc AS State
FROM sys.master_files
WHERE DB_NAME(database_id) LIKE '%Sage%'
GROUP BY database_id, state_desc
"@
                
                $Command = $Connection.CreateCommand()
                $Command.CommandText = $Query
                $Command.CommandTimeout = 10
                
                $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
                $DataSet = New-Object System.Data.DataSet
                [void]$Adapter.Fill($DataSet)
                
                if ($DataSet.Tables[0].Rows.Count -gt 0) {
                    foreach ($Row in $DataSet.Tables[0].Rows) {
                        $DbName = $Row["DatabaseName"]
                        $Size = [math]::Round($Row["SizeMB"], 2)
                        $State = $Row["State"]
                        
                        if ($State -eq "ONLINE") {
                            $Result.Details += "✓ Datenbank '$DbName': ${Size} MB, Status: $State"
                        } else {
                            $Result.Status = "WARNING"
                            $Result.ErrorCode = "SQL-002"
                            $Result.Details += "⚠ Datenbank '$DbName': $State"
                        }
                    }
                } else {
                    $Result.Status = "WARNING"
                    $Result.ErrorCode = "SQL-003"
                    $Result.Details += "⚠ Keine Sage-Datenbanken gefunden"
                }
                
            } catch {
                $Result.Status = "CRITICAL"
                $Result.ErrorCode = "SQL-004"
                $Result.Details += "✗ Datenbankverbindung fehlgeschlagen: $($_.Exception.Message)"
            } finally {
                if ($Connection.State -eq 'Open') {
                    $Connection.Close()
                }
            }
            
        } catch {
            $Result.Status = "CRITICAL"
            $Result.ErrorCode = "SQL-005"
            $Result.Details += "✗ Fehler beim SQL Server Check: $($_.Exception.Message)"
        }
        
        $Stopwatch.Stop()
        $Result.Duration = $Stopwatch.ElapsedMilliseconds
        
        return [PSCustomObject]$Result
        
    } -ArgumentList $Config.SqlServer
    
    # Services Check (Async)
    $Jobs += Start-Job -Name "ServicesCheck" -ScriptBlock {
        param($Services)
        
        $Stopwatch = [Stopwatch]::StartNew()
        
        $Result = @{
            CheckName = "Sage Services"
            Status = "OK"
            Details = @()
            Timestamp = Get-Date
            Duration = 0
            ErrorCode = $null
        }
        
        foreach ($ServiceName in $Services) {
            try {
                $Service = Get-Service -Name $ServiceName -ErrorAction Stop
                
                if ($Service.Status -ne "Running") {
                    if ($Result.Status -ne "CRITICAL") { 
                        $Result.Status = "WARNING"
                        $Result.ErrorCode = "SVC-001"
                    }
                    $Result.Details += "⚠ Service '$ServiceName' ist gestoppt: $($Service.Status)"
                } else {
                    $Result.Details += "✓ Service '$ServiceName' läuft"
                }
                
            } catch {
                $Result.Status = "CRITICAL"
                $Result.ErrorCode = "SVC-002"
                $Result.Details += "✗ Service '$ServiceName' nicht gefunden"
            }
        }
        
        $Stopwatch.Stop()
        $Result.Duration = $Stopwatch.ElapsedMilliseconds
        
        return [PSCustomObject]$Result
        
    } -ArgumentList (,$Config.RequiredServices)
    
    # Disk Space Check (Async)
    $Jobs += Start-Job -Name "DiskSpaceCheck" -ScriptBlock {
        param($MinPercent, $CriticalPercent)
        
        $Stopwatch = [Stopwatch]::StartNew()
        
        $Result = @{
            CheckName = "Disk Space"
            Status = "OK"
            Details = @()
            Timestamp = Get-Date
            Duration = 0
            ErrorCode = $null
        }
        
        $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        
        foreach ($Disk in $Disks) {
            $FreePercent = [math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)
            $FreeSizeGB = [math]::Round($Disk.FreeSpace / 1GB, 2)
            $TotalSizeGB = [math]::Round($Disk.Size / 1GB, 2)
            
            $DiskInfo = "$($Disk.DeviceID) ${FreeSizeGB}GB frei von ${TotalSizeGB}GB (${FreePercent}%)"
            
            if ($FreePercent -lt $CriticalPercent) {
                $Result.Status = "CRITICAL"
                $Result.ErrorCode = "DISK-001"
                $Result.Details += "✗ KRITISCH: $DiskInfo"
            } elseif ($FreePercent -lt $MinPercent) {
                if ($Result.Status -ne "CRITICAL") { 
                    $Result.Status = "WARNING"
                    $Result.ErrorCode = "DISK-002"
                }
                $Result.Details += "⚠ WARNUNG: $DiskInfo"
            } else {
                $Result.Details += "✓ OK: $DiskInfo"
            }
        }
        
        $Stopwatch.Stop()
        $Result.Duration = $Stopwatch.ElapsedMilliseconds
        
        return [PSCustomObject]$Result
        
    } -ArgumentList $Config.DiskSpace.MinimumFreePercent, $Config.DiskSpace.CriticalPercent
    
    # Network Check (Async)
    if ($Config.NetworkEndpoints -and $Config.NetworkEndpoints.Count -gt 0) {
        $Jobs += Start-Job -Name "NetworkCheck" -ScriptBlock {
            param($Endpoints)
            
            $Stopwatch = [Stopwatch]::StartNew()
            
            $Result = @{
                CheckName = "Network Connectivity"
                Status = "OK"
                Details = @()
                Timestamp = Get-Date
                Duration = 0
                ErrorCode = $null
            }
            
            foreach ($Endpoint in $Endpoints) {
                try {
                    $TcpClient = New-Object System.Net.Sockets.TcpClient
                    $AsyncResult = $TcpClient.BeginConnect($Endpoint.Host, $Endpoint.Port, $null, $null)
                    $WaitHandle = $AsyncResult.AsyncWaitHandle
                    
                    if ($WaitHandle.WaitOne(3000)) {
                        $TcpClient.EndConnect($AsyncResult)
                        $Result.Details += "✓ Verbindung zu $($Endpoint.Host):$($Endpoint.Port) erfolgreich"
                        $TcpClient.Close()
                    } else {
                        if ($Endpoint.Critical) {
                            $Result.Status = "CRITICAL"
                            $Result.ErrorCode = "NET-001"
                        } else {
                            if ($Result.Status -ne "CRITICAL") { $Result.Status = "WARNING" }
                            $Result.ErrorCode = "NET-002"
                        }
                        $Result.Details += "✗ Keine Verbindung zu $($Endpoint.Host):$($Endpoint.Port)"
                    }
                    
                } catch {
                    if ($Endpoint.Critical) {
                        $Result.Status = "CRITICAL"
                        $Result.ErrorCode = "NET-003"
                    } else {
                        if ($Result.Status -ne "CRITICAL") { $Result.Status = "WARNING" }
                    }
                    $Result.Details += "✗ Fehler bei Verbindung zu $($Endpoint.Host):$($Endpoint.Port) - $($_.Exception.Message)"
                } finally {
                    if ($TcpClient) { $TcpClient.Close() }
                }
            }
            
            $Stopwatch.Stop()
            $Result.Duration = $Stopwatch.ElapsedMilliseconds
            
            return [PSCustomObject]$Result
            
        } -ArgumentList (,$Config.NetworkEndpoints)
    }
    
    # Warten auf alle Jobs mit Timeout
    $Timeout = 30
    $Jobs | Wait-Job -Timeout $Timeout | Out-Null
    
    # Ergebnisse sammeln
    $AllResults = @()
    foreach ($Job in $Jobs) {
        if ($Job.State -eq "Completed") {
            $JobResult = Receive-Job -Job $Job
            $AllResults += $JobResult
        } else {
            # Timeout-Fehler
            $AllResults += [PSCustomObject]@{
                CheckName = $Job.Name
                Status = "CRITICAL"
                Details = @("Check hat Timeout überschritten (${Timeout}s)")
                Timestamp = Get-Date
                Duration = $Timeout * 1000
                ErrorCode = "TIMEOUT-001"
            }
            Stop-Job -Job $Job
        }
        Remove-Job -Job $Job -Force
    }
    
    return $AllResults
}

function Get-PerformanceMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$CheckResults
    )
    
    $TotalDuration = ($CheckResults | Measure-Object -Property Duration -Sum).Sum
    $AverageDuration = [math]::Round(($CheckResults | Measure-Object -Property Duration -Average).Average, 2)
    
    return [PSCustomObject]@{
        TotalDurationMs = $TotalDuration
        AverageDurationMs = $AverageDuration
        TotalChecks = $CheckResults.Count
        FailedChecks = ($CheckResults | Where-Object { $_.Status -eq "CRITICAL" }).Count
        WarningChecks = ($CheckResults | Where-Object { $_.Status -eq "WARNING" }).Count
        SuccessfulChecks = ($CheckResults | Where-Object { $_.Status -eq "OK" }).Count
    }
}

Export-ModuleMember -Function Invoke-ParallelChecks, Get-PerformanceMetrics
