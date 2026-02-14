# =========================================
# SAGE 100 SERVER CHECK - ERSTEINRICHTUNG
# Interaktiver Installationsassistent
# =========================================

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

$ErrorActionPreference = "Stop"

# Globale Variablen
$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$configPath = Join-Path $scriptRoot "config"
$appPath = Join-Path $scriptRoot "app"

# =========================================
# SCHRITT 1: SYSTEMPRÜFUNG
# =========================================

function Test-SystemRequirements {
    Write-Host "`n[1/4] Systemvoraussetzungen werden geprüft..." -ForegroundColor Cyan
    
    $checks = @{
        "Windows Version" = $true
        "PowerShell 5.0+" = ($PSVersionTable.PSVersion.Major -ge 5)
        "Administrator" = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        ".NET Framework" = $true
    }
    
    $allPassed = $true
    foreach ($check in $checks.GetEnumerator()) {
        $status = if ($check.Value) { "[OK]" } else { "[FEHLER]" }
        $color = if ($check.Value) { "Green" } else { "Red" }
        Write-Host "  $status $($check.Key)" -ForegroundColor $color
        if (-not $check.Value) { $allPassed = $false }
    }
    
    if (-not $allPassed) {
        Write-Host "`n[FEHLER] Systemvoraussetzungen nicht erfüllt!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "`n  Alle Systemprüfungen erfolgreich!" -ForegroundColor Green
}

# =========================================
# SCHRITT 2: ORDNERSTRUKTUR ERSTELLEN
# =========================================

function Initialize-FolderStructure {
    Write-Host "`n[2/4] Ordnerstruktur wird erstellt..." -ForegroundColor Cyan
    
    $folders = @(
        $configPath,
        $appPath,
        (Join-Path $appPath "modules"),
        (Join-Path $appPath "logs")
    )
    
    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
            Write-Host "  [OK] $folder" -ForegroundColor Green
        } else {
            Write-Host "  [EXISTS] $folder" -ForegroundColor Yellow
        }
    }
}

# =========================================
# SCHRITT 3: ERSTKONFIGURATION (GUI)
# =========================================

function Show-ConfigurationWizard {
    Write-Host "`n[3/4] Erstkonfiguration wird durchgeführt..." -ForegroundColor Cyan
    
    # XAML für WPF-Fenster
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Sage 100 Server Check - Erstkonfiguration"
        Height="550" Width="600"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#F5F5F5">
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,20">
            <TextBlock Text="🚀 Sage 100 Server Check" FontSize="24" FontWeight="Bold" Foreground="#2C3E50"/>
            <TextBlock Text="Erstkonfiguration" FontSize="14" Foreground="#7F8C8D" Margin="0,5,0,0"/>
        </StackPanel>
        
        <!-- Konfigurationsbereich -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                
                <!-- Server-Name -->
                <TextBlock Text="Server-Name:" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="txtServerName" Height="30" Padding="5" Margin="0,0,0,15"/>
                
                <!-- Sage 100 Installationspfad -->
                <TextBlock Text="Sage 100 Installationspfad:" FontWeight="Bold" Margin="0,0,0,5"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtSagePath" Grid.Column="0" Height="30" Padding="5"/>
                    <Button Name="btnBrowseSage" Grid.Column="1" Content="📁 Durchsuchen" Width="120" Margin="5,0,0,0"/>
                </Grid>
                
                <!-- Prüfintervall -->
                <TextBlock Text="Prüfintervall (Minuten):" FontWeight="Bold" Margin="0,0,0,5"/>
                <TextBox Name="txtInterval" Text="5" Height="30" Padding="5" Margin="0,0,0,15"/>
                
                <!-- E-Mail Benachrichtigungen -->
                <CheckBox Name="chkEmailNotify" Content="E-Mail Benachrichtigungen aktivieren" Margin="0,0,0,10"/>
                
                <StackPanel Name="pnlEmail" Margin="20,0,0,0" IsEnabled="False">
                    <TextBlock Text="SMTP Server:" FontWeight="Bold" Margin="0,0,0,5"/>
                    <TextBox Name="txtSmtpServer" Height="30" Padding="5" Margin="0,0,0,10"/>
                    
                    <TextBlock Text="E-Mail Empfänger:" FontWeight="Bold" Margin="0,0,0,5"/>
                    <TextBox Name="txtEmailTo" Height="30" Padding="5" Margin="0,0,0,10"/>
                </StackPanel>
                
                <!-- Log-Level -->
                <TextBlock Text="Log-Level:" FontWeight="Bold" Margin="0,15,0,5"/>
                <ComboBox Name="cmbLogLevel" Height="30" Padding="5">
                    <ComboBoxItem Content="Debug" IsSelected="False"/>
                    <ComboBoxItem Content="Info" IsSelected="True"/>
                    <ComboBoxItem Content="Warning" IsSelected="False"/>
                    <ComboBoxItem Content="Error" IsSelected="False"/>
                </ComboBox>
                
            </StackPanel>
        </ScrollViewer>
        
        <!-- Buttons -->
        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
            <Button Name="btnCancel" Content="Abbrechen" Width="120" Height="35" Margin="0,0,10,0" Background="#E74C3C" Foreground="White"/>
            <Button Name="btnSave" Content="Installation starten" Width="150" Height="35" Background="#27AE60" Foreground="White" FontWeight="Bold"/>
        </StackPanel>
        
    </Grid>
</Window>
"@
    
    # WPF-Fenster laden
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Controls referenzieren
    $txtServerName = $window.FindName("txtServerName")
    $txtSagePath = $window.FindName("txtSagePath")
    $txtInterval = $window.FindName("txtInterval")
    $chkEmailNotify = $window.FindName("chkEmailNotify")
    $pnlEmail = $window.FindName("pnlEmail")
    $txtSmtpServer = $window.FindName("txtSmtpServer")
    $txtEmailTo = $window.FindName("txtEmailTo")
    $cmbLogLevel = $window.FindName("cmbLogLevel")
    $btnBrowseSage = $window.FindName("btnBrowseSage")
    $btnCancel = $window.FindName("btnCancel")
    $btnSave = $window.FindName("btnSave")
    
    # Standard-Werte setzen
    $txtServerName.Text = $env:COMPUTERNAME
    $txtSagePath.Text = "C:\Sage\Sage100"
    
    # Event-Handler
    $chkEmailNotify.Add_Checked({
        $pnlEmail.IsEnabled = $true
    })
    
    $chkEmailNotify.Add_Unchecked({
        $pnlEmail.IsEnabled = $false
    })
    
    $btnBrowseSage.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Wählen Sie den Sage 100 Installationspfad"
        $folderBrowser.SelectedPath = $txtSagePath.Text
        
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtSagePath.Text = $folderBrowser.SelectedPath
        }
    })
    
    $btnCancel.Add_Click({
        $window.DialogResult = $false
        $window.Close()
    })
    
    $btnSave.Add_Click({
        # Validierung
        if ([string]::IsNullOrWhiteSpace($txtServerName.Text)) {
            [System.Windows.MessageBox]::Show("Bitte geben Sie einen Server-Namen ein!", "Validierungsfehler", "OK", "Warning")
            return
        }
        
        if ([string]::IsNullOrWhiteSpace($txtSagePath.Text) -or -not (Test-Path $txtSagePath.Text)) {
            [System.Windows.MessageBox]::Show("Bitte geben Sie einen gültigen Sage 100 Pfad ein!", "Validierungsfehler", "OK", "Warning")
            return
        }
        
        # Konfiguration speichern
        $config = @{
            ServerName = $txtServerName.Text
            SagePath = $txtSagePath.Text
            CheckInterval = [int]$txtInterval.Text
            EmailNotifications = @{
                Enabled = $chkEmailNotify.IsChecked
                SmtpServer = $txtSmtpServer.Text
                EmailTo = $txtEmailTo.Text
            }
            LogLevel = $cmbLogLevel.SelectedItem.Content
            LastConfigured = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        $configFile = Join-Path $configPath "config.json"
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $configFile -Encoding UTF8
        
        Write-Host "`n  [OK] Konfiguration gespeichert: $configFile" -ForegroundColor Green
        
        $window.DialogResult = $true
        $window.Close()
    })
    
    # Fenster anzeigen
    $result = $window.ShowDialog()
    
    if (-not $result) {
        Write-Host "`n[ABGEBROCHEN] Installation wurde abgebrochen." -ForegroundColor Yellow
        exit 0
    }
}

# =========================================
# SCHRITT 4: DESKTOP-VERKNÜPFUNG
# =========================================

function Create-DesktopShortcut {
    Write-Host "`n[4/4] Desktop-Verknüpfung wird erstellt..." -ForegroundColor Cyan
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "Sage 100 Server Check.lnk"
    $targetPath = Join-Path $appPath "Sage100ServerCheck.ps1"
    
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
    $shortcut.WorkingDirectory = $appPath
    $shortcut.Description = "Sage 100 Server Check Tool"
    $shortcut.Save()
    
    Write-Host "  [OK] Verknüpfung erstellt: $shortcutPath" -ForegroundColor Green
}

# =========================================
# HAUPTINSTALLATION
# =========================================

try {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  SAGE 100 SERVER CHECK - INSTALLATION" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    Test-SystemRequirements
    Initialize-FolderStructure
    Show-ConfigurationWizard
    Create-DesktopShortcut
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  INSTALLATION ERFOLGREICH!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`nDas Programm wurde installiert und konfiguriert." -ForegroundColor White
    Write-Host "Desktop-Verknüpfung wurde erstellt.`n" -ForegroundColor White
    
    # Programm automatisch starten?
    $start = Read-Host "Möchten Sie das Programm jetzt starten? (J/N)"
    if ($start -eq "J" -or $start -eq "j") {
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$(Join-Path $appPath 'Sage100ServerCheck.ps1')`""
    }
    
    exit 0
    
} catch {
    Write-Host "`n[FEHLER] Installation fehlgeschlagen!" -ForegroundColor Red
    Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
