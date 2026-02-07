# ComplianceCheck.psm1
# Prueft Sage 100 Systemvoraussetzungen

function Test-Sage100Compliance {
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Config
    )

    Write-Host ""
    Write-Host "Pruefe Sage 100 Systemvoraussetzungen..." -ForegroundColor Cyan

    $results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OSCompliance = @{}
        HardwareCompliance = @{}
        SoftwareCompliance = @{}
        SQLServerCompliance = @{}
        PermissionChecks = @{}
        Issues = @()
        Warnings = @()
        Passed = $false
    }

    # 1. Betriebssystem pruefen
    Write-Host ""
    Write-Host "1. Betriebssystem-Anforderungen..." -ForegroundColor Cyan
    
    $os = Get-CimInstance Win32_OperatingSystem
    $osVersion = [System.Environment]::OSVersion.Version
    
    $supportedOS = @(
        "Microsoft Windows Server 2022",
        "Microsoft Windows Server 2019",
        "Microsoft Windows Server 2016",
        "Microsoft Windows 11",
        "Microsoft Windows 10"
    )

    $osSupported = $false
    foreach ($supported in $supportedOS) {
        if ($os.Caption -like "*$supported*") {
            $osSupported = $true
            break
        }
    }

    $results.OSCompliance = @{
        Caption = $os.Caption
        Version = $os.Version
        BuildNumber = $os.BuildNumber
        Architecture = $os.OSArchitecture
        Supported = $osSupported
    }

    if ($osSupported) {
        Write-Host "  OS: $($os.Caption) - UNTERSTUETZT" -ForegroundColor Green
    } else {
        Write-Host "  OS: $($os.Caption) - NICHT UNTERSTUETZT" -ForegroundColor Red
        $results.Issues += "Betriebssystem wird von Sage 100 nicht offiziell unterstuetzt"
    }

    # 2. Hardware-Anforderungen
    Write-Host ""
    Write-Host "2. Hardware-Anforderungen..." -ForegroundColor Cyan

    # RAM pruefen (Minimum 4 GB, empfohlen 8 GB)
    $ram = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $ramStatus = "OK"
    $ramColor = "Green"

    if ($ram -lt 4) {
        $ramStatus = "KRITISCH - Minimum 4 GB erforderlich"
        $ramColor = "Red"
        $results.Issues += "Zu wenig RAM: $ram GB (Minimum: 4 GB)"
    } elseif ($ram -lt 8) {
        $ramStatus = "WARNUNG - 8 GB empfohlen"
        $ramColor = "Yellow"
        $results.Warnings += "RAM unter Empfehlung: $ram GB (Empfohlen: 8 GB)"
    }

    Write-Host "  RAM: $ram GB - $ramStatus" -ForegroundColor $ramColor

    # CPU Kerne pruefen
    $cpu = Get-CimInstance Win32_Processor
    $cores = $cpu.NumberOfCores
    
    if ($cores -lt 2) {
        Write-Host "  CPU: $cores Kerne - WARNUNG (2+ empfohlen)" -ForegroundColor Yellow
        $results.Warnings += "Nur $cores CPU-Kern(e) vorhanden (2+ empfohlen)"
    } else {
        Write-Host "  CPU: $cores Kerne - OK" -ForegroundColor Green
    }

    # Festplattenspeicher pruefen (Minimum 10 GB frei)
    $systemDrive = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DeviceID -eq "C:"}
    $freeSpaceGB = [Math]::Round($systemDrive.FreeSpace / 1GB, 2)
    
    if ($freeSpaceGB -lt 10) {
        Write-Host "  Freier Speicher C:: $freeSpaceGB GB - KRITISCH" -ForegroundColor Red
        $results.Issues += "Zu wenig Speicherplatz: $freeSpaceGB GB (Minimum: 10 GB)"
    } else {
        Write-Host "  Freier Speicher C:: $freeSpaceGB GB - OK" -ForegroundColor Green
    }

    $results.HardwareCompliance = @{
        RAM_GB = $ram
        RAM_Status = $ramStatus
        CPU_Cores = $cores
        FreeSpace_GB = $freeSpaceGB
    }

    # 3. .NET Framework pruefen
    Write-Host ""
    Write-Host "3. .NET Framework..." -ForegroundColor Cyan

    $dotNetVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
    
    if ($dotNetVersion) {
        $release = $dotNetVersion.Release
        $version = switch ($release) {
            {$_ -ge 533320} { "4.8.1 oder neuer" }
            {$_ -ge 528040} { "4.8" }
            {$_ -ge 461808} { "4.7.2" }
            {$_ -ge 461308} { "4.7.1" }
            {$_ -ge 460798} { "4.7" }
            default { "4.6 oder aelter" }
        }

        if ($release -ge 461808) {
            Write-Host "  .NET Framework: $version (Release $release) - OK" -ForegroundColor Green
        } else {
            Write-Host "  .NET Framework: $version - VERALTET (4.7.2+ empfohlen)" -ForegroundColor Yellow
            $results.Warnings += ".NET Framework Version veraltet: $version"
        }

        $results.SoftwareCompliance.DotNetVersion = $version
        $results.SoftwareCompliance.DotNetRelease = $release
    } else {
        Write-Host "  .NET Framework 4.x: NICHT INSTALLIERT" -ForegroundColor Red
        $results.Issues += ".NET Framework 4.7.2 oder neuer erforderlich"
    }

    # 4. SQL Server pruefen
    Write-Host ""
    Write-Host "4. SQL Server..." -ForegroundColor Cyan

    $sqlInstances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -ErrorAction SilentlyContinue
    
    if ($sqlInstances) {
        $installedInstances = $sqlInstances.InstalledInstances
        
        if ($installedInstances) {
            foreach ($instance in $installedInstances) {
                Write-Host "  SQL Server Instanz gefunden: $instance" -ForegroundColor Green
                
                # Version pruefen
                try {
                    $instancePath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
                    $instanceKey = Get-ItemProperty $instancePath -ErrorAction SilentlyContinue
                    
                    if ($instanceKey.$instance) {
                        $versionPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$($instanceKey.$instance)\Setup"
                        $versionInfo = Get-ItemProperty $versionPath -ErrorAction SilentlyContinue
                        
                        if ($versionInfo) {
                            $sqlVersion = $versionInfo.Version
                            $edition = $versionInfo.Edition
                            
                            Write-Host "    Version: $sqlVersion" -ForegroundColor Gray
                            Write-Host "    Edition: $edition" -ForegroundColor Gray
                            
                            $results.SQLServerCompliance.$instance = @{
                                Version = $sqlVersion
                                Edition = $edition
                            }

                            # Versionscheck (Sage 100 unterstuetzt SQL Server 2016+)
                            $majorVersion = [int]($sqlVersion.Split('.')[0])
                            if ($majorVersion -lt 13) {
                                Write-Host "    WARNUNG: SQL Server Version zu alt (2016+ empfohlen)" -ForegroundColor Yellow
                                $results.Warnings += "SQL Server ${instance} - Version $sqlVersion ist veraltet"
                            }
                        }
                    }
                } catch {
                    Write-Host "    Konnte Versionsinformationen nicht auslesen" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "  Keine SQL Server Instanzen gefunden" -ForegroundColor Yellow
            $results.Warnings += "Kein SQL Server installiert (wird fuer Sage 100 benoetigt)"
        }
    } else {
        Write-Host "  SQL Server: NICHT INSTALLIERT" -ForegroundColor Red
        $results.Issues += "SQL Server 2016 oder neuer erforderlich"
    }

    # 5. Microsoft Office / Access Runtime pruefen
    Write-Host ""
    Write-Host "5. Microsoft Office / Access Runtime..." -ForegroundColor Cyan

    $officeVersions = @(
        "HKLM:\SOFTWARE\Microsoft\Office\16.0",  # Office 2016/2019/2021
        "HKLM:\SOFTWARE\Microsoft\Office\15.0",  # Office 2013
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\16.0",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\15.0"
    )

    $officeFound = $false
    foreach ($path in $officeVersions) {
        if (Test-Path $path) {
            $officeFound = $true
            $versionName = switch ($path) {
                {$_ -like "*16.0*"} { "2016/2019/2021" }
                {$_ -like "*15.0*"} { "2013" }
                default { "Unbekannt" }
            }
            Write-Host "  Office $versionName gefunden" -ForegroundColor Green
            $results.SoftwareCompliance.Office = $versionName
            break
        }
    }

    if (-not $officeFound) {
        Write-Host "  Office/Access Runtime: NICHT GEFUNDEN" -ForegroundColor Yellow
        $results.Warnings += "Microsoft Access Runtime empfohlen fuer Sage 100 Berichte"
    }

    # 6. Ordnerberechtigungen pruefen (falls Sage 100 installiert)
    Write-Host ""
    Write-Host "6. Sage 100 Installation..." -ForegroundColor Cyan

    $sage100Paths = @(
        "C:\Program Files (x86)\Sage\Sage 100",
        "C:\Sage\Sage 100",
        "D:\Sage\Sage 100"
    )

    $sage100Found = $false
    foreach ($path in $sage100Paths) {
        if (Test-Path $path) {
            Write-Host "  Sage 100 gefunden: $path" -ForegroundColor Green
            $sage100Found = $true
            $results.SoftwareCompliance.Sage100Path = $path

            # Berechtigungen pruefen
            try {
                $acl = Get-Acl $path
                $userHasAccess = $acl.Access | Where-Object {
                    $_.FileSystemRights -match "FullControl|Modify" -and
                    $_.IdentityReference -like "*$env:USERNAME*"
                }

                if ($userHasAccess) {
                    Write-Host "    Berechtigungen: OK (Benutzer hat Zugriff)" -ForegroundColor Green
                } else {
                    Write-Host "    WARNUNG: Aktuelle Benutzerrechte unklar" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "    Konnte Berechtigungen nicht pruefen" -ForegroundColor Yellow
            }
            break
        }
    }

    if (-not $sage100Found) {
        Write-Host "  Sage 100: NICHT INSTALLIERT" -ForegroundColor Yellow
        $results.Warnings += "Sage 100 nicht gefunden - Installation erforderlich"
    }

    # Gesamtbewertung
    $results.Passed = ($results.Issues.Count -eq 0)

    return $results
}

function Get-Sage100Requirements {
    return @{
        OS = @{
            Supported = @(
                "Windows Server 2022",
                "Windows Server 2019", 
                "Windows Server 2016",
                "Windows 11 Pro/Enterprise",
                "Windows 10 Pro/Enterprise"
            )
            NotSupported = @(
                "Windows Server 2012",
                "Windows 8.x",
                "Windows 7"
            )
        }
        Hardware = @{
            RAM_Minimum = 4
            RAM_Recommended = 8
            CPU_Cores_Minimum = 2
            DiskSpace_Minimum = 10
        }
        Software = @{
            DotNet = "4.7.2 oder neuer"
            SQLServer = "2016, 2017, 2019, 2022"
            Office = "2013 oder neuer (oder Access Runtime)"
        }
        Network = @{
            Ports = @(
                @{Port=1433; Service="SQL Server"},
                @{Port=5493; Service="Sage 100 AppServer"},
                @{Port=4000; Service="Lizenzserver"}
            )
        }
    }
}

Export-ModuleMember -Function Test-Sage100Compliance, Get-Sage100Requirements
