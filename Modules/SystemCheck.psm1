function Get-SystemInformation {
    <#
    .SYNOPSIS
    Sammelt System-Informationen
    #>
    
    Write-Host "`n[i] Sammle System-Informationen..." -ForegroundColor Cyan
    
    $info = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName = $env:COMPUTERNAME
        Domain = (Get-WmiObject Win32_ComputerSystem).Domain
        OS = @{}
        Hardware = @{}
        Software = @{}
        Warnings = @()
        Errors = @()
    }
    
    # Betriebssystem
    try {
        $os = Get-WmiObject Win32_OperatingSystem
        $info.OS = @{
            Name = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate = $os.ConvertToDateTime($os.InstallDate)
            LastBootUpTime = $os.ConvertToDateTime($os.LastBootUpTime)
        }
        
        Write-Host "  OS: $($info.OS.Name) ($($info.OS.Version))" -ForegroundColor Green
        
    } catch {
        $info.Errors += "Fehler beim Auslesen des Betriebssystems: $_"
        Write-Host "  FEHLER: Betriebssystem konnte nicht ausgelesen werden" -ForegroundColor Red
    }
    
    # Hardware
    try {
        $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1
        $ram = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $ramGB = [math]::Round($ram.Sum / 1GB, 2)
        
        $info.Hardware = @{
            CPU = @{
                Name = $cpu.Name
                Cores = $cpu.NumberOfCores
                LogicalProcessors = $cpu.NumberOfLogicalProcessors
                MaxClockSpeed = $cpu.MaxClockSpeed
            }
            RAM = @{
                TotalGB = $ramGB
                Modules = $ram.Count
            }
            Disks = @()
        }
        
        Write-Host "  CPU: $($cpu.Name) ($($cpu.NumberOfCores) Cores)" -ForegroundColor Green
        Write-Host "  RAM: $ramGB GB" -ForegroundColor Green
        
        # Festplatten
        $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($disk in $disks) {
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($disk.Size / 1GB, 2)
            $usedPercent = [math]::Round((($totalGB - $freeGB) / $totalGB) * 100, 1)
            
            $diskInfo = @{
                Drive = $disk.DeviceID
                TotalGB = $totalGB
                FreeGB = $freeGB
                UsedPercent = $usedPercent
            }
            
            $info.Hardware.Disks += $diskInfo
            
            Write-Host "  Disk $($disk.DeviceID): $freeGB GB frei von $totalGB GB" -ForegroundColor Green
            
            if ($usedPercent -gt 90) {
                $warning = "Festplatte $($disk.DeviceID) ist zu $usedPercent% voll!"
                $info.Warnings += $warning
                Write-Host "  WARNUNG: $warning" -ForegroundColor Yellow
            }
        }
        
    } catch {
        $info.Errors += "Fehler beim Auslesen der Hardware: $_"
        Write-Host "  FEHLER: Hardware konnte nicht ausgelesen werden" -ForegroundColor Red
    }
    
    # Software
    try {
        # .NET Framework
        $dotNet = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
        if ($dotNet) {
            $info.Software.DotNetVersion = $dotNet.Version
            Write-Host "  .NET Framework: $($dotNet.Version)" -ForegroundColor Green
        }
        
        # PowerShell Version
        $info.Software.PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Write-Host "  PowerShell: $($info.Software.PowerShellVersion)" -ForegroundColor Green
        
        # SQL Server
        $sqlInstances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server" -ErrorAction SilentlyContinue
        if ($sqlInstances) {
            $instanceNames = $sqlInstances.InstalledInstances
            if ($instanceNames) {
                $info.Software.SQLServer = @{
                    Instances = @($instanceNames)
                }
                Write-Host "  SQL Server Instanzen: $($instanceNames -join ', ')" -ForegroundColor Green
            }
        }
        
    } catch {
        $info.Errors += "Fehler beim Auslesen der Software: $_"
        Write-Host "  FEHLER: Software konnte nicht ausgelesen werden" -ForegroundColor Red
    }
    
    return $info
}

Export-ModuleMember -Function Get-SystemInformation
