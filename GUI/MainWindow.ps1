# GUI/MainWindow.ps1
# Sage 100 Server Check - Hauptfenster (Windows Forms)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =====================================
# GUI-Klasse Definition
# =====================================
class MainWindow {
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel
    [System.Windows.Forms.Button]$StartButton
    [System.Windows.Forms.TextBox]$SystemInfoBox
    [System.Windows.Forms.TextBox]$NetworkInfoBox
    [System.Windows.Forms.TextBox]$ComplianceInfoBox
    [System.Windows.Forms.TextBox]$LogsBox
    [System.Windows.Forms.TextBox]$ResultBox
    [hashtable]$CheckResults = @{}
    
    # Konstruktor
    MainWindow() {
        $this.InitializeComponents()
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
        $this.ResultBox = New-Object System.Windows.Forms.TextBox
        $this.ResultBox.Multiline = $true
        $this.ResultBox.ScrollBars = "Vertical"
        $this.ResultBox.Location = New-Object System.Drawing.Point(20, 310)
        $this.ResultBox.Size = New-Object System.Drawing.Size(900, 200)
        $this.ResultBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.ResultBox.ReadOnly = $true
        $this.ResultBox.Name = "ResultBox"
        $tab.Controls.Add($this.ResultBox)
        
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
        
        $this.SystemInfoBox = New-Object System.Windows.Forms.TextBox
        $this.SystemInfoBox.Multiline = $true
        $this.SystemInfoBox.ScrollBars = "Vertical"
        $this.SystemInfoBox.Dock = "Fill"
        $this.SystemInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.SystemInfoBox.ReadOnly = $true
        $this.SystemInfoBox.Name = "SystemInfoBox"
        $tab.Controls.Add($this.SystemInfoBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Netzwerk-Tab
    [void] CreateNetworkTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Netzwerk"
        
        $this.NetworkInfoBox = New-Object System.Windows.Forms.TextBox
        $this.NetworkInfoBox.Multiline = $true
        $this.NetworkInfoBox.ScrollBars = "Vertical"
        $this.NetworkInfoBox.Dock = "Fill"
        $this.NetworkInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.NetworkInfoBox.ReadOnly = $true
        $this.NetworkInfoBox.Name = "NetworkInfoBox"
        $tab.Controls.Add($this.NetworkInfoBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Compliance-Tab
    [void] CreateComplianceTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Compliance"
        
        $this.ComplianceInfoBox = New-Object System.Windows.Forms.TextBox
        $this.ComplianceInfoBox.Multiline = $true
        $this.ComplianceInfoBox.ScrollBars = "Vertical"
        $this.ComplianceInfoBox.Dock = "Fill"
        $this.ComplianceInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.ComplianceInfoBox.ReadOnly = $true
        $this.ComplianceInfoBox.Name = "ComplianceInfoBox"
        $tab.Controls.Add($this.ComplianceInfoBox)
        
        $this.TabControl.TabPages.Add($tab)
    }
    
    # Logs-Tab
    [void] CreateLogsTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Debug-Logs"
        
        $this.LogsBox = New-Object System.Windows.Forms.TextBox
        $this.LogsBox.Multiline = $true
        $this.LogsBox.ScrollBars = "Vertical"
        $this.LogsBox.Dock = "Fill"
        $this.LogsBox.Font = New-Object System.Drawing.Font("Consolas", 8)
        $this.LogsBox.ReadOnly = $true
        $this.LogsBox.Name = "LogsBox"
        $tab.Controls.Add($this.LogsBox)
        
        $this.TabControl.TabPages.Add($tab)
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
            
            # FEHLERBEHANDLUNG: Prüfe ob Funktion existiert
            if (Get-Command -Name "Get-SystemInfo" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInfo
                $this.CheckResults["System"] = $systemInfo
                $this.UpdateSystemTab($systemInfo)
                $this.UpdateStatusCard("SystemStatusCard", "Erfolgreich geprueft", "Green")
            } else {
                throw "Funktion 'Get-SystemInfo' nicht gefunden! Module wurden nicht korrekt geladen."
            }
            
            $this.ProgressBar.Value = 40
            $this.Form.Refresh()
            
            # Netzwerk-Check
            $this.StatusLabel.Text = "Pruefe Netzwerk..."
            
            if (Get-Command -Name "Test-NetworkConfiguration" -ErrorAction SilentlyContinue) {
                $networkInfo = Test-NetworkConfiguration
                $this.CheckResults["Network"] = $networkInfo
                $this.UpdateNetworkTab($networkInfo)
                $this.UpdateStatusCard("NetworkStatusCard", "Erfolgreich geprueft", "Green")
            } else {
                throw "Funktion 'Test-NetworkConfiguration' nicht gefunden!"
            }
            
            $this.ProgressBar.Value = 70
            $this.Form.Refresh()
            
            # Compliance-Check
            $this.StatusLabel.Text = "Pruefe Compliance..."
            
            if (Get-Command -Name "Test-Sage100Compliance" -ErrorAction SilentlyContinue) {
                $complianceInfo = Test-Sage100Compliance
                $this.CheckResults["Compliance"] = $complianceInfo
                $this.UpdateComplianceTab($complianceInfo)
                $this.UpdateStatusCard("ComplianceStatusCard", "Erfolgreich geprueft", "Green")
            } else {
                throw "Funktion 'Test-Sage100Compliance' nicht gefunden!"
            }
            
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
            
            # Detaillierte Fehlermeldung
            $errorMsg = "Fehler: $($_.Exception.Message)`r`n`r`n"
            $errorMsg += "Position: $($_.InvocationInfo.PositionMessage)`r`n`r`n"
            $errorMsg += "Stack Trace: $($_.ScriptStackTrace)"
            
            [System.Windows.Forms.MessageBox]::Show(
                $errorMsg,
                "Fehler",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            
            # Fehler AUCH in Logs-Tab schreiben - DIREKT über Klasseneigenschaft
            if ($this.LogsBox) {
                $this.LogsBox.AppendText("=== FEHLER ===`r`n")
                $this.LogsBox.AppendText("$errorMsg`r`n`r`n")
            }
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
        $this.SystemInfoBox.Clear()
        $this.SystemInfoBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
        $this.SystemInfoBox.AppendText("Computer: $($systemInfo.ComputerName)`r`n")
        $this.SystemInfoBox.AppendText("OS: $($systemInfo.OSName) ($($systemInfo.OSVersion))`r`n")
        $this.SystemInfoBox.AppendText("CPU: $($systemInfo.CPU)`r`n")
        $this.SystemInfoBox.AppendText("RAM: $($systemInfo.TotalRAM_GB) GB`r`n")
        $this.SystemInfoBox.AppendText("`r`n=== FESTPLATTEN ===`r`n")
        
        foreach ($disk in $systemInfo.Disks) {
            $this.SystemInfoBox.AppendText("`r`nLaufwerk $($disk.Drive):`r`n")
            $this.SystemInfoBox.AppendText("  Gesamt: $($disk.TotalSpaceGB) GB`r`n")
            $this.SystemInfoBox.AppendText("  Frei: $($disk.FreeSpaceGB) GB ($($disk.FreeSpacePercent) Prozent)`r`n")
        }
        
        $this.SystemInfoBox.AppendText("`r`n.NET Framework: $($systemInfo.DotNetVersion)`r`n")
        $this.SystemInfoBox.AppendText("PowerShell: $($systemInfo.PowerShellVersion)`r`n")
    }
    
    # Netzwerk-Tab aktualisieren
    [void] UpdateNetworkTab($networkInfo) {
        $this.NetworkInfoBox.Clear()
        $this.NetworkInfoBox.AppendText("=== NETZWERK-ADAPTER ===`r`n`r`n")
        
        foreach ($adapter in $networkInfo.Adapters) {
            $this.NetworkInfoBox.AppendText("$($adapter.Name):`r`n")
            $this.NetworkInfoBox.AppendText("  IP: $($adapter.IPAddress)`r`n")
            $this.NetworkInfoBox.AppendText("  Speed: $($adapter.Speed)`r`n`r`n")
        }
        
        $this.NetworkInfoBox.AppendText("`r`n=== PORT-STATUS ===`r`n`r`n")
        
        foreach ($port in $networkInfo.Ports) {
            $status = if ($port.IsOpen) { "OFFEN" } else { "GESCHLOSSEN" }
            $this.NetworkInfoBox.AppendText("Port $($port.Port) ($($port.Service)): $status`r`n")
        }
        
        $this.NetworkInfoBox.AppendText("`r`n=== FIREWALL ===`r`n`r`n")
        $this.NetworkInfoBox.AppendText("Domain-Profil: $($networkInfo.Firewall.DomainProfile)`r`n")
        $this.NetworkInfoBox.AppendText("Private-Profil: $($networkInfo.Firewall.PrivateProfile)`r`n")
        $this.NetworkInfoBox.AppendText("Public-Profil: $($networkInfo.Firewall.PublicProfile)`r`n")
    }
    
    # Compliance-Tab aktualisieren
    [void] UpdateComplianceTab($complianceInfo) {
        $this.ComplianceInfoBox.Clear()
        $this.ComplianceInfoBox.AppendText("=== SAGE 100 COMPLIANCE-CHECK ===`r`n`r`n")
        
        $this.ComplianceInfoBox.AppendText("Betriebssystem: ")
        if ($complianceInfo.OSCompliant) {
            $this.ComplianceInfoBox.AppendText("OK`r`n")
        } else {
            $this.ComplianceInfoBox.AppendText("FEHLER - Nicht unterstuetzt`r`n")
        }
        
        $this.ComplianceInfoBox.AppendText("`r`nRAM: $($complianceInfo.RAM_GB) GB ")
        if ($complianceInfo.RAM_GB -ge 8) {
            $this.ComplianceInfoBox.AppendText("(OK)`r`n")
        } else {
            $this.ComplianceInfoBox.AppendText("(WARNUNG - Mindestens 8 GB empfohlen)`r`n")
        }
        
        $this.ComplianceInfoBox.AppendText("`r`n.NET Framework: $($complianceInfo.DotNetVersion) ")
        if ($complianceInfo.DotNetCompliant) {
            $this.ComplianceInfoBox.AppendText("(OK)`r`n")
        } else {
            $this.ComplianceInfoBox.AppendText("(FEHLER - Mindestens 4.7.2 erforderlich)`r`n")
        }
        
        if ($complianceInfo.Errors.Count -gt 0) {
            $this.ComplianceInfoBox.AppendText("`r`n=== FEHLER ===`r`n")
            foreach ($error in $complianceInfo.Errors) {
                $this.ComplianceInfoBox.AppendText("  - $error`r`n")
            }
        }
        
        if ($complianceInfo.Warnings.Count -gt 0) {
            $this.ComplianceInfoBox.AppendText("`r`n=== WARNUNGEN ===`r`n")
            foreach ($warning in $complianceInfo.Warnings) {
                $this.ComplianceInfoBox.AppendText("  - $warning`r`n")
            }
        }
    }
    
    # Fenster anzeigen
    [void] Show() {
        [void]$this.Form.ShowDialog()
    }
}
