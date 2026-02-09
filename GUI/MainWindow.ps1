# GUI/MainWindow.ps1
# Sage 100 Server Check - Hauptfenster (Windows Forms)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =======================================
# GUI-Klasse Definition
# =======================================
class MainWindow {
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel
    [System.Windows.Forms.Button]$StartButton
    [hashtable]$CheckResults = @{}
    
    # Konstruktor
    MainWindow() {
        $this.InitializeComponents()
        $this.SetupEventHandlers()
    }
    
    # Komponenten initialisieren
    [void] InitializeComponents() {
        # Hauptfenster
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Text = "Sage 100 Server Check & Setup Tool"
        $this.Form.Size = New-Object System.Drawing.Size(1000, 700)
        $this.Form.StartPosition = "CenterScreen"
        $this.Form.FormBorderStyle = "FixedDialog"
        $this.Form.MaximizeBox = $false
        
        # Menu erstellen
        $this.CreateMenuBar()
        
        # Tab-Control
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Location = New-Object System.Drawing.Point(10, 30)
        $this.TabControl.Size = New-Object System.Drawing.Size(965, 580)
        $this.Form.Controls.Add($this.TabControl)
        
        # Tabs erstellen
        $this.CreateDashboardTab()
        $this.CreateSystemTab()
        $this.CreateNetworkTab()
        $this.CreateComplianceTab()
        $this.CreateLogsTab()
        
        # Statusleiste
        $this.ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $this.ProgressBar.Location = New-Object System.Drawing.Point(10, 620)
        $this.ProgressBar.Size = New-Object System.Drawing.Size(700, 20)
        $this.ProgressBar.Minimum = 0
        $this.ProgressBar.Maximum = 100
        $this.Form.Controls.Add($this.ProgressBar)
        
        $this.StatusLabel = New-Object System.Windows.Forms.Label
        $this.StatusLabel.Location = New-Object System.Drawing.Point(720, 620)
        $this.StatusLabel.Size = New-Object System.Drawing.Size(250, 20)
        $this.StatusLabel.Text = "Bereit"
        $this.Form.Controls.Add($this.StatusLabel)
    }
    
    # Menuleiste erstellen
    [void] CreateMenuBar() {
        $menuStrip = New-Object System.Windows.Forms.MenuStrip
        
        # Datei-Menu
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $fileMenu.Text = "Datei"
        
        $exportMd = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportMd.Text = "Export Markdown Report"
        $fileMenu.DropDownItems.Add($exportMd)
        
        $exportJson = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportJson.Text = "Export JSON Snapshot"
        $fileMenu.DropDownItems.Add($exportJson)
        
        $exportLog = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportLog.Text = "Export Debug-Log"
        $fileMenu.DropDownItems.Add($exportLog)
        
        $fileMenu.DropDownItems.Add((New-Object System.Windows.Forms.ToolStripSeparator))
        
        $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $exitItem.Text = "Beenden"
        $fileMenu.DropDownItems.Add($exitItem)
        
        $menuStrip.Items.Add($fileMenu)
        
        # Hilfe-Menu
        $helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $helpMenu.Text = "Hilfe"
        
        $aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $aboutItem.Text = "Ueber"
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $menuStrip.Items.Add($helpMenu)
        
        $this.Form.Controls.Add($menuStrip)
        $this.Form.MainMenuStrip = $menuStrip
    }
    
    # Dashboard-Tab
    [void] CreateDashboardTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Dashboard"
        $tab.Name = "DashboardTab"
        
        # Titel
        $title = New-Object System.Windows.Forms.Label
        $title.Text = "Sage 100 Server Check"
        $title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $title.Location = New-Object System.Drawing.Point(20, 20)
        $title.Size = New-Object System.Drawing.Size(400, 40)
        $tab.Controls.Add($title)
        
        # Status-Karten Container
        $cardsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $cardsPanel.Location = New-Object System.Drawing.Point(20, 80)
        $cardsPanel.Size = New-Object System.Drawing.Size(900, 150)
        $cardsPanel.FlowDirection = "LeftToRight"
        $tab.Controls.Add($cardsPanel)
        
        # System-Karte
        $systemCard = $this.CreateStatusCard("System-Check", "Noch nicht geprueft", "Gray")
        $systemCard.Name = "SystemStatusCard"
        $cardsPanel.Controls.Add($systemCard)
        
        # Netzwerk-Karte
        $networkCard = $this.CreateStatusCard("Netzwerk-Check", "Noch nicht geprueft", "Gray")
        $networkCard.Name = "NetworkStatusCard"
        $cardsPanel.Controls.Add($networkCard)
        
        # Compliance-Karte
        $complianceCard = $this.CreateStatusCard("Compliance-Check", "Noch nicht geprueft", "Gray")
        $complianceCard.Name = "ComplianceStatusCard"
        $cardsPanel.Controls.Add($complianceCard)
        
        # Start-Button
        $this.StartButton = New-Object System.Windows.Forms.Button
        $this.StartButton.Text = "Vollstaendige Pruefung starten"
        $this.StartButton.Location = New-Object System.Drawing.Point(20, 250)
        $this.StartButton.Size = New-Object System.Drawing.Size(250, 40)
        $this.StartButton.BackColor = [System.Drawing.Color]::DodgerBlue
        $this.StartButton.ForeColor = [System.Drawing.Color]::White
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $this.StartButton.Name = "StartCheckButton"
        $tab.Controls.Add($this.StartButton)
        
        # Ergebnis-Textbox
        $resultBox = New-Object System.Windows.Forms.TextBox
        $resultBox.Multiline = $true
        $resultBox.ScrollBars = "Vertical"
        $resultBox.Location = New-Object System.Drawing.Point(20, 310)
        $resultBox.Size = New-Object System.Drawing.Size(900, 200)
        $resultBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $resultBox.ReadOnly = $true
        $resultBox.Name = "ResultBox"
        $tab.Controls.Add($resultBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Status-Karte erstellen
    [System.Windows.Forms.Panel] CreateStatusCard([string]$title, [string]$status, [string]$color) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(280, 120)
        $card.BorderStyle = "FixedSingle"
        $card.BackColor = [System.Drawing.Color]::White
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
        $titleLabel.Size = New-Object System.Drawing.Size(260, 25)
        $card.Controls.Add($titleLabel)
        
        $cardStatusLbl = New-Object System.Windows.Forms.Label
        $cardStatusLbl.Text = $status
        $cardStatusLbl.Location = New-Object System.Drawing.Point(10, 45)
        $cardStatusLbl.Size = New-Object System.Drawing.Size(260, 60)
        $cardStatusLbl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $cardStatusLbl.Name = "StatusLabel"
        
        switch ($color) {
            "Green" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Green }
            "Red" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Red }
            "Orange" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Orange }
            default { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Gray }
        }
        
        $card.Controls.Add($cardStatusLbl)
        
        return $card
    }
    
    # System-Tab
    [void] CreateSystemTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "System-Info"
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.ReadOnly = $true
        $textBox.Name = "SystemInfoBox"
        $tab.Controls.Add($textBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Netzwerk-Tab
    [void] CreateNetworkTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Netzwerk"
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.ReadOnly = $true
        $textBox.Name = "NetworkInfoBox"
        $tab.Controls.Add($textBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Compliance-Tab
    [void] CreateComplianceTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Compliance"
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.ReadOnly = $true
        $textBox.Name = "ComplianceInfoBox"
        $tab.Controls.Add($textBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Logs-Tab
    [void] CreateLogsTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Debug-Logs"
        
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 8)
        $textBox.ReadOnly = $true
        $textBox.Name = "LogsBox"
        $tab.Controls.Add($textBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Event-Handler einrichten
    [void] SetupEventHandlers() {
        $window = $this
        
        # Start-Button Click - DIREKTER Zugriff auf $this.StartButton
        $this.StartButton.Add_Click({
            $window.RunFullCheck()
        })
    }
    
    # Vollstaendige Pruefung
    [void] RunFullCheck() {
        $this.StatusLabel.Text = "Starte Pruefung..."
        $this.ProgressBar.Value = 0
        $this.Form.Refresh()
        
        try {
            # System-Check
            $this.StatusLabel.Text = "Pruefe System..."
            $this.ProgressBar.Value = 10
            $this.Form.Refresh()
            
            $systemInfo = Get-SystemInfo
            $this.CheckResults["System"] = $systemInfo
            $this.UpdateSystemTab($systemInfo)
            $this.UpdateStatusCard("SystemStatusCard", "Erfolgreich geprueft", "Green")
            
            $this.ProgressBar.Value = 40
            $this.Form.Refresh()
            
            # Network-Check
            $this.StatusLabel.Text = "Pruefe Netzwerk..."
            $networkInfo = Test-NetworkConfiguration
            $this.CheckResults["Network"] = $networkInfo
            $this.UpdateNetworkTab($networkInfo)
            $this.UpdateStatusCard("NetworkStatusCard", "Erfolgreich geprueft", "Green")
            
            $this.ProgressBar.Value = 70
            $this.Form.Refresh()
            
            # Compliance-Check
            $this.StatusLabel.Text = "Pruefe Compliance..."
            $complianceInfo = Test-Sage100Compliance
            $this.CheckResults["Compliance"] = $complianceInfo
            $this.UpdateComplianceTab($complianceInfo)
            $this.UpdateStatusCard("ComplianceStatusCard", "Erfolgreich geprueft", "Green")
            
            $this.ProgressBar.Value = 100
            $this.StatusLabel.Text = "Pruefung abgeschlossen"
            
            [System.Windows.Forms.MessageBox]::Show(
                "Alle Checks wurden erfolgreich durchgefuehrt!",
                "Erfolg",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
        } catch {
            $this.StatusLabel.Text = "Fehler bei der Pruefung"
            [System.Windows.Forms.MessageBox]::Show(
                "Fehler: $($_.Exception.Message)",
                "Fehler",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
    
    # Status-Karte aktualisieren
    [void] UpdateStatusCard([string]$cardName, [string]$status, [string]$color) {
        $dashboardTab = $this.TabControl.TabPages["DashboardTab"]
        $cardsPanel = $dashboardTab.Controls | Where-Object { $_ -is [System.Windows.Forms.FlowLayoutPanel] }
        $card = $cardsPanel.Controls[$cardName]
        
        if ($card) {
            $cardStatusLbl = $card.Controls["StatusLabel"]
            $cardStatusLbl.Text = $status
            
            switch ($color) {
                "Green" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Green }
                "Red" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Red }
                "Orange" { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Orange }
                default { $cardStatusLbl.ForeColor = [System.Drawing.Color]::Gray }
            }
        }
    }
    
    # System-Tab aktualisieren
    [void] UpdateSystemTab($systemInfo) {
        $tab = $this.TabControl.TabPages[1]
        $textBox = $tab.Controls["SystemInfoBox"]
        
        $textBox.Clear()
        $textBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
        $textBox.AppendText("Computer: $($systemInfo.ComputerName)`r`n")
        $textBox.AppendText("OS: $($systemInfo.OSName) ($($systemInfo.OSVersion))`r`n")
        $textBox.AppendText("CPU: $($systemInfo.CPU)`r`n")
        $textBox.AppendText("RAM: $($systemInfo.TotalRAM_GB) GB`r`n")
        $textBox.AppendText("`r`n=== FESTPLATTEN ===`r`n")
        
        foreach ($disk in $systemInfo.Disks) {
            $textBox.AppendText("`r`nLaufwerk $($disk.Drive):`r`n")
            $textBox.AppendText("  Gesamt: $($disk.TotalSpaceGB) GB`r`n")
            $textBox.AppendText("  Frei: $($disk.FreeSpaceGB) GB ($($disk.FreeSpacePercent) Prozent)`r`n")
        }
        
        $textBox.AppendText("`r`n.NET Framework: $($systemInfo.DotNetVersion)`r`n")
        $textBox.AppendText("PowerShell: $($systemInfo.PowerShellVersion)`r`n")
    }
    
    # Netzwerk-Tab aktualisieren
    [void] UpdateNetworkTab($networkInfo) {
        $tab = $this.TabControl.TabPages[2]
        $textBox = $tab.Controls["NetworkInfoBox"]
        
        $textBox.Clear()
        $textBox.AppendText("=== NETZWERK-ADAPTER ===`r`n`r`n")
        
        foreach ($adapter in $networkInfo.Adapters) {
            $textBox.AppendText("$($adapter.Name):`r`n")
            $textBox.AppendText("  IP: $($adapter.IPAddress)`r`n")
            $textBox.AppendText("  Speed: $($adapter.Speed)`r`n`r`n")
        }
        
        $textBox.AppendText("`r`n=== PORT-STATUS ===`r`n`r`n")
        
        foreach ($port in $networkInfo.Ports) {
            $status = if ($port.IsOpen) { "OFFEN" } else { "GESCHLOSSEN" }
            $textBox.AppendText("Port $($port.Port) ($($port.Service)): $status`r`n")
        }
        
        $textBox.AppendText("`r`n=== FIREWALL ===`r`n`r`n")
        $textBox.AppendText("Domain-Profil: $($networkInfo.Firewall.DomainProfile)`r`n")
        $textBox.AppendText("Private-Profil: $($networkInfo.Firewall.PrivateProfile)`r`n")
        $textBox.AppendText("Public-Profil: $($networkInfo.Firewall.PublicProfile)`r`n")
    }
    
    # Compliance-Tab aktualisieren
    [void] UpdateComplianceTab($complianceInfo) {
        $tab = $this.TabControl.TabPages[3]
        $textBox = $tab.Controls["ComplianceInfoBox"]
        
        $textBox.Clear()
        $textBox.AppendText("=== SAGE 100 COMPLIANCE-CHECK ===`r`n`r`n")
        
        $textBox.AppendText("Betriebssystem: ")
        if ($complianceInfo.OSCompliant) {
            $textBox.AppendText("OK`r`n")
        } else {
            $textBox.AppendText("FEHLER - Nicht unterstuetzt`r`n")
        }
        
        $textBox.AppendText("`r`nRAM: $($complianceInfo.RAM_GB) GB ")
        if ($complianceInfo.RAM_GB -ge 8) {
            $textBox.AppendText("(OK)`r`n")
        } else {
            $textBox.AppendText("(WARNUNG - Mindestens 8 GB empfohlen)`r`n")
        }
        
        $textBox.AppendText("`r`n.NET Framework: $($complianceInfo.DotNetVersion) ")
        if ($complianceInfo.DotNetCompliant) {
            $textBox.AppendText("(OK)`r`n")
        } else {
            $textBox.AppendText("(FEHLER - Mindestens 4.7.2 erforderlich)`r`n")
        }
        
        if ($complianceInfo.Errors.Count -gt 0) {
            $textBox.AppendText("`r`n=== FEHLER ===`r`n")
            foreach ($error in $complianceInfo.Errors) {
                $textBox.AppendText("  - $error`r`n")
            }
        }
        
        if ($complianceInfo.Warnings.Count -gt 0) {
            $textBox.AppendText("`r`n=== WARNUNGEN ===`r`n")
            foreach ($warning in $complianceInfo.Warnings) {
                $textBox.AppendText("  - $warning`r`n")
            }
        }
    }
    
    # Fenster anzeigen
    [void] Show() {
        [void]$this.Form.ShowDialog()
    }
}
