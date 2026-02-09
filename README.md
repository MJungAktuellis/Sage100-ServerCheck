# 🖥️ Sage 100 Server Check Tool

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/MJungAktuellis/Sage100-ServerCheck/graphs/commit-activity)

Ein umfassendes PowerShell-Tool zur Überwachung und Diagnose von Sage 100 Server-Komponenten.

---

## 📋 Inhaltsverzeichnis

- [Features](#-features)
- [Voraussetzungen](#-voraussetzungen)
- [Installation](#-installation)
- [Konfiguration](#-konfiguration)
- [Verwendung](#-verwendung)
- [Automatisierung](#-automatisierung)
- [Ausgabe & Berichte](#-ausgabe--berichte)
- [Troubleshooting](#-troubleshooting)
- [Entwicklung](#-entwicklung)
- [Lizenz](#-lizenz)

---

## ✨ Features

### 🔍 Umfassende Server-Überwachung

- **SQL Server Monitoring**
  - Service-Status Überprüfung
  - Datenbankverbindungs-Test
  - Sage-Datenbank Erkennung und Größenanalyse
  - Performance-Metriken

- **Windows Services**
  - Überwachung aller Sage-relevanten Dienste
  - Automatische Benachrichtigung bei Service-Ausfällen
  - Restart-Optionen (optional)

- **Disk Space Monitoring**
  - Überwachung aller lokalen Festplatten
  - Konfigurierbare Schwellwerte (Warning/Critical)
  - Trend-Analyse für Speicherverbrauch

- **Network Connectivity**
  - Ping-Tests zu definierten Endpunkten
  - Port-Verfügbarkeits-Checks
  - Latenz-Messung

### 📊 Reporting & Benachrichtigungen

- **HTML-Reports**
  - Professionelle, übersichtliche Darstellung
  - Farbcodierte Status-Indikatoren
  - Detaillierte Check-Ergebnisse
  - Zeitstempel für alle Checks

- **E-Mail-Benachrichtigungen**
  - Automatischer Versand bei Problemen
  - Konfigurierbare Empfänger-Listen
  - HTML-formatierte E-Mails mit Report-Anhang
  - Optional: Nur bei Fehlern versenden

### 🛠️ Entwickler-Features

- **Modulare Architektur**
  - Wiederverwendbare PowerShell-Module
  - Einfache Erweiterbarkeit
  - Klare Trennung der Verantwortlichkeiten

- **Logging**
  - Detaillierte Log-Dateien
  - Verschiedene Log-Level (Info, Warning, Error, Debug)
  - Automatische Log-Rotation

- **Testing**
  - Pester-Tests für alle Kernfunktionen
  - Einfache Testausführung
  - CI/CD-ready

---

## 📦 Voraussetzungen

### System-Anforderungen

- **Betriebssystem:** Windows Server 2012 R2 oder höher / Windows 10/11
- **PowerShell:** Version 5.1 oder höher
- **Berechtigungen:** Administrator-Rechte für Installation und Ausführung
- **.NET Framework:** 4.5 oder höher

### Optional

- **Pester:** Für Unit-Tests (wird automatisch installiert)
- **SMTP-Server:** Für E-Mail-Benachrichtigungen
- **SQL Server:** Für SQL-Monitoring (MSSQL 2012+)

### Netzwerk

- Zugriff auf die zu überwachenden Server/Services
- SMTP-Zugriff (Port 587/465) für E-Mail-Benachrichtigungen

---

## 🚀 Installation

### Methode 1: Automatische Installation (Empfohlen)

1. **Repository klonen oder herunterladen:**

```powershell
# Mit Git
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck

# Oder ZIP herunterladen und entpacken
```

2. **PowerShell als Administrator öffnen:**

```powershell
# Rechtsklick auf PowerShell > Als Administrator ausführen
```

3. **Execution Policy anpassen (falls nötig):**

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

4. **Installations-Skript ausführen:**

```powershell
.\Install.ps1 -InstallPath "C:\Program Files\Sage100-ServerCheck" -CreateScheduledTask
```

**Parameter:**
- `-InstallPath`: Zielverzeichnis (Standard: `C:\Program Files\Sage100-ServerCheck`)
- `-CreateScheduledTask`: Erstellt automatisch einen Scheduled Task für regelmäßige Checks

### Methode 2: Manuelle Installation

1. **Verzeichnis erstellen:**

```powershell
New-Item -ItemType Directory -Path "C:\Program Files\Sage100-ServerCheck" -Force
```

2. **Dateien kopieren:**

Kopiere alle Dateien aus dem Repository in das Installationsverzeichnis:

```
C:\Program Files\Sage100-ServerCheck\
├── Config/
│   └── config.json
├── Modules/
│   ├── ServerCheck.psm1
│   ├── Logger.psm1
│   └── NotificationHandler.psm1
├── Logs/
├── Tests/
│   └── ServerCheck.Tests.ps1
├── Sage100-ServerCheck.ps1
└── README.md
```

3. **Konfiguration anpassen:**

Bearbeite `Config\config.json` mit deinen Einstellungen (siehe [Konfiguration](#-konfiguration)).

### Installations-Überprüfung

Test die Installation mit:

```powershell
cd "C:\Program Files\Sage100-ServerCheck"
.\Sage100-ServerCheck.ps1 -Verbose
```

Du solltest eine Ausgabe mit allen Check-Ergebnissen sehen.

---

## ⚙️ Konfiguration

Die Konfiguration erfolgt über die Datei `Config\config.json`.

### Beispiel-Konfiguration

```json
{
  "SqlServer": {
    "ServerName": "localhost\\SQLEXPRESS",
    "ServiceName": "MSSQL$SQLEXPRESS",
    "Databases": ["Sage100_Production", "Sage100_Test"]
  },
  "RequiredServices": [
    "SageDataService",
    "SageApplicationService",
    "SageLicenseService"
  ],
  "DiskSpace": {
    "MinimumFreePercent": 15,
    "CriticalPercent": 10
  },
  "NetworkEndpoints": [
    {
      "Host": "sage-app-server.local",
      "Port": 1433,
      "Critical": true
    }
  ],
  "Email": {
    "Enabled": true,
    "SmtpServer": "smtp.office365.com",
    "Port": 587,
    "UseSsl": true,
    "From": "servercheck@company.com",
    "To": ["admin@company.com"],
    "Subject": "Sage 100 Server Status: {STATUS}",
    "SendOnlyOnError": true
  },
  "Scheduling": {
    "Enabled": true,
    "IntervalMinutes": 30
  }
}
```

### Konfigurations-Parameter

#### SQL Server

| Parameter | Beschreibung | Beispiel |
|-----------|--------------|----------|
| `ServerName` | SQL Server Instanz | `localhost\\SQLEXPRESS` |
| `ServiceName` | Windows Service Name | `MSSQL$SQLEXPRESS` |
| `Databases` | Zu überwachende Datenbanken | `["Sage100_DB"]` |

#### Required Services

Liste aller Windows-Services, die überwacht werden sollen:

```json
"RequiredServices": [
  "SageDataService",
  "SageApplicationService"
]
```

#### Disk Space

| Parameter | Beschreibung | Standard |
|-----------|--------------|----------|
| `MinimumFreePercent` | Warning-Schwelle | `15` |
| `CriticalPercent` | Critical-Schwelle | `10` |

#### Network Endpoints

Überwache Netzwerkverbindungen:

```json
{
  "Host": "server.domain.local",
  "Port": 1433,
  "Critical": true  // true = CRITICAL Status bei Ausfall
}
```

#### E-Mail

| Parameter | Beschreibung | Beispiel |
|-----------|--------------|----------|
| `Enabled` | E-Mail aktivieren | `true` |
| `SmtpServer` | SMTP Server | `smtp.office365.com` |
| `Port` | SMTP Port | `587` (TLS) oder `465` (SSL) |
| `UseSsl` | SSL/TLS verwenden | `true` |
| `From` | Absender-Adresse | `noreply@company.com` |
| `To` | Empfänger (Array) | `["admin@company.com"]` |
| `SendOnlyOnError` | Nur bei Fehlern | `true` |

**Authentifizierung:**

Für SMTP-Authentifizierung (z.B. Office 365):

```json
"Email": {
  ...
  "Username": "servercheck@company.com",
  "Password": "DeinPasswort"  // ⚠️ Sicher speichern!
}
```

> **⚠️ Sicherheitshinweis:** Speichere keine Passwörter im Klartext! Nutze Windows Credential Manager oder App-Passwörter.

---

## 💻 Verwendung

### Basis-Ausführung

```powershell
# Einfacher Check
.\Sage100-ServerCheck.ps1

# Mit detaillierter Ausgabe
.\Sage100-ServerCheck.ps1 -Verbose

# Mit E-Mail-Versand
.\Sage100-ServerCheck.ps1 -SendEmail

# Eigene Config-Datei
.\Sage100-ServerCheck.ps1 -ConfigPath "C:\Custom\config.json"
```

### Parameter

| Parameter | Typ | Beschreibung |
|-----------|-----|--------------|
| `-ConfigPath` | String | Pfad zur Config-Datei (Standard: `.\Config\config.json`) |
| `-SendEmail` | Switch | E-Mail senden (auch wenn kein Fehler) |
| `-Verbose` | Switch | Detaillierte Ausgabe |

### Exit Codes

Das Skript gibt folgende Exit Codes zurück:

- `0` - Alles OK
- `1` - Warnings gefunden
- `2` - Critical Errors gefunden

**Verwendung in Scripts:**

```powershell
.\Sage100-ServerCheck.ps1
if ($LASTEXITCODE -eq 2) {
    Write-Host "Kritische Fehler gefunden!"
    # Notfall-Aktionen
}
```

---

## 🕒 Automatisierung

### Scheduled Task (Empfohlen)

Erstelle einen Scheduled Task für regelmäßige Checks:

```powershell
# Mit Install.ps1
.\Install.ps1 -CreateScheduledTask

# Oder manuell
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File 'C:\Program Files\Sage100-ServerCheck\Sage100-ServerCheck.ps1' -SendEmail"

$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 30) `
    -RepetitionDuration ([TimeSpan]::MaxValue)

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Sage100-ServerCheck" `
    -Action $Action -Trigger $Trigger -Principal $Principal
```

### Task bearbeiten

```powershell
# Status anzeigen
Get-ScheduledTask -TaskName "Sage100-ServerCheck"

# Manuell ausführen
Start-ScheduledTask -TaskName "Sage100-ServerCheck"

# Deaktivieren
Disable-ScheduledTask -TaskName "Sage100-ServerCheck"

# Löschen
Unregister-ScheduledTask -TaskName "Sage100-ServerCheck" -Confirm:$false
```

### Intervalle anpassen

Ändere das Intervall in der Task-Definition oder in `config.json`:

```json
"Scheduling": {
  "IntervalMinutes": 15  // Alle 15 Minuten
}
```

---

## 📊 Ausgabe & Berichte

### Console-Ausgabe

```
=== Sage 100 Server Check gestartet ===
[2024-01-15 14:30:00] [Info] Prüfe SQL Server Status...
[2024-01-15 14:30:02] [Info] Prüfe Sage Dienste...
[2024-01-15 14:30:03] [Info] Prüfe Festplattenspeicher...
[2024-01-15 14:30:04] [Info] Prüfe Netzwerkverbindung...
[2024-01-15 14:30:05] [Info] Gesamtstatus: OK
=== Server Check abgeschlossen ===

Report gespeichert: C:\Program Files\Sage100-ServerCheck\Logs\Report_20240115_143005.html
```

### HTML-Report

Professionell formatierte HTML-Berichte werden automatisch erstellt:

- **Speicherort:** `Logs\Report_<Timestamp>.html`
- **Inhalt:**
  - Übersicht mit Gesamtstatus
  - Detaillierte Ergebnisse aller Checks
  - Farbcodierte Status-Indikatoren
  - Zeitstempel für jeden Check

### Log-Dateien

Detaillierte Logs werden in `Logs\` gespeichert:

```
Logs/
├── ServerCheck_20240115_143005.log
├── ServerCheck_20240115_150005.log
└── Report_20240115_143005.html
```

**Log-Format:**

```
[2024-01-15 14:30:00] [Info] SQL Server Service läuft
[2024-01-15 14:30:01] [Info] Datenbankverbindung erfolgreich
[2024-01-15 14:30:02] [Warning] Festplatte C: hat nur 12% freien Speicher
```

### E-Mail-Berichte

Bei aktivierter E-Mail-Benachrichtigung:

- **Betreff:** Enthält Status (OK/WARNING/CRITICAL)
- **Body:** HTML-formatiert mit allen Details
- **Anhang:** HTML-Report-Datei

---

## 🔧 Troubleshooting

### Häufige Probleme

#### 1. "Execution Policy" Fehler

**Fehler:**
```
.\Sage100-ServerCheck.ps1 cannot be loaded because running scripts is disabled
```

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 2. SQL Server Verbindungsfehler

**Fehler:**
```
Datenbankverbindung fehlgeschlagen: A network-related error occurred
```

**Lösung:**
- Prüfe SQL Server Service Status: `Get-Service -Name "MSSQL$SQLEXPRESS"`
- Prüfe Firewall-Regeln
- Verifiziere `ServerName` in config.json
- Teste Verbindung: `sqlcmd -S localhost\SQLEXPRESS -Q "SELECT @@VERSION"`

#### 3. E-Mail-Versand schlägt fehl

**Fehler:**
```
E-Mail konnte nicht gesendet werden: 5.7.57 SMTP; Unable to relay
```

**Lösungen:**
- **Office 365:** Nutze App-Passwort statt normales Passwort
- **Gmail:** Aktiviere "Weniger sichere Apps" oder nutze App-Passwort
- **Port:** Probiere Port 587 (TLS) statt 465 (SSL)
- **Authentifizierung:** Füge Username/Password in config.json hinzu

#### 4. Module werden nicht gefunden

**Fehler:**
```
Import-Module : The specified module 'ServerCheck.psm1' was not loaded
```

**Lösung:**
```powershell
# Prüfe Pfade
Get-ChildItem -Path "C:\Program Files\Sage100-ServerCheck\Modules"

# Absolute Pfade verwenden
Import-Module "C:\Program Files\Sage100-ServerCheck\Modules\ServerCheck.psm1" -Force
```

#### 5. Scheduled Task läuft nicht

**Lösung:**
```powershell
# Task-Status prüfen
Get-ScheduledTask -TaskName "Sage100-ServerCheck" | Select-Object State, LastRunTime, LastTaskResult

# Task-Historie anzeigen
Get-ScheduledTaskInfo -TaskName "Sage100-ServerCheck"

# Event Log prüfen
Get-EventLog -LogName "Microsoft-Windows-TaskScheduler/Operational" -Newest 10
```

### Debug-Modus

Für detaillierte Fehlersuche:

```powershell
.\Sage100-ServerCheck.ps1 -Verbose -Debug
```

### Log-Analyse

```powershell
# Letzte Fehler anzeigen
Get-Content "Logs\ServerCheck_*.log" | Select-String -Pattern "\[Error\]"

# Log mit Zeitstempel
Get-ChildItem "Logs\*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

---

## 🧪 Entwicklung

### Module-Struktur

```
Modules/
├── ServerCheck.psm1          # Kern-Funktionen (SQL, Services, Disk, Network)
├── Logger.psm1               # Logging-Infrastruktur
└── NotificationHandler.psm1  # E-Mail-Versand
```

### Eigene Checks hinzufügen

**Beispiel: CPU-Auslastung prüfen**

In `Modules/ServerCheck.psm1`:

```powershell
function Test-CpuUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$ThresholdPercent = 80
    )
    
    $Result = @{
        CheckName = "CPU Usage"
        Status = "OK"
        Details = @()
        Timestamp = Get-Date
    }
    
    $CpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' | 
                Select-Object -ExpandProperty CounterSamples | 
                Select-Object -ExpandProperty CookedValue
    
    $CpuUsage = [math]::Round($CpuUsage, 2)
    
    if ($CpuUsage -gt $ThresholdPercent) {
        $Result.Status = "WARNING"
        $Result.Details += "CPU-Auslastung bei $CpuUsage%"
    } else {
        $Result.Details += "CPU-Auslastung: $CpuUsage%"
    }
    
    return $Result
}

Export-ModuleMember -Function Test-CpuUsage
```

In `Sage100-ServerCheck.ps1`:

```powershell
# CPU Check hinzufügen
$CpuCheck = Test-CpuUsage -ThresholdPercent 80
$Results.Checks += $CpuCheck
```

### Unit Tests

Tests mit Pester ausführen:

```powershell
# Pester installieren (falls nicht vorhanden)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Tests ausführen
Invoke-Pester -Path "Tests\ServerCheck.Tests.ps1"

# Mit Coverage
Invoke-Pester -Path "Tests\ServerCheck.Tests.ps1" -CodeCoverage "Modules\*.psm1"
```

### CI/CD Integration

**GitHub Actions Beispiel:**

```yaml
name: Test PowerShell Scripts

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Pester Tests
        shell: powershell
        run: |
          Install-Module -Name Pester -Force -SkipPublisherCheck
          Invoke-Pester -Path "Tests\*.Tests.ps1" -OutputFormat NUnitXml -OutputFile TestResults.xml
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: TestResults.xml
```

---

## 📝 Best Practices

### Sicherheit

1. **Passwörter nicht im Klartext speichern:**

```powershell
# Passwort verschlüsselt speichern
$SecurePassword = Read-Host "SMTP Passwort" -AsSecureString
$SecurePassword | ConvertFrom-SecureString | Out-File "smtp_password.txt"

# Im Skript verwenden
$EncryptedPassword = Get-Content "smtp_password.txt" | ConvertTo-SecureString
```

2. **Least Privilege:** Führe das Skript mit minimalen Berechtigungen aus

3. **Log-Rotation:** Lösche alte Logs regelmäßig:

```powershell
Get-ChildItem "Logs\*.log" -Recurse | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
    Remove-Item
```

### Performance

- **Intervalle anpassen:** Nicht öfter als alle 5 Minuten
- **Timeout-Werte:** Setze sinnvolle Timeouts für SQL/Network-Checks
- **Parallele Ausführung:** Nutze `Start-Job` für unabhängige Checks

### Monitoring

- **Überwache die Überwachung:** Prüfe regelmäßig, ob der Scheduled Task läuft
- **Alert-Fatigue vermeiden:** SendOnlyOnError aktivieren
- **Trend-Analyse:** Sammle historische Daten für Kapazitätsplanung

---

## 🤝 Beitragen

Contributions sind willkommen!

1. Fork das Repository
2. Erstelle einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

### Coding Standards

- PowerShell Best Practices befolgen
- Kommentare auf Deutsch oder Englisch
- Pester-Tests für neue Features
- README aktualisieren

---

## 📄 Lizenz

Dieses Projekt ist unter der MIT Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

---

## 👤 Autor

**MJung**

- GitHub: [@MJungAktuellis](https://github.com/MJungAktuellis)

---

## 🙏 Danksagungen

- Sage 100 Community
- PowerShell Community
- Alle Contributors

---

## 📞 Support

Bei Fragen oder Problemen:

1. **Issues:** Erstelle ein [GitHub Issue](https://github.com/MJungAktuellis/Sage100-ServerCheck/issues)
2. **Diskussionen:** Nutze [GitHub Discussions](https://github.com/MJungAktuellis/Sage100-ServerCheck/discussions)
3. **E-Mail:** (Optional: Deine Support-E-Mail)

---

## 🗺️ Roadmap

### Version 2.0 (Geplant)

- [ ] GUI-Version mit WPF
- [ ] Dashboard mit Echtzeit-Monitoring
- [ ] REST API für externe Integrationen
- [ ] Docker-Support
- [ ] Multi-Server Monitoring
- [ ] Performance-Metriken & Graphen
- [ ] Alert-Management System
- [ ] Mobile App (iOS/Android)

---

## 📊 Changelog

### Version 1.0.0 (2024-01-15)

#### ✨ Features
- SQL Server Monitoring
- Windows Services Check
- Disk Space Monitoring
- Network Connectivity Tests
- HTML Report Generierung
- E-Mail Benachrichtigungen
- Scheduled Task Integration
- Pester Unit Tests
- Umfassende Dokumentation

#### 🐛 Bugfixes
- Initial Release

---

**Made with ❤️ for the Sage 100 Community**
