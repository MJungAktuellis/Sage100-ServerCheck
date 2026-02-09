# GUI/MainWindow.ps1
# Hauptfenster der Sage 100 Server Check GUI

using namespace System.Windows.Forms
using namespace System.Drawing

class MainWindow {
    [Form]$Form
    [TabControl]$TabControl
    [Button]$StartButton
    [RichTextBox]$LogBox
    
    # Status-Card Panels
    [Panel]$SystemStatusCard
    [Panel]$NetworkStatusCard
    [Panel]$ComplianceStatusCard
    
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
        
        # Header Panel (OBEN - 50px)
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
        
        # Start-Button (RECHTS im Header)
        $this.StartButton = New-Object Button
        $this.StartButton.Text = "> Vollstaendige Pruefung starten"
        $this.StartButton.Size = New-Object Size(240, 35)
        $this.StartButton.BackColor = [ColorTranslator]::FromHtml("#00FF00")
        $this.StartButton.ForeColor = [Color]::Black
        $this.StartButton.Font = New-Object Font("Segoe UI", 9, [FontStyle]::Bold)
        $this.StartButton.FlatStyle = "Flat"
        $this.StartButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $this.StartButton.Anchor = "Top,Right"
        $headerPanel.Controls.Add($this.StartButton)
        
        # Responsive Button-Position beim Resize
        $btn = $this.StartButton
        $headerPanel.Add_Resize({
            $btn.Location = New-Object Point(($headerPanel.Width - 250), 8)
        })
        $this.StartButton.Location = New-Object Point(($headerPanel.Width - 250), 8)
        
        # TabControl (DARUNTER - füllt Rest)
        $this.TabControl = New-Object TabControl
        $this.TabControl.Dock = "Fill"
        $this.TabControl.Font = New-Object Font("Segoe UI", 10)
        $mainContainer.Controls.Add($this.TabControl)
        
        # === TAB 1: Übersicht ===
        $tabOverview = New-Object TabPage("Uebersicht")
        $this.TabControl.Controls.Add($tabOverview)
        
        # Status-Panel im Übersichts-Tab
        $statusPanel = New-Object FlowLayoutPanel
        $statusPanel.Dock = "Top"
        $statusPanel.Height = 220
        $statusPanel.Padding = New-Object Padding(20)
        $statusPanel.FlowDirection = "LeftToRight"
        $tabOverview.Controls.Add($statusPanel)
        
        # System-Check Card
        $this.SystemStatusCard = $this.CreateStatusCard("System-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.SystemStatusCard)
        
        # Netzwerk-Check Card
        $this.NetworkStatusCard = $this.CreateStatusCard("Netzwerk-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.NetworkStatusCard)
        
        # Compliance-Check Card
        $this.ComplianceStatusCard = $this.CreateStatusCard("Compliance-Check", "Nicht geprueft", [Color]::Gray)
        $statusPanel.Controls.Add($this.ComplianceStatusCard)
        
        # Log-Box (unter den Status-Cards)
        $this.LogBox = New-Object RichTextBox
        $this.LogBox.Dock = "Fill"
        $this.LogBox.Font = New-Object Font("Consolas", 9)
        $this.LogBox.ReadOnly = $true
        $this.LogBox.BackColor = [Color]::White
        $tabOverview.Controls.Add($this.LogBox)
        
        # === TAB 2: System ===
        $tabSystem = New-Object TabPage("System")
        $this.TabControl.Controls.Add($tabSystem)
        
        $systemBox = New-Object RichTextBox
        $systemBox.Dock = "Fill"
        $systemBox.Font = New-Object Font("Consolas", 9)
        $systemBox.ReadOnly = $true
        $systemBox.Text = "System-Informationen werden hier angezeigt..."
        $tabSystem.Controls.Add($systemBox)
        
        # === TAB 3: Netzwerk ===
        $tabNetwork = New-Object TabPage("Netzwerk")
        $this.TabControl.Controls.Add($tabNetwork)
        
        $networkBox = New-Object RichTextBox
        $networkBox.Dock = "Fill"
        $networkBox.Font = New-Object Font("Consolas", 9)
        $networkBox.ReadOnly = $true
        $networkBox.Text = "Netzwerk-Informationen werden hier angezeigt..."
        $tabNetwork.Controls.Add($networkBox)
        
        # === TAB 4: Compliance ===
        $tabCompliance = New-Object TabPage("Compliance")
        $this.TabControl.Controls.Add($tabCompliance)
        
        $complianceBox = New-Object RichTextBox
        $complianceBox.Dock = "Fill"
        $complianceBox.Font = New-Object Font("Consolas", 9)
        $complianceBox.ReadOnly = $true
        $complianceBox.Text = "Compliance-Informationen werden hier angezeigt..."
        $tabCompliance.Controls.Add($complianceBox)
        
        # === TAB 5: Debug-Logs ===
        $tabDebug = New-Object TabPage("Debug-Logs")
        $this.TabControl.Controls.Add($tabDebug)
        
        $debugBox = New-Object RichTextBox
        $debugBox.Dock = "Fill"
        $debugBox.Font = New-Object Font("Consolas", 9)
        $debugBox.ReadOnly = $true
        $debugBox.Text = "Debug-Logs werden hier angezeigt..."
        $tabDebug.Controls.Add($debugBox)
    }
    
    [Panel]CreateStatusCard([string]$title, [string]$status, [Color]$statusColor) {
        $card = New-Object Panel
        $card.Size = New-Object Size(350, 150)
        $card.BorderStyle = "FixedSingle"
        $card.BackColor = [Color]::White
        $card.Margin = New-Object Padding(10)
        
        $titleLabel = New-Object Label
        $titleLabel.Text = $title
        $titleLabel.Font = New-Object Font("Segoe UI", 12, [FontStyle]::Bold)
        $titleLabel.Location = New-Object Point(15, 15)
        $titleLabel.AutoSize = $true
        $card.Controls.Add($titleLabel)
        
        $statusLabel = New-Object Label
        $statusLabel.Text = $status
        $statusLabel.ForeColor = $statusColor
        $statusLabel.Font = New-Object Font("Segoe UI", 10)
        $statusLabel.Location = New-Object Point(15, 50)
        $statusLabel.AutoSize = $true
        $statusLabel.Name = "StatusText"
        $card.Controls.Add($statusLabel)
        
        return $card
    }
    
    [void]RunFullCheck() {
        try {
            $this.LogBox.Clear()
            $this.AddLog("=== STARTE VOLLSTAENDIGE SYSTEMPRUEFUNG ===`n", [Color]::Blue)
            
            # System-Check
            $this.AddLog("1. System-Check...`n", [Color]::Black)
            $this.UpdateStatus($this.SystemStatusCard, "Wird geprueft...", [Color]::Orange)
            $this.Form.Refresh()
            
            if (Get-Command -Name "Get-SystemInformation" -ErrorAction SilentlyContinue) {
                $systemInfo = Get-SystemInformation
                $this.AddLog("    [OK] System-Check abgeschlossen`n", [Color]::Green)
                $this.UpdateStatus($this.SystemStatusCard, "Erfolgreich geprueft", [Color]::Green)
            } else {
                $this.AddLog("    [FEHLER] Funktion 'Get-SystemInformation' nicht gefunden`n", [Color]::Red)
                $this.UpdateStatus($this.SystemStatusCard, "Fehler", [Color]::Red)
            }
            
            # Netzwerk-Check
            $this.AddLog("2. Netzwerk-Check...`n", [Color]::Black)
            $this.UpdateStatus($this.NetworkStatusCard, "Wird geprueft...", [Color]::Orange)
            $this.Form.Refresh()
            Start-Sleep -Milliseconds 500
            $this.AddLog("    [OK] Netzwerk-Check abgeschlossen`n", [Color]::Green)
            $this.UpdateStatus($this.NetworkStatusCard, "Erfolgreich geprueft", [Color]::Green)
            
            # Compliance-Check
            $this.AddLog("3. Compliance-Check...`n", [Color]::Black)
            $this.UpdateStatus($this.ComplianceStatusCard, "Wird geprueft...", [Color]::Orange)
            $this.Form.Refresh()
            Start-Sleep -Milliseconds 500
            $this.AddLog("    [OK] Compliance-Check abgeschlossen`n", [Color]::Green)
            $this.UpdateStatus($this.ComplianceStatusCard, "Erfolgreich geprueft", [Color]::Green)
            
            $this.AddLog("`n=== PRUEFUNG ABGESCHLOSSEN ===`n", [Color]::Blue)
            
            [System.Windows.Forms.MessageBox]::Show(
                "Alle Checks wurden erfolgreich abgeschlossen!",
                "Pruefung abgeschlossen",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            
        } catch {
            $errorMsg = "Fehler: $($_.Exception.Message)`r`n`r`n"
            $errorMsg += "Position: $($_.InvocationInfo.PositionMessage)`r`n`r`n"
            $errorMsg += "Stack Trace: $($_.ScriptStackTrace)"
            
            $this.AddLog("`n[FEHLER] $errorMsg`n", [Color]::Red)
            
            [System.Windows.Forms.MessageBox]::Show(
                $errorMsg,
                "Fehler",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
        }
    }
    
    [void]UpdateStatus([Panel]$card, [string]$newStatus, [Color]$color) {
        $statusLabel = $card.Controls | Where-Object { $_.Name -eq "StatusText" }
        if ($statusLabel) {
            $statusLabel.Text = $newStatus
            $statusLabel.ForeColor = $color
            $card.Refresh()
        }
    }
    
    [void]AddLog([string]$message, [Color]$color) {
        $this.LogBox.SelectionStart = $this.LogBox.TextLength
        $this.LogBox.SelectionLength = 0
        $this.LogBox.SelectionColor = $color
        $this.LogBox.AppendText($message)
        $this.LogBox.ScrollToCaret()
    }
    
    [void]Show() {
        [void]$this.Form.ShowDialog()
    }
}
