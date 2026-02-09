# Modules/ConfigValidator.psm1
<#
.SYNOPSIS
    Konfigurationsvalidierung für Sage100-ServerCheck
.DESCRIPTION
    Validiert die config.json gegen ein definiertes Schema
#>

function Test-ConfigSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )
    
    $ValidationErrors = @()
    
    # SQL Server Validierung
    if (-not $Config.SqlServer) {
        $ValidationErrors += "SqlServer-Konfiguration fehlt"
    } else {
        if ([string]::IsNullOrWhiteSpace($Config.SqlServer.ServerName)) {
            $ValidationErrors += "SqlServer.ServerName ist erforderlich"
        }
        if ([string]::IsNullOrWhiteSpace($Config.SqlServer.ServiceName)) {
            $ValidationErrors += "SqlServer.ServiceName ist erforderlich"
        }
    }
    
    # Required Services Validierung
    if (-not $Config.RequiredServices -or $Config.RequiredServices.Count -eq 0) {
        $ValidationErrors += "Mindestens ein Service muss in RequiredServices definiert sein"
    }
    
    # DiskSpace Validierung
    if ($Config.DiskSpace) {
        if ($Config.DiskSpace.MinimumFreePercent -lt 0 -or $Config.DiskSpace.MinimumFreePercent -gt 100) {
            $ValidationErrors += "DiskSpace.MinimumFreePercent muss zwischen 0 und 100 liegen"
        }
        if ($Config.DiskSpace.CriticalPercent -lt 0 -or $Config.DiskSpace.CriticalPercent -gt 100) {
            $ValidationErrors += "DiskSpace.CriticalPercent muss zwischen 0 und 100 liegen"
        }
    }
    
    # Email Validierung
    if ($Config.Email -and $Config.Email.Enabled) {
        if ([string]::IsNullOrWhiteSpace($Config.Email.SmtpServer)) {
            $ValidationErrors += "Email.SmtpServer ist erforderlich wenn Email aktiviert ist"
        }
        if ([string]::IsNullOrWhiteSpace($Config.Email.From)) {
            $ValidationErrors += "Email.From ist erforderlich"
        }
        if (-not $Config.Email.To -or $Config.Email.To.Count -eq 0) {
            $ValidationErrors += "Mindestens ein Empfänger in Email.To ist erforderlich"
        }
        if ($Config.Email.Port -lt 1 -or $Config.Email.Port -gt 65535) {
            $ValidationErrors += "Email.Port muss zwischen 1 und 65535 liegen"
        }
    }
    
    # Network Endpoints Validierung
    if ($Config.NetworkEndpoints) {
        foreach ($Endpoint in $Config.NetworkEndpoints) {
            if ([string]::IsNullOrWhiteSpace($Endpoint.Host)) {
                $ValidationErrors += "NetworkEndpoint.Host darf nicht leer sein"
            }
            if ($Endpoint.Port -lt 1 -or $Endpoint.Port -gt 65535) {
                $ValidationErrors += "NetworkEndpoint.Port muss zwischen 1 und 65535 liegen"
            }
        }
    }
    
    return [PSCustomObject]@{
        IsValid = ($ValidationErrors.Count -eq 0)
        Errors = $ValidationErrors
    }
}

function Get-SecureConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )
    
    try {
        if (-not (Test-Path $ConfigPath)) {
            throw "Konfigurationsdatei nicht gefunden: $ConfigPath"
        }
        
        $ConfigJson = Get-Content $ConfigPath -Raw -ErrorAction Stop
        $Config = $ConfigJson | ConvertFrom-Json -ErrorAction Stop
        
        # Validierung
        $ValidationResult = Test-ConfigSchema -Config $Config
        
        if (-not $ValidationResult.IsValid) {
            throw "Konfigurationsvalidierung fehlgeschlagen:`n" + ($ValidationResult.Errors -join "`n")
        }
        
        # Verschlüsselte Credentials entschlüsseln falls vorhanden
        if ($Config.Email.Password -and $Config.Email.Password.StartsWith("encrypted:")) {
            $EncryptedPassword = $Config.Email.Password.Replace("encrypted:", "")
            $Config.Email.Password = ConvertFrom-SecureStringToPlainText -SecureString (ConvertTo-SecureString $EncryptedPassword)
        }
        
        return $Config
        
    } catch {
        throw "Fehler beim Laden der Konfiguration: $_"
    }
}

function Set-SecurePassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory=$true)]
        [SecureString]$Password
    )
    
    try {
        $Config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        # Verschlüsselung mit DPAPI (Windows Data Protection API)
        $EncryptedPassword = ConvertFrom-SecureString -SecureString $Password
        $Config.Email.Password = "encrypted:$EncryptedPassword"
        
        $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
        
        Write-Verbose "Passwort wurde verschlüsselt gespeichert"
        
    } catch {
        throw "Fehler beim Verschlüsseln des Passworts: $_"
    }
}

function ConvertFrom-SecureStringToPlainText {
    param(
        [Parameter(Mandatory=$true)]
        [SecureString]$SecureString
    )
    
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

Export-ModuleMember -Function Test-ConfigSchema, Get-SecureConfig, Set-SecurePassword
