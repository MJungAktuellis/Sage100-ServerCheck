# 📦 Sage100-ServerCheck - Installationsanleitung

> **Version:** 2.0  
> **Autor:** DevOps Team  
> **Datum:** 2026-02-09  
> **Status:** ✅ Produktionsreif

---

## 📋 Inhaltsverzeichnis

1. [Systemvoraussetzungen](#-systemvoraussetzungen)
2. [Schnellinstallation (Empfohlen)](#-schnellinstallation-empfohlen)
3. [Manuelle Installation](#-manuelle-installation)
4. [Konfiguration](#-konfiguration)
5. [Erste Schritte](#-erste-schritte)
6. [Automatisierung (Scheduled Task)](#-automatisierung-scheduled-task)
7. [Deinstallation](#-deinstallation)
8. [Troubleshooting](#-troubleshooting)

---

## 🔧 Systemvoraussetzungen

### Betriebssystem
- ✅ Windows Server 2016 oder höher
- ✅ Windows 10/11 Pro/Enterprise

### Software-Komponenten
| Komponente | Minimum | Empfohlen |
|------------|---------|-----------|
| **PowerShell** | 5.1 | 7.4+ |
| **SQL Server** | 2014 | 2019/2022 |
| **.NET Framework** | 4.7.2 | 4.8 |
| **Arbeitsspeicher** | 4 GB | 8 GB+ |
| **Festplatte** | 100 MB frei | 1 GB+ |

### Berechtigungen
- 🔐 **Administrator-Rechte** auf dem Server
- 🔐 **SQL Server sysadmin** oder **db_datareader** für Sage-Datenbanken
- 🔐 **Lesezugriff** auf Windows Event Log

### Netzwerk
- 📡 Port **1433** (SQL Server) erreichbar
- 📡 SMTP-Server (optional, für E-Mail-Benachrichtigungen)

---

## ⚡ Schnellinstallation (Empfohlen)

### Schritt 1: Repository herunterladen

**Option A: Git Clone (empfohlen)**
```powershell
# In PowerShell als Administrator:
cd C:\
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck
```

**Option B: ZIP-Download**
1. Öffne https://github.com/MJungAktuellis/Sage100-ServerCheck
2. Klicke auf **Code** → **Download ZIP**
3. Entpacke nach `C:\Sage100-ServerCheck\`

---

### Schritt 2: Installation ausführen

**🚀 ONE-CLICK-INSTALLATION:**

1. **Rechtsklick** auf `EASY-INSTALL.cmd`
2. Wähle **"Als Administrator ausführen"**

![EASY-INSTALL Kontextmenü](https://via.placeholder.com/600x150/0078D4/FFFFFF?text=Rechtsklick+%3E+Als+Administrator+ausf%C3%BChren)

3. Das Installationsfenster öffnet sich automatisch:

```
╔════════════════════════════════════════════════════════════╗
║         SAGE100-SERVERCHECK INSTALLATION v2.0              ║
╠════════════════════════════════════════════════════════════╣
║ [✓] Administrator-Rechte erkannt                           ║
║ [✓] PowerShell 5.1 gefunden                                ║
║ [✓] .NET Framework 4.8 vorhanden                           ║
║ [ ] Module werden installiert...                           ║
╚════════════════════════════════════════════════════════════╝
```

4. **Warten**, bis folgende Meldung erscheint:
```
✅ Installation erfolgreich abgeschlossen!

📁 Installiert in: C:\Program Files\Sage100-ServerCheck
🖥️  Desktop-Verknüpfung erstellt
⏰ Scheduled Task "Sage100-DailyCheck" konfiguriert

Drücken Sie eine beliebige Taste zum Beenden...
```

---

## 🛠️ Manuelle Installation

Falls die automatische Installation fehlschlägt, folge diesen Schritten:

### Schritt 1: PowerShell Execution Policy anpassen
```powershell
# Als Administrator ausführen:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### Schritt 2: Installationsskript ausführen
```powershell
cd C:\Sage100-ServerCheck
.\Install.ps1 -Verbose
```

### Schritt 3: Module manuell importieren
```powershell
# Prüfen, ob alle Module geladen werden können:
Import-Module .\Modules\DebugLogger.psm1 -Force
Import-Module .\Modules\SystemCheck.psm1 -Force
Import-Module .\Modules\NetworkCheck.psm1 -Force
Import-Module .\Modules\ComplianceCheck.psm1 -Force
Import-Module .\Modules\WorkLog.psm1 -Force
Import-Module .\Modules\ReportGenerator.psm1 -Force
```

**Erwartete Ausgabe:**
```
ModuleType Version    Name
---------- -------    ----
Script     2.0        DebugLogger
Script     2.0        SystemCheck
Script     2.0        NetworkCheck
...
```

---

## ⚙️ Konfiguration

### Config-Datei bearbeiten

Öffne `Config\config.json` in einem Texteditor:

```json
{
  "SqlServer": {
    "ServerName": "DEIN-SQL-SERVER\\SAGE",
    "InstanceName": "SAGE",
    "Databases": [
      "Mandant001",
      "Mandant002"
    ],
    "ConnectionTimeout": 15
  },
  "Monitoring": {
    "CheckInterval": 300,
    "EnableEmailAlerts": true,
    "EmailRecipients": [
      "admin@deinefirma.de",
      "it-support@deinefirma.de"
    ]
  },
  "SMTP": {
    "Server": "smtp.office365.com",
    "Port": 587,
    "UseSsl": true,
    "From": "sage-monitoring@deinefirma.de",
    "Username": "sage-monitoring@deinefirma.de",
    "PasswordSecure": ""
  },
  "Logging": {
    "Level": "Info",
    "Path": "C:\\Logs\\Sage100-ServerCheck",
    "MaxFileSizeMB": 50,
    "RetentionDays": 30
  },
  "Services": [
    "MSSQL$SAGE",
    "OAServer",
    "SageApplicationServer"
  ],
  "Performance": {
    "CpuThreshold": 80,
    "MemoryThreshold": 85,
    "DiskSpaceThreshold": 90
  }
}
```

### 🔐 SMTP-Passwort verschlüsseln

```powershell
# Passwort sicher speichern:
$SmtpPassword = Read-Host "SMTP-Passwort eingeben" -AsSecureString
$SmtpPassword | ConvertFrom-SecureString | Out-File "Config\smtp_password.txt"
```

Dann in `config.json` anpassen:
```json
"PasswordSecure": "01000000d08c9ddf011..."
```

---

## 🚀 Erste Schritte

### Test 1: Grundfunktionen prüfen

```powershell
# Schnelltest (ohne Admin-Rechte):
.\Sage100-ServerCheck.ps1 -QuickScan

# Erwartete Ausgabe:
# ✅ SQL Server erreichbar
# ✅ Datenbanken online
# ⚠️  Dienst "OAServer" gestoppt
# ✅ Festplatte: 45% belegt
```

### Test 2: Vollständiger Check

```powershell
# Vollständiger Check (benötigt Admin-Rechte):
.\Sage100-ServerCheck.ps1 -FullCheck -Verbose

# Erstellt Report in: C:\Logs\Sage100-ServerCheck\Report-2026-02-09.html
```

### Test 3: GUI starten

```powershell
# Grafische Oberfläche starten:
.\Sage100-ServerCheck-GUI.ps1
```

**GUI-Screenshot:**
![Sage100-ServerCheck GUI](https://via.placeholder.com/800x600/1E1E1E/00FF00?text=Sage100+ServerCheck+GUI+%7C+Status%3A+All+Systems+Operational)

---

## ⏰ Automatisierung (Scheduled Task)

### Automatische Installation

Der Installer hat bereits einen Scheduled Task erstellt. Prüfe ihn mit:

```powershell
Get-ScheduledTask -TaskName "Sage100-DailyCheck" | Format-List
```

**Erwartete Ausgabe:**
```
TaskName  : Sage100-DailyCheck
State     : Ready
Triggers  : {Täglich um 08:00}
Actions   : {PowerShell.exe -File "C:\Program Files\Sage100-ServerCheck\Sage100-ServerCheck.ps1" -FullCheck}
```

### Manuelle Task-Konfiguration

Falls der Task fehlt, erstelle ihn manuell:

```powershell
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-ExecutionPolicy Bypass -File `"C:\Program Files\Sage100-ServerCheck\Sage100-ServerCheck.ps1`" -FullCheck"

$Trigger = New-ScheduledTaskTrigger -Daily -At 08:00

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Sage100-DailyCheck" `
  -Action $Action `
  -Trigger $Trigger `
  -Principal $Principal `
  -Description "Täglicher Sage100 Server-Check mit automatischem Report"
```

### Task-Einstellungen anpassen

```powershell
# Trigger auf 2x täglich ändern (08:00 und 16:00):
$Task = Get-ScheduledTask -TaskName "Sage100-DailyCheck"
$Task | Set-ScheduledTask -Trigger @(
  (New-ScheduledTaskTrigger -Daily -At 08:00),
  (New-ScheduledTaskTrigger -Daily -At 16:00)
)
```

---

## 🗑️ Deinstallation

### Automatische Deinstallation

```powershell
# Als Administrator ausführen:
C:\Program Files\Sage100-ServerCheck\Uninstall.ps1
```

### Manuelle Deinstallation

```powershell
# 1. Scheduled Task entfernen:
Unregister-ScheduledTask -TaskName "Sage100-DailyCheck" -Confirm:$false

# 2. Desktop-Verknüpfung löschen:
Remove-Item "$env:PUBLIC\Desktop\Sage100-ServerCheck.lnk" -Force

# 3. Programmdateien löschen:
Remove-Item "C:\Program Files\Sage100-ServerCheck" -Recurse -Force

# 4. Logs behalten oder löschen:
# Remove-Item "C:\Logs\Sage100-ServerCheck" -Recurse -Force
```

---

## 🔧 Troubleshooting

### Problem 1: "Ausführung wurde verhindert"

**Fehlermeldung:**
```
.\Sage100-ServerCheck.ps1 : Die Datei [...] kann nicht geladen werden, da die Ausführung
von Skripts auf diesem System deaktiviert ist.
```

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

---

### Problem 2: "SQL Server nicht erreichbar"

**Fehlermeldung:**
```
❌ SQL Server-Verbindung fehlgeschlagen: Timeout expired
```

**Lösungsschritte:**
1. **SQL Server-Dienst prüfen:**
   ```powershell
   Get-Service -Name "MSSQL*" | Format-Table -AutoSize
   ```

2. **Firewall-Regel prüfen:**
   ```powershell
   Test-NetConnection -ComputerName "DEIN-SERVER" -Port 1433
   ```

3. **SQL Server Browser aktivieren:**
   - Öffne **SQL Server Configuration Manager**
   - Gehe zu **SQL Server-Dienste**
   - Starte **SQL Server-Browser**

4. **Verbindungsstring testen:**
   ```powershell
   $ConnectionString = "Server=DEIN-SERVER\SAGE;Database=master;Integrated Security=True;Connection Timeout=5;"
   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
   $SqlConnection.Open()
   $SqlConnection.State  # Sollte "Open" zurückgeben
   $SqlConnection.Close()
   ```

---

### Problem 3: "Modul konnte nicht geladen werden"

**Fehlermeldung:**
```
Import-Module : Die angegebene Modul "DebugLogger" wurde nicht geladen, da in keinem Modulverzeichnis eine gültige Moduldatei gefunden wurde.
```

**Lösung:**
```powershell
# Modulpfade prüfen:
$env:PSModulePath -split ';'

# Module manuell mit vollem Pfad laden:
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ScriptRoot\Modules\DebugLogger.psm1" -Force -Verbose
```

---

### Problem 4: "Zugriff verweigert" bei Event-Log

**Fehlermeldung:**
```
Write-EventLog : Zugriff verweigert
```

**Lösung:**
```powershell
# Event-Quelle als Administrator registrieren:
New-EventLog -LogName "Application" -Source "Sage100ServerCheck"
```

---

### Problem 5: E-Mails werden nicht versendet

**Fehlermeldung:**
```
❌ E-Mail konnte nicht gesendet werden: Der SMTP-Server erfordert eine sichere Verbindung
```

**Lösungsschritte:**

1. **SMTP-Einstellungen prüfen:**
   ```json
   "SMTP": {
     "Server": "smtp.office365.com",
     "Port": 587,
     "UseSsl": true  // ← Muss "true" sein für Office365
   }
   ```

2. **Authentifizierung testen:**
   ```powershell
   $SmtpServer = "smtp.office365.com"
   $SmtpPort = 587
   $SmtpUser = "dein-user@firma.de"
   $SmtpPassword = Read-Host "Passwort" -AsSecureString
   
   $Credential = New-Object System.Management.Automation.PSCredential($SmtpUser, $SmtpPassword)
   
   Send-MailMessage `
     -To "test@firma.de" `
     -From "dein-user@firma.de" `
     -Subject "Test" `
     -Body "Test-Mail" `
     -SmtpServer $SmtpServer `
     -Port $SmtpPort `
     -UseSsl `
     -Credential $Credential
   ```

3. **Firewall-Regel für SMTP-Port hinzufügen:**
   ```powershell
   New-NetFirewallRule `
     -DisplayName "SMTP Outbound" `
     -Direction Outbound `
     -Protocol TCP `
     -RemotePort 587 `
     -Action Allow
   ```

---

### Problem 6: Performance-Probleme bei großen Datenbanken

**Symptom:**
```
⚠️  Check dauert länger als 5 Minuten
```

**Optimierungen:**

1. **Datenbank-Checks limitieren:**
   ```json
   "SqlServer": {
     "CheckOnlyOnlineDatabases": true,
     "SkipSystemDatabases": true,
     "MaxParallelChecks": 4
   }
   ```

2. **Performance-Counter deaktivieren:**
   ```json
   "Monitoring": {
     "EnablePerformanceCounters": false
   }
   ```

3. **Verbindungs-Timeout reduzieren:**
   ```json
   "SqlServer": {
     "ConnectionTimeout": 5  // Von 15 auf 5 Sekunden
   }
   ```

---

## 📊 Log-Dateien

### Log-Verzeichnis-Struktur

```
C:\Logs\Sage100-ServerCheck\
├── 2026-02-09_Check.log          # Tägliches Haupt-Log
├── 2026-02-09_Errors.log         # Nur Fehler
├── 2026-02-09_Report.html        # HTML-Report
├── Archive\
│   ├── 2026-02-08_Check.log
│   └── 2026-02-07_Check.log
└── Performance\
    └── 2026-02-09_Counters.csv   # Performance-Daten
```

### Log-Dateien analysieren

```powershell
# Letzte 50 Fehler anzeigen:
Get-Content "C:\Logs\Sage100-ServerCheck\*_Errors.log" -Tail 50

# Nach spezifischem Fehler suchen:
Select-String -Path "C:\Logs\Sage100-ServerCheck\*.log" -Pattern "SQL Server" -CaseSensitive
```

---

## 📞 Support & Kontakt

**GitHub Issues:**  
https://github.com/MJungAktuellis/Sage100-ServerCheck/issues

**Dokumentation:**  
https://github.com/MJungAktuellis/Sage100-ServerCheck/wiki

**E-Mail:**  
support@deinefirma.de

---

## 📝 Changelog

### Version 2.0 (2026-02-09)
- ✅ Vollständige Installationsanleitung hinzugefügt
- ✅ Automatischer EASY-INSTALL.cmd
- ✅ Verbesserte Fehlerbehandlung
- ✅ GUI mit WPF/XAML
- ✅ E-Mail-Benachrichtigungen
- ✅ Performance-Monitoring

### Version 1.0 (2025-12-01)
- 🎉 Erste öffentliche Version

---

## ✅ Installations-Checkliste

Nutze diese Checkliste, um sicherzustellen, dass alles korrekt installiert ist:

- [ ] **PowerShell 5.1+** installiert
- [ ] **Administrator-Rechte** verfügbar
- [ ] **Repository geklont** nach `C:\Sage100-ServerCheck`
- [ ] **EASY-INSTALL.cmd** ausgeführt
- [ ] **Config\config.json** angepasst (SQL Server-Name)
- [ ] **SMTP-Passwort** verschlüsselt
- [ ] **QuickScan-Test** erfolgreich durchgeführt
- [ ] **FullCheck-Test** erfolgreich durchgeführt
- [ ] **Scheduled Task** "Sage100-DailyCheck" aktiv
- [ ] **Desktop-Verknüpfung** funktioniert
- [ ] **Erste Test-E-Mail** erhalten
- [ ] **Log-Dateien** werden korrekt erstellt

---

**🎉 Installation abgeschlossen! Dein Sage100-Server wird jetzt automatisch überwacht.**
