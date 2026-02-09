# 🔍 Sage100 ServerCheck

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![.NET Framework](https://img.shields.io/badge/.NET%20Framework-4.5%2B-purple.svg)](https://dotnet.microsoft.com/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-brightgreen.svg)](https://github.com/MJungAktuellis/Sage100-ServerCheck/graphs/commit-activity)

**Professionelles Monitoring-Tool für Sage100-Serverumgebungen**

Automatisierte Überwachung von SQL Server, Windows-Diensten, Netzwerkverbindungen und Compliance-Status mit integrierter GUI und E-Mail-Benachrichtigungen.

---

## 📋 Features

### ✅ Kernfunktionalität
- **SQL Server Monitoring**
  - Verbindungstest mit konfigurierbarem Timeout
  - Datenbank-Status-Prüfung (Online, Offline, Restoring)
  - Mandanten-Datenbank-Verfügbarkeit
  - Backup-Status und Last Backup Time

- **Windows-Dienste-Überwachung**
  - SQL Server Service Status
  - Sage OA+Server Monitoring
  - Automatische Restart-Funktion (optional)

- **Netzwerk & Konnektivität**
  - ICMP Ping-Tests
  - TCP Port-Verfügbarkeit (1433, 443, etc.)
  - Latenz-Messung
  - DNS-Auflösung

- **Compliance & Sicherheit**
  - Windows Update Status
  - Firewall-Konfiguration
  - Disk Space Monitoring
  - Event Log Analyse (Critical/Error Events)

### 🎨 Benutzeroberflächen
- **WPF GUI** - Moderne grafische Oberfläche (XAML-basiert)
- **CLI-Modus** - Für Automatisierung und Skripte
- **Scheduled Tasks** - Automatische Checks im Hintergrund

### 📊 Reporting
- **HTML-Reports** - Detaillierte Zusammenfassungen
- **E-Mail-Benachrichtigungen** - Automatische Alerts bei Problemen
- **Event-Log-Integration** - Windows Event Log Einträge
- **CSV-Export** - Für externe Analyse

---

## ⚡ Quick Start

### 🚀 One-Click-Installation

```batch
# 1. Repository klonen oder ZIP herunterladen
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git

# 2. Als Administrator ausführen
EASY-INSTALL.cmd
```

**Das war's!** Die Installation:
- ✅ Prüft automatisch alle Voraussetzungen
- ✅ Erstellt Verzeichnisstruktur und Logs
- ✅ Konfiguriert PowerShell Execution Policy
- ✅ Erstellt Desktop-Verknüpfung

---

## 📖 Dokumentation

| Dokument | Beschreibung |
|----------|-------------|
| **[INSTALLATION.md](docs/INSTALLATION.md)** | Vollständige Installationsanleitung mit Screenshots |
| **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** | Häufige Probleme und Lösungen |
| **[Config/config.json](Config/config.json)** | Beispielkonfiguration mit Kommentaren |

---

## 🔧 Manuelle Installation

Falls die automatische Installation nicht funktioniert:

### Voraussetzungen
- Windows Server 2012 R2+ oder Windows 10/11
- PowerShell 5.1 oder höher
- .NET Framework 4.5+ (für GUI)
- Administrator-Rechte

### Schritt-für-Schritt

1. **Repository herunterladen**
   ```bash
   git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
   cd Sage100-ServerCheck
   ```

2. **Konfiguration anpassen**
   ```bash
   notepad Config\config.json
   ```
   
   Wichtige Einstellungen:
   - `SqlServerInstance` - Ihre SQL Server Instanz
   - `SmtpServer` - Mail-Server für Benachrichtigungen
   - `AlertRecipients` - E-Mail-Adressen für Alerts

3. **Execution Policy setzen**
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

4. **Ersten Test ausführen**
   ```powershell
   .\src\Sage100-ServerCheck.ps1 -QuickScan
   ```

---

## 💻 Verwendung

### GUI-Modus (empfohlen)
```powershell
.\src\Sage100-ServerCheck.ps1
```

### CLI-Modi
```powershell
# Schneller Basis-Check
.\src\Sage100-ServerCheck.ps1 -QuickScan

# Vollständiger System-Check
.\src\Sage100-ServerCheck.ps1 -FullCheck

# HTML-Report generieren
.\src\Sage100-ServerCheck.ps1 -ExportReport -OutputPath "C:\Reports"

# Nur SQL-Server-Check
.\src\Sage100-ServerCheck.ps1 -CheckSQL

# Nur Dienste-Check
.\src\Sage100-ServerCheck.ps1 -CheckServices
```

### Scheduled Task (Automatisierung)
```powershell
# Täglich um 6:00 Uhr ausführen
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\Sage100-ServerCheck\src\Sage100-ServerCheck.ps1 -FullCheck"

$Trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM

Register-ScheduledTask -TaskName "Sage100 Health Check" `
    -Action $Action -Trigger $Trigger -User "SYSTEM" -RunLevel Highest
```

---

## 📁 Projektstruktur

```
Sage100-ServerCheck/
├── src/
│   ├── Sage100-ServerCheck.ps1       # Hauptprogramm
│   └── Install.ps1                    # Installations-Skript
├── Modules/
│   ├── DebugLogger.psm1               # Logging-Modul
│   ├── SystemCheck.psm1               # System-Checks
│   ├── NetworkCheck.psm1              # Netzwerk-Tests
│   ├── ComplianceCheck.psm1           # Compliance-Prüfungen
│   ├── WorkLog.psm1                   # Arbeitsprotokoll
│   └── ReportGenerator.psm1           # Report-Generierung
├── Config/
│   └── config.json                    # Hauptkonfiguration
├── docs/
│   ├── INSTALLATION.md                # Installationsanleitung
│   └── TROUBLESHOOTING.md             # Fehlerbehebung
├── Tests/
│   └── Test-Prerequisites.ps1         # Voraussetzungsprüfung
├── Logs/                              # Log-Dateien (automatisch)
├── EASY-INSTALL.cmd                   # One-Click-Installer
├── README.md                          # Diese Datei
└── LICENSE                            # MIT-Lizenz
```

---

## 🔍 Beispiel-Output

### ✅ Erfolgreicher Check
```
╔══════════════════════════════════════════════════════════════╗
║          Sage100 ServerCheck v2.0 - System Status            ║
╚══════════════════════════════════════════════════════════════╝

[✓] SQL Server (SQLSERVER\SAGE100)          Online
[✓] Mandanten-Datenbank (Firma01)           Verfügbar
[✓] SQL Server Service                      Running
[✓] Sage OA+Server                          Running
[✓] Netzwerk-Verbindung (192.168.1.100)     OK (2ms)
[✓] Disk Space C:\                          120 GB frei (65%)
[✓] Windows Updates                         Aktuell

═══════════════════════════════════════════════════════════════
Status: GESUND ✓
Letzte Prüfung: 09.02.2026 22:15:30
Nächster Check: 10.02.2026 06:00:00
═══════════════════════════════════════════════════════════════
```

### ❌ Fehler erkannt
```
[✗] SQL Server (SQLSERVER\SAGE100)          OFFLINE
[!] Mandanten-Datenbank (Firma01)           Nicht erreichbar
[✓] SQL Server Service                      Running
[!] Sage OA+Server                          Stopped

═══════════════════════════════════════════════════════════════
Status: KRITISCH ✗
E-Mail-Benachrichtigung gesendet an: admin@firma.de
═══════════════════════════════════════════════════════════════
```

---

## 🚨 Troubleshooting

### Problem: "Execution Policy" Fehler
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

### Problem: Module können nicht geladen werden
```powershell
# Module entsperren
Get-ChildItem -Path .\Modules\*.psm1 | Unblock-File
```

### Problem: SQL Server-Verbindung schlägt fehl
1. Prüfen Sie `config.json` → `SqlServerInstance`
2. Testen Sie manuell:
   ```powershell
   Test-Connection -ComputerName "SQLSERVER" -Count 2
   sqlcmd -S "SQLSERVER\SAGE100" -Q "SELECT @@VERSION"
   ```

**Weitere Lösungen:** Siehe [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

---

## 🤝 Contributing

Beiträge sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature-Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add some AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

---

## 📝 Changelog

### v2.0 (2026-02-09)
- ✨ Vollständig überarbeitete Installation mit Fehlerprüfung
- 📚 Umfassende Dokumentation hinzugefügt
- 🐛 Modul-Pfad-Probleme behoben
- 🎨 Verbesserte GUI mit XAML
- ⚡ Performance-Optimierungen
- 🔒 Erweiterte Sicherheitsprüfungen

### v1.0 (Initial Release)
- 🎉 Erste öffentliche Version
- ✅ Grundlegende SQL Server Checks
- 📧 E-Mail-Benachrichtigungen
- 📊 HTML-Reports

---

## 📄 Lizenz

Dieses Projekt ist unter der **MIT-Lizenz** lizenziert - siehe [LICENSE](LICENSE) für Details.

---

## 👤 Autor

**Marcel Jung (Aktuellis)**
- GitHub: [@MJungAktuellis](https://github.com/MJungAktuellis)
- E-Mail: marcel.jung@aktuellis.de

---

## 🙏 Danksagungen

- Microsoft PowerShell Team
- Sage Software GmbH
- Alle Contributors und Tester

---

## 📊 Status

![GitHub last commit](https://img.shields.io/github/last-commit/MJungAktuellis/Sage100-ServerCheck)
![GitHub issues](https://img.shields.io/github/issues/MJungAktuellis/Sage100-ServerCheck)
![GitHub pull requests](https://img.shields.io/github/issues-pr/MJungAktuellis/Sage100-ServerCheck)

---

<div align="center">
  <strong>Made with ❤️ for the Sage100 Community</strong>
</div>
