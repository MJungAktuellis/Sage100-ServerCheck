class MainWindow {
    [System.Windows.Forms.Form]$MainForm
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel
    [object]$DebugLogger
    
    MainWindow() {
        $this.InitializeComponent()
    }
    
    [void]InitializeComponent() {
        # Main Form
        $this.MainForm = New-Object System.Windows.Forms.Form
        $this.MainForm.Text = "Sage 100 Server Check & Setup Tool"
        $this.MainForm.Size = New-Object System.Drawing.Size(1200, 800)
        $this.MainForm.StartPosition = "CenterScreen"
        $this.MainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        
        # Menu Bar
        $menuBar = New-Object System.Windows.Forms.MenuStrip
        
        # File Menu
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $fileMenu.Text = "Datei"
        
        $exportMarkdown = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportMarkdown.Text = "Export Markdown-Report"
        $exportMarkdown.Add_Click({ $this.ExportMarkdown() })
        
        $exportJson = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportJson.Text = "Export JSON-Snapshot"
        $exportJson.Add_Click({ $this.ExportJSON() })
        
        $exportLog = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportLog.Text = "Export Debug-Log"
        $exportLog.Add_Click({ $this.ExportDebugLog() })
        
        $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $exitItem.Text = "Beenden"
        $exitItem.Add_Click({ $this.MainForm.Close() })
        
        $fileMenu.DropDownItems.AddRange(@($exportMarkdown, $exportJson, $exportLog, 
            (New-Object System.Windows.Forms.ToolStripSeparator), $exitItem))
        
        # Actions Menu
        $actionsMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $actionsMenu.Text = "Aktionen"
        
        $fullCheck = New-Object System.Windows.Forms.ToolStripMenuItem
        $fullCheck.Text = "Vollstaendige Pruefung"
        $fullCheck.Add_Click({ $this.RunFullCheck() })
        
        $systemCheck = New-Object System.Windows.Forms.ToolStripMenuItem
        $systemCheck.Text = "Nur System-Check"
        $systemCheck.Add_Click({ $this.RunSystemCheck() })
        
        $networkCheck = New-Object System.Windows.Forms.ToolStripMenuItem
        $networkCheck.Text = "Nur Netzwerk-Check"
        $networkCheck.Add_Click({ $this.RunNetworkCheck() })
        
        $complianceCheck = New-Object System.Windows.Forms.ToolStripMenuItem
        $complianceCheck.Text = "Nur Compliance-Check"
        $complianceCheck.Add_Click({ $this.RunComplianceCheck() })
        
        $actionsMenu.DropDownItems.AddRange(@($fullCheck, (New-Object System.Windows.Forms.ToolStripSeparator),
            $systemCheck, $networkCheck, $complianceCheck))
        
        # Help Menu
        $helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $helpMenu.Text = "Hilfe"
        
        $aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $aboutItem.Text = "Ueber"
        $aboutItem.Add_Click({ $this.ShowAbout() })
        
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $menuBar.Items.AddRange(@($fileMenu, $actionsMenu, $helpMenu))
        $this.MainForm.Controls.Add($menuBar)
        
        # Tab Control
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Location = New-Object System.Drawing.Point(10, 30)
        $this.TabControl.Size = New-Object System.Drawing.Size(1160, 680)
        
        # Dashboard Tab
        $dashboardTab = New-Object System.Windows.Forms.TabPage
        $dashboardTab.Text = "Dashboard"
        $dashboardTab.BackColor = [System.Drawing.Color]::White
        
        # Header
        $headerLabel = New-Object System.Windows.Forms.Label
        $headerLabel.Text = "Sage 100 Server Status-Uebersicht"
        $headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
        $headerLabel.Location = New-Object System.Drawing.Point(20, 20)
        $headerLabel.Size = New-Object System.Drawing.Size(600, 40)
        $dashboardTab.Controls.Add($headerLabel)
        
        # Status Cards Container
        $cardsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $cardsPanel.Location = New-Object System.Drawing.Point(20, 80)
        $cardsPanel.Size = New-Object System.Drawing.Size(1100, 200)
        $cardsPanel.FlowDirection = "LeftToRight"
        
        # System Status Card
        $systemCard = $this.CreateStatusCard("System-Status", "Noch nicht geprueft", "SystemStatusLabel")
        $cardsPanel.Controls.Add($systemCard)
        
        # Network Status Card
        $networkCard = $this.CreateStatusCard("Netzwerk-Status", "Noch nicht geprueft", "NetworkStatusLabel")
        $cardsPanel.Controls.Add($networkCard)
        
        # Compliance Status Card
        $complianceCard = $this.CreateStatusCard("Compliance-Status", "Noch nicht geprueft", "ComplianceStatusLabel")
        $cardsPanel.Controls.Add($complianceCard)
        
        $dashboardTab.Controls.Add($cardsPanel)
        
        # Action Button
        $checkButton = New-Object System.Windows.Forms.Button
        $checkButton.Text = "Vollstaendige Pruefung starten"
        $checkButton.Location = New-Object System.Drawing.Point(20, 300)
        $checkButton.Size = New-Object System.Drawing.Size(300, 50)
        $checkButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $checkButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
        $checkButton.ForeColor = [System.Drawing.Color]::White
        $checkButton.FlatStyle = "Flat"
        $checkButton.Add_Click({ $this.RunFullCheck() })
        $dashboardTab.Controls.Add($checkButton)
        
        # Result TextBox
        $resultBox = New-Object System.Windows.Forms.TextBox
        $resultBox.Multiline = $true
        $resultBox.ScrollBars = "Vertical"
        $resultBox.Location = New-Object System.Drawing.Point(20, 370)
        $resultBox.Size = New-Object System.Drawing.Size(1100, 250)
        $resultBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $resultBox.ReadOnly = $true
        $resultBox.Name = "DashboardResultBox"
        $dashboardTab.Controls.Add($resultBox)
        
        $this.TabControl.TabPages.Add($dashboardTab)
        
        # System Info Tab
        $systemTab = $this.CreateSystemTab()
        $this.TabControl.TabPages.Add($systemTab)
        
        # Network Tab
        $networkTab = $this.CreateNetworkTab()
        $this.TabControl.TabPages.Add($networkTab)
        
        # Compliance Tab
        $complianceTab = $this.CreateComplianceTab()
        $this.TabControl.TabPages.Add($complianceTab)
        
        # Debug Log Tab
        $debugTab = $this.CreateDebugTab()
        $this.TabControl.TabPages.Add($debugTab)
        
        $this.MainForm.Controls.Add($this.TabControl)
        
        # Status Bar
        $statusPanel = New-Object System.Windows.Forms.Panel
        $statusPanel.Dock = "Bottom"
        $statusPanel.Height = 30
        $statusPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        
        $this.StatusLabel = New-Object System.Windows.Forms.Label
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Location = New-Object System.Drawing.Point(10, 5)
        $this.StatusLabel.AutoSize = $true
        $statusPanel.Controls.Add($this.StatusLabel)
        
        $this.ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $this.ProgressBar.Location = New-Object System.Drawing.Point(200, 5)
        $this.ProgressBar.Size = New-Object System.Drawing.Size(300, 20)
        $this.ProgressBar.Visible = $false
        $statusPanel.Controls.Add($this.ProgressBar)
        
        $this.MainForm.Controls.Add($statusPanel)
    }
    
    [System.Windows.Forms.Panel]CreateStatusCard([string]$title, [string]$status, [string]$labelName) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(340, 150)
        $card.BackColor = [System.Drawing.Color]::White
        $card.BorderStyle = "FixedSingle"
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(15, 15)
        $titleLabel.Size = New-Object System.Drawing.Size(310, 30)
        $card.Controls.Add($titleLabel)
        
        $cardStatusLabel = New-Object System.Windows.Forms.Label
        $cardStatusLabel.Text = $status
        $cardStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $cardStatusLabel.Location = New-Object System.Drawing.Point(15, 60)
        $cardStatusLabel.Size = New-Object System.Drawing.Size(310, 70)
        $cardStatusLabel.Name = $labelName
        $card.Controls.Add($cardStatusLabel)
        
        return $card
    }
    
    [System.Windows.Forms.TabPage]CreateSystemTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "System-Info"
        $tab.BackColor = [System.Drawing.Color]::White
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "SystemInfoTextBox"
        
        $tab.Controls.Add($textBox)
        return $tab
    }
    
    [System.Windows.Forms.TabPage]CreateNetworkTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Netzwerk und Firewall"
        $tab.BackColor = [System.Drawing.Color]::White
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "NetworkInfoTextBox"
        
        $tab.Controls.Add($textBox)
        return $tab
    }
    
    [System.Windows.Forms.TabPage]CreateComplianceTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Compliance-Check"
        $tab.BackColor = [System.Drawing.Color]::White
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "ComplianceInfoTextBox"
        
        $tab.Controls.Add($textBox)
        return $tab
    }
    
    [System.Windows.Forms.TabPage]CreateDebugTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Debug-Logs"
        $tab.BackColor = [System.Drawing.Color]::White
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.ReadOnly = $true
        $textBox.Name = "DebugLogTextBox"
        
        $tab.Controls.Add($textBox)
        return $tab
    }
    
    [void]RunFullCheck() {
        try {
            $this.StatusLabel.Text = "Starte vollstaendige Pruefung..."
            $this.ProgressBar.Visible = $true
            $this.ProgressBar.Value = 0
            
            $dashboardTab = $this.TabControl.TabPages[0]
            $resultBox = $dashboardTab.Controls.Find("DashboardResultBox", $true)[0]
            $resultBox.Clear()
            
            # System Check
            $this.ProgressBar.Value = 10
            $this.StatusLabel.Text = "Pruefe System..."
            $systemInfo = Get-SystemInformation
            $this.UpdateSystemTab($systemInfo)
            
            $dashboardCard = $dashboardTab.Controls.Find("SystemStatusLabel", $true)[0]
            if ($dashboardCard) {
                $dashboardCard.Text = "Erfolgreich geprueft"
                $dashboardCard.ForeColor = [System.Drawing.Color]::Green
            }
            
            $resultBox.AppendText("=== SYSTEM-CHECK ===`r`n")
            $resultBox.AppendText("OS: $($systemInfo.OS.Caption)`r`n")
            $resultBox.AppendText("RAM: $($systemInfo.Memory.TotalGB) GB`r`n")
            $resultBox.AppendText("CPU: $($systemInfo.CPU.Name)`r`n")
            
            foreach ($disk in $systemInfo.Disks) {
                $resultBox.AppendText("  Disk $($disk.DeviceID): $($disk.FreeSpaceGB) GB frei von $($disk.SizeGB) GB ($($disk.FreeSpacePercent) Prozent)`n")
            }
            $resultBox.AppendText("`r`n")
            
            # Network Check
            $this.ProgressBar.Value = 40
            $this.StatusLabel.Text = "Pruefe Netzwerk und Firewall..."
            $networkInfo = Test-NetworkConfiguration
            $this.UpdateNetworkTab($networkInfo)
            
            $networkCard = $dashboardTab.Controls.Find("NetworkStatusLabel", $true)[0]
            if ($networkCard) {
                $networkCard.Text = "Erfolgreich geprueft"
                $networkCard.ForeColor = [System.Drawing.Color]::Green
            }
            
            $resultBox.AppendText("=== NETZWERK-CHECK ===`r`n")
            foreach ($adapter in $networkInfo.Adapters) {
                if ($adapter.IPAddress) {
                    $resultBox.AppendText("  $($adapter.Name): $($adapter.IPAddress)`r`n")
                }
            }
            
            $resultBox.AppendText("`r`n=== KONNEKTIVITAETS-TESTS ===`r`n")
            foreach ($test in $networkInfo.PortTests) {
                $status = if ($test.Success) { "OK" } else { "FEHLER" }
                $resultBox.AppendText("  Port $($test.Port): $status`r`n")
            }
            $resultBox.AppendText("`r`n")
            
            $this.StatusLabel.Text = "Netzwerk-Check abgeschlossen"
            
            # Compliance Check
            $this.ProgressBar.Value = 70
            $this.StatusLabel.Text = "Pruefe Compliance..."
            $complianceInfo = Test-Sage100Compliance
            $this.UpdateComplianceTab($complianceInfo)
            
            $complianceCard = $dashboardTab.Controls.Find("ComplianceStatusLabel", $true)[0]
            if ($complianceCard) {
                $complianceCard.Text = "Erfolgreich geprueft"
                $complianceCard.ForeColor = [System.Drawing.Color]::Green
            }
            
            $resultBox.AppendText("=== COMPLIANCE-CHECK ===`r`n")
            $resultBox.AppendText("Fehler: $($complianceInfo.Summary.ErrorCount)`r`n")
            $resultBox.AppendText("Warnungen: $($complianceInfo.Summary.WarningCount)`r`n")
            $resultBox.AppendText("`r`n")
            
            # Complete
            $this.ProgressBar.Value = 100
            $this.StatusLabel.Text = "Pruefung abgeschlossen"
            
            [System.Windows.Forms.MessageBox]::Show("Alle Checks wurden erfolgreich durchgefuehrt.`r`n`r`nDetails finden Sie in den einzelnen Tabs.", 
                "Pruefung abgeschlossen", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
        } catch {
            $this.StatusLabel.Text = "Fehler bei der Pruefung"
            [System.Windows.Forms.MessageBox]::Show("Fehler bei der Pruefung: $($_.Exception.Message)", 
                "Fehler", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        } finally {
            $this.ProgressBar.Visible = $false
        }
    }
    
    [void]UpdateSystemTab($systemInfo) {
        $tab = $this.TabControl.TabPages[1]
        $textBox = $tab.Controls.Find("SystemInfoTextBox", $true)[0]
        $textBox.Clear()
        
        $textBox.AppendText("=== BETRIEBSSYSTEM ===`r`n")
        $textBox.AppendText("Name: $($systemInfo.OS.Caption)`r`n")
        $textBox.AppendText("Version: $($systemInfo.OS.Version)`r`n")
        $textBox.AppendText("Build: $($systemInfo.OS.BuildNumber)`r`n")
        $textBox.AppendText("`r`n")
        
        $textBox.AppendText("=== HARDWARE ===`r`n")
        $textBox.AppendText("CPU: $($systemInfo.CPU.Name)`r`n")
        $textBox.AppendText("Kerne: $($systemInfo.CPU.Cores)`r`n")
        $textBox.AppendText("RAM: $($systemInfo.Memory.TotalGB) GB`r`n")
        $textBox.AppendText("`r`n")
        
        $textBox.AppendText("=== FESTPLATTEN ===`r`n")
        foreach ($disk in $systemInfo.Disks) {
            $textBox.AppendText("$($disk.DeviceID)`r`n")
            $textBox.AppendText("  Gesamt: $($disk.SizeGB) GB`r`n")
            $textBox.AppendText("  Frei: $($disk.FreeSpaceGB) GB ($($disk.FreeSpacePercent) Prozent)`r`n")
            $textBox.AppendText("`r`n")
        }
    }
    
    [void]UpdateNetworkTab($networkInfo) {
        $tab = $this.TabControl.TabPages[2]
        $textBox = $tab.Controls.Find("NetworkInfoTextBox", $true)[0]
        $textBox.Clear()
        
        $textBox.AppendText("=== NETZWERKADAPTER ===`r`n")
        foreach ($adapter in $networkInfo.Adapters) {
            if ($adapter.IPAddress) {
                $textBox.AppendText("$($adapter.Name)`r`n")
                $textBox.AppendText("  IP: $($adapter.IPAddress)`r`n")
                $textBox.AppendText("  Gateway: $($adapter.Gateway)`r`n")
                $textBox.AppendText("`r`n")
            }
        }
        
        $textBox.AppendText("=== PORT-TESTS ===`r`n")
        foreach ($test in $networkInfo.PortTests) {
            $status = if ($test.Success) { "OFFEN" } else { "GESCHLOSSEN" }
            $textBox.AppendText("Port $($test.Port) ($($test.Description)): $status`r`n")
        }
    }
    
    [void]UpdateComplianceTab($complianceInfo) {
        $tab = $this.TabControl.TabPages[3]
        $textBox = $tab.Controls.Find("ComplianceInfoTextBox", $true)[0]
        $textBox.Clear()
        
        $textBox.AppendText("=== COMPLIANCE-ZUSAMMENFASSUNG ===`r`n")
        $textBox.AppendText("Fehler: $($complianceInfo.Summary.ErrorCount)`r`n")
        $textBox.AppendText("Warnungen: $($complianceInfo.Summary.WarningCount)`r`n")
        $textBox.AppendText("`r`n")
        
        if ($complianceInfo.Errors.Count -gt 0) {
            $textBox.AppendText("=== FEHLER ===`r`n")
            foreach ($error in $complianceInfo.Errors) {
                $textBox.AppendText("- $error`r`n")
            }
            $textBox.AppendText("`r`n")
        }
        
        if ($complianceInfo.Warnings.Count -gt 0) {
            $textBox.AppendText("=== WARNUNGEN ===`r`n")
            foreach ($warning in $complianceInfo.Warnings) {
                $textBox.AppendText("- $warning`r`n")
            }
        }
    }
    
    [void]RunSystemCheck() {
        $this.StatusLabel.Text = "Pruefe System..."
        $systemInfo = Get-SystemInformation
        $this.UpdateSystemTab($systemInfo)
        $this.TabControl.SelectedIndex = 1
        $this.StatusLabel.Text = "System-Check abgeschlossen"
    }
    
    [void]RunNetworkCheck() {
        $this.StatusLabel.Text = "Pruefe Netzwerk..."
        $networkInfo = Test-NetworkConfiguration
        $this.UpdateNetworkTab($networkInfo)
        $this.TabControl.SelectedIndex = 2
        $this.StatusLabel.Text = "Netzwerk-Check abgeschlossen"
    }
    
    [void]RunComplianceCheck() {
        $this.StatusLabel.Text = "Pruefe Compliance..."
        $complianceInfo = Test-Sage100Compliance
        $this.UpdateComplianceTab($complianceInfo)
        $this.TabControl.SelectedIndex = 3
        $this.StatusLabel.Text = "Compliance-Check abgeschlossen"
    }
    
    [void]ExportMarkdown() {
        $this.StatusLabel.Text = "Exportiere Markdown-Report..."
        New-MarkdownReport
        [System.Windows.Forms.MessageBox]::Show("Markdown-Report wurde erstellt.", "Export", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $this.StatusLabel.Text = "Export abgeschlossen"
    }
    
    [void]ExportJSON() {
        $this.StatusLabel.Text = "Exportiere JSON-Snapshot..."
        New-JSONSnapshot
        [System.Windows.Forms.MessageBox]::Show("JSON-Snapshot wurde erstellt.", "Export", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        $this.StatusLabel.Text = "Export abgeschlossen"
    }
    
    [void]ExportDebugLog() {
        if ($this.DebugLogger) {
            $this.StatusLabel.Text = "Exportiere Debug-Log..."
            $logPath = $this.DebugLogger.ExportLog()
            [System.Windows.Forms.MessageBox]::Show("Debug-Log wurde exportiert nach:`r`n$logPath", "Export", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            $this.StatusLabel.Text = "Export abgeschlossen"
        }
    }
    
    [void]ShowAbout() {
        $aboutText = @"
Sage 100 Server Check & Setup Tool
Version 2.0

Funktionen:
- System-Informationen sammeln
- Netzwerk & Firewall pruefen
- Sage 100 Compliance-Check
- Automatische Dokumentation
- Debug-Logging

(c) 2026 - Entwickelt fuer Sage 100 Administratoren
"@
        [System.Windows.Forms.MessageBox]::Show($aboutText, "Ueber", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    
    [void]Show() {
        $this.MainForm.ShowDialog()
    }
}
