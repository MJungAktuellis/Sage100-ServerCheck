# ============================================
# SAGE 100 SERVER CHECK - SIMPLE INSTALLER
# ============================================

param(
    [switch]$Silent
)

# Farben für bessere Lesbarkeit
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "[FEHLER] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "[INFO] $Text" -ForegroundColor Yellow
}

# ============================================
# HAUPTPROGRAMM
# ============================================

Clear-Host
Write-Header "SAGE 100 SERVER CHECK - INSTALLATION"

# Schritt 1: Voraussetzungen prüfen
Write-Info "Pruefe Systemvoraussetzungen..."

# PowerShell-Version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error "PowerShell 5.1 oder hoeher erforderlich!"
    Write-Info "Aktuelle Version: $($PSVersionTable.PSVersion)"
    pause
    exit 1
}
Write-Success "PowerShell $($PSVersionTable.PSVersion) erkannt"

# Administrator-Rechte
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "Administrator-Rechte erforderlich!"
    pause
    exit 1
}
Write-Success "Administrator-Rechte vorhanden"

# .NET Framework
$dotNetVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
if ($dotNetVersion -ge 378389) {
    Write-Success ".NET Framework 4.5+ vorhanden"
} else {
    Write-Error ".NET Framework 4.5 oder hoeher erforderlich!"
    pause
    exit 1
}

# Schritt 2: Installationsordner
Write-Header "INSTALLATIONSORDNER"

$defaultPath = "C:\Program Files\Sage100-ServerCheck"
Write-Info "Standard-Pfad: $defaultPath"

if (-not $Silent) {
    $customPath = Read-Host "Anderen Pfad verwenden? (Enter = Standard)"
    if ($customPath) {
        $installPath = $customPath
    } else {
        $installPath = $defaultPath
    }
} else {
    $installPath = $defaultPath
}

Write-Info "Installiere nach: $installPath"

# Ordner erstellen
try {
    if (Test-Path $installPath) {
        Write-Info "Ordner existiert bereits - wird aktualisiert"
    } else {
        New-Item -ItemType Directory -Path $installPath -Force | Out-Null
        Write-Success "Installationsordner erstellt"
    }
} catch {
    Write-Error "Konnte Ordner nicht erstellen: $_"
    pause
    exit 1
}

# Schritt 3: Dateien kopieren
Write-Header "DATEIEN KOPIEREN"

$sourcePath = $PSScriptRoot | Split-Path -Parent
Write-Info "Quelle: $sourcePath"

try {
    # Hauptverzeichnisse
    $folders = @("src", "Config", "Logs", "Installer")
    
    foreach ($folder in $folders) {
        $source = Join-Path $sourcePath $folder
        $dest = Join-Path $installPath $folder
        
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Recurse -Force
            Write-Success "Kopiert: $folder"
        } else {
            Write-Info "Uebersprungen (nicht vorhanden): $folder"
        }
    }
    
    # Einzeldateien
    $files = @("README.md", "USER-GUIDE.md", "README-BENUTZER.md")
    foreach ($file in $files) {
        $source = Join-Path $sourcePath $file
        $dest = Join-Path $installPath $file
        
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Force
            Write-Success "Kopiert: $file"
        }
    }
    
} catch {
    Write-Error "Fehler beim Kopieren: $_"
    pause
    exit 1
}

# Schritt 4: Konfiguration
Write-Header "KONFIGURATION"

$configPath = Join-Path $installPath "Config\config.json"

if (Test-Path $configPath) {
    Write-Info "Konfigurationsdatei gefunden"
    
    if (-not $Silent) {
        $editConfig = Read-Host "Moechten Sie die Konfiguration jetzt bearbeiten? (j/n)"
        
        if ($editConfig -eq "j") {
            Write-Info "SQL Server-Einstellungen:"
            $sqlServer = Read-Host "  SQL Server (z.B. localhost\SQLEXPRESS)"
            $sqlDatabase = Read-Host "  Datenbank (z.B. Sage100_Demo)"
            
            Write-Info "E-Mail-Einstellungen:"
            $smtpServer = Read-Host "  SMTP Server (z.B. smtp.office365.com)"
            $emailFrom = Read-Host "  Von-Adresse (z.B. servercheck@firma.de)"
            $emailTo = Read-Host "  An-Adresse (z.B. admin@firma.de)"
            
            # Config aktualisieren
            try {
                $config = Get-Content $configPath | ConvertFrom-Json
                $config.DatabaseConfig.ServerName = $sqlServer
                $config.DatabaseConfig.DatabaseName = $sqlDatabase
                $config.EmailConfig.SMTPServer = $smtpServer
                $config.EmailConfig.From = $emailFrom
                $config.EmailConfig.To = $emailTo
                
                $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
                Write-Success "Konfiguration gespeichert"
            } catch {
                Write-Error "Fehler beim Speichern der Konfiguration: $_"
            }
        }
    }
} else {
    Write-Error "config.json nicht gefunden!"
}

# Schritt 5: Desktop-Verknüpfung
Write-Header "DESKTOP-VERKNUEPFUNG"

if (-not $Silent) {
    $createShortcut = Read-Host "Desktop-Verknuepfung erstellen? (j/n)"
} else {
    $createShortcut = "j"
}

if ($createShortcut -eq "j") {
    try {
        $shortcutPath = Join-Path ([Environment]::GetFolderPath("Desktop")) "Sage100 ServerCheck.lnk"
        $targetPath = Join-Path $installPath "src\Sage100-ServerCheck.ps1"
        
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
        $Shortcut.WorkingDirectory = $installPath
        $Shortcut.IconLocation = "powershell.exe,0"
        $Shortcut.Description = "Sage 100 Server Check"
        $Shortcut.Save()
        
        Write-Success "Desktop-Verknuepfung erstellt"
    } catch {
        Write-Error "Konnte Verknuepfung nicht erstellen: $_"
    }
}

# Schritt 6: Task Scheduler (optional)
Write-Header "AUTOMATISCHE AUSFUEHRUNG"

if (-not $Silent) {
    $createTask = Read-Host "Automatische taegliche Ausfuehrung einrichten? (j/n)"
} else {
    $createTask = "n"
}

if ($createTask -eq "j") {
    try {
        $taskName = "Sage100-ServerCheck"
        $scriptPath = Join-Path $installPath "src\Sage100-ServerCheck.ps1"
        
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
        $trigger = New-ScheduledTaskTrigger -Daily -At 8am
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        Write-Success "Automatische Ausfuehrung eingerichtet (taeglich um 8:00 Uhr)"
    } catch {
        Write-Error "Konnte Task nicht erstellen: $_"
    }
}

# Fertig!
Write-Header "INSTALLATION ABGESCHLOSSEN"

Write-Success "Sage 100 Server Check wurde erfolgreich installiert!"
Write-Info ""
Write-Info "Installationsort: $installPath"
Write-Info "Konfiguration: $configPath"
Write-Info ""
Write-Info "Naechste Schritte:"
Write-Info "1. Passen Sie die Konfiguration an: $configPath"
Write-Info "2. Starten Sie den Check ueber die Desktop-Verknuepfung"
Write-Info "3. Lesen Sie die Dokumentation: $(Join-Path $installPath 'USER-GUIDE.md')"
Write-Info ""

pause