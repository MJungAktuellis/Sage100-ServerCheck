#Requires -Version 5.1
<#
.SYNOPSIS
    SAGE 100 Server Check - Hauptprogramm
.DESCRIPTION
    Überwacht Sage 100 Server, Dienste und Prozesse mit moderner WPF GUI
#>

# ===========================
# MODUL-IMPORTE
# ===========================
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptRoot\modules\ServiceMonitor.psm1" -Force
Import-Module "$scriptRoot\modules\ProcessChecker.psm1" -Force
Import-Module "$scriptRoot\modules\Notifier.psm1" -Force

# ===========================
# KONFIGURATION LADEN
# ===========================
$configPath = Join-Path (Split-Path -Parent $scriptRoot) "config\config.json"

if (Test-Path $configPath) {
    $global:Config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    Write-Host "❌ FEHLER: Konfiguration nicht gefunden!" -ForegroundColor Red
    Write-Host "Bitte führen Sie INSTALL.cmd erneut aus." -ForegroundColor Yellow
    pause
    exit
}

# ===========================
# XAML GUI DEFINITION
# ===========================
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SAGE 100 Server Check" Height="650" Width="1000"
        WindowStartupLocation="CenterScreen" Background="#F5F5F5">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#005A9E"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- HEADER -->
        <Border Grid.Row="0" Background="#0078D4" CornerRadius="8" Padding="20,15" Margin="0,0,0,20">
            <StackPanel>
                <TextBlock Text="🖥️ SAGE 100 SERVER CHECK" FontSize="24" FontWeight="Bold" Foreground="White"/>
                <TextBlock x:Name="StatusText" Text="Status: Bereit" FontSize="14" Foreground="White" Margin="0,5,0,0"/>
            </StackPanel>
        </Border>
        
        <!-- SERVER INFO -->
        <Border Grid.Row="1" Background="White" CornerRadius="8" Padding="20" Margin="0,0,0,15" 
                BorderBrush="#E0E0E0" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0">
                    <TextBlock Text="SERVER" FontWeight="Bold" FontSize="12" Foreground="#666"/>
                    <TextBlock x:Name="ServerNameText" Text="Loading..." FontSize="16" Margin="0,5,0,0"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1">
                    <TextBlock Text="LETZTER CHECK" FontWeight="Bold" FontSize="12" Foreground="#666"/>
                    <TextBlock x:Name="LastCheckText" Text="--:--:--" FontSize="16" Margin="0,5,0,0"/>
                </StackPanel>
                
                <StackPanel Grid.Column="2">
                    <TextBlock Text="INTERVALL" FontWeight="Bold" FontSize="12" Foreground="#666"/>
                    <TextBlock x:Name="IntervalText" Text="-- Min" FontSize="16" Margin="0,5,0,0"/>
                </StackPanel>
            </Grid>
        </Border>
        
        <!-- MAIN CONTENT -->
        <TabControl Grid.Row="2" Background="White" BorderThickness="1" BorderBrush="#E0E0E0">
            <TabItem Header="📊 DIENSTE">
                <Grid Margin="15">
                    <DataGrid x:Name="ServicesGrid" AutoGenerateColumns="False" 
                              IsReadOnly="True" CanUserAddRows="False" GridLinesVisibility="None"
                              HeadersVisibility="Column" BorderThickness="0">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Dienst" Binding="{Binding Name}" Width="*"/>
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="120"/>
                            <DataGridTextColumn Header="Starttyp" Binding="{Binding StartType}" Width="120"/>
                            <DataGridTextColumn Header="Letzter Check" Binding="{Binding LastCheck}" Width="150"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <TabItem Header="🔧 PROZESSE">
                <Grid Margin="15">
                    <DataGrid x:Name="ProcessesGrid" AutoGenerateColumns="False" 
                              IsReadOnly="True" CanUserAddRows="False" GridLinesVisibility="None"
                              HeadersVisibility="Column" BorderThickness="0">
                        <DataGrid.Columns>
                            <DataGridTextColumn Header="Prozess" Binding="{Binding Name}" Width="*"/>
                            <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="120"/>
                            <DataGridTextColumn Header="PID" Binding="{Binding PID}" Width="100"/>
                            <DataGridTextColumn Header="RAM (MB)" Binding="{Binding Memory}" Width="120"/>
                        </DataGrid.Columns>
                    </DataGrid>
                </Grid>
            </TabItem>
            
            <TabItem Header="📝 EREIGNISLOG">
                <Grid Margin="15">
                    <ListBox x:Name="LogListBox" FontFamily="Consolas" FontSize="12"/>
                </Grid>
            </TabItem>
        </TabControl>
        
        <!-- FOOTER BUTTONS -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
            <Button x:Name="RefreshBtn" Content="🔄 AKTUALISIEREN" Width="150" Margin="0,0,10,0"/>
            <Button x:Name="ConfigBtn" Content="⚙️ EINSTELLUNGEN" Width="150" Margin="0,0,10,0"/>
            <Button x:Name="ExitBtn" Content="❌ BEENDEN" Width="150" Background="#D13438"/>
        </StackPanel>
    </Grid>
</Window>
"@

# ===========================
# GUI LADEN
# ===========================
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Controls abrufen
$statusText = $window.FindName("StatusText")
$serverNameText = $window.FindName("ServerNameText")
$lastCheckText = $window.FindName("LastCheckText")
$intervalText = $window.FindName("IntervalText")
$servicesGrid = $window.FindName("ServicesGrid")
$processesGrid = $window.FindName("ProcessesGrid")
$logListBox = $window.FindName("LogListBox")
$refreshBtn = $window.FindName("RefreshBtn")
$configBtn = $window.FindName("ConfigBtn")
$exitBtn = $window.FindName("ExitBtn")

# ===========================
# FUNKTIONEN
# ===========================
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    $logListBox.Items.Insert(0, $logEntry)
    if ($logListBox.Items.Count -gt 100) { $logListBox.Items.RemoveAt(100) }
}

function Update-Dashboard {
    Write-Log "🔄 Aktualisiere Dashboard..."
    
    # Server-Info
    $serverNameText.Text = $global:Config.ServerIP
    $intervalText.Text = "$($global:Config.CheckInterval) Min"
    $lastCheckText.Text = Get-Date -Format "HH:mm:ss"
    
    # Dienste prüfen
    $serviceResults = @()
    foreach ($service in $global:Config.Services) {
        $status = Get-ServiceStatus -ServerIP $global:Config.ServerIP -ServiceName $service
        $serviceResults += [PSCustomObject]@{
            Name = $service
            Status = $status
            StartType = "Automatic"
            LastCheck = Get-Date -Format "HH:mm:ss"
        }
    }
    $servicesGrid.ItemsSource = $serviceResults
    
    # Prozesse prüfen
    $processResults = @()
    foreach ($process in $global:Config.Processes) {
        $procInfo = Get-ProcessInfo -ServerIP $global:Config.ServerIP -ProcessName $process
        $processResults += [PSCustomObject]@{
            Name = $process
            Status = if ($procInfo) { "✅ Läuft" } else { "❌ Gestoppt" }
            PID = if ($procInfo) { $procInfo.Id } else { "-" }
            Memory = if ($procInfo) { [math]::Round($procInfo.WS / 1MB, 2) } else { "0" }
        }
    }
    $processesGrid.ItemsSource = $processResults
    
    # Status aktualisieren
    $allOK = ($serviceResults | Where-Object { $_.Status -ne "✅ Running" }).Count -eq 0
    if ($allOK) {
        $statusText.Text = "Status: ✅ Alle Systeme laufen"
        $statusText.Foreground = "LightGreen"
    } else {
        $statusText.Text = "Status: ⚠️ Probleme erkannt"
        $statusText.Foreground = "Yellow"
        Send-Notification -Message "⚠️ SAGE 100 Server-Probleme erkannt!"
    }
    
    Write-Log "✅ Dashboard aktualisiert"
}

# ===========================
# EVENT HANDLER
# ===========================
$refreshBtn.Add_Click({ Update-Dashboard })
$configBtn.Add_Click({ 
    Write-Log "⚙️ Einstellungen werden geöffnet..."
    Start-Process notepad.exe $configPath
})
$exitBtn.Add_Click({ $window.Close() })

# ===========================
# TIMER FÜR AUTO-REFRESH
# ===========================
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMinutes($global:Config.CheckInterval)
$timer.Add_Tick({ Update-Dashboard })
$timer.Start()

# ===========================
# INITIALER CHECK
# ===========================
Write-Log "🚀 SAGE 100 Server Check gestartet"
Update-Dashboard

# GUI anzeigen
$window.ShowDialog() | Out-Null
