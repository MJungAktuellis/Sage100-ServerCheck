# NetworkCheck.psm1
# Netzwerk- und Firewall-Pruefungen fuer Sage 100

function Test-NetworkConfiguration {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Config
    )

    Write-Host ""
    Write-Host "Pruefe Netzwerk-Konfiguration..." -ForegroundColor Cyan

    $results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        NetworkAdapters = @()
        PortChecks = @()
        FirewallRules = @()
        DNSTests = @()
        Issues = @()
        Warnings = @()
    }

    # 1. Netzwerkadapter pruefen
    try {
        $adapters = Get-NetAdapter | Where-Object {$_.Status -eq 'Up'}
        foreach ($adapter in $adapters) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            $results.NetworkAdapters += @{
                Name = $adapter.Name
                Status = $adapter.Status
                Speed = $adapter.LinkSpeed
                IPAddress = $ip.IPAddress
                MACAddress = $adapter.MacAddress
            }
            Write-Host "  Adapter: $($adapter.Name) - $($ip.IPAddress) [$($adapter.LinkSpeed)]" -ForegroundColor Gray
        }
    } catch {
        $results.Issues += "Fehler beim Auslesen der Netzwerkadapter: $_"
    }

    # 2. Wichtige Ports fuer Sage 100 pruefen
    $portsToCheck = @(
        @{Port=1433; Service="SQL Server"; Protocol="TCP"},
        @{Port=5493; Service="Sage 100 AppServer"; Protocol="TCP"},
        @{Port=4000; Service="Sage 100 Lizenzserver"; Protocol="TCP"},
        @{Port=135; Service="RPC Endpoint Mapper"; Protocol="TCP"},
        @{Port=139; Service="NetBIOS Session"; Protocol="TCP"},
        @{Port=445; Service="SMB/CIFS"; Protocol="TCP"},
        @{Port=3389; Service="Remote Desktop"; Protocol="TCP"}
    )

    Write-Host ""
    Write-Host "Pruefe wichtige Ports..." -ForegroundColor Cyan

    foreach ($portCheck in $portsToCheck) {
        $port = $portCheck.Port
        $service = $portCheck.Service
        
        try {
            $listener = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
            $isListening = $listener -ne $null

            $portResult = @{
                Port = $port
                Service = $service
                Protocol = $portCheck.Protocol
                IsListening = $isListening
                Process = ""
            }

            if ($isListening) {
                try {
                    $process = Get-Process -Id $listener[0].OwningProcess -ErrorAction SilentlyContinue
                    $portResult.Process = $process.ProcessName
                    Write-Host "  Port $port ($service): OFFEN - Prozess: $($process.ProcessName)" -ForegroundColor Green
                } catch {
                    Write-Host "  Port $port ($service): OFFEN" -ForegroundColor Green
                }
            } else {
                Write-Host "  Port $port ($service): GESCHLOSSEN" -ForegroundColor Yellow
                $results.Warnings += "Port $port ($service) ist nicht geoeffnet"
            }

            $results.PortChecks += $portResult

        } catch {
            $results.Issues += "Fehler beim Pruefen von Port ${port}: $_"
        }
    }

    # 3. Firewall-Regeln pruefen
    Write-Host ""
    Write-Host "Pruefe Firewall-Regeln..." -ForegroundColor Cyan

    try {
        $firewallEnabled = Get-NetFirewallProfile | Where-Object {$_.Enabled -eq $true}
        
        foreach ($profile in $firewallEnabled) {
            Write-Host "  Firewall-Profil '$($profile.Name)' ist AKTIV" -ForegroundColor Gray
        }

        # Pruefe spezifische Sage 100 Regeln
        $sage100Rules = Get-NetFirewallRule | Where-Object {
            $_.DisplayName -like "*Sage*" -or 
            $_.DisplayName -like "*SQL*" -or
            $_.DisplayName -like "*1433*" -or
            $_.DisplayName -like "*5493*"
        }

        if ($sage100Rules.Count -gt 0) {
            Write-Host "  Gefundene Sage 100 Firewall-Regeln: $($sage100Rules.Count)" -ForegroundColor Green
            foreach ($rule in $sage100Rules) {
                $results.FirewallRules += @{
                    Name = $rule.DisplayName
                    Enabled = $rule.Enabled
                    Direction = $rule.Direction
                    Action = $rule.Action
                }
            }
        } else {
            Write-Host "  WARNUNG: Keine Sage 100 spezifischen Firewall-Regeln gefunden" -ForegroundColor Yellow
            $results.Warnings += "Keine Sage 100 Firewall-Regeln konfiguriert"
        }

    } catch {
        $results.Issues += "Fehler beim Pruefen der Firewall: $_"
    }

    # 4. DNS-Tests (nur wenn Config vorhanden)
    if ($Config -and $Config.DNSTestHosts) {
        Write-Host ""
        Write-Host "Pruefe DNS-Aufloesung..." -ForegroundColor Cyan

        foreach ($hostname in $Config.DNSTestHosts) {
            try {
                $resolved = Resolve-DnsName -Name $hostname -ErrorAction SilentlyContinue
                if ($resolved) {
                    Write-Host "  $hostname -> $($resolved[0].IPAddress)" -ForegroundColor Green
                    $results.DNSTests += @{
                        Hostname = $hostname
                        Resolved = $true
                        IPAddress = $resolved[0].IPAddress
                    }
                } else {
                    Write-Host "  $hostname -> NICHT AUFLOESBAR" -ForegroundColor Red
                    $results.DNSTests += @{
                        Hostname = $hostname
                        Resolved = $false
                        IPAddress = $null
                    }
                    $results.Issues += "DNS: $hostname kann nicht aufgeloest werden"
                }
            } catch {
                $results.Issues += "DNS-Test fuer $hostname fehlgeschlagen: $_"
            }
        }
    }

    # 5. Internet-Verbindung testen
    Write-Host ""
    Write-Host "Teste Internet-Verbindung..." -ForegroundColor Cyan
    
    try {
        $pingTest = Test-Connection -ComputerName "8.8.8.8" -Count 2 -Quiet
        if ($pingTest) {
            Write-Host "  Internet-Verbindung: OK" -ForegroundColor Green
            $results.InternetConnectivity = $true
        } else {
            Write-Host "  Internet-Verbindung: FEHLER" -ForegroundColor Red
            $results.InternetConnectivity = $false
            $results.Warnings += "Keine Internet-Verbindung verfuegbar"
        }
    } catch {
        $results.InternetConnectivity = $false
        $results.Warnings += "Internet-Test fehlgeschlagen"
    }

    return $results
}

function New-FirewallRule {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$Protocol = "TCP",
        
        [Parameter(Mandatory=$false)]
        [string]$Direction = "Inbound"
    )

    Write-Host ""
    Write-Host "Erstelle Firewall-Regel: $Name (Port $Port/$Protocol)" -ForegroundColor Cyan

    try {
        $existingRule = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
        
        if ($existingRule) {
            Write-Host "  Regel existiert bereits: $Name" -ForegroundColor Yellow
            return $false
        }

        New-NetFirewallRule `
            -DisplayName $Name `
            -Direction $Direction `
            -Protocol $Protocol `
            -LocalPort $Port `
            -Action Allow `
            -Enabled True `
            -ErrorAction Stop

        Write-Host "  Firewall-Regel erfolgreich erstellt!" -ForegroundColor Green
        return $true

    } catch {
        Write-Host "  FEHLER beim Erstellen der Firewall-Regel: $_" -ForegroundColor Red
        return $false
    }
}

function Test-Port {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 1000
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($asyncResult)
                $tcpClient.Close()
                return $true
            } catch {
                return $false
            }
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

Export-ModuleMember -Function Test-NetworkConfiguration, New-FirewallRule, Test-Port
