using namespace System.Windows.Forms
using namespace System.Drawing

class MainWindow : Form {
    # ============================================
    # GUI Controls
    # ============================================
    [TabControl]$TabControl
    [ToolStripProgressBar]$ProgressBar
    [ToolStripStatusLabel]$StatusLabel
    [MenuStrip]$MenuStrip
    [Button]$StartButton
    
    # Dashboard Tab
    [GroupBox]$SystemCard
    [GroupBox]$NetworkCard
    [GroupBox]$ComplianceCard
    [Label]$SystemStatus
    [Label]$NetworkStatus
    [Label]$ComplianceStatus
    
    # Details Tabs
    [RichTextBox]$SystemDetails
    [RichTextBox]$NetworkDetails
    [RichTextBox]$LogTextBox
    
    # ============================================
    # Constructor
    # ============================================
    MainWindow() {
        try {
            Write-Debug "[MainWindow] Initialisiere GUI..."
            
            # Store instance for closures
            $script:MainWindowInstance = $this
            
            # Form Setup
            $this.Text = "Sage 100 Server Check & Setup Tool v2.0"
            $this.Size = [Size]::new(1400, 900)
            $this.StartPosition = [FormStartPosition]::CenterScreen
            $this.MinimumSize = [Size]::new(1200, 700)
            $this.FormBorderStyle = [FormBorderStyle]::Sizable
            $this.BackColor = [Color]::FromArgb(240, 240, 240)
            
            # Initialize Controls
            $this.InitializeMenu()
            $this.InitializeHeader()
            $this.InitializeTabs()
            $this.InitializeStatusBar()
            
            Write-Debug "[MainWindow] GUI erfolgreich initialisiert"
        }
        catch {
            Write-Error "[MainWindow] FEHLER beim Initialisieren: $_"
            Write-Debug $_.ScriptStackTrace
            throw
        }
    }
    
    # ============================================
    # Menu Initialization
    # ============================================
    [void] InitializeMenu() {
        $this.MenuStrip = [MenuStrip]::new()
        
        # File Menu
        $fileMenu = [ToolStripMenuItem]::new("&Datei")
        $exportItem = [ToolStripMenuItem]::new("&Export Report", $null, {
            try {
                $script:MainWindowInstance.ExportReport()
            } catch {
                [MessageBox]::Show("Fehler beim Export: $_", "Fehler", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
            }
        })
        $exportItem.ShortcutKeys = [Keys]::Control -bor [Keys]::E
        $fileMenu.DropDownItems.Add($exportItem)
        $fileMenu.DropDownItems.Add([ToolStripSeparator]::new())
        
        $exitItem = [ToolStripMenuItem]::new("&Beenden", $null, {
            $script:MainWindowInstance.Close()
        })
        $exitItem.ShortcutKeys = [Keys]::Alt -bor [Keys]::F4
        $fileMenu.DropDownItems.Add($exitItem)
        
        # Help Menu
        $helpMenu = [ToolStripMenuItem]::new("&Hilfe")
        $aboutItem = [ToolStripMenuItem]::new("Ü&ber...", $null, {
            [MessageBox]::Show(
                "Sage 100 Server Check & Setup Tool v2.0`n`n© 2024 - Professionelle Systemprüfung",
                "Über",
                [MessageBoxButtons]::OK,
                [MessageBoxIcon]::Information
            )
        })
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $this.MenuStrip.Items.Add($fileMenu)
        $this.MenuStrip.Items.Add($helpMenu)
        $this.Controls.Add($this.MenuStrip)
        $this.MainMenuStrip = $this.MenuStrip
    }
    
    # ============================================
    # Header Initialization
    # ============================================
    [void] InitializeHeader() {
        $headerPanel = [Panel]::new()
        $headerPanel.Dock = [DockStyle]::Top
        $headerPanel.Height = 80
        $headerPanel.BackColor = [Color]::FromArgb(0, 120, 215)
        $headerPanel.Padding = [Padding]::new(20, 10, 20, 10)
        
        # Title
        $title = [Label]::new()
        $title.Text = "Sage 100 Server Check Tool"
        $title.Font = [Font]::new("Segoe UI", 18, [FontStyle]::Bold)
        $title.ForeColor = [Color]::White
        $title.AutoSize = $true
        $title.Location = [Point]::new(20, 15)
        $headerPanel.Controls.Add($title)
        
        # Start Button
        $this.StartButton = [Button]::new()
        $this.StartButton.Text = "⚡ Vollständige Prüfung starten"
        $this.StartButton.Size = [Size]::new(250, 45)
        $this.StartButton.Location = [Point]::new(1100, 15)
        $this.StartButton.Anchor = [AnchorStyles]::Top -bor [AnchorStyles]::Right
        $this.StartButton.BackColor = [Color]::FromArgb(16, 185, 129)
        $this.StartButton.ForeColor = [Color]::White
        $this.StartButton.FlatStyle = [FlatStyle]::Flat
        $this.StartButton.Font = [Font]::new("Segoe UI", 10, [FontStyle]::Bold)
        $this.StartButton.Cursor = [Cursors]::Hand
        $this.StartButton.Add_Click({
            try {
                Write-Debug "[Button] Click-Event ausgelöst"
                $script:MainWindowInstance.RunFullCheck()
            }
            catch {
                Write-Error "[Button] FEHLER: $_"
                Write-Debug $_.ScriptStackTrace
                [MessageBox]::Show(
                    "Fehler beim Starten der Prüfung:`n`n$_`n`n$($_.ScriptStackTrace)",
                    "Fehler",
                    [MessageBoxButtons]::OK,
                    [MessageBoxIcon]::Error
                )
            }
        })
        $headerPanel.Controls.Add($this.StartButton)
        
        $this.Controls.Add($headerPanel)
    }
    
    # ============================================
    # Tabs Initialization
    # ============================================
    [void] InitializeTabs() {
        $this.TabControl = [TabControl]::new()
        $this.TabControl.Dock = [DockStyle]::Fill
        $this.TabControl.Font = [Font]::new("Segoe UI", 10)
        $this.TabControl.Padding = [Point]::new(10, 5)
        
        # Tab 1: Dashboard
        $dashboardTab = [TabPage]::new("📊 Dashboard")
        $dashboardTab.Padding = [Padding]::new(10)
        $dashboardTab.BackColor = [Color]::FromArgb(240, 240, 240)
        $this.InitializeDashboard($dashboardTab)
        $this.TabControl.TabPages.Add($dashboardTab)
        
        # Tab 2: System Details
        $systemTab = [TabPage]::new("🖥️ System-Details")
        $systemTab.Padding = [Padding]::new(10)
        $this.SystemDetails = [RichTextBox]::new()
        $this.SystemDetails.Dock = [DockStyle]::Fill
        $this.SystemDetails.Font = [Font]::new("Consolas", 9)
        $this.SystemDetails.ReadOnly = $true
        $this.SystemDetails.BackColor = [Color]::White
        $this.SystemDetails.Text = "Noch keine Prüfung durchgeführt.`n`nKlicken Sie auf 'Vollständige Prüfung starten'."
        $systemTab.Controls.Add($this.SystemDetails)
        $this.TabControl.TabPages.Add($systemTab)
        
        # Tab 3: Network Details
        $networkTab = [TabPage]::new("🌐 Netzwerk-Details")
        $networkTab.Padding = [Padding]::new(10)
        $this.NetworkDetails = [RichTextBox]::new()
        $this.NetworkDetails.Dock = [DockStyle]::Fill
        $this.NetworkDetails.Font = [Font]::new("Consolas", 9)
        $this.NetworkDetails.ReadOnly = $true
        $this.NetworkDetails.BackColor = [Color]::White
        $this.NetworkDetails.Text = "Noch keine Prüfung durchgeführt.`n`nKlicken Sie auf 'Vollständige Prüfung starten'."
        $networkTab.Controls.Add($this.NetworkDetails)
        $this.TabControl.TabPages.Add($networkTab)
        
        # Tab 4: Logs
        $logTab = [TabPage]::new("📝 Logs")
        $logTab.Padding = [Padding]::new(10)
        $this.LogTextBox = [RichTextBox]::new()
        $this.LogTextBox.Dock = [DockStyle]::Fill
        $this.LogTextBox.Font = [Font]::new("Consolas", 9)
        $this.LogTextBox.ReadOnly = $true
        $this.LogTextBox.BackColor = [Color]::FromArgb(30, 30, 30)
        $this.LogTextBox.ForeColor = [Color]::LimeGreen
        $this.LogTextBox.Text = "[$(Get-Date -Format 'HH:mm:ss')] Anwendung gestartet`n"
        $logTab.Controls.Add($this.LogTextBox)
        $this.TabControl.TabPages.Add($logTab)
        
        $this.Controls.Add($this.TabControl)
    }
    
    # ============================================
    # Dashboard Initialization
    # ============================================
    [void] InitializeDashboard([TabPage]$tab) {
        $panel = [FlowLayoutPanel]::new()
        $panel.Dock = [DockStyle]::Fill
        $panel.Padding = [Padding]::new(20)
        $panel.AutoScroll = $true
        
        # System Card
        $this.SystemCard = $this.CreateStatusCard(
            "System-Check",
            "Nicht geprüft",
            [Color]::Gray
        )
        $panel.Controls.Add($this.SystemCard)
        
        # Network Card
        $this.NetworkCard = $this.CreateStatusCard(
            "Netzwerk-Check",
            "Nicht geprüft",
            [Color]::Gray
        )
        $panel.Controls.Add($this.NetworkCard)
        
        # Compliance Card
        $this.ComplianceCard = $this.CreateStatusCard(
            "Compliance-Check",
            "Nicht geprüft",
            [Color]::Gray
        )
        $panel.Controls.Add($this.ComplianceCard)
        
        $tab.Controls.Add($panel)
    }
    
    # ============================================
    # Create Status Card
    # ============================================
    [GroupBox] CreateStatusCard([string]$title, [string]$status, [Color]$color) {
        $card = [GroupBox]::new()
        $card.Text = $title
        $card.Size = [Size]::new(380, 200)
        $card.Margin = [Padding]::new(10)
        $card.Padding = [Padding]::new(15)
        $card.Font = [Font]::new("Segoe UI", 11, [FontStyle]::Bold)
        $card.BackColor = [Color]::White
        
        $statusLabel = [Label]::new()
        $statusLabel.Text = $status
        $statusLabel.Font = [Font]::new("Segoe UI", 14)
        $statusLabel.ForeColor = $color
        $statusLabel.AutoSize = $false
        $statusLabel.Size = [Size]::new(350, 150)
        $statusLabel.TextAlign = [ContentAlignment]::MiddleCenter
        $statusLabel.Dock = [DockStyle]::Fill
        
        # Store reference
        switch ($title) {
            "System-Check" { $this.SystemStatus = $statusLabel }
            "Netzwerk-Check" { $this.NetworkStatus = $statusLabel }
            "Compliance-Check" { $this.ComplianceStatus = $statusLabel }
        }
        
        $card.Controls.Add($statusLabel)
        return $card
    }
    
    # ============================================
    # Status Bar Initialization
    # ============================================
    [void] InitializeStatusBar() {
        $statusStrip = [StatusStrip]::new()
        
        $this.StatusLabel = [ToolStripStatusLabel]::new()
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = [ContentAlignment]::MiddleLeft
        
        $this.ProgressBar = [ToolStripProgressBar]::new()
        $this.ProgressBar.Size = [Size]::new(200, 16)
        $this.ProgressBar.Visible = $false
        
        $statusStrip.Items.Add($this.StatusLabel)
        $statusStrip.Items.Add($this.ProgressBar)
        
        $this.Controls.Add($statusStrip)
    }
    
    # ============================================
    # Run Full Check
    # ============================================
    [void] RunFullCheck() {
        try {
            Write-Debug "[RunFullCheck] Starte vollständige Prüfung..."
            $this.AddLog("Starte vollständige Systemprüfung...")
            
            # Disable button
            $this.StartButton.Enabled = $false
            $this.ProgressBar.Visible = $true
            $this.ProgressBar.Value = 0
            
            # Reset status
            $this.SystemStatus.Text = "Wird geprüft..."
            $this.SystemStatus.ForeColor = [Color]::Orange
            $this.NetworkStatus.Text = "Wird geprüft..."
            $this.NetworkStatus.ForeColor = [Color]::Orange
            $this.ComplianceStatus.Text = "Wird geprüft..."
            $this.ComplianceStatus.ForeColor = [Color]::Orange
            
            # System Check
            $this.StatusLabel.Text = "Führe System-Check durch..."
            $this.ProgressBar.Value = 10
            $systemResult = Invoke-SystemCheck
            $this.UpdateSystemDetails($systemResult)
            $this.ProgressBar.Value = 40
            
            # Network Check
            $this.StatusLabel.Text = "Führe Netzwerk-Check durch..."
            $networkResult = Invoke-NetworkCheck
            $this.UpdateNetworkDetails($networkResult)
            $this.ProgressBar.Value = 70
            
            # Compliance Check
            $this.StatusLabel.Text = "Führe Compliance-Check durch..."
            $complianceResult = Invoke-ComplianceCheck
            $this.UpdateComplianceStatus($complianceResult)
            $this.ProgressBar.Value = 100
            
            # Update Dashboard
            $this.SystemStatus.Text = "✅ Erfolgreich geprüft"
            $this.SystemStatus.ForeColor = [Color]::Green
            $this.NetworkStatus.Text = "✅ Erfolgreich geprüft"
            $this.NetworkStatus.ForeColor = [Color]::Green
            $this.ComplianceStatus.Text = "✅ Erfolgreich geprüft"
            $this.ComplianceStatus.ForeColor = [Color]::Green
            
            $this.StatusLabel.Text = "Prüfung abgeschlossen"
            $this.AddLog("✅ Prüfung erfolgreich abgeschlossen")
            
            # Re-enable button
            $this.StartButton.Enabled = $true
            $this.ProgressBar.Visible = $false
        }
        catch {
            Write-Error "[RunFullCheck] FEHLER: $_"
            $this.AddLog("❌ FEHLER: $_")
            $this.StatusLabel.Text = "Fehler bei der Prüfung"
            $this.StartButton.Enabled = $true
            $this.ProgressBar.Visible = $false
            
            [MessageBox]::Show(
                "Fehler bei der Prüfung:`n`n$_",
                "Fehler",
                [MessageBoxButtons]::OK,
                [MessageBoxIcon]::Error
            )
        }
    }
    
    # ============================================
    # Update Details
    # ============================================
    [void] UpdateSystemDetails($result) {
        $text = @"
═══════════════════════════════════════════════════════
   SYSTEM-INFORMATIONEN
═══════════════════════════════════════════════════════

Betriebssystem:    $($result.OS.Name)
Version:           $($result.OS.Version)
Build:             $($result.OS.BuildNumber)

Prozessor:         $($result.CPU.Name)
Kerne:             $($result.CPU.Cores)
Logische Prozessoren: $($result.CPU.LogicalProcessors)

Arbeitsspeicher:   $($result.Memory.TotalGB) GB
Verfügbar:         $($result.Memory.AvailableGB) GB

.NET Framework:    $($result.DotNet.Version)
PowerShell:        $($result.PowerShell.Version)

═══════════════════════════════════════════════════════
   FESTPLATTEN
═══════════════════════════════════════════════════════

"@
        foreach ($disk in $result.Disks) {
            $text += "Laufwerk $($disk.Drive)`n"
            $text += "  Gesamt:     $($disk.TotalGB) GB`n"
            $text += "  Frei:       $($disk.FreeGB) GB`n"
            $text += "  Verwendet:  $($disk.UsedPercent)%`n`n"
        }
        
        $this.SystemDetails.Text = $text
    }
    
    [void] UpdateNetworkDetails($result) {
        $text = @"
═══════════════════════════════════════════════════════
   NETZWERK-KONFIGURATION
═══════════════════════════════════════════════════════

"@
        foreach ($adapter in $result.Adapters) {
            $text += "Adapter: $($adapter.Name)`n"
            $text += "  IP:        $($adapter.IPAddress)`n"
            $text += "  Subnet:    $($adapter.SubnetMask)`n"
            $text += "  Gateway:   $($adapter.Gateway)`n"
            $text += "  DNS:       $($adapter.DNS -join ', ')`n"
            $text += "  Status:    $($adapter.Status)`n`n"
        }
        
        $text += @"

═══════════════════════════════════════════════════════
   PORT-STATUS
═══════════════════════════════════════════════════════

"@
        foreach ($port in $result.Ports) {
            $status = if ($port.IsOpen) { "✅ OFFEN" } else { "❌ GESCHLOSSEN" }
            $text += "$($port.Port) ($($port.Description)): $status`n"
        }
        
        $this.NetworkDetails.Text = $text
    }
    
    [void] UpdateComplianceStatus($result) {
        # Just update the card status - details go to logs
        $this.AddLog("Compliance-Check durchgeführt")
    }
    
    # ============================================
    # Logging
    # ============================================
    [void] AddLog([string]$message) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $this.LogTextBox.AppendText("[$timestamp] $message`n")
        $this.LogTextBox.ScrollToCaret()
    }
    
    # ============================================
    # Export Report
    # ============================================
    [void] ExportReport() {
        try {
            $saveDialog = [SaveFileDialog]::new()
            $saveDialog.Filter = "HTML Dateien (*.html)|*.html|Text Dateien (*.txt)|*.txt"
            $saveDialog.FileName = "Sage100-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            
            if ($saveDialog.ShowDialog() -eq [DialogResult]::OK) {
                $content = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Sage 100 Server Check Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #0078d7; border-bottom: 3px solid #0078d7; padding-bottom: 10px; }
        h2 { color: #333; margin-top: 30px; border-bottom: 2px solid #ddd; padding-bottom: 5px; }
        pre { background: #f8f8f8; padding: 15px; border-left: 4px solid #0078d7; overflow-x: auto; }
        .timestamp { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Sage 100 Server Check Report</h1>
        <p class="timestamp">Erstellt am: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')</p>
        
        <h2>System-Details</h2>
        <pre>$($this.SystemDetails.Text)</pre>
        
        <h2>Netzwerk-Details</h2>
        <pre>$($this.NetworkDetails.Text)</pre>
        
        <h2>Logs</h2>
        <pre>$($this.LogTextBox.Text)</pre>
    </div>
</body>
</html>
"@
                [System.IO.File]::WriteAllText($saveDialog.FileName, $content, [System.Text.Encoding]::UTF8)
                [MessageBox]::Show("Report erfolgreich exportiert!`n`n$($saveDialog.FileName)", "Export erfolgreich", [MessageBoxButtons]::OK, [MessageBoxIcon]::Information)
                $this.AddLog("Report exportiert: $($saveDialog.FileName)")
            }
        }
        catch {
            [MessageBox]::Show("Fehler beim Export: $_", "Fehler", [MessageBoxButtons]::OK, [MessageBoxIcon]::Error)
        }
    }
}

# ============================================
# Export
# ============================================
Export-ModuleMember -Function * -Variable *
