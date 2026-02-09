# GUI/MainWindow.ps1
# Hauptfenster der Sage 100 Server Check GUI

using namespace System.Windows.Forms
using namespace System.Drawing

class MainWindow {
    [Form]$Form
    [TabControl]$TabControl
    [Button]$StartButton
    [ProgressBar]$ProgressBar
    [Label]$StatusLabel
    
    # TextBoxen fuer alle Tabs
    [RichTextBox]$SystemInfoBox
    [RichTextBox]$NetworkInfoBox
    [RichTextBox]$ComplianceInfoBox
    [RichTextBox]$LogsBox
    
    # Status-Cards
    [hashtable]$StatusCards = @{}
    [hashtable]$CheckResults = @{}
    
    MainWindow() {
        $this.InitializeComponents()
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
        $titleLabel.Font = New-Object Font("Segoe UI", 12, [FontStyle]::Bold)
        $titleLabel.Location = New-Object Point(15, 15)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)
        
        # Start-Button
        $this.StartButton = New-Object Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Size = New-Object Size(240, 35)
        $this.StartButton.BackColor = [ColorTranslator]::FromHtml("#00FF00")
        $this.StartButton.ForeColor = [Color]::Black
        $this.StartButton.Font = New-Object Font("Segoe UI", 9, [FontStyle]::Bold)
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Cursor = [Cursors]::Hand
        $this.StartButton.Anchor = "Top,Right"
        $headerPanel.Controls.Add($this.StartButton)
        
        # Responsive Button-Position
        $btn = $this.StartButton
        $headerPanel.Add_Resize({
            $btn.Location = New-Object Point(($headerPanel.Width - 250), 8)
        })
        $btn.Location = New-Object Point(($headerPanel.Width - 250), 8)
        
        # TabControl
        $this.TabControl = New-Object TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object Font("Segoe UI", 10)
        $mainContainer.Controls.Add($this.TabControl)
        
        # Tabs erstellen
        $this.CreateOverviewTab()
        $this.CreateSystemTab()
        $this.CreateNetworkTab()
        $this.CreateComplianceTab()
        $this.CreateDebugLogsTab()
        
        # StatusBar
        $statusStrip = New-Object StatusStrip
        $statusStrip.Dock = "Bottom"
        $this.Form.Controls.Add($statusStrip)
        
        $this.StatusLabel = New-Object ToolStripStatusLabel
        $this.StatusLabel.Text = "Bereit"
        $statusStrip.Items.Add($this.StatusLabel)
        
        $this.ProgressBar = New-Object ToolStripProgressBar
        $this.ProgressBar.Size = New-Object Size(200, 16)
        $statusStrip.Items.Add($this.ProgressBar)
    }
    
    [void]CreateOverviewTab() {
        $tab = New-Object TabPage("Uebersicht")
        $this.TabControl.Controls.Add($tab)
        
        # Status-Panel
        $statusPanel = New-Object FlowLayoutPanel
        $statusPanel.Dock = "Top"
        $statusPanel.Height = 180
        $statusPanel.Padding = New-Object Padding(20)
        $statusPanel.FlowDirection = "LeftToRight"
        $tab.Controls.Add($statusPanel)
        
        # Status-Cards
        $this.StatusCards["SystemStatusCard"] = $this.CreateStatusCard("System-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["SystemStatusCard"])
        
        $this.StatusCards["NetworkStatusCard"] = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["NetworkStatusCard"])
        
        $this.StatusCards["ComplianceStatusCard"] = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.StatusCards["ComplianceStatusCard"])
        
        # Log-Box
        $logBox = New-Object RichTextBox
        $logBox.Dock = "Fill"
        $logBox.Font = New-Object Font("Consolas", 9)
        $logBox.ReadOnly = $true
        $logBox.BackColor = [Color]::White
        $logBox.Name = "OverviewLogBox"
        $tab.Controls.Add($logBox)
    }
    
    [void]CreateSystemTab() {
        $tab = New-Object TabPage("System")
        $this.TabControl.Controls.Add($tab)
        
        $this.SystemInfoBox = New-Object RichTextBox
        $this.SystemInfoBox.Dock = "Fill"
        $this.SystemInfoBox.Font = New-Object Font("Consolas", 9)
        $this.SystemInfoBox.ReadOnly = $true
        $this.SystemInfoBox.BackColor = [Color]::White
        $tab.Controls.Add($this.SystemInfoBox)
    }
    
    [void]CreateNetworkTab() {
        $tab = New-Object TabPage("Netzwerk")
        $this.TabControl.Controls.Add($tab)
        
        $this.NetworkInfoBox = New-Object RichTextBox
        $this.NetworkInfoBox.Dock = "Fill"
        $this.NetworkInfoBox.Font = New-Object Font("Consolas", 9)
        $this.NetworkInfoBox.ReadOnly = $true
        $this.NetworkInfoBox.BackColor = [Color]::White
        $tab.Controls.Add($this.NetworkInfoBox)
    }
    
    [void]CreateComplianceTab() {
        $tab = New-Object TabPage("Compliance")
        $this.TabControl.Controls.Add($tab)
        
        $this.ComplianceInfoBox = New-Object RichTextBox
        $this.ComplianceInfoBox.Dock = "Fill"
        $this.ComplianceInfoBox.Font = New-Object Font("Consolas", 9)
        $this.ComplianceInfoBox.ReadOnly = $true
        $this.ComplianceInfoBox.BackColor = [Color]::White
        $tab.Controls.Add($this.ComplianceInfoBox)
    }
    
    [void]CreateDebugLogsTab() {
        $tab = New-Object TabPage("Debug-Logs")
        $this.TabControl.Controls.Add($tab)
        
        $this.LogsBox = New-Object RichTextBox
        $this.LogsBox.Dock = "Fill"
        $this.LogsBox.Font = New-Object Font("Consolas", 9)
        $this.LogsBox.ReadOnly = $true
        $this.LogsBox.BackColor = [Color]::White
        $tab.Controls.Add($this.LogsBox)
    }
    
    [Panel]CreateStatusCard([string]$title, [string]$status, [Color]$statusColor) {
        $card = New-Object Panel
        $card.Size = New-Object Size(350, 120)
        $card.BorderStyle = "FixedSingle"
        $card.BackColor = [Color]::White
        $card.Margin = New-Object Padding(10)
        
        $titleLabel = New-Object Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object Font("Segoe UI", 11, [FontStyle]::Bold)
        $titleLabel.Location = New-Object Point(15, 15)
        $titleLabel.AutoSize = $true
        $card.Controls.Add($titleLabel)
        
        # FIX: Umbenennung von $statusLabel zu $cardStatusLabel
        $cardStatusLabel = New-Object Label
        $cardStatusLabel.Text = $status
        $cardStatusLabel.ForeColor = $statusColor
        $cardStatusLabel.Font = New-Object Font("Segoe UI", 9)
        $cardStatusLabel.Location = New-Object Point(15, 50)
        $cardStatusLabel.AutoSize = $true
        $cardStatusLabel.Name = "StatusLabel"
        $card.Controls.Add($cardStatusLabel)
        
        return $card
    }
    
    [void]UpdateStatusCard([string]$cardName, [string]$newStatus, [Color]$color) {
        if ($this.StatusCards.ContainsKey($cardName)) {
            $card = $this.StatusCards[$cardName]
            # FIX: Umbenennung von $statusLabel zu $cardStatusLabel
            $cardStatusLabel = $card.Controls | Where-Object { $_.Name -eq "StatusLabel" }
            if ($cardStatusLabel) {
                $cardStatusLabel.Text = $newStatus
                $cardStatusLabel.ForeColor = $color
                $this.Form.Refresh()
                [Application]::DoEvents()
            }
        }
    }
    
    [void]AddLog([string]$message, [Color]$color) {
        $logBox = $this.TabControl.TabPages[0].Controls | Where-Object { $_.Name -eq "OverviewLogBox" }
        if ($logBox) {
            $logBox.SelectionStart = $logBox.TextLength
            $logBox.SelectionLength = 0
            $logBox.SelectionColor = $color
            $logBox.AppendText($message)
            $logBox.ScrollToCaret()
            $this.Form.Refresh()
            [Application]::DoEvents()
        }
    }
    
    [void]RunFullCheck() {
        try {
            $this.StartButton.Enabled = $false
            $this.ProgressBar.Value = 0
            $this.StatusLabel.Text = "Pruefung laeuft..."
            
            # Clear all outputs
            $logBox = $this.TabControl.TabPages[0].Controls | Where-Object { $_.Name -eq "OverviewLogBox" }
            if ($logBox) { $logBox.Clear() }
            $this.SystemInfoBox.Clear()
            $this.NetworkInfoBox.Clear()
            $this.ComplianceInfoBox.Clear()
            $this.LogsBox.Clear()
            
            $this.AddLog("=== STARTE VOLLSTAENDIGE SYSTEMPRUEFUNG ===`r`n`r`n", [Color]::Blue)
            
            # 1. System-Check
            $this.AddLog("1. System-Check...`r`n", [Color]::Black)
            $this.UpdateStatusCard("SystemStatusCard", "Wird geprueft...", [Color]::Orange)
            $this.ProgressBar.Value = 10
            
            if (Get-Command -Name "Get-SystemInformation" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInformation
                $this.CheckResults["System"] = $systemInfo
                $this.UpdateSystemTab($systemInfo)
                $this.AddLog("    [OK] System-Check abgeschlossen`r`n", [Color]::Green)
                $this.UpdateStatusCard("SystemStatusCard", "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("    [FEHLER] Funktion 'Get-SystemInformation' nicht gefunden`r`n", [Color]::Red)
                $this.UpdateStatusCard("SystemStatusCard", "Fehler", [Color]::Red)
            }
            $this.ProgressBar.Value = 33
            
            # 2. Netzwerk-Check
            $this.AddLog("2. Netzwerk-Check...`r`n", [Color]::Black)
            $this.UpdateStatusCard("NetworkStatusCard", "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-NetworkConfiguration" -ErrorAction SilentlyContinue) {
                $networkInfo = Test-NetworkConfiguration
                $this.CheckResults["Network"] = $networkInfo
                $this.UpdateNetworkTab($networkInfo)
                $this.AddLog("    [OK] Netzwerk-Check abgeschlossen`r`n", [Color]::Green)
                $this.UpdateStatusCard("NetworkStatusCard", "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("    [FEHLER] Funktion 'Test-NetworkConfiguration' nicht gefunden`r`n", [Color]::Red)
                $this.UpdateStatusCard("NetworkStatusCard", "Fehler", [Color]::Red)
            }
            $this.ProgressBar.Value = 66
            
            # 3. Compliance-Check
            $this.AddLog("3. Compliance-Check...`r`n", [Color]::Black)
            $this.UpdateStatusCard("ComplianceStatusCard", "Wird geprueft...", [Color]::Orange)
            
            if (Get-Command -Name "Test-Sage100Compliance" -ErrorAction SilentlyContinue) {
                $complianceInfo = Test-Sage100Compliance
                $this.CheckResults["Compliance"] = $complianceInfo
                $this.UpdateComplianceTab($complianceInfo)
                $this.AddLog("    [OK] Compliance-Check abgeschlossen`r`n", [Color]::Green)
                $this.UpdateStatusCard("ComplianceStatusCard", "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("    [FEHLER] Funktion 'Test-Sage100Compliance' nicht gefunden`r`n", [Color]::Red)
                $this.UpdateStatusCard("ComplianceStatusCard", "Fehler", [Color]::Red)
            }
            $this.ProgressBar.Value = 100
            
            $this.AddLog("`r`n=== PRUEFUNG ABGESCHLOSSEN ===`r`n", [Color]::Blue)
            $this.StatusLabel.Text = "Pruefung abgeschlossen"
            
            [MessageBox]::Show("Alle Checks wurden erfolgreich durchgefuehrt!`r`n`r`nWechseln Sie zu den Tabs (System, Netzwerk, Compliance), um Details zu sehen.", 
                "Pruefung abgeschlossen", 
                [MessageBoxButtons]::OK, 
                [MessageBoxIcon]::Information)
            
        } catch {
            $errorMsg = "Fehler: $($_.Exception.Message)`r`n`r`n"
            $errorMsg += "Position: $($_.InvocationInfo.PositionMessage)`r`n`r`n"
            $errorMsg += "Stack Trace: $($_.ScriptStackTrace)"
            
            $this.AddLog("[FEHLER] $errorMsg`r`n", [Color]::Red)
            
            if ($this.LogsBox) {
                $this.LogsBox.AppendText("=== FEHLER ===`r`n")
                $this.LogsBox.AppendText("$errorMsg`r`n`r`n")
            }
            
            [MessageBox]::Show($errorMsg, "Fehler bei der Pruefung", 
                [MessageBoxButtons]::OK, 
                [MessageBoxIcon]::Error)
            
            $this.StatusLabel.Text = "Fehler bei Pruefung"
        } finally {
            $this.StartButton.Enabled = $true
        }
    }
    
    [void]UpdateSystemTab([object]$systemInfo) {
        $this.SystemInfoBox.Clear()
        $this.SystemInfoBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
        
        if ($systemInfo) {
            $this.SystemInfoBox.AppendText("Computername: $($systemInfo.ComputerName)`r`n")
            $this.SystemInfoBox.AppendText("Betriebssystem: $($systemInfo.OSName) $($systemInfo.OSVersion)`r`n")
            $this.SystemInfoBox.AppendText("CPU: $($systemInfo.CPUName) ($($systemInfo.CPUCores) Cores)`r`n")
            $this.SystemInfoBox.AppendText("RAM: $($systemInfo.TotalRAM_GB) GB (Frei: $($systemInfo.FreeRAM_GB) GB)`r`n")
            $this.SystemInfoBox.AppendText(".NET Framework: $($systemInfo.DotNetVersion)`r`n")
            $this.SystemInfoBox.AppendText("PowerShell: $($systemInfo.PowerShellVersion)`r`n`r`n")
            
            if ($systemInfo.Disks) {
                $this.SystemInfoBox.AppendText("=== FESTPLATTEN ===`r`n")
                foreach ($disk in $systemInfo.Disks) {
                    $this.SystemInfoBox.AppendText("Laufwerk $($disk.DriveLetter): $($disk.TotalSizeGB) GB gesamt`r`n")
                    $this.SystemInfoBox.AppendText("  Frei: $($disk.FreeSpaceGB) GB ($($disk.FreeSpacePercent) Prozent)`r`n`r`n")
                }
            }
        } else {
            $this.SystemInfoBox.AppendText("[FEHLER] Keine Daten verfuegbar`r`n")
        }
    }
    
    [void]UpdateNetworkTab([object]$networkInfo) {
        $this.NetworkInfoBox.Clear()
        $this.NetworkInfoBox.AppendText("=== NETZWERK-KONFIGURATION ===`r`n`r`n")
        
        if ($networkInfo) {
            if ($networkInfo.Adapters) {
                $this.NetworkInfoBox.AppendText("=== NETZWERKADAPTER ===`r`n")
                foreach ($adapter in $networkInfo.Adapters) {
                    $this.NetworkInfoBox.AppendText("Name: $($adapter.Name)`r`n")
                    $this.NetworkInfoBox.AppendText("  IP: $($adapter.IPAddress)`r`n")
                    $this.NetworkInfoBox.AppendText("  Subnet: $($adapter.SubnetMask)`r`n")
                    $this.NetworkInfoBox.AppendText("  Gateway: $($adapter.DefaultGateway)`r`n`r`n")
                }
            }
            
            if ($networkInfo.DNSServers) {
                $this.NetworkInfoBox.AppendText("`r`n=== DNS-SERVER ===`r`n")
                foreach ($dns in $networkInfo.DNSServers) {
                    $this.NetworkInfoBox.AppendText("  - $dns`r`n")
                }
            }
            
            if ($networkInfo.ConnectivityTests) {
                $this.NetworkInfoBox.AppendText("`r`n=== KONNEKTIVITAETS-TESTS ===`r`n")
                foreach ($test in $networkInfo.ConnectivityTests) {
                    $status = if ($test.Success) { "OK" } else { "FEHLER" }
                    $this.NetworkInfoBox.AppendText("  $($test.Target): $status`r`n")
                }
            }
        } else {
            $this.NetworkInfoBox.AppendText("[FEHLER] Keine Daten verfuegbar`r`n")
        }
    }
    
    [void]UpdateComplianceTab([object]$complianceInfo) {
        $this.ComplianceInfoBox.Clear()
        $this.ComplianceInfoBox.AppendText("=== SAGE 100 COMPLIANCE-CHECK ===`r`n`r`n")
        
        if ($complianceInfo) {
            if ($complianceInfo.Requirements) {
                foreach ($req in $complianceInfo.Requirements) {
                    $status = if ($req.Passed) { "OK" } else { "FEHLER" }
                    $this.ComplianceInfoBox.AppendText("[$status] $($req.Name)`r`n")
                    $this.ComplianceInfoBox.AppendText("  $($req.Description)`r`n")
                    if (-not $req.Passed) {
                        $this.ComplianceInfoBox.AppendText("  HINWEIS: $($req.Recommendation)`r`n")
                    }
                    $this.ComplianceInfoBox.AppendText("`r`n")
                }
            }
            
            $passedCount = ($complianceInfo.Requirements | Where-Object { $_.Passed }).Count
            $totalCount = $complianceInfo.Requirements.Count
            $this.ComplianceInfoBox.AppendText("`r`n=== ZUSAMMENFASSUNG ===`r`n")
            $this.ComplianceInfoBox.AppendText("Bestanden: $passedCount von $totalCount Anforderungen`r`n")
        } else {
            $this.ComplianceInfoBox.AppendText("[FEHLER] Keine Daten verfuegbar`r`n")
        }
    }
    
    [void]Show() {
        [void]$this.Form.ShowDialog()
    }
}
