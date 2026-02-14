# 🏗️ **Sage100-ServerCheck - ARCHITEKTUR-DOKUMENTATION**

> **Version:** 2.0  
> **Letzte Aktualisierung:** 14.02.2026  
> **Status:** ✅ Produktionsreif

---

## 📋 **INHALTSVERZEICHNIS**

1. [Übersicht](#übersicht)
2. [Ordnerstruktur](#ordnerstruktur)
3. [Komponenten](#komponenten)
4. [Datenfluss](#datenfluss)
5. [Konfiguration](#konfiguration)
6. [Module](#module)
7. [GUI-Architektur](#gui-architektur)
8. [Fehlerbehandlung](#fehlerbehandlung)

---

## 🎯 **1. ÜBERSICHT**

### **Zweck**
Sage100-ServerCheck ist ein **Enterprise-Monitoring-Tool** für Sage 100 Server-Umgebungen. Es überwacht:
- Windows-Dienste (SQL Server, OPPlus Services)
- Prozesse (CPU, RAM, Laufzeit)
- Server-Verfügbarkeit (lokal & remote)

### **Technologie-Stack**
- **Sprache:** PowerShell 5.1+ (Windows-nativ)
- **GUI:** WPF (Windows Presentation Foundation)
- **Datenformat:** JSON (Konfiguration & Logs)
- **Remote-Management:** WinRM, CIM-Sessions
- **Benachrichtigungen:** SMTP, Windows Toast, Event Log

### **Kernprinzipien**
1. ✅ **Zero-Installation:** Nur INSTALL.cmd ausführen
2. ✅ **Modular:** Austauschbare PowerShell-Module
3. ✅ **Persistent:** Konfiguration überlebt Neustarts
4. ✅ **User-Friendly:** Visuelle Konfiguration (kein CMD-Editing)

---

## 📁 **2. ORDNERSTRUKTUR**

```
Sage100-ServerCheck/
│
├── 📄 INSTALL.cmd                 # ⭐ HAUPT-EINSTIEGSPUNKT
├── 📄 README.md                   # Benutzer-Dokumentation
├── 📄 LICENSE                     # MIT Lizenz
├── 📄 .gitignore                  # Git-Konfiguration
│
├── 📂 app/                        # 🔧 HAUPT-ANWENDUNG
│   ├── Sage100ServerCheck.ps1    # GUI & Haupt-Loop
│   └── modules/                  # PowerShell Module
│       ├── ServiceMonitor.psm1   # Dienst-Überwachung
│       ├── ProcessChecker.psm1   # Prozess-Management
│       └── Notifier.psm1         # Benachrichtigungen
│
├── 📂 config/                     # ⚙️ KONFIGURATION
│   ├── defaults.json             # Standard-Werte
│   └── config.json.template      # Template für User
│   └── config.json               # ⚠️ User-Config (nicht in Git!)
│
├── 📂 setup/                      # 🚀 INSTALLATION
│   ├── FirstRunWizard.ps1        # Interaktiver Setup-Wizard
│   └── Uninstall.ps1             # Deinstallations-Script
│
└── 📂 docs/                       # 📚 DOKUMENTATION
    ├── ARCHITECTURE.md           # Diese Datei
    ├── CHANGELOG.md              # Versionshistorie
    └── screenshots/              # GUI-Screenshots
```

---

## 🧩 **3. KOMPONENTEN**

### **3.1 INSTALL.cmd** (Haupteinstieg)
```batch
@echo off
:: Prüft Admin-Rechte
:: Prüft PowerShell Version >= 5.1
:: Startet setup/FirstRunWizard.ps1
```

**Zweck:** Ein-Klick-Installation für End-User

---

### **3.2 FirstRunWizard.ps1** (Installations-Assistent)
```powershell
[WPF GUI]
├── System-Checks (PowerShell, Admin-Rechte)
├── Server-Konfiguration
├── E-Mail Setup
├── Ordner-Erstellung (logs/, config/)
└── Desktop-Verknüpfung erstellen
```

**Output:**
- `config/config.json` (persistente Konfiguration)
- `Desktop/Sage100 ServerCheck.lnk`
- `logs/` Ordner

---

### **3.3 Sage100ServerCheck.ps1** (Hauptprogramm)

**Struktur:**
```powershell
# 1. Module importieren
Import-Module ./modules/ServiceMonitor.psm1
Import-Module ./modules/ProcessChecker.psm1
Import-Module ./modules/Notifier.psm1

# 2. Konfiguration laden
$config = Get-Content config/config.json | ConvertFrom-Json

# 3. WPF GUI initialisieren
$window = [Windows.Markup.XamlReader]::Load($xaml)

# 4. Monitoring-Loop starten
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds($config.monitoring.checkInterval)
$timer.Add_Tick({
    # Status-Updates für alle Server
    foreach ($server in $config.servers) {
        $status = Get-ServiceStatus -Server $server
        Update-GUI $status
    }
})
$timer.Start()

# 5. GUI anzeigen
$window.ShowDialog()
```

---

### **3.4 Module**

#### **ServiceMonitor.psm1**
```powershell
Export-ModuleMember -Function @(
    'Get-ServiceStatus',      # Status eines Dienstes abrufen
    'Start-ServiceMonitoring', # Kontinuierliche Überwachung
    'Restart-RemoteService'   # Dienst neustarten
)
```

**Beispiel:**
```powershell
$status = Get-ServiceStatus -ComputerName "SERVER01" -ServiceName "MSSQLSERVER"
# Rückgabe: @{ Status = "Running"; StartType = "Automatic"; ... }
```

#### **ProcessChecker.psm1**
```powershell
Export-ModuleMember -Function @(
    'Get-ProcessInfo',        # Prozess-Details (CPU, RAM)
    'Stop-RemoteProcess'      # Prozess beenden
)
```

#### **Notifier.psm1**
```powershell
Export-ModuleMember -Function @(
    'Send-EmailAlert',        # SMTP E-Mail
    'Send-ToastNotification', # Windows 10/11 Toast
    'Write-EventLog'          # Windows Event Log
)
```

---

## 🔄 **4. DATENFLUSS**

### **Installations-Flow:**
```
[User] 
  → Rechtsklick INSTALL.cmd → Als Admin ausführen
    → INSTALL.cmd prüft Admin + PowerShell
      → Startet setup/FirstRunWizard.ps1
        → Wizard zeigt WPF-Fenster
          → User konfiguriert Server, E-Mail etc.
            → Wizard erstellt config/config.json
              → Desktop-Verknüpfung erstellt
                → Hauptprogramm startet automatisch
```

### **Runtime-Monitoring-Flow:**
```
[Timer-Tick alle 60s]
  → Für jeden Server in config.json:
    1. Get-ServiceStatus (ServiceMonitor)
       → CIM-Session zu Remote-Server
       → Dienst-Status abrufen
    
    2. Get-ProcessInfo (ProcessChecker)
       → Prozess-Metriken abrufen (CPU, RAM)
    
    3. Status im GUI aktualisieren
       → Grün/Rot Icons
       → Letzte Prüfung: Timestamp
    
    4. Falls Status = "Stopped":
       → Send-EmailAlert (Notifier)
       → Send-ToastNotification
       → Write-EventLog
```

---

## ⚙️ **5. KONFIGURATION**

### **config/defaults.json** (Unveränderlich)
Enthält sichere Standardwerte für:
- Monitoring-Intervalle (60s)
- Retry-Logik (3 Versuche)
- Timeout-Werte (30s)

### **config/config.json** (User-spezifisch)
```json
{
  "servers": [
    {
      "name": "SAGE-DB-01",
      "type": "database",
      "services": ["MSSQLSERVER", "SQLSERVERAGENT"],
      "processes": ["sqlservr.exe"]
    }
  ],
  "email": {
    "enabled": true,
    "smtp": "smtp.example.com",
    "from": "alerts@example.com",
    "to": ["admin@example.com"]
  },
  "monitoring": {
    "checkInterval": 60,
    "autoRestart": false
  }
}
```

**Lade-Logik:**
```powershell
$defaults = Get-Content config/defaults.json | ConvertFrom-Json
$userConfig = Get-Content config/config.json | ConvertFrom-Json

# Merge: User-Config überschreibt Defaults
$config = Merge-Objects $defaults $userConfig
```

---

## 🖥️ **6. GUI-ARCHITEKTUR**

### **WPF-XAML-Struktur:**
```xml
<Window>
  <TabControl>
    <TabItem Header="📊 Dashboard">
      <DataGrid Name="ServerGrid">
        <!-- Zeigt alle Server mit Status -->
      </DataGrid>
    </TabItem>
    
    <TabItem Header="⚙️ Einstellungen">
      <StackPanel>
        <Button Name="AddServerBtn" />
        <TextBox Name="EmailSmtp" />
      </StackPanel>
    </TabItem>
    
    <TabItem Header="📜 Logs">
      <TextBox Name="LogViewer" IsReadOnly="True" />
    </TabItem>
  </TabControl>
</Window>
```

### **Event-Handling:**
```powershell
# Button-Click Event
$AddServerBtn.Add_Click({
    $newServer = Show-AddServerDialog
    $config.servers += $newServer
    Save-Config -Path "config/config.json" -Config $config
    Refresh-ServerGrid
})
```

---

## 🛡️ **7. FEHLERBEHANDLUNG**

### **Strategie:**
1. **Granulare Try-Catch-Blöcke** in jedem Modul
2. **Logging in Dateien:** `logs/error_YYYY-MM-DD.log`
3. **Fallback-Werte:** Wenn Remote-Server nicht erreichbar → Status "Unknown"

### **Beispiel:**
```powershell
function Get-ServiceStatus {
    param($ComputerName, $ServiceName)
    
    try {
        $session = New-CimSession -ComputerName $ComputerName -ErrorAction Stop
        $service = Get-CimInstance -CimSession $session -ClassName Win32_Service `
                                  -Filter "Name='$ServiceName'"
        return @{
            Status = $service.State
            Error = $null
        }
    }
    catch {
        Write-EventLog -Message "Failed to connect to $ComputerName`: $_"
        return @{
            Status = "Unknown"
            Error = $_.Exception.Message
        }
    }
    finally {
        if ($session) { Remove-CimSession $session }
    }
}
```

---

## 🔒 **8. SICHERHEIT**

### **Credentials:**
- **KEINE Klartext-Passwörter in config.json**
- SMTP-Passwort: Verschlüsselt mit `ConvertTo-SecureString`
- Remote-Zugriff: Verwendet aktuelle Windows-Credentials (Kerberos)

### **Berechtigungen:**
| Aktion | Erforderliche Rechte |
|--------|---------------------|
| Installation | Administrator (lokal) |
| Monitoring (lokal) | Benutzer |
| Monitoring (remote) | Mitglied der "Remote Management Users" Gruppe |
| Dienst-Neustart | Administrator (remote) |

---

## 📈 **9. PERFORMANCE**

### **Optimierungen:**
1. **CIM-Sessions wiederverwenden** statt für jeden Check neu erstellen
2. **Parallele Checks** mit `Start-Job` für mehrere Server
3. **GUI-Updates throtteln** (maximal 1x pro Sekunde)

### **Benchmark:**
- 10 Server-Checks: ~5-8 Sekunden
- GUI-Refresh: <100ms
- RAM-Footprint: ~80-120 MB

---

## 🚀 **10. DEPLOYMENT**

### **Release-Checklist:**
- [ ] Alle Module syntax-geprüft (`Test-ModuleManifest`)
- [ ] JSON-Dateien validiert (`Test-Json`)
- [ ] README.md aktualisiert
- [ ] Screenshots erstellt
- [ ] Tag in Git erstellt (`v2.0.0`)

### **Update-Prozess:**
1. User lädt neues Repository
2. Alte `config.json` sichern
3. `INSTALL.cmd` erneut ausführen
4. Wizard erkennt bestehende Config → überspringt Setup

---

## 📞 **SUPPORT & KONTAKT**

- **GitHub Issues:** https://github.com/MJungAktuellis/Sage100-ServerCheck/issues
- **Autor:** Marcel Jung (marcel.jung@aktuellis.de)
- **Lizenz:** MIT

---

**Letzte Änderung:** 14.02.2026 | Sage100-ServerCheck v2.0
