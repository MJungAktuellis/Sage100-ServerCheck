# GUI/MainWindow.ps1
# Hauptfenster der Sage 100 Server Check GUI - FINALE VERSION

using namespace System.Windows.Forms
using namespace System.Drawing

class MainWindow {
    [Form]$Form
    [TabControl]$TabControl
    [Button]$StartButton
    [MenuStrip]$MenuStrip
    [ToolStripProgressBar]$ProgressBar
    [ToolStripStatusLabel]$StatusLabel
    
    # Tab Content Controls
    [RichTextBox]$SystemDetailsBox
    [RichTextBox]$NetworkDetailsBox
    [RichTextBox]$LogBox
    
    # Status Cards
    [GroupBox]$SystemCard
    [GroupBox]$NetworkCard
    [GroupBox]$ComplianceCard
    
    MainWindow() {
        $this.InitializeComponents()
        # Event-Handler werden extern in Sage100-ServerCheck-GUI.ps1 registriert
    }
    
    [void]InitializeComponents() {
        # === HAUPTFENSTER ===
        $this.Form = New-Object Form
        $this.Form.Text = "Sage 100 Server Check & Setup Tool v2.0"
        $this.Form.Size = New-Object Size(1400, 900)
        $this.Form.StartPosition = "CenterScreen"
        $this.Form.MinimumSize = New-Object Size(1200, 700)
        
        # === MENU BAR ===
        $this.MenuStrip = New-Object MenuStrip
        
        $menuFile = New-Object ToolStripMenuItem("Datei")
        $menuExport = New-Object ToolStripMenuItem("Export Report")
        $menuExport.Add_Click({ $this.ExportReport() })
        $menuExit = New-Object ToolStripMenuItem("Beenden")
        $menuExit.Add_Click({ $this.Form.Close() })
        $menuFile.DropDownItems.Add($menuExport)
        $menuFile.DropDownItems.Add($menuExit)
        
        $menuHelp = New-Object ToolStripMenuItem("Hilfe")
        $menuAbout = New-Object ToolStripMenuItem("Ueber...")
        $menuAbout.Add_Click({ 
            [MessageBox]::Show("Sage 100 Server Check Tool v2.0`n`nProfessionelles Prueftool fuer Sage 100 Server", "Info") 
        })
        $menuHelp.DropDownItems.Add($menuAbout)
        
        $this.MenuStrip.Items.Add($menuFile)
        $this.MenuStrip.Items.Add($menuHelp)
        $this.Form.Controls.Add($this.MenuStrip)
        
        # === HEADER PANEL ===
        $headerPanel = New-Object Panel
        $headerPanel.Dock = "Top"
        $headerPanel.Height = 60
        $headerPanel.BackColor = [ColorTranslator]::FromHtml("#0078D4")
        $this.Form.Controls.Add($headerPanel)
        
        $titleLabel = New-Object Label
        $titleLabel.Text = "Sage 100 Server Check Tool"
        $titleLabel.ForeColor = [Color]::White
        $titleLabel.Font = New-Object Font("Segoe UI", 14, [FontStyle]::Bold)
        $titleLabel.Location = New-Object Point(20, 18)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)
        
        # Start Button (rechts im Header)
        $this.StartButton = New-Object Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Size = New-Object Size(280, 40)
        $this.StartButton.BackColor = [ColorTranslator]::FromHtml("#00CC00")
        $this.StartButton.ForeColor = [Color]::White
        $this.StartButton.Font = New-Object Font("Segoe UI", 10, [FontStyle]::Bold)
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $this.StartButton.Anchor = "Top,Right"
        $headerPanel.Controls.Add($this.StartButton)
        
        # Responsive Button-Position
        $headerPanel.Add_Resize({
            $this.StartButton.Location = New-Object Point(($headerPanel.Width - 300), 10)
        })
        $this.StartButton.Location = New-Object Point(($headerPanel.Width - 300), 10)
        
        # === TAB CONTROL ===
        $this.TabControl = New-Object TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object Font("Segoe UI", 10)
        $this.Form.Controls.Add($this.TabControl)
        
        $this.InitializeTabs()
        
        # === STATUS BAR ===
        $this.InitializeStatusBar()
    }
    
    [void]InitializeTabs() {
        # === TAB 1: DASHBOARD ===
        $dashboardTab = [TabPage]::new("Dashboard")
        $this.TabControl.Controls.Add($dashboardTab)
        $this.InitializeDashboard($dashboardTab)
        
        # === TAB 2: SYSTEM-DETAILS ===
        $systemTab = [TabPage]::new("System-Details")
        $this.TabControl.Controls.Add($systemTab)
        
        $this.SystemDetailsBox = New-Object RichTextBox
        $this.SystemDetailsBox.Dock = "Fill"
        $this.SystemDetailsBox.Font = New-Object Font("Consolas", 9)
        $this.SystemDetailsBox.ReadOnly = $true
        $this.SystemDetailsBox.BackColor = [Color]::White
        $this.SystemDetailsBox.Text = "Klicken Sie auf 'Vollstaendige Pruefung starten', um System-Details anzuzeigen."
        $systemTab.Controls.Add($this.SystemDetailsBox)
        
        # === TAB 3: NETZWERK-DETAILS ===
        $networkTab = [TabPage]::new("Netzwerk-Details")
        $this.TabControl.Controls.Add($networkTab)
        
        $this.NetworkDetailsBox = New-Object RichTextBox
        $this.NetworkDetailsBox.Dock = "Fill"
        $this.NetworkDetailsBox.Font = New-Object Font("Consolas", 9)
        $this.NetworkDetailsBox.ReadOnly = $true
        $this.NetworkDetailsBox.BackColor = [Color]::White
        $this.NetworkDetailsBox.Text = "Klicken Sie auf 'Vollstaendige Pruefung starten', um Netzwerk-Details anzuzeigen."
        $networkTab.Controls.Add($this.NetworkDetailsBox)
        
        # === TAB 4: LOGS ===
        $logTab = [TabPage]::new("Logs")
        $this.TabControl.Controls.Add($logTab)
        
        $this.LogBox = New-Object RichTextBox
        $this.LogBox.Dock = "Fill"
        $this.LogBox.Font = New-Object Font("Consolas", 9)
        $this.LogBox.ReadOnly = $true
        $this.LogBox.BackColor = [Color]::White
        $logTab.Controls.Add($this.LogBox)
    }
    
    [void]InitializeDashboard([TabPage]$tab) {
        # Container für Status-Cards
        $cardPanel = New-Object FlowLayoutPanel
        $cardPanel.Dock = "Fill"
        $cardPanel.Padding = New-Object Padding(20)
        $cardPanel.FlowDirection = "LeftToRight"
        $cardPanel.WrapContents = $true
        $tab.Controls.Add($cardPanel)
        
        # Status Cards erstellen
        $this.SystemCard = $this.CreateStatusCard("System-Check", "Nicht geprueft", [Color]::Gray)
        $this.NetworkCard = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", [Color]::Gray)
        $this.ComplianceCard = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", [Color]::Gray)
        
        $cardPanel.Controls.Add($this.SystemCard)
        $cardPanel.Controls.Add($this.NetworkCard)
        $cardPanel.Controls.Add($this.ComplianceCard)
    }
    
    [GroupBox]CreateStatusCard([string]$title, [string]$status, [Color]$statusColor) {
        $card = New-Object GroupBox
        $card.Text = $title
        $card.Size = New-Object Size(400, 180)
        $card.Font = New-Object Font("Segoe UI", 11, [FontStyle]::Bold)
        $card.Margin = New-Object Padding(10)
        
        $cardStatusLabel = New-Object Label
        $cardStatusLabel.Name = "StatusLabel"
        $cardStatusLabel.Text = $status
        $cardStatusLabel.ForeColor = $statusColor
        $cardStatusLabel.Font = New-Object Font("Segoe UI", 14, [FontStyle]::Bold)
        $cardStatusLabel.Location = New-Object Point(20, 40)
        $cardStatusLabel.AutoSize = $true
        $card.Controls.Add($cardStatusLabel)
        
        return $card
    }
    
    [void]InitializeStatusBar() {
        $statusBar = New-Object StatusStrip
        
        $this.StatusLabel = New-Object ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = "MiddleLeft"
        
        $this.ProgressBar = New-Object ToolStripProgressBar
        $this.ProgressBar.Size = New-Object Size(200, 16)
        $this.ProgressBar.Visible = $false
        
        $statusBar.Items.Add($this.StatusLabel)
        $statusBar.Items.Add($this.ProgressBar)
        
        $this.Form.Controls.Add($statusBar)
    }
    
    [void]RunFullCheck() {
        try {
            $this.LogBox.Clear()
            $this.AddLog("========================================", [Color]::Blue)
            $this.AddLog("  VOLLSTAENDIGE SYSTEMPRUEFUNG GESTARTET", [Color]::Blue)
            $this.AddLog("========================================`n", [Color]::Blue)
            
            $this.StatusLabel.Text = "Pruefung laeuft..."
            $this.ProgressBar.Visible = $true
            $this.ProgressBar.Value = 0
            $this.StartButton.Enabled = $false
            
            # === 1. SYSTEM-CHECK ===
            $this.AddLog("[1/3] Fuehre System-Check durch...`n", [Color]::DarkBlue)
            $this.UpdateCardStatus($this.SystemCard, "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Get-SystemInformation" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInformation
                $this.UpdateSystemTab($systemInfo)
                $this.AddLog("  [OK] System-Check erfolgreich`n", [Color]::Green)
                $this.UpdateCardStatus($this.SystemCard, "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("  [FEHLER] Modul 'Get-SystemInformation' nicht gefunden`n", [Color]::Red)
                $this.UpdateCardStatus($this.SystemCard, "Fehler", [Color]::Red)
            }
            
            $this.ProgressBar.Value = 33
            $this.Form.Refresh()
            
            # === 2. NETZWERK-CHECK ===
            $this.AddLog("`n[2/3] Fuehre Netzwerk-Check durch...`n", [Color]::DarkBlue)
            $this.UpdateCardStatus($this.NetworkCard, "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-NetworkConfiguration" -ErrorAction SilentlyContinue) {
                $networkInfo = Test-NetworkConfiguration
                $this.UpdateNetworkTab($networkInfo)
                $this.AddLog("  [OK] Netzwerk-Check erfolgreich`n", [Color]::Green)
                $this.UpdateCardStatus($this.NetworkCard, "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("  [FEHLER] Modul 'Test-NetworkConfiguration' nicht gefunden`n", [Color]::Red)
                $this.UpdateCardStatus($this.NetworkCard, "Fehler", [Color]::Red)
            }
            
            $this.ProgressBar.Value = 66
            $this.Form.Refresh()
            
            # === 3. COMPLIANCE-CHECK ===
            $this.AddLog("`n[3/3] Fuehre Compliance-Check durch...`n", [Color]::DarkBlue)
            $this.UpdateCardStatus($this.ComplianceCard, "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-Sage100Compliance" -ErrorAction SilentlyContinue) {
                $complianceInfo = Test-Sage100Compliance
                $this.AddLog("  [OK] Compliance-Check erfolgreich`n", [Color]::Green)
                $this.UpdateCardStatus($this.ComplianceCard, "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("  [FEHLER] Modul 'Test-Sage100Compliance' nicht gefunden`n", [Color]::Red)
                $this.UpdateCardStatus($this.ComplianceCard, "Fehler", [Color]::Red)
            }
            
            $this.ProgressBar.Value = 100
            
            $this.AddLog("`n========================================", [Color]::Blue)
            $this.AddLog("  PRUEFUNG ABGESCHLOSSEN", [Color]::Blue)
            $this.AddLog("========================================", [Color]::Blue)
            
            $this.StatusLabel.Text = "Pruefung abgeschlossen"
            
        } catch {
            $errorMsg = $_.Exception.Message
            $this.AddLog("`n[FEHLER] $errorMsg", [Color]::Red)
            $this.StatusLabel.Text = "Fehler bei Pruefung"
        } finally {
            $this.StartButton.Enabled = $true
            $this.ProgressBar.Visible = $false
        }
    }
    
    [void]UpdateSystemTab([hashtable]$data) {
        $this.SystemDetailsBox.Clear()
        $this.SystemDetailsBox.AppendText("=== SYSTEM-INFORMATIONEN ===`n`n")
        
        if ($data) {
            $this.SystemDetailsBox.AppendText("Computername: $($data.Computername)`n")
            $this.SystemDetailsBox.AppendText("Betriebssystem: $($data.OS)`n")
            $this.SystemDetailsBox.AppendText("CPU: $($data.CPU)`n")
            $this.SystemDetailsBox.AppendText("RAM: $($data.TotalRAM) GB`n")
            $this.SystemDetailsBox.AppendText(".NET Framework: $($data.DotNetVersion)`n")
            $this.SystemDetailsBox.AppendText("PowerShell: $($data.PSVersion)`n`n")
            
            $this.SystemDetailsBox.AppendText("=== FESTPLATTEN ===`n")
            foreach ($disk in $data.Disks) {
                $this.SystemDetailsBox.AppendText("Laufwerk $($disk.DeviceID) $([math]::Round($disk.Size / 1GB, 2)) GB gesamt`n")
                $this.SystemDetailsBox.AppendText("  Frei: $([math]::Round($disk.FreeSpace / 1GB, 2)) GB`n")
            }
        }
    }
    
    [void]UpdateNetworkTab([hashtable]$data) {
        $this.NetworkDetailsBox.Clear()
        $this.NetworkDetailsBox.AppendText("=== NETZWERK-KONFIGURATION ===`n`n")
        
        if ($data -and $data.Adapters) {
            foreach ($adapter in $data.Adapters) {
                $this.NetworkDetailsBox.AppendText("Adapter: $($adapter.Name)`n")
                $this.NetworkDetailsBox.AppendText("  IP: $($adapter.IPAddress)`n")
                $this.NetworkDetailsBox.AppendText("  Geschwindigkeit: $($adapter.Speed)`n`n")
            }
        }
        
        if ($data -and $data.Ports) {
            $this.NetworkDetailsBox.AppendText("`n=== PORT-STATUS ===`n")
            foreach ($port in $data.Ports) {
                $status = if ($port.Open) { "OFFEN" } else { "GESCHLOSSEN" }
                $this.NetworkDetailsBox.AppendText("Port $($port.Port) ($($port.Service)): $status`n")
            }
        }
    }
    
    [void]UpdateCardStatus([GroupBox]$card, [string]$newStatus, [Color]$color) {
        $cardStatusLabel = $card.Controls | Where-Object { $_.Name -eq "StatusLabel" }
        if ($cardStatusLabel) {
            $cardStatusLabel.Text = $newStatus
            $cardStatusLabel.ForeColor = $color
            $card.Refresh()
        }
    }
    
    [void]AddLog([string]$message, [Color]$color) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        $this.LogBox.SelectionStart = $this.LogBox.TextLength
        $this.LogBox.SelectionLength = 0
        $this.LogBox.SelectionColor = [Color]::Gray
        $this.LogBox.AppendText("[$timestamp] ")
        $this.LogBox.SelectionColor = $color
        $this.LogBox.AppendText("$message`n")
        $this.LogBox.ScrollToCaret()
        $this.Form.Refresh()
    }
    
    [void]ExportReport() {
        try {
            $saveDialog = New-Object SaveFileDialog
            $saveDialog.Filter = "HTML Datei (*.html)|*.html"
            $saveDialog.FileName = "Sage100-ServerCheck-Report-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
            
            if ($saveDialog.ShowDialog() -eq "OK") {
                if (Get-Command -Name "Export-HtmlReport" -ErrorAction SilentlyContinue) {
                    Export-HtmlReport -OutputPath $saveDialog.FileName
                    [MessageBox]::Show("Report erfolgreich exportiert nach:`n$($saveDialog.FileName)", "Export erfolgreich")
                } else {
                    [MessageBox]::Show("Export-Funktion nicht verfuegbar", "Fehler")
                }
            }
        } catch {
            [MessageBox]::Show("Fehler beim Export: $($_.Exception.Message)", "Fehler")
        }
    }
    
    [void]Show() {
        [void]$this.Form.ShowDialog()
    }
}
