# GUI\MainWindow.ps1
# Hauptfenster der Sage 100 Server Check GUI

using namespace System.Windows.Forms
using namespace System.Drawing

class MainWindow {
    [Form]$Form
    [TabControl]$TabControl
    [Button]$StartButton
    [MenuStrip]$MenuStrip
    [ToolStripProgressBar]$ProgressBar
    [ToolStripStatusLabel]$StatusLabel
    [System.Collections.Hashtable]$StatusCards
    [RichTextBox]$SystemInfoBox
    [RichTextBox]$NetworkInfoBox
    [RichTextBox]$LogBox
    [System.Collections.Hashtable]$CheckResults
    
    MainWindow() {
        $this.StatusCards = @{}
        $this.CheckResults = @{}
        $this.InitializeComponents()
        $script:MainWindowInstance = $this
    }
    
    [void]InitializeComponents() {
        # Hauptfenster
        $this.Form = New-Object Form
        $this.Form.Text = "Sage 100 Server Check & Setup Tool v2.0"
        $this.Form.Size = New-Object Size(1200, 800)
        $this.Form.StartPosition = "CenterScreen"
        $this.Form.FormBorderStyle = "Sizable"
        $this.Form.MinimumSize = New-Object Size(1000, 600)
        
        # Main Container
        $mainContainer = New-Object Panel
        $mainContainer.Dock = "Fill"
        $this.Form.Controls.Add($mainContainer)
        
        # Menu Strip
        $this.CreateMenuStrip()
        
        # Header Panel
        $headerPanel = New-Object Panel
        $headerPanel.Dock = "Top"
        $headerPanel.Height = 50
        $headerPanel.BackColor = [ColorTranslator]::FromHtml("#0078D4")
        $mainContainer.Controls.Add($headerPanel)
        
        # Header Title
        $titleLabel = New-Object Label
        $titleLabel.Text = "Sage 100 Server Check Tool"
        $titleLabel.ForeColor = [Color]::White
        $titleLabel.Font = New-Object Drawing.Font("Segoe UI", 12, [FontStyle]::Bold)
        $titleLabel.Location = New-Object Point(15, 15)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)
        
        # Start-Button
        $this.StartButton = New-Object Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Size = New-Object Size(240, 35)
        $this.StartButton.BackColor = [ColorTranslator]::FromHtml("#00FF00")
        $this.StartButton.ForeColor = [Color]::Black
        $this.StartButton.Font = New-Object Drawing.Font("Segoe UI", 9, [FontStyle]::Bold)
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $this.StartButton.Anchor = "Top,Right"
        $this.StartButton.Location = New-Object Point(($headerPanel.Width - 250), 8)
        $headerPanel.Controls.Add($this.StartButton)
        
        # Event Handler
        $this.StartButton.Add_Click({
            $script:MainWindowInstance.RunFullCheck()
        })
        
        # Responsive Button
        $headerPanel.Add_Resize({
            $this.StartButton.Location = New-Object Point(($headerPanel.Width - 250), 8)
        })
        
        # TabControl
        $this.TabControl = New-Object TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object Drawing.Font("Segoe UI", 10)
        $mainContainer.Controls.Add($this.TabControl)
        
        # Initialize Tabs
        $this.InitializeTabs()
        
        # StatusBar
        $this.InitializeStatusBar()
    }
    
    [void]CreateMenuStrip() {
        $this.MenuStrip = New-Object MenuStrip
        
        # Datei-Menu
        $fileMenu = New-Object ToolStripMenuItem("Datei")
        
        $exportItem = New-Object ToolStripMenuItem("Export Report...")
        $exportItem.Add_Click({
            $script:MainWindowInstance.ExportReport()
        })
        $fileMenu.DropDownItems.Add($exportItem)
        
        $fileMenu.DropDownItems.Add((New-Object ToolStripSeparator))
        
        $exitItem = New-Object ToolStripMenuItem("Beenden")
        $exitItem.ShortcutKeys = [Keys]::Alt -bor [Keys]::F4
        $exitItem.Add_Click({
            $script:MainWindowInstance.Form.Close()
        })
        $fileMenu.DropDownItems.Add($exitItem)
        
        $this.MenuStrip.Items.Add($fileMenu)
        
        # Hilfe-Menu
        $helpMenu = New-Object ToolStripMenuItem("Hilfe")
        
        $aboutItem = New-Object ToolStripMenuItem("Ueber...")
        $aboutItem.Add_Click({
            [MessageBox]::Show("Sage 100 Server Check & Setup Tool`nVersion 2.0`n`n(c) 2024", "Ueber", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
        })
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $this.MenuStrip.Items.Add($helpMenu)
        
        $this.Form.MainMenuStrip = $this.MenuStrip
        $this.Form.Controls.Add($this.MenuStrip)
    }
    
    [void]InitializeTabs() {
        # Tab 1: Dashboard
        $dashboardTab = [TabPage]::new("Dashboard")
        $this.TabControl.Controls.Add($dashboardTab)
        $this.InitializeDashboard($dashboardTab)
        
        # Tab 2: System-Details
        $systemTab = [TabPage]::new("System-Details")
        $this.TabControl.Controls.Add($systemTab)
        
        $this.SystemInfoBox = New-Object RichTextBox
        $this.SystemInfoBox.Dock = "Fill"
        $this.SystemInfoBox.Font = New-Object Drawing.Font("Consolas", 9)
        $this.SystemInfoBox.ReadOnly = $true
        $this.SystemInfoBox.BackColor = [Color]::White
        $this.SystemInfoBox.Text = "Klicken Sie auf 'Vollstaendige Pruefung starten', um System-Informationen anzuzeigen."
        $systemTab.Controls.Add($this.SystemInfoBox)
        
        # Tab 3: Netzwerk-Details
        $networkTab = [TabPage]::new("Netzwerk-Details")
        $this.TabControl.Controls.Add($networkTab)
        
        $this.NetworkInfoBox = New-Object RichTextBox
        $this.NetworkInfoBox.Dock = "Fill"
        $this.NetworkInfoBox.Font = New-Object Drawing.Font("Consolas", 9)
        $this.NetworkInfoBox.ReadOnly = $true
        $this.NetworkInfoBox.BackColor = [Color]::White
        $this.NetworkInfoBox.Text = "Klicken Sie auf 'Vollstaendige Pruefung starten', um Netzwerk-Informationen anzuzeigen."
        $networkTab.Controls.Add($this.NetworkInfoBox)
        
        # Tab 4: Logs
        $logTab = [TabPage]::new("Logs")
        $this.TabControl.Controls.Add($logTab)
        
        $this.LogBox = New-Object RichTextBox
        $this.LogBox.Dock = "Fill"
        $this.LogBox.Font = New-Object Drawing.Font("Consolas", 9)
        $this.LogBox.ReadOnly = $true
        $this.LogBox.BackColor = [Color]::White
        $logTab.Controls.Add($this.LogBox)
    }
    
    [void]InitializeDashboard([TabPage]$tab) {
        # Status Panel
        $statusPanel = New-Object FlowLayoutPanel
        $statusPanel.Dock = "Fill"
        $statusPanel.Padding = New-Object Padding(20)
        $statusPanel.FlowDirection = "LeftToRight"
        $statusPanel.AutoScroll = $true
        $tab.Controls.Add($statusPanel)
        
        # Status Cards
        $this.StatusCards["System"] = $this.CreateStatusCard("System-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["System"])
        
        $this.StatusCards["Network"] = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["Network"])
        
        $this.StatusCards["Compliance"] = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["Compliance"])
    }
    
    [GroupBox]CreateStatusCard([string]$title, [string]$status, [Color]$statusColor) {
        $card = New-Object GroupBox
        $card.Text = $title
        $card.Size = New-Object Size(350, 150)
        $card.Font = New-Object Drawing.Font("Segoe UI", 11, [FontStyle]::Bold)
        $card.Margin = New-Object Padding(10)
        
        $cardStatusLabel = New-Object Label
        $cardStatusLabel.Text = $status
        $cardStatusLabel.ForeColor = $statusColor
        $cardStatusLabel.Font = New-Object Drawing.Font("Segoe UI", 10)
        $cardStatusLabel.Location = New-Object Point(15, 35)
        $cardStatusLabel.AutoSize = $true
        $cardStatusLabel.Name = "StatusLabel"
        $card.Controls.Add($cardStatusLabel)
        
        return $card
    }
    
    [void]UpdateStatusCard([string]$cardName, [string]$newStatus, [Color]$color) {
        if ($this.StatusCards.ContainsKey($cardName)) {
            $card = $this.StatusCards[$cardName]
            $cardStatusLabel = $card.Controls | Where-Object { $_.Name -eq "StatusLabel" }
            if ($cardStatusLabel) {
                $cardStatusLabel.Text = $newStatus
                $cardStatusLabel.ForeColor = $color
                $card.Refresh()
                $this.Form.Refresh()
            }
        }
    }
    
    [void]InitializeStatusBar() {
        $statusBar = New-Object StatusStrip
        
        $this.StatusLabel = New-Object ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = "MiddleLeft"
        $statusBar.Items.Add($this.StatusLabel)
        
        $this.ProgressBar = New-Object ToolStripProgressBar
        $this.ProgressBar.Visible = $false
        $this.ProgressBar.Size = New-Object Size(200, 16)
        $statusBar.Items.Add($this.ProgressBar)
        
        $this.Form.Controls.Add($statusBar)
    }
    
    [void]RunFullCheck() {
        try {
            $this.AddLog("=== STARTE VOLLSTAENDIGE SYSTEMPRUEFUNG ===", [Color]::Blue)
            $this.StatusLabel.Text = "Pruefung laeuft..."
            $this.ProgressBar.Visible = $true
            $this.ProgressBar.Value = 0
            $this.StartButton.Enabled = $false
            
            # System-Check
            $this.AddLog("1. System-Check...", [Color]::Black)
            $this.UpdateStatusCard("System", "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Get-SystemInformation" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInformation
                $this.CheckResults["System"] = $systemInfo
                $this.UpdateSystemTab($systemInfo)
                $this.UpdateStatusCard("System", "Erfolgreich geprueft", [Color]::Green)
                $this.AddLog("   [OK] System-Check abgeschlossen", [Color]::Green)
            } else {
                throw "Funktion 'Get-SystemInformation' nicht gefunden!"
            }
            
            $this.ProgressBar.Value = 33
            
            # Netzwerk-Check
            $this.AddLog("2. Netzwerk-Check...", [Color]::Black)
            $this.UpdateStatusCard("Network", "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-NetworkConfiguration" -ErrorAction SilentlyContinue) {
                $networkInfo = Test-NetworkConfiguration
                $this.CheckResults["Network"] = $networkInfo
                $this.UpdateNetworkTab($networkInfo)
                $this.UpdateStatusCard("Network", "Erfolgreich geprueft", [Color]::Green)
                $this.AddLog("   [OK] Netzwerk-Check abgeschlossen", [Color]::Green)
            } else {
                throw "Funktion 'Test-NetworkConfiguration' nicht gefunden!"
            }
            
            $this.ProgressBar.Value = 66
            
            # Compliance-Check
            $this.AddLog("3. Compliance-Check...", [Color]::Black)
            $this.UpdateStatusCard("Compliance", "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-Sage100Compliance" -ErrorAction SilentlyContinue) {
                $complianceInfo = Test-Sage100Compliance
                $this.CheckResults["Compliance"] = $complianceInfo
                $this.UpdateStatusCard("Compliance", "Erfolgreich geprueft", [Color]::Green)
                $this.AddLog("   [OK] Compliance-Check abgeschlossen", [Color]::Green)
            } else {
                throw "Funktion 'Test-Sage100Compliance' nicht gefunden!"
            }
            
            $this.ProgressBar.Value = 100
            $this.AddLog("=== PRUEFUNG ABGESCHLOSSEN ===", [Color]::Blue)
            $this.StatusLabel.Text = "Pruefung abgeschlossen"
            
        } catch {
            $errorMsg = "FEHLER: $($_.Exception.Message)"
            $this.AddLog($errorMsg, [Color]::Red)
            $this.AddLog("Position: $($_.InvocationInfo.PositionMessage)", [Color]::Red)
            
            [MessageBox]::Show($errorMsg, "Fehler", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
            
            $this.StatusLabel.Text = "Fehler bei der Pruefung"
        } finally {
            $this.StartButton.Enabled = $true
            $this.ProgressBar.Visible = $false
        }
    }
    
    [void]UpdateSystemTab([PSObject]$systemInfo) {
        $this.SystemInfoBox.Clear()
        $this.SystemInfoBox.SelectionFont = New-Object Drawing.Font("Consolas", 10, [FontStyle]::Bold)
        $this.SystemInfoBox.SelectionColor = [Color]::DarkBlue
        $this.SystemInfoBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
        
        $this.SystemInfoBox.SelectionFont = New-Object Drawing.Font("Consolas", 9)
        $this.SystemInfoBox.SelectionColor = [Color]::Black
        
        if ($systemInfo.Computername) {
            $this.SystemInfoBox.AppendText("Computername: $($systemInfo.Computername)`r`n")
        }
        if ($systemInfo.OS) {
            $this.SystemInfoBox.AppendText("Betriebssystem: $($systemInfo.OS)`r`n")
        }
        if ($systemInfo.CPU) {
            $this.SystemInfoBox.AppendText("CPU: $($systemInfo.CPU) ($($systemInfo.CPUCores) Cores)`r`n")
        }
        if ($systemInfo.RAM) {
            $this.SystemInfoBox.AppendText("RAM: $($systemInfo.RAM) GB`r`n")
        }
        if ($systemInfo.DotNetVersion) {
            $this.SystemInfoBox.AppendText(".NET Framework: $($systemInfo.DotNetVersion)`r`n")
        }
        if ($systemInfo.PowerShellVersion) {
            $this.SystemInfoBox.AppendText("PowerShell: $($systemInfo.PowerShellVersion)`r`n")
        }
        
        if ($systemInfo.Disks) {
            $this.SystemInfoBox.AppendText("`r`n=== FESTPLATTEN ===`r`n")
            foreach ($disk in $systemInfo.Disks) {
                $this.SystemInfoBox.AppendText("Laufwerk $($disk.Drive): $($disk.SizeGB) GB gesamt`r`n")
                $this.SystemInfoBox.AppendText("  Frei: $($disk.FreeGB) GB ($($disk.FreePercent) Prozent)`r`n")
            }
        }
    }
    
    [void]UpdateNetworkTab([PSObject]$networkInfo) {
        $this.NetworkInfoBox.Clear()
        $this.NetworkInfoBox.SelectionFont = New-Object Drawing.Font("Consolas", 10, [FontStyle]::Bold)
        $this.NetworkInfoBox.SelectionColor = [Color]::DarkBlue
        $this.NetworkInfoBox.AppendText("=== NETZWERK-KONFIGURATION ===`r`n`r`n")
        
        $this.NetworkInfoBox.SelectionFont = New-Object Drawing.Font("Consolas", 9)
        $this.NetworkInfoBox.SelectionColor = [Color]::Black
        
        if ($networkInfo.Adapters) {
            $this.NetworkInfoBox.AppendText("=== NETZWERK-ADAPTER ===`r`n")
            foreach ($adapter in $networkInfo.Adapters) {
                $this.NetworkInfoBox.AppendText("$($adapter.Name): $($adapter.IPAddress)`r`n")
                if ($adapter.Speed) {
                    $this.NetworkInfoBox.AppendText("  Geschwindigkeit: $($adapter.Speed)`r`n")
                }
            }
        }
        
        if ($networkInfo.Ports) {
            $this.NetworkInfoBox.AppendText("`r`n=== PORT-STATUS ===`r`n")
            foreach ($port in $networkInfo.Ports) {
                $status = if ($port.Open) { "OFFEN" } else { "GESCHLOSSEN" }
                $color = if ($port.Open) { [Color]::Green } else { [Color]::Red }
                
                $this.NetworkInfoBox.SelectionColor = $color
                $this.NetworkInfoBox.AppendText("Port $($port.Port) ($($port.Service)): $status`r`n")
                $this.NetworkInfoBox.SelectionColor = [Color]::Black
                
                if ($port.Process) {
                    $this.NetworkInfoBox.AppendText("  Prozess: $($port.Process)`r`n")
                }
            }
        }
        
        if ($networkInfo.FirewallStatus) {
            $this.NetworkInfoBox.AppendText("`r`n=== FIREWALL-STATUS ===`r`n")
            $this.NetworkInfoBox.AppendText("Domain: $($networkInfo.FirewallStatus.Domain)`r`n")
            $this.NetworkInfoBox.AppendText("Private: $($networkInfo.FirewallStatus.Private)`r`n")
            $this.NetworkInfoBox.AppendText("Public: $($networkInfo.FirewallStatus.Public)`r`n")
        }
    }
    
    [void]AddLog([string]$message, [Color]$color) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $this.LogBox.SelectionStart = $this.LogBox.TextLength
        $this.LogBox.SelectionLength = 0
        $this.LogBox.SelectionColor = [Color]::Gray
        $this.LogBox.AppendText("[$timestamp] ")
        $this.LogBox.SelectionColor = $color
        $this.LogBox.AppendText("$message`r`n")
        $this.LogBox.ScrollToCaret()
        $this.Form.Refresh()
    }
    
    [void]ExportReport() {
        try {
            $saveDialog = New-Object SaveFileDialog
            $saveDialog.Filter = "HTML Report (*.html)|*.html|Text File (*.txt)|*.txt"
            $saveDialog.FileName = "Sage100_ServerCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            
            if ($saveDialog.ShowDialog() -eq [DialogResult]::OK) {
                if (Get-Command -Name "Export-HTMLReport" -ErrorAction SilentlyContinue) {
                    Export-HTMLReport -CheckResults $this.CheckResults -OutputPath $saveDialog.FileName
                    [MessageBox]::Show("Report erfolgreich exportiert nach:`n$($saveDialog.FileName)", "Export erfolgreich", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
                } else {
                    # Fallback: Simple Text Export
                    $this.LogBox.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
                    [MessageBox]::Show("Log erfolgreich exportiert nach:`n$($saveDialog.FileName)", "Export erfolgreich", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
                }
            }
        } catch {
            [MessageBox]::Show("Fehler beim Export: $($_.Exception.Message)", "Fehler", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
        }
    }
    
    [void]Show() {
        [void]$this.Form.ShowDialog()
    }
}
