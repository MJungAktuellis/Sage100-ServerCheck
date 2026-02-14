# ═══════════════════════════════════════════════════════════
# SAGE 100 SERVER CHECK - GUI INSTALLER
# Version: 1.0
# Beschreibung: Grafischer Installations-Wizard mit WPF
# ═══════════════════════════════════════════════════════════

#Requires -Version 5.1
#Requires -RunAsAdministrator

param(
    [switch]$Silent
)

# Setze Error Action
$ErrorActionPreference = "Stop"

# Lade .NET Framework für WPF
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ═══════════════════════════════════════════════════════════
# KONFIGURATION
# ═══════════════════════════════════════════════════════════

$script:InstallConfig = @{
    AppName = "Sage100 ServerCheck"
    Version = "1.0.0"
    DefaultInstallPath = "C:\Program Files\Sage100-ServerCheck"
    RequiredPSVersion = 5.1
    LogPath = "$PSScriptRoot\..\Logs\installer.log"
}

# ═══════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════

function Write-InstallLog {
    param(
        [string]$Message,
        [ValidateSet('Info','Warning','Error','Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Erstelle Logs-Ordner falls nicht vorhanden
    $logDir = Split-Path $script:InstallConfig.LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    # Schreibe in Logfile
    Add-Content -Path $script:InstallConfig.LogPath -Value $logMessage
    
    # Ausgabe in Konsole (farbig)
    switch ($Level) {
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage -ForegroundColor White }
    }
}

# ═══════════════════════════════════════════════════════════
# XAML GUI DEFINITION
# ═══════════════════════════════════════════════════════════

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Sage100 ServerCheck - Installation" 
        Height="600" Width="800"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D4" Padding="15" Margin="0,0,0,20">
            <StackPanel>
                <TextBlock Text="SAGE 100 SERVER CHECK" FontSize="24" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Installations-Wizard v1.0" FontSize="14" Foreground="White" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>

        <!-- Content Area -->
        <TabControl x:Name="InstallTabs" Grid.Row="1" Margin="0,0,0,20">
            
            <!-- Tab 1: Willkommen -->
            <TabItem Header="Willkommen" x:Name="TabWelcome">
                <ScrollViewer>
                    <StackPanel Margin="20">
                        <TextBlock Text="Willkommen zur Installation!" FontSize="18" FontWeight="Bold" Margin="0,0,0,20"/>
                        <TextBlock TextWrapping="Wrap" Margin="0,0,0,10">
                            Dieser Assistent führt Sie durch die Installation des Sage100 ServerCheck Tools.
                        </TextBlock>
                        <TextBlock TextWrapping="Wrap" Margin="0,0,0,10">
                            Das Tool überwacht automatisch:
                        </TextBlock>
                        <TextBlock Margin="20,0,0,5">• SQL Server-Verfügbarkeit</TextBlock>
                        <TextBlock Margin="20,0,0,5">• Mandanten-Datenbanken</TextBlock>
                        <TextBlock Margin="20,0,0,5">• System-Ressourcen (CPU, RAM, Disk)</TextBlock>
                        <TextBlock Margin="20,0,0,20">• E-Mail-Benachrichtigungen bei Problemen</TextBlock>
                        
                        <Border Background="#FFF4CE" Padding="10" BorderBrush="#FFC107" BorderThickness="1">
                            <StackPanel>
                                <TextBlock Text="⚠ Wichtige Hinweise:" FontWeight="Bold" Margin="0,0,0,5"/>
                                <TextBlock TextWrapping="Wrap">• Administrator-Rechte sind erforderlich</TextBlock>
                                <TextBlock TextWrapping="Wrap">• PowerShell 5.1 oder höher wird benötigt</TextBlock>
                                <TextBlock TextWrapping="Wrap">• SQL Server muss erreichbar sein</TextBlock>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <!-- Tab 2: Installationsort -->
            <TabItem Header="Installationsort" x:Name="TabLocation">
                <StackPanel Margin="20">
                    <TextBlock Text="Installations-Verzeichnis" FontSize="18" FontWeight="Bold" Margin="0,0,0,20"/>
                    <TextBlock Text="Wählen Sie den Installationsort:" Margin="0,0,0,10"/>
                    
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <TextBox x:Name="TxtInstallPath" Grid.Column="0" Padding="5" FontSize="14"/>
                        <Button x:Name="BtnBrowse" Content="Durchsuchen..." Grid.Column="1" Margin="10,0,0,0" Padding="15,5"/>
                    </Grid>
                    
                    <TextBlock Text="Erforderlicher Speicherplatz: ca. 50 MB" Margin="0,10,0,0" FontStyle="Italic" Foreground="Gray"/>
                </StackPanel>
            </TabItem>

            <!-- Tab 3: SQL Server -->
            <TabItem Header="SQL Server" x:Name="TabSQL">
                <StackPanel Margin="20">
                    <TextBlock Text="SQL Server-Konfiguration" FontSize="18" FontWeight="Bold" Margin="0,0,0,20"/>
                    
                    <TextBlock Text="Server-Name:" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtSQLServer" Padding="5" Margin="0,0,0,15" Text="localhost\SQLEXPRESS"/>
                    
                    <TextBlock Text="Datenbank:" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtDatabase" Padding="5" Margin="0,0,0,15" Text="master"/>
                    
                    <CheckBox x:Name="ChkWindowsAuth" Content="Windows-Authentifizierung verwenden" IsChecked="True" Margin="0,0,0,15"/>
                    
                    <TextBlock x:Name="LblSQLUser" Text="Benutzername:" Margin="0,0,0,5" IsEnabled="False"/>
                    <TextBox x:Name="TxtSQLUser" Padding="5" Margin="0,0,0,10" IsEnabled="False"/>
                    
                    <TextBlock x:Name="LblSQLPass" Text="Passwort:" Margin="0,0,0,5" IsEnabled="False"/>
                    <PasswordBox x:Name="TxtSQLPass" Padding="5" Margin="0,0,0,15" IsEnabled="False"/>
                    
                    <Button x:Name="BtnTestSQL" Content="Verbindung testen" Padding="15,5" HorizontalAlignment="Left"/>
                    <TextBlock x:Name="LblSQLStatus" Text="" Margin="0,10,0,0" FontWeight="Bold"/>
                </StackPanel>
            </TabItem>

            <!-- Tab 4: E-Mail -->
            <TabItem Header="E-Mail" x:Name="TabEmail">
                <StackPanel Margin="20">
                    <TextBlock Text="E-Mail-Benachrichtigungen" FontSize="18" FontWeight="Bold" Margin="0,0,0,20"/>
                    
                    <CheckBox x:Name="ChkEnableEmail" Content="E-Mail-Benachrichtigungen aktivieren" IsChecked="True" Margin="0,0,0,15"/>
                    
                    <TextBlock Text="SMTP-Server:" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtSMTP" Padding="5" Margin="0,0,0,10" Text="smtp.office365.com"/>
                    
                    <TextBlock Text="Port:" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtSMTPPort" Padding="5" Margin="0,0,0,10" Text="587"/>
                    
                    <CheckBox x:Name="ChkSMTPSSL" Content="SSL/TLS verwenden" IsChecked="True" Margin="0,0,0,15"/>
                    
                    <TextBlock Text="Absender (Von):" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtEmailFrom" Padding="5" Margin="0,0,0,10" Text="servercheck@firma.de"/>
                    
                    <TextBlock Text="Empfänger (An):" Margin="0,0,0,5"/>
                    <TextBox x:Name="TxtEmailTo" Padding="5" Margin="0,0,0,10" Text="admin@firma.de"/>
                </StackPanel>
            </TabItem>

            <!-- Tab 5: Zusammenfassung -->
            <TabItem Header="Zusammenfassung" x:Name="TabSummary">
                <ScrollViewer>
                    <StackPanel Margin="20">
                        <TextBlock Text="Installations-Zusammenfassung" FontSize="18" FontWeight="Bold" Margin="0,0,0,20"/>
                        <TextBlock x:Name="TxtSummary" TextWrapping="Wrap" FontFamily="Consolas" Background="#F5F5F5" Padding="10"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <!-- Footer mit Buttons -->
        <Grid Grid.Row="2">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            
            <ProgressBar x:Name="ProgressBar" Grid.Column="0" Height="25" Margin="0,0,10,0" Visibility="Collapsed"/>
            <Button x:Name="BtnBack" Content="◄ Zurück" Grid.Column="1" Padding="20,10" Margin="5,0" IsEnabled="False"/>
            <Button x:Name="BtnNext" Content="Weiter ►" Grid.Column="2" Padding="20,10" Margin="5,0"/>
            <Button x:Name="BtnCancel" Content="Abbrechen" Grid.Column="3" Padding="20,10" Margin="5,0"/>
        </Grid>
    </Grid>
</Window>
"@

# ═══════════════════════════════════════════════════════════
# GUI LOGIK
# ═══════════════════════════════════════════════════════════

Write-InstallLog "Starte GUI-Installer..." -Level Info

try {
    # Lade XAML
    $reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Hole UI-Elemente
    $txtInstallPath = $window.FindName("TxtInstallPath")
    $btnBrowse = $window.FindName("BtnBrowse")
    $txtSQLServer = $window.FindName("TxtSQLServer")
    $txtDatabase = $window.FindName("TxtDatabase")
    $chkWindowsAuth = $window.FindName("ChkWindowsAuth")
    $txtSQLUser = $window.FindName("TxtSQLUser")
    $txtSQLPass = $window.FindName("TxtSQLPass")
    $lblSQLUser = $window.FindName("LblSQLUser")
    $lblSQLPass = $window.FindName("LblSQLPass")
    $btnTestSQL = $window.FindName("BtnTestSQL")
    $lblSQLStatus = $window.FindName("LblSQLStatus")
    $chkEnableEmail = $window.FindName("ChkEnableEmail")
    $txtSMTP = $window.FindName("TxtSMTP")
    $txtSMTPPort = $window.FindName("TxtSMTPPort")
    $chkSMTPSSL = $window.FindName("ChkSMTPSSL")
    $txtEmailFrom = $window.FindName("TxtEmailFrom")
    $txtEmailTo = $window.FindName("TxtEmailTo")
    $txtSummary = $window.FindName("TxtSummary")
    $installTabs = $window.FindName("InstallTabs")
    $btnBack = $window.FindName("BtnBack")
    $btnNext = $window.FindName("BtnNext")
    $btnCancel = $window.FindName("BtnCancel")
    $progressBar = $window.FindName("ProgressBar")
    
    # Setze Default-Werte
    $txtInstallPath.Text = $script:InstallConfig.DefaultInstallPath
    
    # Event: Durchsuchen-Button
    $btnBrowse.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowser.Description = "Wählen Sie den Installationsort"
        $folderBrowser.SelectedPath = $txtInstallPath.Text
        
        if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtInstallPath.Text = $folderBrowser.SelectedPath
        }
    })
    
    # Event: Windows Auth Checkbox
    $chkWindowsAuth.Add_Checked({
        $txtSQLUser.IsEnabled = $false
        $txtSQLPass.IsEnabled = $false
        $lblSQLUser.IsEnabled = $false
        $lblSQLPass.IsEnabled = $false
    })
    
    $chkWindowsAuth.Add_Unchecked({
        $txtSQLUser.IsEnabled = $true
        $txtSQLPass.IsEnabled = $true
        $lblSQLUser.IsEnabled = $true
        $lblSQLPass.IsEnabled = $true
    })
    
    # Event: SQL-Verbindung testen
    $btnTestSQL.Add_Click({
        $lblSQLStatus.Text = "Teste Verbindung..."
        $lblSQLStatus.Foreground = "Orange"
        
        try {
            $connString = if ($chkWindowsAuth.IsChecked) {
                "Server=$($txtSQLServer.Text);Database=$($txtDatabase.Text);Integrated Security=True;Connection Timeout=5;"
            } else {
                "Server=$($txtSQLServer.Text);Database=$($txtDatabase.Text);User ID=$($txtSQLUser.Text);Password=$($txtSQLPass.Password);Connection Timeout=5;"
            }
            
            $conn = New-Object System.Data.SqlClient.SqlConnection($connString)
            $conn.Open()
            $conn.Close()
            
            $lblSQLStatus.Text = "✓ Verbindung erfolgreich!"
            $lblSQLStatus.Foreground = "Green"
            Write-InstallLog "SQL-Verbindungstest erfolgreich" -Level Success
        }
        catch {
            $lblSQLStatus.Text = "✗ Verbindung fehlgeschlagen: $($_.Exception.Message)"
            $lblSQLStatus.Foreground = "Red"
            Write-InstallLog "SQL-Verbindungstest fehlgeschlagen: $_" -Level Error
        }
    })
    
    # Event: Weiter-Button
    $btnNext.Add_Click({
        $currentTab = $installTabs.SelectedIndex
        
        if ($currentTab -lt 4) {
            $installTabs.SelectedIndex = $currentTab + 1
            $btnBack.IsEnabled = $true
            
            # Zeige Zusammenfassung auf letztem Tab
            if ($currentTab -eq 3) {
                $summary = @"
INSTALLATIONS-KONFIGURATION
═══════════════════════════════════════

Installation:
  Ziel: $($txtInstallPath.Text)
  Version: $($script:InstallConfig.Version)

SQL Server:
  Server: $($txtSQLServer.Text)
  Datenbank: $($txtDatabase.Text)
  Authentifizierung: $(if ($chkWindowsAuth.IsChecked) {'Windows'} else {'SQL'})

E-Mail:
  Status: $(if ($chkEnableEmail.IsChecked) {'Aktiviert'} else {'Deaktiviert'})
  SMTP: $($txtSMTP.Text):$($txtSMTPPort.Text)
  Von: $($txtEmailFrom.Text)
  An: $($txtEmailTo.Text)

═══════════════════════════════════════
Klicken Sie auf 'Installieren' um fortzufahren.
"@
                $txtSummary.Text = $summary
                $btnNext.Content = "Installieren"
            }
        }
        else {
            # Installation durchführen
            Start-Installation
        }
    })
    
    # Event: Zurück-Button
    $btnBack.Add_Click({
        $currentTab = $installTabs.SelectedIndex
        if ($currentTab -gt 0) {
            $installTabs.SelectedIndex = $currentTab - 1
            $btnNext.Content = "Weiter ►"
            
            if ($currentTab -eq 1) {
                $btnBack.IsEnabled = $false
            }
        }
    })
    
    # Event: Abbrechen-Button
    $btnCancel.Add_Click({
        $result = [System.Windows.MessageBox]::Show(
            "Möchten Sie die Installation wirklich abbrechen?",
            "Abbrechen",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            Write-InstallLog "Installation vom Benutzer abgebrochen" -Level Warning
            $window.Close()
        }
    })
    
    # Installation durchführen
    function Start-Installation {
        Write-InstallLog "Starte Installation..." -Level Info
        
        $btnNext.IsEnabled = $false
        $btnBack.IsEnabled = $false
        $btnCancel.IsEnabled = $false
        $progressBar.Visibility = "Visible"
        
        try {
            # Erstelle Installations-Verzeichnis
            $installPath = $txtInstallPath.Text
            Write-InstallLog "Erstelle Verzeichnis: $installPath" -Level Info
            
            if (-not (Test-Path $installPath)) {
                New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            }
            
            # Kopiere Dateien
            Write-InstallLog "Kopiere Programm-Dateien..." -Level Info
            $sourcePath = Split-Path $PSScriptRoot -Parent
            
            $filesToCopy = @(
                @{Source="$sourcePath\src"; Dest="$installPath\src"}
                @{Source="$sourcePath\Config"; Dest="$installPath\Config"}
                @{Source="$sourcePath\Logs"; Dest="$installPath\Logs"}
            )
            
            foreach ($file in $filesToCopy) {
                if (Test-Path $file.Source) {
                    Copy-Item -Path $file.Source -Destination $file.Dest -Recurse -Force
                    Write-InstallLog "Kopiert: $($file.Source) → $($file.Dest)" -Level Info
                }
            }
            
            # Update Config.json
            Write-InstallLog "Aktualisiere Konfiguration..." -Level Info
            $configPath = "$installPath\Config\config.json"
            
            if (Test-Path $configPath) {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                
                $config.database.server = $txtSQLServer.Text
                $config.database.database = $txtDatabase.Text
                $config.database.useWindowsAuth = $chkWindowsAuth.IsChecked
                
                if ($chkEnableEmail.IsChecked) {
                    $config.email.smtpServer = $txtSMTP.Text
                    $config.email.smtpPort = [int]$txtSMTPPort.Text
                    $config.email.enableSSL = $chkSMTPSSL.IsChecked
                    $config.email.from = $txtEmailFrom.Text
                    $config.email.to = @($txtEmailTo.Text)
                    $config.email.enabled = $true
                }
                
                $config | ConvertTo-Json -Depth 10 | Set-Content $configPath -Encoding UTF8
                Write-InstallLog "Konfiguration gespeichert" -Level Success
            }
            
            # Erstelle Desktop-Verknüpfung
            Write-InstallLog "Erstelle Desktop-Verknüpfung..." -Level Info
            $WScriptShell = New-Object -ComObject WScript.Shell
            $desktopPath = [Environment]::GetFolderPath("Desktop")
            $shortcut = $WScriptShell.CreateShortcut("$desktopPath\Sage100 ServerCheck.lnk")
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installPath\src\Sage100-ServerCheck.ps1`""
            $shortcut.WorkingDirectory = $installPath
            $shortcut.IconLocation = "powershell.exe,0"
            $shortcut.Description = "Sage100 ServerCheck Tool"
            $shortcut.Save()
            Write-InstallLog "Desktop-Verknüpfung erstellt" -Level Success
            
            # Installation abgeschlossen
            Write-InstallLog "Installation erfolgreich abgeschlossen!" -Level Success
            
            [System.Windows.MessageBox]::Show(
                "Installation erfolgreich abgeschlossen!`n`nEine Desktop-Verknüpfung wurde erstellt.`n`nProgramm-Ordner: $installPath",
                "Installation abgeschlossen",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            )
            
            $window.Close()
        }
        catch {
            Write-InstallLog "Installation fehlgeschlagen: $_" -Level Error
            
            [System.Windows.MessageBox]::Show(
                "Installation fehlgeschlagen!`n`nFehler: $($_.Exception.Message)`n`nDetails in: $($script:InstallConfig.LogPath)",
                "Fehler",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            )
            
            $btnNext.IsEnabled = $true
            $btnBack.IsEnabled = $true
            $btnCancel.IsEnabled = $true
            $progressBar.Visibility = "Collapsed"
        }
    }
    
    # Zeige Fenster
    Write-InstallLog "GUI geladen, zeige Installer-Fenster" -Level Info
    $window.ShowDialog() | Out-Null
}
catch {
    Write-InstallLog "Fehler beim Laden der GUI: $_" -Level Error
    [System.Windows.MessageBox]::Show(
        "Fehler beim Laden der Installations-Oberfläche:`n`n$($_.Exception.Message)",
        "Kritischer Fehler",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    )
    exit 1
}

Write-InstallLog "Installer beendet" -Level Info
