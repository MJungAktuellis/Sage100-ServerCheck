# MainWindow.ps1 - Grafische Oberflaeche fuer Sage 100 Server Check Tool
# Encoding: UTF-8 (NO BOM) - Umlaute vermeiden wegen PowerShell Parsing Issues

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Lade Module
$scriptRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$scriptRoot\Modules\SystemCheck.psm1" -Force
Import-Module "$scriptRoot\Modules\NetworkCheck.psm1" -Force
Import-Module "$scriptRoot\Modules\ComplianceCheck.psm1" -Force
Import-Module "$scriptRoot\Modules\WorkLog.psm1" -Force
Import-Module "$scriptRoot\Modules\ReportGenerator.psm1" -Force
Import-Module "$scriptRoot\Modules\DebugLogger.psm1" -Force

class MainWindow {
    [System.Windows.Forms.Form]$MainForm
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel
    
    # Constructor
    MainWindow() {
        $this.InitializeForm()
        $this.CreateMenuBar()
        $this.CreateTabs()
        $this.CreateStatusBar()
    }
    
    [void] InitializeForm() {
        $this.MainForm = New-Object System.Windows.Forms.Form
        $this.MainForm.Text = "Sage 100 Server Check & Setup Tool"
        $this.MainForm.Size = New-Object System.Drawing.Size(1200, 800)
        $this.MainForm.StartPosition = "CenterScreen"
        $this.MainForm.FormBorderStyle = "Sizable"
        $this.MainForm.MinimumSize = New-Object System.Drawing.Size(1000, 600)
        $this.MainForm.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    }
    
    [void] CreateMenuBar() {
        $menuStrip = New-Object System.Windows.Forms.MenuStrip
        
        # Datei-Menue
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Datei")
        $exportMdItem = New-Object System.Windows.Forms.ToolStripMenuItem("Export Markdown-Report")
        $exportJsonItem = New-Object System.Windows.Forms.ToolStripMenuItem("Export JSON-Snapshot")
        $exportLogItem = New-Object System.Windows.Forms.ToolStripMenuItem("Export Debug-Log")
        $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem("Beenden")
        
        # Event-Handler mit $window Variable
        $window = $this
        $exportMdItem.Add_Click({ $window.ExportMarkdown() })
        $exportJsonItem.Add_Click({ $window.ExportJSON() })
        $exportLogItem.Add_Click({ $window.ExportDebugLog() })
        $exitItem.Add_Click({ $window.MainForm.Close() })
        
        $fileMenu.DropDownItems.Add($exportMdItem)
        $fileMenu.DropDownItems.Add($exportJsonItem)
        $fileMenu.DropDownItems.Add($exportLogItem)
        $fileMenu.DropDownItems.Add("-")
        $fileMenu.DropDownItems.Add($exitItem)
        
        # Aktionen-Menue
        $actionsMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Aktionen")
        $fullCheckItem = New-Object System.Windows.Forms.ToolStripMenuItem("Vollstaendige Pruefung")
        $systemCheckItem = New-Object System.Windows.Forms.ToolStripMenuItem("Nur System-Check")
        $networkCheckItem = New-Object System.Windows.Forms.ToolStripMenuItem("Nur Netzwerk-Check")
        $complianceCheckItem = New-Object System.Windows.Forms.ToolStripMenuItem("Nur Compliance-Check")
        
        $fullCheckItem.Add_Click({ $window.RunFullCheck() })
        $systemCheckItem.Add_Click({ $window.RunSystemCheck() })
        $networkCheckItem.Add_Click({ $window.RunNetworkCheck() })
        $complianceCheckItem.Add_Click({ $window.RunComplianceCheck() })
        
        $actionsMenu.DropDownItems.Add($fullCheckItem)
        $actionsMenu.DropDownItems.Add($systemCheckItem)
        $actionsMenu.DropDownItems.Add($networkCheckItem)
        $actionsMenu.DropDownItems.Add($complianceCheckItem)
        
        # Hilfe-Menue
        $helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem("Hilfe")
        $aboutItem = New-Object System.Windows.Forms.ToolStripMenuItem("Ueber")
        $aboutItem.Add_Click({ $window.ShowAbout() })
        $helpMenu.DropDownItems.Add($aboutItem)
        
        $menuStrip.Items.Add($fileMenu)
        $menuStrip.Items.Add($actionsMenu)
        $menuStrip.Items.Add($helpMenu)
        
        $this.MainForm.MainMenuStrip = $menuStrip
        $this.MainForm.Controls.Add($menuStrip)
    }
    
    [void] CreateTabs() {
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        
        # Tab 1: Dashboard
        $dashboardTab = New-Object System.Windows.Forms.TabPage("Dashboard")
        $this.CreateDashboard($dashboardTab)
        
        # Tab 2: System-Info
        $systemTab = New-Object System.Windows.Forms.TabPage("System-Info")
        $this.CreateSystemTab($systemTab)
        
        # Tab 3: Netzwerk
        $networkTab = New-Object System.Windows.Forms.TabPage("Netzwerk und Firewall")
        $this.CreateNetworkTab($networkTab)
        
        # Tab 4: Compliance
        $complianceTab = New-Object System.Windows.Forms.TabPage("Compliance-Check")
        $this.CreateComplianceTab($complianceTab)
        
        # Tab 5: Debug-Logs
        $logTab = New-Object System.Windows.Forms.TabPage("Debug-Logs")
        $this.CreateLogTab($logTab)
        
        $this.TabControl.TabPages.Add($dashboardTab)
        $this.TabControl.TabPages.Add($systemTab)
        $this.TabControl.TabPages.Add($networkTab)
        $this.TabControl.TabPages.Add($complianceTab)
        $this.TabControl.TabPages.Add($logTab)
        
        $this.MainForm.Controls.Add($this.TabControl)
    }
    
    [void] CreateDashboard([System.Windows.Forms.TabPage]$tab) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Dock = "Fill"
        $panel.AutoScroll = $true
        $panel.Padding = New-Object System.Windows.Forms.Padding(20)
        
        # Titel
        $title = New-Object System.Windows.Forms.Label
        $title.Text = "Sage 100 Server Check - Dashboard"
        $title.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
        $title.Location = New-Object System.Drawing.Point(20, 20)
        $title.Size = New-Object System.Drawing.Size(800, 40)
        $panel.Controls.Add($title)
        
        # Status-Karten
        $yPos = 80
        $card1 = $this.CreateStatusCard("System", "Noch nicht geprueft", [System.Drawing.Color]::Gray)
        $card1.Name = "SystemCard"
        $card1.Location = New-Object System.Drawing.Point(20, $yPos)
        $panel.Controls.Add($card1)
        
        $card2 = $this.CreateStatusCard("Netzwerk", "Noch nicht geprueft", [System.Drawing.Color]::Gray)
        $card2.Name = "NetworkCard"
        $card2.Location = New-Object System.Drawing.Point(400, $yPos)
        $panel.Controls.Add($card2)
        
        $card3 = $this.CreateStatusCard("Compliance", "Noch nicht geprueft", [System.Drawing.Color]::Gray)
        $card3.Name = "ComplianceCard"
        $card3.Location = New-Object System.Drawing.Point(780, $yPos)
        $panel.Controls.Add($card3)
        
        # Start-Button
        $checkButton = New-Object System.Windows.Forms.Button
        $checkButton.Text = "Vollstaendige Pruefung starten"
        $checkButton.Size = New-Object System.Drawing.Size(300, 50)
        $checkButton.Location = New-Object System.Drawing.Point(400, 300)
        $checkButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $checkButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
        $checkButton.ForeColor = [System.Drawing.Color]::White
        $checkButton.FlatStyle = "Flat"
        
        # FIX: Event-Handler mit $window Variable
        $window = $this
        $checkButton.Add_Click({ $window.RunFullCheck() })
        
        $panel.Controls.Add($checkButton)
        $tab.Controls.Add($panel)
    }
    
    [System.Windows.Forms.Panel]CreateStatusCard([string]$title, [string]$status, [System.Drawing.Color]$color) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(350, 150)
        $card.BackColor = [System.Drawing.Color]::White
        $card.BorderStyle = "FixedSingle"
        
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(15, 15)
        $titleLabel.Size = New-Object System.Drawing.Size(320, 30)
        $card.Controls.Add($titleLabel)
        
        $cardStatusLabel = New-Object System.Windows.Forms.Label
        $cardStatusLabel.Name = "${title}StatusLabel"
        $cardStatusLabel.Text = $status
        $cardStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $cardStatusLabel.Location = New-Object System.Drawing.Point(15, 60)
        $cardStatusLabel.Size = New-Object System.Drawing.Size(320, 70)
        $cardStatusLabel.ForeColor = $color
        $card.Controls.Add($cardStatusLabel)
        
        return $card
    }
    
    [void] CreateSystemTab([System.Windows.Forms.TabPage]$tab) {
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "SystemInfoTextBox"
        $tab.Controls.Add($textBox)
    }
    
    [void] CreateNetworkTab([System.Windows.Forms.TabPage]$tab) {
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "NetworkInfoTextBox"
        $tab.Controls.Add($textBox)
    }
    
    [void] CreateComplianceTab([System.Windows.Forms.TabPage]$tab) {
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $textBox.ReadOnly = $true
        $textBox.Name = "ComplianceInfoTextBox"
        $tab.Controls.Add($textBox)
    }
    
    [void] CreateLogTab([System.Windows.Forms.TabPage]$tab) {
        $textBox = New-Object System.Windows.Forms.TextBox
        $textBox.Multiline = $true
        $textBox.ScrollBars = "Vertical"
        $textBox.Dock = "Fill"
        $textBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $textBox.ReadOnly = $true
        $textBox.Name = "DebugLogTextBox"
        $tab.Controls.Add($textBox)
    }
    
    [void] CreateStatusBar() {
        $statusStrip = New-Object System.Windows.Forms.StatusStrip
        
        $this.StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = "MiddleLeft"
        
        $this.ProgressBar = New-Object System.Windows.Forms.ToolStripProgressBar
        $this.ProgressBar.Size = New-Object System.Drawing.Size(200, 16)
        
        $statusStrip.Items.Add($this.StatusLabel)
        $statusStrip.Items.Add($this.ProgressBar)
        
        $this.MainForm.Controls.Add($statusStrip)
    }
    
    # === ACTION METHODS ===
    
    [void] RunFullCheck() {
        try {
            Start-DebugLog
            Write-DebugLog -Level "Info" -Message "Starte vollstaendige Pruefung (GUI)"
            
            $this.StatusLabel.Text = "Fuehre vollstaendige Pruefung durch..."
            $this.ProgressBar.Value = 0
            $this.ProgressBar.Maximum = 3
            
            # System-Check
            $this.RunSystemCheck()
            $this.ProgressBar.Value = 1
            
            # Network-Check
            $this.RunNetworkCheck()
            $this.ProgressBar.Value = 2
            
            # Compliance-Check
            $this.RunComplianceCheck()
            $this.ProgressBar.Value = 3
            
            $this.StatusLabel.Text = "Alle Checks abgeschlossen"
            [System.Windows.Forms.MessageBox]::Show("Alle Checks wurden erfolgreich durchgefuehrt.", "Erfolg", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Write-DebugLog -Level "Info" -Message "Vollstaendige Pruefung abgeschlossen"
        }
        catch {
            Write-DebugLog -Level "Error" -Message "Fehler bei vollstaendiger Pruefung" -Error $_
            [System.Windows.Forms.MessageBox]::Show("Fehler bei der Pruefung: $_", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void] RunSystemCheck() {
        try {
            $this.StatusLabel.Text = "Pruefe System-Informationen..."
            $systemInfo = Get-SystemInformation
            
            # Update Dashboard Card
            $dashboardTab = $this.TabControl.TabPages[0]
            $cardStatusLabel = $dashboardTab.Controls.Find("SystemStatusLabel", $true)[0]
            if ($cardStatusLabel) {
                $cardStatusLabel.Text = "Erfolgreich geprueft"
                $cardStatusLabel.ForeColor = [System.Drawing.Color]::Green
            }
            
            # Update System Tab
            $systemTab = $this.TabControl.TabPages[1]
            $textBox = $systemTab.Controls.Find("SystemInfoTextBox", $true)[0]
            if ($textBox) {
                $textBox.Clear()
                $textBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
                $textBox.AppendText("Computername: $($systemInfo.ComputerName)`r`n")
                $textBox.AppendText("Betriebssystem: $($systemInfo.OSName) ($($systemInfo.OSVersion))`r`n")
                $textBox.AppendText("CPU: $($systemInfo.ProcessorName) ($($systemInfo.NumberOfCores) Kerne)`r`n")
                $textBox.AppendText("RAM: $($systemInfo.TotalMemoryGB) GB`r`n")
                $textBox.AppendText(".NET Framework: $($systemInfo.DotNetVersion)`r`n")
                $textBox.AppendText("PowerShell: $($systemInfo.PowerShellVersion)`r`n`r`n")
                
                $textBox.AppendText("=== FESTPLATTEN ===`r`n")
                foreach ($disk in $systemInfo.Disks) {
                    $textBox.AppendText("$($disk.Drive): $($disk.FreeSpaceGB) GB frei von $($disk.TotalSizeGB) GB ($($disk.FreeSpacePercent) Prozent)`r`n")
                }
            }
            
            $this.StatusLabel.Text = "System-Check abgeschlossen"
            Write-DebugLog -Level "Info" -Message "System-Check erfolgreich"
        }
        catch {
            Write-DebugLog -Level "Error" -Message "Fehler beim System-Check" -Error $_
        }
    }
    
    [void] RunNetworkCheck() {
        try {
            $this.StatusLabel.Text = "Pruefe Netzwerk und Firewall..."
            $networkCheck = Test-NetworkConfiguration
            
            # Update Dashboard Card
            $dashboardTab = $this.TabControl.TabPages[0]
            $cardStatusLabel = $dashboardTab.Controls.Find("NetworkStatusLabel", $true)[0]
            if ($cardStatusLabel) {
                if ($networkCheck.HasErrors) {
                    $cardStatusLabel.Text = "Fehler gefunden"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Red
                } elseif ($networkCheck.HasWarnings) {
                    $cardStatusLabel.Text = "Warnungen vorhanden"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Orange
                } else {
                    $cardStatusLabel.Text = "Erfolgreich geprueft"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }
            }
            
            # Update Network Tab
            $networkTab = $this.TabControl.TabPages[2]
            $textBox = $networkTab.Controls.Find("NetworkInfoTextBox", $true)[0]
            if ($textBox) {
                $textBox.Clear()
                $textBox.AppendText("=== NETZWERK-ADAPTER ===`r`n")
                foreach ($adapter in $networkCheck.Adapters) {
                    $textBox.AppendText("$($adapter.Name) - $($adapter.IPAddress)`r`n")
                }
                
                $textBox.AppendText("`r`n=== PORT-STATUS ===`r`n")
                foreach ($port in $networkCheck.Ports) {
                    $status = if ($port.IsOpen) { "OFFEN" } else { "GESCHLOSSEN" }
                    $textBox.AppendText("Port $($port.Port) ($($port.Description)): $status`r`n")
                }
                
                $textBox.AppendText("`r`n=== KONNEKTIVITAETS-TESTS ===`r`n")
                foreach ($test in $networkCheck.ConnectivityTests) {
                    $status = if ($test.Success) { "OK" } else { "FEHLER" }
                    $textBox.AppendText("$($test.Target): $status`r`n")
                }
            }
            
            $this.StatusLabel.Text = "Netzwerk-Check abgeschlossen"
            Write-DebugLog -Level "Info" -Message "Netzwerk-Check erfolgreich"
        }
        catch {
            Write-DebugLog -Level "Error" -Message "Fehler beim Netzwerk-Check" -Error $_
        }
    }
    
    [void] RunComplianceCheck() {
        try {
            $this.StatusLabel.Text = "Pruefe Sage 100 Voraussetzungen..."
            $complianceCheck = Test-Sage100Compliance
            
            # Update Dashboard Card
            $dashboardTab = $this.TabControl.TabPages[0]
            $cardStatusLabel = $dashboardTab.Controls.Find("ComplianceStatusLabel", $true)[0]
            if ($cardStatusLabel) {
                if ($complianceCheck.HasErrors) {
                    $cardStatusLabel.Text = "$($complianceCheck.Errors.Count) Fehler gefunden"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Red
                } elseif ($complianceCheck.HasWarnings) {
                    $cardStatusLabel.Text = "$($complianceCheck.Warnings.Count) Warnungen"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Orange
                } else {
                    $cardStatusLabel.Text = "Alle Voraussetzungen erfuellt"
                    $cardStatusLabel.ForeColor = [System.Drawing.Color]::Green
                }
            }
            
            # Update Compliance Tab
            $complianceTab = $this.TabControl.TabPages[3]
            $textBox = $complianceTab.Controls.Find("ComplianceInfoTextBox", $true)[0]
            if ($textBox) {
                $textBox.Clear()
                $textBox.AppendText("=== SAGE 100 COMPLIANCE-CHECK ===`r`n`r`n")
                
                if ($complianceCheck.Errors.Count -gt 0) {
                    $textBox.AppendText("FEHLER:`r`n")
                    foreach ($error in $complianceCheck.Errors) {
                        $textBox.AppendText("  - $error`r`n")
                    }
                    $textBox.AppendText("`r`n")
                }
                
                if ($complianceCheck.Warnings.Count -gt 0) {
                    $textBox.AppendText("WARNUNGEN:`r`n")
                    foreach ($warning in $complianceCheck.Warnings) {
                        $textBox.AppendText("  - $warning`r`n")
                    }
                    $textBox.AppendText("`r`n")
                }
                
                if ($complianceCheck.Passed.Count -gt 0) {
                    $textBox.AppendText("ERFOLGREICH:`r`n")
                    foreach ($pass in $complianceCheck.Passed) {
                        $textBox.AppendText("  - $pass`r`n")
                    }
                }
            }
            
            $this.StatusLabel.Text = "Compliance-Check abgeschlossen"
            Write-DebugLog -Level "Info" -Message "Compliance-Check erfolgreich"
        }
        catch {
            Write-DebugLog -Level "Error" -Message "Fehler beim Compliance-Check" -Error $_
        }
    }
    
    [void] ExportMarkdown() {
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "Markdown Files (*.md)|*.md"
            $saveDialog.Title = "Markdown-Report speichern"
            $saveDialog.FileName = "Sage100-Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                New-MarkdownReport -OutputPath $saveDialog.FileName
                [System.Windows.Forms.MessageBox]::Show("Report erfolgreich gespeichert: $($saveDialog.FileName)", "Erfolg", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $_", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void] ExportJSON() {
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JSON Files (*.json)|*.json"
            $saveDialog.Title = "JSON-Snapshot speichern"
            $saveDialog.FileName = "Sage100-Snapshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                New-JSONSnapshot -OutputPath $saveDialog.FileName
                [System.Windows.Forms.MessageBox]::Show("Snapshot erfolgreich gespeichert: $($saveDialog.FileName)", "Erfolg", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $_", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void] ExportDebugLog() {
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JSON Files (*.json)|*.json"
            $saveDialog.Title = "Debug-Log speichern"
            $saveDialog.FileName = "Debug-Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            
            if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                Export-DebugLog -OutputPath $saveDialog.FileName
                [System.Windows.Forms.MessageBox]::Show("Debug-Log erfolgreich gespeichert: $($saveDialog.FileName)", "Erfolg", 
                    [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $_", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void] ShowAbout() {
        $aboutText = @"
Sage 100 Server Check & Setup Tool
Version 2.0

Ein umfassendes Tool zur Pruefung und Konfiguration
von Sage 100 Server-Umgebungen.

Features:
- System-Informationen sammeln
- Netzwerk- und Firewall-Pruefung
- Compliance-Check fuer Sage 100
- Automatische Konfiguration
- Debug-Logging
- Markdown- und JSON-Export

Entwickelt fuer Aktuellis GmbH
(c) 2026
"@
        [System.Windows.Forms.MessageBox]::Show($aboutText, "Ueber", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    
    [void] Show() {
        $this.MainForm.ShowDialog()
    }
}

# Export der Klasse
Export-ModuleMember -Function * -Variable *
