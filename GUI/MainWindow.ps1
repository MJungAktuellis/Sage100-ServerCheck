# GUI/MainWindow.ps1
# Hauptfenster-Klasse fuer Sage 100 Server Check Tool

using namespace System.Windows.Forms
using namespace System.Drawing

<#
.SYNOPSIS
    Hauptfenster-Klasse fuer die GUI-Anwendung
.DESCRIPTION
    Erstellt und verwaltet das Hauptfenster mit allen UI-Elementen
#>

class MainWindow {
    [System.Windows.Forms.Form]$Form
    [System.Windows.Forms.TabControl]$TabControl
    [System.Windows.Forms.Button]$StartButton
    
    # TextBoxen als Klasseneigenschaften fuer direkten Zugriff
    [System.Windows.Forms.TextBox]$SystemInfoBox
    [System.Windows.Forms.TextBox]$NetworkInfoBox
    [System.Windows.Forms.TextBox]$ComplianceInfoBox
    [System.Windows.Forms.TextBox]$LogsBox
    [System.Windows.Forms.TextBox]$ResultBox
    
    [hashtable]$StatusCards = @{}
    [hashtable]$CheckResults = @{}

    # Konstruktor
    MainWindow() {
        $this.InitializeUI()
    }

    # UI Initialisierung
    [void] InitializeUI() {
        # Hauptfenster
        $this.Form = New-Object System.Windows.Forms.Form
        $this.Form.Text = "Sage 100 Server Check & Setup Tool v2.0"
        $this.Form.Size = New-Object System.Drawing.Size(1200, 800)
        $this.Form.StartPosition = "CenterScreen"
        $this.Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 245)

        # Container Panel fuer gesamten Inhalt
        $mainContainer = New-Object System.Windows.Forms.Panel
        $mainContainer.Dock = "Fill"
        $this.Form.Controls.Add($mainContainer)

        # Header Panel - KOMPAKT 50px
        $headerPanel = New-Object System.Windows.Forms.Panel
        $headerPanel.Dock = "Top"
        $headerPanel.Height = 50
        $headerPanel.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
        $mainContainer.Controls.Add($headerPanel)

        # Title - KOMPAKT
        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = "Sage 100 Server Check Tool"
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleLabel.ForeColor = [System.Drawing.Color]::White
        $titleLabel.Location = New-Object System.Drawing.Point(10, 12)
        $titleLabel.AutoSize = $true
        $headerPanel.Controls.Add($titleLabel)

        # Start Button - RECHTS IM HEADER
        $this.StartButton = New-Object System.Windows.Forms.Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $this.StartButton.Size = New-Object System.Drawing.Size(240, 35)
        $this.StartButton.Anchor = "Top,Right"
        $this.StartButton.Location = New-Object System.Drawing.Point(($headerPanel.Width - 250), 8)
        $this.StartButton.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 0)
        $this.StartButton.ForeColor = [System.Drawing.Color]::White
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $headerPanel.Controls.Add($this.StartButton)
        
        # WICHTIG: Button bleibt rechts beim Resize
        $headerPanel.Add_Resize({
            $this.StartButton.Location = New-Object System.Drawing.Point(($headerPanel.Width - 250), 8)
        })

        # TabControl
        $this.TabControl = New-Object System.Windows.Forms.TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $mainContainer.Controls.Add($this.TabControl)

        # Tabs erstellen
        $this.CreateOverviewTab()
        $this.CreateSystemTab()
        $this.CreateNetworkTab()
        $this.CreateComplianceTab()
        $this.CreateLogsTab()
    }

    # Overview Tab
    [void] CreateOverviewTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Uebersicht"
        $tab.BackColor = [System.Drawing.Color]::White
        $this.TabControl.TabPages.Add($tab)

        # Dashboard Panel
        $dashPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $dashPanel.Dock = "Fill"
        $dashPanel.Padding = New-Object System.Windows.Forms.Padding(20)
        $dashPanel.AutoScroll = $true
        $tab.Controls.Add($dashPanel)

        # Status Cards
        $this.StatusCards["SystemStatusCard"] = $this.CreateStatusCard("System-Check", "Nicht geprueft", "Gray")
        $this.StatusCards["NetworkStatusCard"] = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", "Gray")
        $this.StatusCards["ComplianceStatusCard"] = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", "Gray")

        $dashPanel.Controls.Add($this.StatusCards["SystemStatusCard"])
        $dashPanel.Controls.Add($this.StatusCards["NetworkStatusCard"])
        $dashPanel.Controls.Add($this.StatusCards["ComplianceStatusCard"])

        # Ergebnisse TextBox
        $this.ResultBox = New-Object System.Windows.Forms.TextBox
        $this.ResultBox.Multiline = $true
        $this.ResultBox.ScrollBars = "Vertical"
        $this.ResultBox.Font = New-Object System.Drawing.Font("Consolas", 10)
        $this.ResultBox.Dock = "Bottom"
        $this.ResultBox.Height = 300
        $this.ResultBox.ReadOnly = $true
        $tab.Controls.Add($this.ResultBox)
    }

    # System-Check Tab
    [void] CreateSystemTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "System"
        $tab.BackColor = [System.Drawing.Color]::White
        $this.TabControl.TabPages.Add($tab)

        # TextBox fuer System-Informationen
        $this.SystemInfoBox = New-Object System.Windows.Forms.TextBox
        $this.SystemInfoBox.Multiline = $true
        $this.SystemInfoBox.ScrollBars = "Vertical"
        $this.SystemInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.SystemInfoBox.Dock = "Fill"
        $this.SystemInfoBox.ReadOnly = $true
        $tab.Controls.Add($this.SystemInfoBox)
    }

    # Netzwerk-Check Tab
    [void] CreateNetworkTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Netzwerk"
        $tab.BackColor = [System.Drawing.Color]::White
        $this.TabControl.TabPages.Add($tab)

        # TextBox fuer Netzwerk-Informationen
        $this.NetworkInfoBox = New-Object System.Windows.Forms.TextBox
        $this.NetworkInfoBox.Multiline = $true
        $this.NetworkInfoBox.ScrollBars = "Vertical"
        $this.NetworkInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.NetworkInfoBox.Dock = "Fill"
        $this.NetworkInfoBox.ReadOnly = $true
        $tab.Controls.Add($this.NetworkInfoBox)
    }

    # Compliance-Check Tab
    [void] CreateComplianceTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Compliance"
        $tab.BackColor = [System.Drawing.Color]::White
        $this.TabControl.TabPages.Add($tab)

        # TextBox fuer Compliance-Informationen
        $this.ComplianceInfoBox = New-Object System.Windows.Forms.TextBox
        $this.ComplianceInfoBox.Multiline = $true
        $this.ComplianceInfoBox.ScrollBars = "Vertical"
        $this.ComplianceInfoBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.ComplianceInfoBox.Dock = "Fill"
        $this.ComplianceInfoBox.ReadOnly = $true
        $tab.Controls.Add($this.ComplianceInfoBox)
    }

    # Debug-Logs Tab
    [void] CreateLogsTab() {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = "Debug-Logs"
        $tab.BackColor = [System.Drawing.Color]::White
        $this.TabControl.TabPages.Add($tab)

        # TextBox fuer Logs
        $this.LogsBox = New-Object System.Windows.Forms.TextBox
        $this.LogsBox.Multiline = $true
        $this.LogsBox.ScrollBars = "Vertical"
        $this.LogsBox.Font = New-Object System.Drawing.Font("Consolas", 9)
        $this.LogsBox.Dock = "Fill"
        $this.LogsBox.ReadOnly = $true
        $tab.Controls.Add($this.LogsBox)
    }

    # Status Card erstellen
    [System.Windows.Forms.Panel] CreateStatusCard([string]$title, [string]$status, [string]$color) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(350, 120)
        $card.BackColor = [System.Drawing.Color]::White
        $card.BorderStyle = "FixedSingle"
        $card.Margin = New-Object System.Windows.Forms.Padding(10)

        $titleLabel = New-Object System.Windows.Forms.Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $titleLabel.Location = New-Object System.Drawing.Point(15, 15)
        $titleLabel.AutoSize = $true
        $card.Controls.Add($titleLabel)

        $statusLabel = New-Object System.Windows.Forms.Label
        $statusLabel.Text = $status
        $statusLabel.Name = "StatusLabel"
        $statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11)
        $statusLabel.Location = New-Object System.Drawing.Point(15, 50)
        $statusLabel.AutoSize = $true
        
        switch ($color) {
            "Green" { $statusLabel.ForeColor = [System.Drawing.Color]::Green }
            "Red"   { $statusLabel.ForeColor = [System.Drawing.Color]::Red }
            "Yellow" { $statusLabel.ForeColor = [System.Drawing.Color]::Orange }
            default { $statusLabel.ForeColor = [System.Drawing.Color]::Gray }
        }
        
        $card.Controls.Add($statusLabel)

        return $card
    }

    # Status Card aktualisieren
    [void] UpdateStatusCard([string]$cardName, [string]$status, [string]$color) {
        if ($this.StatusCards.ContainsKey($cardName)) {
            $card = $this.StatusCards[$cardName]
            $statusLabel = $card.Controls["StatusLabel"]
            
            if ($statusLabel) {
                $statusLabel.Text = $status
                
                switch ($color) {
                    "Green" { $statusLabel.ForeColor = [System.Drawing.Color]::Green }
                    "Red"   { $statusLabel.ForeColor = [System.Drawing.Color]::Red }
                    "Yellow" { $statusLabel.ForeColor = [System.Drawing.Color]::Orange }
                    default { $statusLabel.ForeColor = [System.Drawing.Color]::Gray }
                }
            }
        }
    }

    # Vollstaendige Pruefung starten
    [void] RunFullCheck() {
        try {
            $this.ResultBox.Clear()
            $this.ResultBox.AppendText("=== STARTE VOLLSTAENDIGE SYSTEMPRUEFUNG ===`r`n`r`n")
            
            # 1. System-Check
            $this.ResultBox.AppendText("1. System-Check...`r`n")
            $this.UpdateStatusCard("SystemStatusCard", "Wird geprueft...", "Yellow")
            
            if (Get-Command -Name "Get-SystemInformation" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInformation
                $this.CheckResults["System"] = $systemInfo
                $this.UpdateSystemTab($systemInfo)
                $this.UpdateStatusCard("SystemStatusCard", "Erfolgreich geprueft", "Green")
                $this.ResultBox.AppendText("   [OK] System-Check abgeschlossen`r`n")
            } else {
                throw "Funktion 'Get-SystemInformation' nicht gefunden! Module wurden nicht korrekt geladen."
            }
            
            # 2. Netzwerk-Check
            $this.ResultBox.AppendText("2. Netzwerk-Check...`r`n")
            $this.UpdateStatusCard("NetworkStatusCard", "Wird geprueft...", "Yellow")
            
            if (Get-Command -Name "Test-NetworkConfiguration" -ErrorAction SilentlyContinue) {
                $networkInfo = Test-NetworkConfiguration
                $this.CheckResults["Network"] = $networkInfo
                $this.UpdateNetworkTab($networkInfo)
                $this.UpdateStatusCard("NetworkStatusCard", "Erfolgreich geprueft", "Green")
                $this.ResultBox.AppendText("   [OK] Netzwerk-Check abgeschlossen`r`n")
            } else {
                throw "Funktion 'Test-NetworkConfiguration' nicht gefunden!"
            }
            
            # 3. Compliance-Check
            $this.ResultBox.AppendText("3. Compliance-Check...`r`n")
            $this.UpdateStatusCard("ComplianceStatusCard", "Wird geprueft...", "Yellow")
            
            if (Get-Command -Name "Test-Sage100Compliance" -ErrorAction SilentlyContinue) {
                $complianceInfo = Test-Sage100Compliance
                $this.CheckResults["Compliance"] = $complianceInfo
                $this.UpdateComplianceTab($complianceInfo)
                $this.UpdateStatusCard("ComplianceStatusCard", "Erfolgreich geprueft", "Green")
                $this.ResultBox.AppendText("   [OK] Compliance-Check abgeschlossen`r`n")
            } else {
                throw "Funktion 'Test-Sage100Compliance' nicht gefunden!"
            }
            
            $this.ResultBox.AppendText("`r`n=== PRUEFUNG ABGESCHLOSSEN ===`r`n")
            
            [System.Windows.Forms.MessageBox]::Show(
                "Alle Pruefungen wurden erfolgreich abgeschlossen!",
                "Erfolg",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
        } catch {
            # Detaillierte Fehlermeldung
            $errorMsg = "Fehler: $($_.Exception.Message)`r`n`r`n"
            $errorMsg += "Position: $($_.InvocationInfo.PositionMessage)`r`n`r`n"
            $errorMsg += "Stack Trace: $($_.ScriptStackTrace)"
            
            [System.Windows.Forms.MessageBox]::Show(
                $errorMsg,
                "Fehler bei der Pruefung",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            
            # Fehler auch in Logs-Tab schreiben
            if ($this.LogsBox) {
                $this.LogsBox.AppendText("=== FEHLER ===`r`n")
                $this.LogsBox.AppendText("$errorMsg`r`n`r`n")
            }
        }
    }

    # System-Tab aktualisieren
    [void] UpdateSystemTab([hashtable]$info) {
        $this.SystemInfoBox.Clear()
        $this.SystemInfoBox.AppendText("=== SYSTEM-INFORMATIONEN ===`r`n`r`n")
        
        if ($info) {
            foreach ($key in $info.Keys | Sort-Object) {
                $value = $info[$key]
                if ($value -is [hashtable]) {
                    $this.SystemInfoBox.AppendText("$key`r`n")
                    foreach ($subKey in $value.Keys | Sort-Object) {
                        $this.SystemInfoBox.AppendText("  - ${subKey}: $($value[$subKey])`r`n")
                    }
                } else {
                    $this.SystemInfoBox.AppendText("${key}: $value`r`n")
                }
            }
        } else {
            $this.SystemInfoBox.AppendText("Keine Informationen verfuegbar.`r`n")
        }
    }

    # Netzwerk-Tab aktualisieren
    [void] UpdateNetworkTab([hashtable]$info) {
        $this.NetworkInfoBox.Clear()
        $this.NetworkInfoBox.AppendText("=== NETZWERK-INFORMATIONEN ===`r`n`r`n")
        
        if ($info) {
            foreach ($key in $info.Keys | Sort-Object) {
                $value = $info[$key]
                if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary]) {
                    $this.NetworkInfoBox.AppendText("$key`r`n")
                    foreach ($subKey in $value.Keys | Sort-Object) {
                        $this.NetworkInfoBox.AppendText("  - ${subKey}: $($value[$subKey])`r`n")
                    }
                } elseif ($value -is [array]) {
                    $this.NetworkInfoBox.AppendText("${key}:`r`n")
                    foreach ($item in $value) {
                        $this.NetworkInfoBox.AppendText("  - $item`r`n")
                    }
                } else {
                    $this.NetworkInfoBox.AppendText("${key}: $value`r`n")
                }
            }
        } else {
            $this.NetworkInfoBox.AppendText("Keine Informationen verfuegbar.`r`n")
        }
    }

    # Compliance-Tab aktualisieren
    [void] UpdateComplianceTab([hashtable]$info) {
        $this.ComplianceInfoBox.Clear()
        $this.ComplianceInfoBox.AppendText("=== COMPLIANCE-CHECK ERGEBNISSE ===`r`n`r`n")
        
        if ($info) {
            foreach ($key in $info.Keys | Sort-Object) {
                $value = $info[$key]
                if ($value -is [hashtable]) {
                    $this.ComplianceInfoBox.AppendText("$key`r`n")
                    foreach ($subKey in $value.Keys | Sort-Object) {
                        $subValue = $value[$subKey]
                        if ($subValue -is [bool]) {
                            $status = if ($subValue) { "[OK]" } else { "[FEHLT]" }
                            $this.ComplianceInfoBox.AppendText("  $status ${subKey}`r`n")
                        } else {
                            $this.ComplianceInfoBox.AppendText("  - ${subKey}: $subValue`r`n")
                        }
                    }
                } elseif ($value -is [array]) {
                    $this.ComplianceInfoBox.AppendText("${key}:`r`n")
                    foreach ($item in $value) {
                        $this.ComplianceInfoBox.AppendText("  - $item`r`n")
                    }
                } else {
                    $this.ComplianceInfoBox.AppendText("${key}: $value`r`n")
                }
            }
        } else {
            $this.ComplianceInfoBox.AppendText("Keine Compliance-Informationen verfuegbar.`r`n")
        }
    }

    # Fenster anzeigen
    [void] Show() {
        [void]$this.Form.ShowDialog()
    }
}
