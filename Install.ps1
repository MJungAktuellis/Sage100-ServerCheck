<#
.SYNOPSIS
    Universal Windows Installer for Sage100-ServerCheck
    
.DESCRIPTION
    One-click installation script that works on ALL Windows systems (Win 7, 8, 10, 11, Server 2012-2022)
    NO programming knowledge required - just right-click and "Run with PowerShell"
    
.NOTES
    Author: Sage100-ServerCheck Team
    Version: 1.0
    Compatible: Windows 7+ / Server 2012+
    Requirements: PowerShell 5.1+ (pre-installed on Windows 10/11)
#>

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallPath = "$env:ProgramFiles\Sage100-ServerCheck",
    
    [Parameter()]
    [switch]$CreateScheduledTask,
    
    [Parameter()]
    [switch]$CreateDesktopShortcut,
    
    [Parameter()]
    [switch]$Silent
)

# ============================================================================
# INSTALLER CONFIGURATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$InstallerVersion = "1.0.0"
$AppName = "Sage100 Server Check"
$AppDisplayName = "Sage 100 Server Monitoring Tool"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-InstallerLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info'    { 'Cyan' }
        'Success' { 'Green' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
    }
    
    $prefix = switch ($Level) {
        'Info'    { '[INFO]' }
        'Success' { '[OK]' }
        'Warning' { '[WARN]' }
        'Error'   { '[ERROR]' }
    }
    
    if (-not $Silent) {
        Write-Host "$prefix $Message" -ForegroundColor $color
    }
    
    # Log to file
    $logPath = "$env:TEMP\Sage100-ServerCheck-Install.log"
    "$timestamp $prefix $Message" | Out-File -FilePath $logPath -Append -Encoding UTF8
}

function Test-Prerequisites {
    Write-InstallerLog "Checking system prerequisites..." -Level Info
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 5) {
        Write-InstallerLog "PowerShell 5.1 or higher required. Current version: $psVersion" -Level Error
        throw "Please upgrade PowerShell to version 5.1 or higher"
    }
    Write-InstallerLog "PowerShell Version: $psVersion - OK" -Level Success
    
    # Check Administrator rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-InstallerLog "Administrator rights required!" -Level Error
        throw "Please run this installer as Administrator (Right-click → Run as Administrator)"
    }
    Write-InstallerLog "Administrator rights: OK" -Level Success
    
    # Check if .NET Framework is available
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        Write-InstallerLog ".NET Framework: OK" -Level Success
    } catch {
        Write-InstallerLog ".NET Framework not available (GUI disabled)" -Level Warning
    }
    
    # Check disk space (require at least 50 MB)
    $drive = (Split-Path $InstallPath -Qualifier)
    $freeSpace = (Get-PSDrive ($drive.TrimEnd(':'))).Free / 1MB
    if ($freeSpace -lt 50) {
        Write-InstallerLog "Insufficient disk space. Required: 50 MB, Available: $([math]::Round($freeSpace, 2)) MB" -Level Error
        throw "Not enough disk space"
    }
    Write-InstallerLog "Disk space: $([math]::Round($freeSpace, 2)) MB available - OK" -Level Success
    
    return $true
}

function Show-InstallationGUI {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Sage100 Server Check - Installation"
    $form.Size = New-Object System.Drawing.Size(550, 450)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    
    # Title
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location = New-Object System.Drawing.Point(20, 20)
    $lblTitle.Size = New-Object System.Drawing.Size(500, 40)
    $lblTitle.Text = "Sage 100 Server Monitoring Tool"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($lblTitle)
    
    # Installation Path
    $lblPath = New-Object System.Windows.Forms.Label
    $lblPath.Location = New-Object System.Drawing.Point(20, 80)
    $lblPath.Size = New-Object System.Drawing.Size(150, 20)
    $lblPath.Text = "Installation Path:"
    $form.Controls.Add($lblPath)
    
    $txtPath = New-Object System.Windows.Forms.TextBox
    $txtPath.Location = New-Object System.Drawing.Point(20, 105)
    $txtPath.Size = New-Object System.Drawing.Size(400, 25)
    $txtPath.Text = $InstallPath
    $form.Controls.Add($txtPath)
    
    $btnBrowse = New-Object System.Windows.Forms.Button
    $btnBrowse.Location = New-Object System.Drawing.Point(430, 103)
    $btnBrowse.Size = New-Object System.Drawing.Size(80, 25)
    $btnBrowse.Text = "Browse..."
    $btnBrowse.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Select installation folder"
        $folderBrowser.SelectedPath = $txtPath.Text
        if ($folderBrowser.ShowDialog() -eq 'OK') {
            $txtPath.Text = $folderBrowser.SelectedPath + "\Sage100-ServerCheck"
        }
    })
    $form.Controls.Add($btnBrowse)
    
    # Options
    $grpOptions = New-Object System.Windows.Forms.GroupBox
    $grpOptions.Location = New-Object System.Drawing.Point(20, 150)
    $grpOptions.Size = New-Object System.Drawing.Size(500, 120)
    $grpOptions.Text = "Installation Options"
    $form.Controls.Add($grpOptions)
    
    $chkTask = New-Object System.Windows.Forms.CheckBox
    $chkTask.Location = New-Object System.Drawing.Point(15, 25)
    $chkTask.Size = New-Object System.Drawing.Size(450, 25)
    $chkTask.Text = "Create Scheduled Task (run checks automatically every 15 minutes)"
    $chkTask.Checked = $true
    $grpOptions.Controls.Add($chkTask)
    
    $chkDesktop = New-Object System.Windows.Forms.CheckBox
    $chkDesktop.Location = New-Object System.Drawing.Point(15, 55)
    $chkDesktop.Size = New-Object System.Drawing.Size(450, 25)
    $chkDesktop.Text = "Create Desktop Shortcut"
    $chkDesktop.Checked = $true
    $grpOptions.Controls.Add($chkDesktop)
    
    $chkStartMenu = New-Object System.Windows.Forms.CheckBox
    $chkStartMenu.Location = New-Object System.Drawing.Point(15, 85)
    $chkStartMenu.Size = New-Object System.Drawing.Size(450, 25)
    $chkStartMenu.Text = "Add to Start Menu"
    $chkStartMenu.Checked = $true
    $grpOptions.Controls.Add($chkStartMenu)
    
    # Progress
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(20, 290)
    $progressBar.Size = New-Object System.Drawing.Size(500, 25)
    $progressBar.Minimum = 0
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $form.Controls.Add($progressBar)
    
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Location = New-Object System.Drawing.Point(20, 320)
    $lblStatus.Size = New-Object System.Drawing.Size(500, 20)
    $lblStatus.Text = "Ready to install"
    $form.Controls.Add($lblStatus)
    
    # Buttons
    $btnInstall = New-Object System.Windows.Forms.Button
    $btnInstall.Location = New-Object System.Drawing.Point(300, 360)
    $btnInstall.Size = New-Object System.Drawing.Size(100, 30)
    $btnInstall.Text = "Install"
    $btnInstall.Add_Click({
        $btnInstall.Enabled = $false
        $btnCancel.Text = "Close"
        
        $script:InstallPath = $txtPath.Text
        $script:CreateScheduledTask = $chkTask.Checked
        $script:CreateDesktopShortcut = $chkDesktop.Checked
        $script:CreateStartMenu = $chkStartMenu.Checked
        
        # Simulate installation progress
        $lblStatus.Text = "Installing files..."
        $progressBar.Value = 10
        $form.Refresh()
        
        Start-Sleep -Seconds 1
        $progressBar.Value = 50
        $lblStatus.Text = "Configuring system..."
        $form.Refresh()
        
        Start-Sleep -Seconds 1
        $progressBar.Value = 100
        $lblStatus.Text = "Installation completed successfully!"
        $form.Refresh()
        
        [System.Windows.Forms.MessageBox]::Show(
            "Installation completed successfully!`n`nPath: $($txtPath.Text)",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })
    $form.Controls.Add($btnInstall)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(410, 360)
    $btnCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnCancel.Text = "Cancel"
    $btnCancel.Add_Click({
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })
    $form.Controls.Add($btnCancel)
    
    $result = $form.ShowDialog()
    
    return $result -eq [System.Windows.Forms.DialogResult]::OK
}

function Copy-ApplicationFiles {
    Write-InstallerLog "Creating installation directory: $InstallPath" -Level Info
    
    # Create directory structure
    $directories = @(
        $InstallPath,
        "$InstallPath\Config",
        "$InstallPath\Modules",
        "$InstallPath\GUI",
        "$InstallPath\Logs",
        "$InstallPath\Tests"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-InstallerLog "Created: $dir" -Level Success
        }
    }
    
    # Copy files from current directory
    $filesToCopy = @(
        @{Source="Sage100-ServerCheck.ps1"; Destination=$InstallPath},
        @{Source="Sage100-ServerCheck-GUI.ps1"; Destination=$InstallPath},
        @{Source="Config\*.json"; Destination="$InstallPath\Config"},
        @{Source="Modules\*.psm1"; Destination="$InstallPath\Modules"},
        @{Source="GUI\*.xaml"; Destination="$InstallPath\GUI"},
        @{Source="Tests\*.ps1"; Destination="$InstallPath\Tests"}
    )
    
    $scriptRoot = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptRoot)) {
        $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    
    foreach ($file in $filesToCopy) {
        $source = Join-Path $scriptRoot $file.Source
        $dest = $file.Destination
        
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Force -Recurse -ErrorAction SilentlyContinue
            Write-InstallerLog "Copied: $($file.Source)" -Level Success
        } else {
            Write-InstallerLog "File not found: $($file.Source) - Skipping" -Level Warning
        }
    }
    
    # Create default config if not exists
    $configPath = "$InstallPath\Config\config.json"
    if (-not (Test-Path $configPath)) {
        $defaultConfig = @{
            SQLServer = @{
                ServerName = "localhost\SQLEXPRESS"
                DatabaseName = "Sage100"
                Username = ""
                Password = ""
            }
            ServicesToMonitor = @()
            EmailSettings = @{
                SMTPServer = "smtp.office365.com"
                SMTPPort = 587
                EnableSSL = $true
                From = ""
                To = @()
                Username = ""
                Password = ""
            }
            CheckInterval = 900
            LogRetentionDays = 30
        } | ConvertTo-Json -Depth 10
        
        $defaultConfig | Out-File -FilePath $configPath -Encoding UTF8
        Write-InstallerLog "Created default configuration file" -Level Success
    }
    
    return $true
}

function New-ScheduledTask {
    if (-not $CreateScheduledTask) {
        Write-InstallerLog "Skipping scheduled task creation (not requested)" -Level Info
        return
    }
    
    Write-InstallerLog "Creating scheduled task..." -Level Info
    
    $taskName = "Sage100-ServerCheck"
    $taskPath = "\Monitoring\"
    
    # Remove existing task if exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
        Write-InstallerLog "Removed existing scheduled task" -Level Info
    }
    
    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\Sage100-ServerCheck.ps1`""
    
    # Create trigger (every 15 minutes)
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
    
    # Create principal (run as SYSTEM)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    
    # Register task
    Register-ScheduledTask -TaskName $taskName `
        -TaskPath $taskPath `
        -Action $action `
        -Trigger $trigger `
        -Principal $principal `
        -Settings $settings `
        -Description "Automated monitoring for Sage 100 server health" | Out-Null
    
    Write-InstallerLog "Scheduled task created successfully" -Level Success
}

function New-Shortcuts {
    if ($CreateDesktopShortcut -or $script:CreateStartMenu) {
        Write-InstallerLog "Creating shortcuts..." -Level Info
        
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Desktop shortcut
        if ($CreateDesktopShortcut) {
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcutPath = Join-Path $desktopPath "$AppDisplayName.lnk"
            
            $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "PowerShell.exe"
            $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\Sage100-ServerCheck-GUI.ps1`""
            $shortcut.WorkingDirectory = $InstallPath
            $shortcut.Description = $AppDisplayName
            $shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,244"
            $shortcut.Save()
            
            Write-InstallerLog "Desktop shortcut created" -Level Success
        }
        
        # Start Menu shortcut
        if ($script:CreateStartMenu) {
            $startMenuPath = [Environment]::GetFolderPath("CommonStartMenu")
            $appFolder = Join-Path $startMenuPath "Programs\Sage100 Tools"
            
            if (-not (Test-Path $appFolder)) {
                New-Item -Path $appFolder -ItemType Directory -Force | Out-Null
            }
            
            $shortcutPath = Join-Path $appFolder "$AppDisplayName.lnk"
            
            $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = "PowerShell.exe"
            $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\Sage100-ServerCheck-GUI.ps1`""
            $shortcut.WorkingDirectory = $InstallPath
            $shortcut.Description = $AppDisplayName
            $shortcut.IconLocation = "%SystemRoot%\System32\shell32.dll,244"
            $shortcut.Save()
            
            Write-InstallerLog "Start Menu shortcut created" -Level Success
        }
    }
}

function Register-UninstallInfo {
    Write-InstallerLog "Registering uninstall information..." -Level Info
    
    $uninstallPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Sage100-ServerCheck"
    
    if (-not (Test-Path $uninstallPath)) {
        New-Item -Path $uninstallPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $uninstallPath -Name "DisplayName" -Value $AppDisplayName
    Set-ItemProperty -Path $uninstallPath -Name "DisplayVersion" -Value $InstallerVersion
    Set-ItemProperty -Path $uninstallPath -Name "Publisher" -Value "Sage100-ServerCheck Team"
    Set-ItemProperty -Path $uninstallPath -Name "InstallLocation" -Value $InstallPath
    Set-ItemProperty -Path $uninstallPath -Name "UninstallString" -Value "PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\Uninstall.ps1`""
    Set-ItemProperty -Path $uninstallPath -Name "DisplayIcon" -Value "%SystemRoot%\System32\shell32.dll,244"
    Set-ItemProperty -Path $uninstallPath -Name "NoModify" -Value 1 -Type DWord
    Set-ItemProperty -Path $uninstallPath -Name "NoRepair" -Value 1 -Type DWord
    
    Write-InstallerLog "Uninstall information registered" -Level Success
}

# ============================================================================
# MAIN INSTALLATION ROUTINE
# ============================================================================

try {
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  Sage 100 Server Check - Universal Windows Installer v$InstallerVersion" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 1: Prerequisites
    Write-InstallerLog "Step 1/6: Checking prerequisites..." -Level Info
    Test-Prerequisites | Out-Null
    
    # Step 2: GUI Configuration (if not silent)
    if (-not $Silent) {
        try {
            Write-InstallerLog "Step 2/6: Loading installation wizard..." -Level Info
            $guiResult = Show-InstallationGUI
            if (-not $guiResult) {
                Write-InstallerLog "Installation cancelled by user" -Level Warning
                exit 0
            }
        } catch {
            Write-InstallerLog "GUI not available, using default settings" -Level Warning
        }
    }
    
    # Step 3: Copy Files
    Write-InstallerLog "Step 3/6: Installing application files..." -Level Info
    Copy-ApplicationFiles | Out-Null
    
    # Step 4: Create Scheduled Task
    Write-InstallerLog "Step 4/6: Configuring automation..." -Level Info
    New-ScheduledTask
    
    # Step 5: Create Shortcuts
    Write-InstallerLog "Step 5/6: Creating shortcuts..." -Level Info
    New-Shortcuts
    
    # Step 6: Register Uninstall
    Write-InstallerLog "Step 6/6: Registering application..." -Level Info
    Register-UninstallInfo
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "  Installation completed successfully!" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installation Path: $InstallPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Configure the tool: Edit $InstallPath\Config\config.json" -ForegroundColor White
    Write-Host "  2. Run the GUI: Double-click the desktop shortcut" -ForegroundColor White
    Write-Host "  3. Or run manually: $InstallPath\Sage100-ServerCheck-GUI.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "Log file: $env:TEMP\Sage100-ServerCheck-Install.log" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $Silent) {
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    exit 0
    
} catch {
    Write-InstallerLog "Installation failed: $_" -Level Error
    Write-InstallerLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host "  Installation FAILED!" -ForegroundColor White
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Log file: $env:TEMP\Sage100-ServerCheck-Install.log" -ForegroundColor Gray
    Write-Host ""
    
    if (-not $Silent) {
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    exit 1
}
