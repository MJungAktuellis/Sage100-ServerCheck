# ===================================================================
# MainWindow.ps1 - VOLLSTÄNDIG ÜBERARBEITETE VERSION MIT TABCONTROL
# ===================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

class MainWindow {
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.RichTextBox]$SystemTextBox
    [System.Windows.Forms.RichTextBox]$NetworkTextBox
    [System.Windows.Forms.RichTextBox]$LogTextBox
    [System.Windows.Forms.Label]$SystemStatusLabel
    [System.Windows.Forms.Label]$NetworkStatusLabel
    [System.Windows.Forms.Label]$ComplianceStatusLabel
    [System.Windows.Forms.Button]$StartButton
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel

    MainWindow() {
        $this.InitializeForm()
        $this.CreateMenuBar()
        $this.CreateTabControl()
        $this.CreateStatusBar()
    }

    [void]InitializeForm() {
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Text = "Sage 100 Server Check & Setup Tool v2.0"
        $this.Form.Size = New-Object System.Drawing.Size(1400, 900)
        $this.Form.StartPosition = "CenterScreen"
        $this.Form.FormBorderStyle = "FixedSingle"
        $this.Form.MaximizeBox = $true
        $this.Form.MinimizeBox = $true
    }

    [void]CreateMenuBar() {
        $menuStrip = New-Object System.Windows.Forms.MenuStrip
        
        # Datei-Menü
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $fileMenu.Text = "Datei"
        
        $exportItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $exportItem.Text = "Bericht exportieren..."
        $exportItem.Add_Click({ $this.ExportReport() })
        
        $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $exitItem.Text = "Beenden"
        $exitItem.Add_Click({ $this.Form.Close() })
        
        $fileMenu.DropDownItems.Add($exportItem)
        $fileMenu.DropDownItems.Add($exitItem)
        
        # Hilfe-Menü
        $helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
        $helpMenu.Text = "Hilfe"
        
        $aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $aboutItem.Text = "Über..."
        $aboutItem.Add_Click({ $this.ShowAbout() })
        
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $menuStrip.Items.Add($fileMenu)
        $menuStrip.Items.Add($helpMenu)
        
        $this.Form.Controls.Add($menuStrip)
        $this.Form.MainMenuStrip = $menuStrip
    }

    [void]CreateTabControl() {
        # TabControl erstellen
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Location = New-Object System.Drawing.Point(0, 24)
        $this.TabControl.Size = New-Object System.Drawing.Size(1384, 815)
        $this.TabControl.Anchor = "Top,Bottom,Left,Right"
        
        # Tab 1: Dashboard
        $dashboardTab = New-Object System.Windows.Forms.TabPage
        $dashboardTab.Text = "Dashboard"
        $dashboardTab.BackColor = [System.Drawing.Color]::WhiteSmoke
        
        $this.CreateDashboardContent($dashboardTab)
        
        # Tab 2: System-Details
        $systemTab = New-Object System.Windows.Forms.TabPage
        $systemTab.Text = "System-Details"
        
        $this.SystemTextBox = New-Object System.Windows.Forms.RichTextBox
        $this.SystemTextBox.Dock = "Fill"
        $this.SystemTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $this.SystemTextBox.ReadOnly = $true
        $this.SystemTextBox.Text = "Noch keine Pruefung durchgefuehrt.`n`nKlicke auf 'Vollstaendige Pruefung starten' um Systemdaten zu sammeln."
        $systemTab.Controls.Add($this.SystemTextBox)
        
        # Tab 3: Netzwerk-Details
        $networkTab = New-Object System.Windows.Forms.TabPage
        $networkTab.Text = "Netzwerk-Details"
        
        $this.NetworkTextBox = New-Object System.Windows.Forms.RichTextBox
        $this.NetworkTextBox.Dock = "Fill"
        $this.NetworkTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $this.NetworkTextBox.ReadOnly = $true
        $this.NetworkTextBox.Text = "Noch keine Pruefung durchgefuehrt.`n`nKlicke auf 'Vollstaendige Pruefung starten' um Netzwerkdaten zu sammeln."
        $networkTab.Controls.Add($this.NetworkTextBox)
        
        # Tab 4: Logs
        $logTab = New-Object System.Windows.Forms.TabPage
        $logTab.Text = "Logs"
        
        $this.LogTextBox = New-Object System.Windows.Forms.RichTextBox
        $this.LogTextBox.Dock = "Fill"
        $this.LogTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.LogTextBox.ReadOnly = $true
        $this.LogTextBox.Text = "[$(Get-Date -Format 'HH:mm:ss')] GUI gestartet`n"
        $logTab.Controls.Add($this.LogTextBox)
        
        # Tabs hinzufügen
        $this.TabControl.TabPages.Add($dashboardTab)
        $this.TabControl.TabPages.Add($systemTab)
        $this.TabControl.TabPages.Add($networkTab)
        $this.TabControl.TabPages.Add($logTab)
        
        $this.Form.Controls.Add($this.TabControl)
    }

    [void]CreateDashboardContent([System.Windows.Forms.TabPage]$tab) {
        # Header-Panel
        $headerPanel = New-Object System.Windows.Forms.Panel
        $headerPanel.Height = 80
        $headerPanel.Dock = "Top"
        $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 102, 204)
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "Sage 100 Server Check Tool"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = [System.Drawing.Color]::White
        $titleLabel.Location = New-Object System.Drawing.Point(20, 15)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)
        
        # Start-Button
        $this.StartButton = New-Object System.Windows.Forms.Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Size = New-Object System.Drawing.Size(280, 45)
        $this.StartButton.Location = New-Object System.Drawing.Point(1070, 18)
        $this.StartButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 0)
        $this.StartButton.ForeColor = [System.Drawing.Color]::White
        $this.StartButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $this.StartButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $headerPanel.Controls.Add($this.StartButton)
        
        $tab.Controls.Add($headerPanel)
        
        # Dashboard-Inhalt Panel
        $dashPanel = New-Object System.Windows.Forms.Panel
        $dashPanel.Dock = "Fill"
        $dashPanel.Padding = New-Object System.Windows.Forms.Padding(20)
        
        # Status-Cards Panel
        $cardsPanel = New-Object System.Windows.Forms.Panel
        $cardsPanel.Location = New-Object System.Drawing.Point(20, 20)
        $cardsPanel.Size = New-Object System.Drawing.Size(1320, 250)
        
        # System-Card
        $systemCard = $this.CreateStatusCard("System-Check", "Nicht geprueft", 20)
        $this.SystemStatusLabel = $systemCard.Controls[1]
        $cardsPanel.Controls.Add($systemCard)
        
        # Netzwerk-Card
        $networkCard = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", 460)
        $this.NetworkStatusLabel = $networkCard.Controls[1]
        $cardsPanel.Controls.Add($networkCard)
        
        # Compliance-Card
        $complianceCard = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", 900)
        $this.ComplianceStatusLabel = $complianceCard.Controls[1]
        $cardsPanel.Controls.Add($complianceCard)
        
        $dashPanel.Controls.Add($cardsPanel)
        $tab.Controls.Add($dashPanel)
    }

    [System.Windows.Forms.Panel]CreateStatusCard([string]$title, [string]$status, [int]$xPos) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(400, 220)
        $card.Location = New-Object System.Drawing.Point($xPos, 0)
        $card.BackColor = [System.Drawing.Color]::White
        $card.BorderStyle = "FixedSingle"
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(15, 15)
        $titleLabel.AutoSize = $true
        $card.Controls.Add($titleLabel)
        
        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Text = $status
        $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
        $statusLabel.ForeColor = [System.Drawing.Color]::Gray
        $statusLabel.Location = New-Object System.Drawing.Point(15, 90)
        $statusLabel.Size = New-Object System.Drawing.Size(370, 110)
        $card.Controls.Add($statusLabel)
        
        return $card
    }

    [void]CreateStatusBar() {
        $statusStrip = New-Object System.Windows.Forms.StatusStrip
        
        $this.StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = "MiddleLeft"
        
        $this.ProgressBar = New-Object System.Windows.Forms.ToolStripProgressBar
        $this.ProgressBar.Size = New-Object System.Drawing.Size(200, 16)
        $this.ProgressBar.Visible = $false
        
        $statusStrip.Items.Add($this.StatusLabel)
        $statusStrip.Items.Add($this.ProgressBar)
        
        $this.Form.Controls.Add($statusStrip)
    }

    [void]UpdateSystemTab([hashtable]$data) {
        $text = @"
========================================
SYSTEM-INFORMATIONEN
========================================

Betriebssystem: $($data.SystemInfo.OS)
Prozessor: $($data.SystemInfo.CPU)
RAM: $($data.SystemInfo.RAM)
Festplatte: $($data.SystemInfo.Disk)
.NET Framework: $($data.SystemInfo.DotNet)
PowerShell: $($data.SystemInfo.PowerShell)

SQL Server Instanzen:
$($data.SystemInfo.SQLInstances -join "`n  ")

========================================
SAGE 100 KOMPATIBILITÄT
========================================

$($data.ComplianceResults)
"@
        $this.SystemTextBox.Text = $text
        $this.LogMessage("System-Tab aktualisiert")
    }

    [void]UpdateNetworkTab([hashtable]$data) {
        $text = @"
========================================
NETZWERK-KONFIGURATION
========================================

$($data.NetworkInfo)

========================================
PORT-STATUS
========================================

$($data.PortStatus)

========================================
FIREWALL-STATUS
========================================

$($data.FirewallStatus)
"@
        $this.NetworkTextBox.Text = $text
        $this.LogMessage("Netzwerk-Tab aktualisiert")
    }

    [void]UpdateStatus([string]$component, [string]$status, [string]$color) {
        switch ($component) {
            "System" {
                $this.SystemStatusLabel.Text = $status
                $this.SystemStatusLabel.ForeColor = [System.Drawing.Color]::FromName($color)
            }
            "Network" {
                $this.NetworkStatusLabel.Text = $status
                $this.NetworkStatusLabel.ForeColor = [System.Drawing.Color]::FromName($color)
            }
            "Compliance" {
                $this.ComplianceStatusLabel.Text = $status
                $this.ComplianceStatusLabel.ForeColor = [System.Drawing.Color]::FromName($color)
            }
        }
        $this.Form.Refresh()
    }

    [void]LogMessage([string]$message) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $this.LogTextBox.AppendText("[$timestamp] $message`n")
        $this.LogTextBox.ScrollToCaret()
    }

    [void]SetProgress([int]$value) {
        if ($value -eq 0) {
            $this.ProgressBar.Visible = $false
        } else {
            $this.ProgressBar.Visible = $true
            $this.ProgressBar.Value = $value
        }
        $this.Form.Refresh()
    }

    [void]SetStatus([string]$text) {
        $this.StatusLabel.Text = $text
        $this.Form.Refresh()
    }

    [void]ExportReport() {
        $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
        $saveDialog.Filter = "HTML Dateien (*.html)|*.html|Text Dateien (*.txt)|*.txt"
        $saveDialog.FileName = "Sage100_ServerCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        
        if ($saveDialog.ShowDialog() -eq "OK") {
            $this.LogMessage("Exportiere Bericht nach: $($saveDialog.FileName)")
            # Export-Logik hier implementieren
        }
    }

    [void]ShowAbout() {
        [System.Windows.Forms.MessageBox]::Show(
            "Sage 100 Server Check & Setup Tool`nVersion 2.0`n`nEntwickelt fuer die Pruefung von Sage 100 Serverumgebungen",
            "Über",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }

    [void]Show() {
        $this.Form.ShowDialog()
    }
}
