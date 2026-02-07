# DebugLogger.psm1
# Comprehensive logging system for debugging and analysis

$script:LogSession = @{
    SessionId = [guid]::NewGuid().ToString()
    StartTime = Get-Date
    Actions = @()
    Errors = @()
    Warnings = @()
}

$script:LogPath = Join-Path $PSScriptRoot "..\Data\Logs"

function Initialize-DebugLog {
    <#
    .SYNOPSIS
    Initializes the debug logging system
    #>
    [CmdletBinding()]
    param()
    
    # Create Logs directory if it doesn't exist
    if (-not (Test-Path $script:LogPath)) {
        New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
    }
    
    $script:LogSession.SessionId = [guid]::NewGuid().ToString()
    $script:LogSession.StartTime = Get-Date
    $script:LogSession.Actions = @()
    $script:LogSession.Errors = @()
    $script:LogSession.Warnings = @()
    
    Write-LogAction -FunctionName "Initialize-DebugLog" -Status "Success" -Message "Debug logging initialized"
}

function Write-LogAction {
    <#
    .SYNOPSIS
    Logs an action with timing and result information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory=$false)]
        [string]$Status = "Running",
        
        [Parameter(Mandatory=$false)]
        [object]$Result = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "",
        
        [Parameter(Mandatory=$false)]
        [int]$DurationMs = 0,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    $logEntry = @{
        Timestamp = (Get-Date).ToString("o")
        Function = $FunctionName
        Status = $Status
        Message = $Message
        DurationMs = $DurationMs
    }
    
    if ($Parameters.Count -gt 0) {
        $logEntry.Parameters = $Parameters
    }
    
    if ($Result) {
        # Convert result to serializable format
        try {
            $logEntry.Result = $Result | ConvertTo-Json -Depth 3 -Compress
        } catch {
            $logEntry.Result = $Result.ToString()
        }
    }
    
    if ($ErrorRecord) {
        $logEntry.Error = @{
            Message = $ErrorRecord.Exception.Message
            Type = $ErrorRecord.Exception.GetType().FullName
            ScriptStackTrace = $ErrorRecord.ScriptStackTrace
            InvocationInfo = @{
                ScriptName = $ErrorRecord.InvocationInfo.ScriptName
                Line = $ErrorRecord.InvocationInfo.ScriptLineNumber
                Command = $ErrorRecord.InvocationInfo.MyCommand.Name
            }
        }
        $script:LogSession.Errors += $logEntry
    } elseif ($Status -eq "Warning") {
        $script:LogSession.Warnings += $logEntry
    }
    
    $script:LogSession.Actions += $logEntry
}

function Invoke-LoggedFunction {
    <#
    .SYNOPSIS
    Wrapper that executes a function and logs its execution
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FunctionName,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )
    
    $startTime = Get-Date
    $status = "Success"
    $result = $null
    $errorRecord = $null
    
    try {
        Write-LogAction -FunctionName $FunctionName -Parameters $Parameters -Status "Started"
        $result = & $ScriptBlock
    } catch {
        $status = "Error"
        $errorRecord = $_
        throw
    } finally {
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        Write-LogAction -FunctionName $FunctionName `
                       -Parameters $Parameters `
                       -Status $status `
                       -Result $result `
                       -DurationMs ([int]$duration) `
                       -ErrorRecord $errorRecord
    }
    
    return $result
}

function Export-DebugLog {
    <#
    .SYNOPSIS
    Exports the debug log to a JSON file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$OutputPath = $null
    )
    
    if (-not $OutputPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $OutputPath = Join-Path $script:LogPath "debug_$timestamp.json"
    }
    
    $script:LogSession.EndTime = Get-Date
    $script:LogSession.TotalDurationSeconds = ((Get-Date) - $script:LogSession.StartTime).TotalSeconds
    
    # Create summary statistics
    $summary = @{
        TotalActions = $script:LogSession.Actions.Count
        SuccessfulActions = ($script:LogSession.Actions | Where-Object { $_.Status -eq "Success" }).Count
        FailedActions = $script:LogSession.Errors.Count
        Warnings = $script:LogSession.Warnings.Count
        TotalDurationSeconds = [math]::Round($script:LogSession.TotalDurationSeconds, 2)
    }
    
    $script:LogSession.Summary = $summary
    
    # Add system context
    $script:LogSession.SystemContext = @{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        OSVersion = [System.Environment]::OSVersion.VersionString
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        ExecutionPolicy = (Get-ExecutionPolicy).ToString()
    }
    
    try {
        $script:LogSession | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Host "`n[DEBUG] Log gespeichert: $OutputPath" -ForegroundColor Cyan
        return $OutputPath
    } catch {
        Write-Warning "Fehler beim Speichern des Debug-Logs: $_"
        return $null
    }
}

function Get-DebugLogSummary {
    <#
    .SYNOPSIS
    Returns a human-readable summary of the current log session
    #>
    [CmdletBinding()]
    param()
    
    $duration = ((Get-Date) - $script:LogSession.StartTime).TotalSeconds
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "DEBUG LOG ZUSAMMENFASSUNG" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Session ID: $($script:LogSession.SessionId)"
    Write-Host "Dauer: $([math]::Round($duration, 2)) Sekunden"
    Write-Host "Aktionen: $($script:LogSession.Actions.Count)"
    Write-Host "Fehler: $($script:LogSession.Errors.Count)"
    Write-Host "Warnungen: $($script:LogSession.Warnings.Count)"
    
    if ($script:LogSession.Errors.Count -gt 0) {
        Write-Host "`nFEHLER:" -ForegroundColor Red
        foreach ($error in $script:LogSession.Errors) {
            Write-Host "  [$($error.Timestamp)] $($error.Function): $($error.Error.Message)" -ForegroundColor Red
        }
    }
    
    if ($script:LogSession.Warnings.Count -gt 0) {
        Write-Host "`nWARNUNGEN:" -ForegroundColor Yellow
        foreach ($warning in $script:LogSession.Warnings) {
            Write-Host "  [$($warning.Timestamp)] $($warning.Function): $($warning.Message)" -ForegroundColor Yellow
        }
    }
    
    # Top 5 slowest operations
    $slowest = $script:LogSession.Actions | 
               Where-Object { $_.DurationMs -gt 0 } | 
               Sort-Object -Property DurationMs -Descending | 
               Select-Object -First 5
    
    if ($slowest) {
        Write-Host "`nLANGSAMSTE OPERATIONEN:" -ForegroundColor Yellow
        foreach ($op in $slowest) {
            Write-Host "  $($op.Function): $($op.DurationMs) ms"
        }
    }
    
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Start-LoggedOperation {
    <#
    .SYNOPSIS
    Starts a logged operation and returns a stopwatch
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OperationName,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )
    
    Write-LogAction -FunctionName $OperationName -Parameters $Parameters -Status "Started"
    
    return @{
        Name = $OperationName
        StartTime = Get-Date
        Parameters = $Parameters
    }
}

function Stop-LoggedOperation {
    <#
    .SYNOPSIS
    Stops a logged operation and records the result
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Operation,
        
        [Parameter(Mandatory=$false)]
        [string]$Status = "Success",
        
        [Parameter(Mandatory=$false)]
        [object]$Result = $null,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "",
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord = $null
    )
    
    $duration = ((Get-Date) - $Operation.StartTime).TotalMilliseconds
    
    Write-LogAction -FunctionName $Operation.Name `
                   -Parameters $Operation.Parameters `
                   -Status $Status `
                   -Result $Result `
                   -Message $Message `
                   -DurationMs ([int]$duration) `
                   -ErrorRecord $ErrorRecord
}

# Auto-initialize on module import
Initialize-DebugLog

Export-ModuleMember -Function Initialize-DebugLog, Write-LogAction, Invoke-LoggedFunction, Export-DebugLog, Get-DebugLogSummary, Start-LoggedOperation, Stop-LoggedOperation
