function Test-NetworkConfiguration {
    <#
    .SYNOPSIS
    Prueft Netzwerk-Konfiguration und Firewall-Regeln
    #>
    
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = ".\Config\Sage100Config.json"
    )
    
    Write-Host "`n[i] Pruefe Netzwerk-Konfiguration..." -ForegroundColor Cyan
    
    $result = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Ports = @()
        Firewall = @()
        DNS = @{}
        Warnings = @()
        Errors = @()
    }
    
    # Config laden
    try {
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        $result.Errors += "Config-Datei konnte nicht geladen werden: $_"
        return $result
    }
    
    # SQL Server Ports pruefen
    Write-Host "`n  Pruefe SQL Server Ports..." -ForegroundColor Gray
    
    $sqlPort = 1433
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $sqlPort)
        $listener.Start()
        $listener.Stop()
        
        $portInfo = @{
            Port = $sqlPort
            Name = "SQL Server"
            Status = "Verfuegbar"
            InUse = $false
        }
        Write-Host "    Port $sqlPort (SQL Server): Verfuegbar" -ForegroundColor Green
        
    } catch {
        $portInfo = @{
            Port = $sqlPort
            Name = "SQL Server"
            Status = "In Verwendung"
            InUse = $true
        }
        Write-Host "    Port $sqlPort (SQL Server): In Verwendung" -ForegroundColor Yellow
    }
    
    $result.Ports += $portInfo
    
    # Application Server Ports pruefen
    Write-Host "`n  Pruefe Application Server Ports..." -ForegroundColor Gray
    
    $appServerPorts = @(5493, 5494, 5466)
    foreach ($port in $appServerPorts) {
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
            $listener.Start()
            $listener.Stop()
            
            $portInfo = @{
                Port = $port
                Name = "Application Server"
                Status = "Verfuegbar"
                InUse = $false
            }
            Write-Host "    Port $port: Verfuegbar" -ForegroundColor Green
            
        } catch {
            $portInfo = @{
                Port = $port
                Name = "Application Server"
                Status = "In Verwendung"
                InUse = $true
            }
            Write-Host "    Port $port: In Verwendung" -ForegroundColor Yellow
        }
        
        $result.Ports += $portInfo
    }
    
    # BlobStorage Ports pruefen
    Write-Host "`n  Pruefe BlobStorage Ports..." -ForegroundColor Gray
    
    $blobPorts = @(4000, 4010, 4020)
    foreach ($port in $blobPorts) {
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
            $listener.Start()
            $listener.Stop()
            
            $portInfo = @{
                Port = $port
                Name = "BlobStorage"
                Status = "Verfuegbar"
                InUse = $false
            }
            Write-Host "    Port $port: Verfuegbar" -ForegroundColor Green
            
        } catch {
            $portInfo = @{
                Port = $port
                Name = "BlobStorage"
                Status = "In Verwendung"
                InUse = $true
            }
            Write-Host "    Port $port: In Verwendung" -ForegroundColor Yellow
        }
        
        $result.Ports += $portInfo
    }
    
    # Firewall-Regeln pruefen
    Write-Host "`n  Pruefe Firewall-Regeln..." -ForegroundColor Gray
    
    try {
        $fwRules = Get-NetFirewallRule -ErrorAction SilentlyContinue | Where-Object {
            $_.DisplayName -like "*SQL*" -or 
            $_.DisplayName -like "*Sage*" -or
            $_.DisplayName -like "*1433*"
        }
        
        if ($fwRules) {
            foreach ($rule in $fwRules) {
                $result.Firewall += @{
                    Name = $rule.DisplayName
                    Enabled = $rule.Enabled
                    Direction = $rule.Direction
                    Action = $rule.Action
                }
                Write-Host "    Regel gefunden: $($rule.DisplayName) ($(if($rule.Enabled){'Aktiv'}else{'Inaktiv'}))" -ForegroundColor $(if($rule.Enabled){'Green'}else{'Yellow'})
            }
        } else {
            $result.Warnings += "Keine Firewall-Regeln fuer SQL Server oder Sage gefunden"
            Write-Host "    WARNUNG: Keine relevanten Firewall-Regeln gefunden" -ForegroundColor Yellow
        }
        
    } catch {
        $result.Warnings += "Firewall-Regeln konnten nicht geprueft werden: $_"
        Write-Host "    WARNUNG: Firewall konnte nicht geprueft werden" -ForegroundColor Yellow
    }
    
    # DNS-Aufloesung pruefen
    Write-Host "`n  Pruefe DNS-Aufloesung..." -ForegroundColor Gray
    
    try {
        $hostname = [System.Net.Dns]::GetHostName()
        $ipAddresses = [System.Net.Dns]::GetHostAddresses($hostname) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        
        $result.DNS = @{
            Hostname = $hostname
            IPAddresses = @($ipAddresses | ForEach-Object { $_.IPAddressToString })
        }
        
        Write-Host "    Hostname: $hostname" -ForegroundColor Green
        foreach ($ip in $ipAddresses) {
            Write-Host "    IP: $($ip.IPAddressToString)" -ForegroundColor Green
        }
        
    } catch {
        $result.Errors += "DNS-Aufloesung fehlgeschlagen: $_"
        Write-Host "    FEHLER: DNS konnte nicht aufgeloest werden" -ForegroundColor Red
    }
    
    return $result
}

function New-FirewallRule {
    <#
    .SYNOPSIS
    Erstellt eine neue Firewall-Regel
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [string]$Protocol = "TCP"
    )
    
    try {
        New-NetFirewallRule -DisplayName $Name `
                            -Direction Inbound `
                            -Protocol $Protocol `
                            -LocalPort $Port `
                            -Action Allow `
                            -ErrorAction Stop
        
        Write-Host "[OK] Firewall-Regel '$Name' erstellt (Port $Port)" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "[FEHLER] Firewall-Regel konnte nicht erstellt werden: $_" -ForegroundColor Red
        return $false
    }
}

Export-ModuleMember -Function Test-NetworkConfiguration, New-FirewallRule
