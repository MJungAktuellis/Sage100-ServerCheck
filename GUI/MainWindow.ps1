# GUI/MainWindow.ps1
# Hauptfenster der Sage 100 Server Check GUI

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Importiere alle Module
Import-Module "$PSScriptRoot\..\Modules\SystemCheck.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\NetworkCheck.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\ComplianceCheck.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\WorkLog.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\DebugLogger.psm1" -Force
Import-Module "$PSScriptRoot\..\Modules\ReportGenerator.psm1" -Force

class Sage100GUI {
    [System.Windows.Forms.Form]$MainForm
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.ProgressBar]$ProgressBar
    [System.Windows.Forms.Label]$StatusLabel
    [hashtable]$Results = @{}
    
    Sage100GUI() {
        Initialize-DebugLogger
        Start-DebugAction -FunctionName "GUI.Initialize" -Parameters @{ User = $env:USERNAME }
        
        $this.CreateMainForm()
        $this.CreateMenuBar()
        $this.CreateTabControl()
        $this.CreateStatusBar()
        $this.CreateDashboardTab()
        $this.CreateSystemTab()
        $this.CreateNetworkTab()
        $this.CreateComplianceTab()
        $this.CreateLogsTab()
        
        Complete-DebugAction -Status "Success"
    }
    
    [void]CreateMainForm() {
        $this.MainForm = New-Object System.Windows.Forms.Form
        $this.MainForm.Text = "Sage 100 Server Check & Setup Tool"
        $this.MainForm.Size = New-Object System.Drawing.Size(1200, 800)
        $this.MainForm.StartPosition = "CenterScreen"
        $this.MainForm.FormBorderStyle = "FixedDialog"
        $this.MainForm.MaximizeBox = $true
        $this.MainForm.MinimizeBox = $true
        
        # Icon (falls vorhanden)
        # $this.MainForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$PSScriptRoot\..\icon.ico")
    }
    
    [void]CreateMenuBar() {
        $menuStrip = New-Object System.Windows.Forms.MenuStrip
        
        # Datei-Menü
        $fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Datei")
        
        $exportMarkdown = New-Object System.Windows.Forms.ToolStripMenuItem("Export Markdown-Report")
        $exportMarkdown.Add_Click({ $this.ExportMarkdownReport() })
        
        $exportJSON = New-Object System.Windows.Forms.ToolStripMenuItem("Export JSON-Snapshot")
        $exportJSON.Add_Click({ $this.ExportJSONSnapshot() })
        
        $exportDebugLog = New-Object System.Windows.Forms.ToolStripMenuItem("Export Debug-Log")
        $exportDebugLog.Add_Click({ $this.ExportDebugLog() })
        
        $exitMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Beenden")
        $exitMenu.Add_Click({ $this.MainForm.Close() })
        
        $fileMenu.DropDownItems.AddRange(@($exportMarkdown, $exportJSON, $exportDebugLog, 
            (New-Object System.Windows.Forms.ToolStripSeparator), $exitMenu))
        
        # Aktionen-Menü
        $actionsMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Aktionen")
        
        $fullCheck = New-Object System.Windows.Forms.ToolStripMenuItem("Vollständige Prüfung")
        $fullCheck.Add_Click({ $this.RunFullCheck() })
        
        $systemCheck = New-Object System.Windows.Forms.ToolStripMenuItem("Nur System-Check")
        $systemCheck.Add_Click({ $this.RunSystemCheck() })
        
        $networkCheck = New-Object System.Windows.Forms.ToolStripMenuItem("Nur Netzwerk-Check")
        $networkCheck.Add_Click({ $this.RunNetworkCheck() })
        
        $complianceCheck = New-Object System.Windows.Forms.ToolStripMenuItem("Nur Compliance-Check")
        $complianceCheck.Add_Click({ $this.RunComplianceCheck() })
        
        $actionsMenu.DropDownItems.AddRange(@($fullCheck, 
            (New-Object System.Windows.Forms.ToolStripSeparator),
            $systemCheck, $networkCheck, $complianceCheck))
        
        # Hilfe-Menü
        $helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem("&Hilfe")
        
        $about = New-Object System.Windows.Forms.ToolStripMenuItem("Über")
        $about.Add_Click({ $this.ShowAbout() })
        
        $helpMenu.DropDownItems.Add($about)
        
        $menuStrip.Items.AddRange(@($fileMenu, $actionsMenu, $helpMenu))
        $this.MainForm.Controls.Add($menuStrip)
        $this.MainForm.MainMenuStrip = $menuStrip
    }
    
    [void]CreateTabControl() {
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Location = New-Object System.Drawing.Point(10, 35)
        $this.TabControl.Size = New-Object System.Drawing.Size(1160, 670)
        $this.TabControl.Anchor = "Top,Bottom,Left,Right"
        $this.MainForm.Controls.Add($this.TabControl)
    }
    
    [void]CreateStatusBar() {
        $statusStrip = New-Object System.Windows.Forms.StatusStrip
        
        $this.StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $this.StatusLabel.Spring = $true
        $this.StatusLabel.TextAlign = "MiddleLeft"
        
        $this.ProgressBar = New-Object System.Windows.Forms.ToolStripProgressBar
        $this.ProgressBar.Size = New-Object System.Drawing.Size(200, 16)
        
        $statusStrip.Items.AddRange(@($this.StatusLabel, $this.ProgressBar))
        $this.MainForm.Controls.Add($statusStrip)
    }
    
    [void]CreateDashboardTab() {
        $dashboardTab = New-Object System.Windows.Forms.TabPage
        $dashboardTab.Text = "Dashboard"
        $dashboardTab.BackColor = [System.Drawing.Color]::White
        
        # Titel
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "Sage 100 Server Check - Dashboard"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
        $titleLabel.Size = New-Object System.Drawing.Size(600, 40)
        $dashboardTab.Controls.Add($titleLabel)
        
        # Start-Button
        $startButton = New-Object System.Windows.Forms.Button
        $startButton.Text = "Vollständige Prüfung starten"
        $startButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $startButton.Location = New-Object System.Drawing.Point(20, 80)
        $startButton.Size = New-Object System.Drawing.Size(300, 50)
        $startButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 212)
        $startButton.ForeColor = [System.Drawing.Color]::White
        $startButton.FlatStyle = "Flat"
        $startButton.Add_Click({ $this.RunFullCheck() })
        $dashboardTab.Controls.Add($startButton)
        
        # Status-Karten
        $yPos = 150
        
        # System-Status Karte
        $systemCard = $this.CreateStatusCard("System", "Noch nicht geprüft", "Gray", 20, $yPos)
        $dashboardTab.Controls.Add($systemCard)
        
        # Netzwerk-Status Karte
        $networkCard = $this.CreateStatusCard("Netzwerk", "Noch nicht geprüft", "Gray", 400, $yPos)
        $dashboardTab.Controls.Add($networkCard)
        
        # Compliance-Status Karte
        $complianceCard = $this.CreateStatusCard("Compliance", "Noch nicht geprüft", "Gray", 780, $yPos)
        $dashboardTab.Controls.Add($complianceCard)
        
        $this.TabControl.TabPages.Add($dashboardTab)
    }
    
    [System.Windows.Forms.Panel]CreateStatusCard([string]$title, [string]$status, [string]$color, [int]$x, [int]$y) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Location = New-Object System.Drawing.Point($x, $y)
        $card.Size = New-Object System.Drawing.Size(350, 120)
        $card.BorderStyle = "FixedSingle"
        $card.BackColor = [System.Drawing.Color]::White
        
        # Titel
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
        $titleLabel.Size = New-Object System.Drawing.Size(330, 30)
        $card.Controls.Add($titleLabel)
        
        # Status
        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Text = $status
        $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $statusLabel.Location = New-Object System.Drawing.Point(10, 50)
        $statusLabel.Size = New-Object System.Drawing.Size(330, 25)
        $statusLabel.Name = "${title}StatusLabel"
        $card.Controls.Add($statusLabel)
        
        # Farbindikator
        $indicator = New-Object System.Windows.Forms.Panel
        $indicator.Size = New-Object System.Drawing.Size(330, 5)
        $indicator.Location = New-Object System.Drawing.Point(10, 105)
        $indicator.BackColor = [System.Drawing.Color]::$color
        $indicator.Name = "${title}Indicator"
        $card.Controls.Add($indicator)
        
        return $card
    }
    
    [void]CreateSystemTab() {
        $systemTab = New-Object System.Windows.Forms.TabPage
        $systemTab.Text = "System-Info"
        $systemTab.BackColor = [System.Drawing.Color]::White
        
        # RichTextBox für System-Details
        $systemTextBox = New-Object System.Windows.Forms.RichTextBox
        $systemTextBox.Location = New-Object System.Drawing.Point(10, 50)
        $systemTextBox.Size = New-Object System.Drawing.Size(1120, 550)
        $systemTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $systemTextBox.ReadOnly = $true
        $systemTextBox.Name = "SystemTextBox"
        $systemTab.Controls.Add($systemTextBox)
        
        # Refresh-Button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Text = "System-Info aktualisieren"
        $refreshButton.Location = New-Object System.Drawing.Point(10, 10)
        $refreshButton.Size = New-Object System.Drawing.Size(200, 30)
        $refreshButton.Add_Click({ $this.RunSystemCheck() })
        $systemTab.Controls.Add($refreshButton)
        
        $this.TabControl.TabPages.Add($systemTab)
    }
    
    [void]CreateNetworkTab() {
        $networkTab = New-Object System.Windows.Forms.TabPage
        $networkTab.Text = "Netzwerk & Firewall"
        $networkTab.BackColor = [System.Drawing.Color]::White
        
        # RichTextBox für Netzwerk-Details
        $networkTextBox = New-Object System.Windows.Forms.RichTextBox
        $networkTextBox.Location = New-Object System.Drawing.Point(10, 50)
        $networkTextBox.Size = New-Object System.Drawing.Size(1120, 550)
        $networkTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $networkTextBox.ReadOnly = $true
        $networkTextBox.Name = "NetworkTextBox"
        $networkTab.Controls.Add($networkTextBox)
        
        # Refresh-Button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Text = "Netzwerk prüfen"
        $refreshButton.Location = New-Object System.Drawing.Point(10, 10)
        $refreshButton.Size = New-Object System.Drawing.Size(200, 30)
        $refreshButton.Add_Click({ $this.RunNetworkCheck() })
        $networkTab.Controls.Add($refreshButton)
        
        $this.TabControl.TabPages.Add($networkTab)
    }
    
    [void]CreateComplianceTab() {
        $complianceTab = New-Object System.Windows.Forms.TabPage
        $complianceTab.Text = "Compliance-Check"
        $complianceTab.BackColor = [System.Drawing.Color]::White
        
        # RichTextBox für Compliance-Details
        $complianceTextBox = New-Object System.Windows.Forms.RichTextBox
        $complianceTextBox.Location = New-Object System.Drawing.Point(10, 50)
        $complianceTextBox.Size = New-Object System.Drawing.Size(1120, 550)
        $complianceTextBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $complianceTextBox.ReadOnly = $true
        $complianceTextBox.Name = "ComplianceTextBox"
        $complianceTab.Controls.Add($complianceTextBox)
        
        # Refresh-Button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Text = "Compliance prüfen"
        $refreshButton.Location = New-Object System.Drawing.Point(10, 10)
        $refreshButton.Size = New-Object System.Drawing.Size(200, 30)
        $refreshButton.Add_Click({ $this.RunComplianceCheck() })
        $complianceTab.Controls.Add($refreshButton)
        
        $this.TabControl.TabPages.Add($complianceTab)
    }
    
    [void]CreateLogsTab() {
        $logsTab = New-Object System.Windows.Forms.TabPage
        $logsTab.Text = "Debug-Logs"
        $logsTab.BackColor = [System.Drawing.Color]::White
        
        # RichTextBox für Logs
        $logsTextBox = New-Object System.Windows.Forms.RichTextBox
        $logsTextBox.Location = New-Object System.Drawing.Point(10, 50)
        $logsTextBox.Size = New-Object System.Drawing.Size(1120, 550)
        $logsTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $logsTextBox.ReadOnly = $true
        $logsTextBox.Name = "LogsTextBox"
        $logsTab.Controls.Add($logsTextBox)
        
        # Refresh-Button
        $refreshButton = New-Object System.Windows.Forms.Button
        $refreshButton.Text = "Logs aktualisieren"
        $refreshButton.Location = New-Object System.Drawing.Point(10, 10)
        $refreshButton.Size = New-Object System.Drawing.Size(200, 30)
        $refreshButton.Add_Click({ $this.RefreshLogs() })
        $logsTab.Controls.Add($refreshButton)
        
        $this.TabControl.TabPages.Add($logsTab)
    }
    
    # Action-Methoden
    [void]RunFullCheck() {
        Start-DebugAction -FunctionName "GUI.RunFullCheck" -Parameters @{}
        
        $this.StatusLabel.Text = "Führe vollständige Prüfung durch..."
        $this.ProgressBar.Value = 0
        
        try {
            # System-Check (33%)
            $this.ProgressBar.Value = 10
            $this.RunSystemCheck()
            $this.ProgressBar.Value = 33
            
            # Netzwerk-Check (66%)
            $this.RunNetworkCheck()
            $this.ProgressBar.Value = 66
            
            # Compliance-Check (100%)
            $this.RunComplianceCheck()
            $this.ProgressBar.Value = 100
            
            $this.StatusLabel.Text = "Vollständige Prüfung abgeschlossen"
            [System.Windows.Forms.MessageBox]::Show("Alle Checks wurden erfolgreich durchgeführt.", "Erfolg", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Complete-DebugAction -Status "Success"
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler bei der Prüfung: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
        finally {
            $this.ProgressBar.Value = 0
        }
    }
    
    [void]RunSystemCheck() {
        Start-DebugAction -FunctionName "GUI.RunSystemCheck" -Parameters @{}
        
        $this.StatusLabel.Text = "Sammle System-Informationen..."
        
        try {
            $systemInfo = Get-SystemInfo
            $this.Results["System"] = $systemInfo
            
            # Update Dashboard-Karte
            $dashboardTab = $this.TabControl.TabPages[0]
            $statusLabel = $dashboardTab.Controls.Find("SystemStatusLabel", $true)[0]
            $indicator = $dashboardTab.Controls.Find("SystemIndicator", $true)[0]
            
            if ($systemInfo) {
                $statusLabel.Text = "✓ Erfolgreich geprüft"
                $indicator.BackColor = [System.Drawing.Color]::Green
            }
            
            # Update System-Tab
            $systemTab = $this.TabControl.TabPages[1]
            $textBox = $systemTab.Controls.Find("SystemTextBox", $true)[0]
            $textBox.Clear()
            
            $textBox.AppendText("=== SYSTEM-INFORMATIONEN ===`n`n")
            $textBox.AppendText("Computer: $($systemInfo.ComputerName)`n")
            $textBox.AppendText("OS: $($systemInfo.OSVersion)`n")
            $textBox.AppendText("Prozessor: $($systemInfo.ProcessorName)`n")
            $textBox.AppendText("Kerne: $($systemInfo.LogicalProcessors)`n")
            $textBox.AppendText("RAM: $($systemInfo.TotalRAMGB) GB`n")
            $textBox.AppendText("Freier RAM: $($systemInfo.FreeRAMGB) GB`n`n")
            
            $textBox.AppendText("=== FESTPLATTEN ===`n")
            foreach ($disk in $systemInfo.Disks) {
                $textBox.AppendText("`n$($disk.DeviceID)`n")
                $textBox.AppendText("  Größe: $($disk.SizeGB) GB`n")
                $textBox.AppendText("  Frei: $($disk.FreeSpaceGB) GB ($($disk.FreeSpacePercent)%)`n")
            }
            
            $this.StatusLabel.Text = "System-Check abgeschlossen"
            Complete-DebugAction -Status "Success" -Result $systemInfo
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim System-Check: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]RunNetworkCheck() {
        Start-DebugAction -FunctionName "GUI.RunNetworkCheck" -Parameters @{}
        
        $this.StatusLabel.Text = "Prüfe Netzwerk & Firewall..."
        
        try {
            $networkInfo = Test-NetworkConnectivity
            $this.Results["Network"] = $networkInfo
            
            # Update Dashboard-Karte
            $dashboardTab = $this.TabControl.TabPages[0]
            $statusLabel = $dashboardTab.Controls.Find("NetworkStatusLabel", $true)[0]
            $indicator = $dashboardTab.Controls.Find("NetworkIndicator", $true)[0]
            
            if ($networkInfo) {
                $statusLabel.Text = "✓ Erfolgreich geprüft"
                $indicator.BackColor = [System.Drawing.Color]::Green
            }
            
            # Update Netzwerk-Tab
            $networkTab = $this.TabControl.TabPages[2]
            $textBox = $networkTab.Controls.Find("NetworkTextBox", $true)[0]
            $textBox.Clear()
            
            $textBox.AppendText("=== NETZWERK-KONFIGURATION ===`n`n")
            foreach ($adapter in $networkInfo.Adapters) {
                $textBox.AppendText("$($adapter.Name)`n")
                $textBox.AppendText("  IP: $($adapter.IPAddress)`n")
                $textBox.AppendText("  Subnet: $($adapter.SubnetMask)`n")
                $textBox.AppendText("  Gateway: $($adapter.DefaultGateway)`n")
                $textBox.AppendText("  DNS: $($adapter.DNSServers -join ', ')`n`n")
            }
            
            $textBox.AppendText("`n=== KONNEKTIVITÄTS-TESTS ===`n")
            foreach ($test in $networkInfo.ConnectivityTests) {
                $status = if ($test.Success) { "✓" } else { "✗" }
                $textBox.AppendText("$status $($test.Target):$($test.Port) - $($test.ResponseTime)ms`n")
            }
            
            $this.StatusLabel.Text = "Netzwerk-Check abgeschlossen"
            Complete-DebugAction -Status "Success" -Result $networkInfo
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Netzwerk-Check: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]RunComplianceCheck() {
        Start-DebugAction -FunctionName "GUI.RunComplianceCheck" -Parameters @{}
        
        $this.StatusLabel.Text = "Prüfe Sage 100 Voraussetzungen..."
        
        try {
            $complianceInfo = Test-Sage100Compliance
            $this.Results["Compliance"] = $complianceInfo
            
            # Update Dashboard-Karte
            $dashboardTab = $this.TabControl.TabPages[0]
            $statusLabel = $dashboardTab.Controls.Find("ComplianceStatusLabel", $true)[0]
            $indicator = $dashboardTab.Controls.Find("ComplianceIndicator", $true)[0]
            
            $passedCount = ($complianceInfo.Checks | Where-Object { $_.Status -eq "Pass" }).Count
            $totalCount = $complianceInfo.Checks.Count
            
            $statusLabel.Text = "✓ $passedCount/$totalCount Tests bestanden"
            
            if ($passedCount -eq $totalCount) {
                $indicator.BackColor = [System.Drawing.Color]::Green
            }
            elseif ($passedCount -gt $totalCount / 2) {
                $indicator.BackColor = [System.Drawing.Color]::Orange
            }
            else {
                $indicator.BackColor = [System.Drawing.Color]::Red
            }
            
            # Update Compliance-Tab
            $complianceTab = $this.TabControl.TabPages[3]
            $textBox = $complianceTab.Controls.Find("ComplianceTextBox", $true)[0]
            $textBox.Clear()
            
            $textBox.AppendText("=== SAGE 100 COMPLIANCE-CHECK ===`n`n")
            $textBox.AppendText("Ergebnis: $passedCount von $totalCount Tests bestanden`n`n")
            
            foreach ($check in $complianceInfo.Checks) {
                $icon = switch ($check.Status) {
                    "Pass" { "✓" }
                    "Fail" { "✗" }
                    "Warning" { "⚠" }
                    default { "?" }
                }
                
                $textBox.AppendText("$icon $($check.Name)`n")
                $textBox.AppendText("   Erwartet: $($check.Expected)`n")
                $textBox.AppendText("   Aktuell: $($check.Actual)`n")
                if ($check.Message) {
                    $textBox.AppendText("   Info: $($check.Message)`n")
                }
                $textBox.AppendText("`n")
            }
            
            $this.StatusLabel.Text = "Compliance-Check abgeschlossen"
            Complete-DebugAction -Status "Success" -Result $complianceInfo
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Compliance-Check: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]RefreshLogs() {
        $logsTab = $this.TabControl.TabPages[4]
        $textBox = $logsTab.Controls.Find("LogsTextBox", $true)[0]
        $textBox.Clear()
        
        $summary = Get-DebugLogSummary
        
        $textBox.AppendText("=== DEBUG-LOG ÜBERSICHT ===`n`n")
        $textBox.AppendText("Session-ID: $($summary.SessionId)`n")
        $textBox.AppendText("Start: $($summary.StartTime)`n")
        $textBox.AppendText("Laufzeit: $([Math]::Round($summary.TotalDurationSeconds, 2))s`n`n")
        
        $textBox.AppendText("Aktionen: $($summary.TotalActions)`n")
        $textBox.AppendText("  Erfolgreich: $($summary.SuccessfulActions)`n")
        $textBox.AppendText("  Fehler: $($summary.FailedActions)`n")
        $textBox.AppendText("  Warnungen: $($summary.Warnings)`n`n")
        
        if ($summary.SlowestActions.Count -gt 0) {
            $textBox.AppendText("=== LANGSAMSTE OPERATIONEN ===`n")
            foreach ($action in $summary.SlowestActions) {
                $textBox.AppendText("  $($action.Function): $($action.DurationMs)ms`n")
            }
            $textBox.AppendText("`n")
        }
        
        if ($summary.Errors.Count -gt 0) {
            $textBox.AppendText("=== FEHLER ===`n")
            foreach ($error in $summary.Errors) {
                $textBox.AppendText("`n[$($error.Timestamp)] $($error.Function)`n")
                $textBox.AppendText("  Fehler: $($error.Error.Message)`n")
                $textBox.AppendText("  Typ: $($error.Error.Type)`n")
            }
        }
    }
    
    # Export-Methoden
    [void]ExportMarkdownReport() {
        Start-DebugAction -FunctionName "GUI.ExportMarkdownReport" -Parameters @{}
        
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "Markdown files (*.md)|*.md"
            $saveDialog.DefaultExt = "md"
            $saveDialog.FileName = "Sage100_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
            
            if ($saveDialog.ShowDialog() -eq "OK") {
                $report = New-MarkdownReport -Results $this.Results
                $report | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
                
                [System.Windows.Forms.MessageBox]::Show("Markdown-Report wurde gespeichert unter:`n$($saveDialog.FileName)", 
                    "Export erfolgreich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                
                Complete-DebugAction -Status "Success" -Result @{ Path = $saveDialog.FileName }
            }
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]ExportJSONSnapshot() {
        Start-DebugAction -FunctionName "GUI.ExportJSONSnapshot" -Parameters @{}
        
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JSON files (*.json)|*.json"
            $saveDialog.DefaultExt = "json"
            $saveDialog.FileName = "Sage100_Snapshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            
            if ($saveDialog.ShowDialog() -eq "OK") {
                $snapshot = New-JSONSnapshot -Results $this.Results
                $snapshot | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
                
                [System.Windows.Forms.MessageBox]::Show("JSON-Snapshot wurde gespeichert unter:`n$($saveDialog.FileName)", 
                    "Export erfolgreich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                
                Complete-DebugAction -Status "Success" -Result @{ Path = $saveDialog.FileName }
            }
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]ExportDebugLog() {
        Start-DebugAction -FunctionName "GUI.ExportDebugLog" -Parameters @{}
        
        try {
            $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
            $saveDialog.Filter = "JSON files (*.json)|*.json"
            $saveDialog.DefaultExt = "json"
            $saveDialog.FileName = "Debug_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            
            if ($saveDialog.ShowDialog() -eq "OK") {
                Export-DebugLog -FilePath $saveDialog.FileName
                
                [System.Windows.Forms.MessageBox]::Show("Debug-Log wurde gespeichert unter:`n$($saveDialog.FileName)", 
                    "Export erfolgreich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                
                Complete-DebugAction -Status "Success" -Result @{ Path = $saveDialog.FileName }
            }
        }
        catch {
            Complete-DebugAction -Status "Error" -ErrorRecord $_
            [System.Windows.Forms.MessageBox]::Show("Fehler beim Export: $($_.Exception.Message)", "Fehler", 
                [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    [void]ShowAbout() {
        $aboutText = @"
Sage 100 Server Check & Setup Tool
Version 2.0

Entwickelt für die Überprüfung von Sage 100 Server-Voraussetzungen.

Features:
• System-Informationen sammeln
• Netzwerk & Firewall prüfen
• Compliance-Check (Sage 100 Requirements)
• Debug-Logging
• Export (Markdown, JSON)

© 2026 Marcel Jung
"@
        [System.Windows.Forms.MessageBox]::Show($aboutText, "Über Sage 100 Server Check", 
            [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    
    [void]Show() {
        [void]$this.MainForm.ShowDialog()
    }
}

# Initialisiere und starte GUI
$gui = [Sage100GUI]::new()
$gui.Show()
