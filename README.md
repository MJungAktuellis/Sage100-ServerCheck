# Sage100-ServerCheck

**Automatisches PowerShell-Tool zur Validierung und Konfiguration von Sage 100 Server-Installationen**

## 📋 Überblick

Dieses Tool unterstützt bei der Installation und Wartung von Sage 100 Umgebungen durch:

- ✅ **Automatische Systemprüfung** gegen Sage 100 Systemvoraussetzungen
- ✅ **Validierung** von Hardware, Software, Ports und Netzwerk
- ✅ **Interaktive Behebung** erkannter Probleme (User entscheidet)
- ✅ **Dokumentation** als Markdown-Export (Kundenstammblatt)
- ✅ **Arbeitsprotokoll** für geleistete Tätigkeiten
- ✅ **Debug-Logging** für Fehleranalyse
- ✅ **Grafische Benutzeroberfläche** (GUI) - NEU! 🎨

---

## 🚀 Installation

### Voraussetzungen
- Windows Server 2022/2025 oder Windows 11
- PowerShell 5.1 oder höher
- .NET Framework 4.7.2+
- Administratorrechte (für System-Checks und Konfigurationen)

### Schnellinstallation

1. **Repository klonen oder Download**
```powershell
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck
```

2. **Execution Policy anpassen** (falls nötig)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. **Tool starten**

**Option A: Grafische Oberfläche (empfohlen)**
```powershell
.\Sage100-ServerCheck-GUI.ps1
```

**Option B: PowerShell-Konsole (klassisch)**
```powershell
.\Sage100-ServerCheck.ps1
```

---

## 🎨 GUI-Version (NEU!)

Die neue grafische Benutzeroberfläche bietet:

### Features
- **Dashboard** mit Live-Status-Übersicht
- **Tab-basierte Navigation**
  - System-Informationen
  - Netzwerk & Firewall
  - Compliance-Check
  - Debug-Logs
- **Ein-Klick-Prüfungen**
- **Visual Status-Indikatoren** (✅ Grün, ⚠️ Orange, ❌ Rot)
- **Export-Funktionen** über Menü
- **Progress-Bars** für laufende Checks

### Starten

```powershell
.\Sage100-ServerCheck-GUI.ps1
```

![GUI Screenshot](docs/gui-screenshot.png)

### Menü-Optionen

**Datei**
- Export Markdown-Report
- Export JSON-Snapshot
- Export Debug-Log
- Beenden

**Aktionen**
- Vollständige Prüfung
- Nur System-Check
- Nur Netzwerk-Check
- Nur Compliance-Check

**Hilfe**
- Über

---

## 📁 Struktur

```
Sage100-ServerCheck/
│
├── Sage100-ServerCheck.ps1          # Haupt-Skript (CLI)
├── Sage100-ServerCheck-GUI.ps1      # GUI-Starter (NEU)
│
├── GUI/
│   └── MainWindow.ps1               # GUI-Hauptfenster
│
├── config/
│   ├── SystemRequirements.json      # Sage 100 Systemvoraussetzungen
│   └── Ports.json                   # Erforderliche Firewall-Ports
│
├── Modules/
│   ├── SystemCheck.psm1             # Hardware/Software-Prüfung
│   ├── NetworkCheck.psm1            # Netzwerk & Firewall
│   ├── ComplianceCheck.psm1         # Sage 100 Compliance
│   ├── WorkLog.psm1                 # Arbeitsprotokoll
│   ├── DebugLogger.psm1             # Debug-Logging (NEU)
│   └── ReportGenerator.psm1         # Markdown/JSON-Export
│
├── Data/
│   ├── Logs/                        # Debug-Logs
│   ├── Reports/                     # Generierte Reports
│   └── Snapshots/                   # JSON-Snapshots
│
└── README.md
```

---

## 🛠️ Verwendung

### CLI-Version (PowerShell-Konsole)

#### Standard-Check durchführen

```powershell
.\Sage100-ServerCheck.ps1
```

**Menü:**
```
[1] Vollständige System-Prüfung
[2] Nur System-Informationen sammeln
[3] Netzwerk & Firewall prüfen
[4] Compliance-Check (Sage 100 Voraussetzungen)
[5] Arbeitsprotokoll hinzufügen
[6] Markdown-Report erstellen
[7] JSON-Snapshot erstellen
[8] Debug-Log anzeigen (NEU)
[0] Beenden
```

### GUI-Version (Windows Forms)

```powershell
.\Sage100-ServerCheck-GUI.ps1
```

**Dashboard:**
- Klicke auf "Vollständige Prüfung starten"
- Oder navigiere zu den einzelnen Tabs
- Status-Karten zeigen Live-Ergebnisse

**Export:**
- Menü → Datei → Export wählen
- Speicherort auswählen
- Fertig!

---

## 🔍 Geprüfte Komponenten

### 1. **Hardware**
- CPU (Mindestanforderungen Sage 100)
- RAM (pro Server-Rolle)
- Disk Space & Geschwindigkeit (SSD empfohlen)

### 2. **Betriebssystem**
- Windows Version & Support-Status
- .NET Framework
- Microsoft Access Runtime (32-bit!)

### 3. **SQL Server**
- Version & Edition (2019/2022 Standard/Enterprise)
- Instanz-Name & Port (Standard: 1433)
- TCP/IP aktiviert
- SQL Browser Service (bei named instances)

### 4. **Netzwerk & Firewall**
- Erforderliche Ports offen:
  - SQL: 1433 (TCP), 1434 (UDP)
  - Application Server: 5493, 5494
  - Blobstorage: 4000, 4010, 4020
  - ELSTER-Verbindungen
- Netzwerk-Geschwindigkeit (min. 1 Gbit/s)

### 5. **Ordnerstrukturen**
- Sage-Installationsordner
- Datenbank-Pfade
- Backup-Verzeichnisse
- NTFS-Berechtigungen

---

## 📊 Debug-Logging (NEU!)

### Automatisches Logging

Bei jedem Lauf werden automatisch Debug-Informationen erfasst:

```json
{
  "SessionId": "abc-123-def",
  "StartTime": "2026-02-07T16:30:00",
  "Summary": {
    "TotalActions": 45,
    "SuccessfulActions": 42,
    "FailedActions": 3
  },
  "Actions": [...],
  "Errors": [...]
}
```

### Log anzeigen

**CLI:**
```
Option [8] → Debug-Log anzeigen
```

**GUI:**
```
Tab "Debug-Logs" → Logs aktualisieren
```

### Log exportieren

```
Menü → Datei → Export Debug-Log
→ Speichert als JSON-Datei
```

**Log enthält:**
- Session-ID
- Zeitstempel aller Aktionen
- Fehlermeldungen mit Stack-Trace
- Performance-Metriken (langsamste Operationen)
- System-Kontext (PC-Name, User, OS-Version)

---

## 🔧 Konfiguration

### Systemvoraussetzungen anpassen

Bearbeiten Sie `config/SystemRequirements.json`:

```json
{
  "MinRAM": 8,
  "RecommendedRAM": 32,
  "MinCPUCores": 4,
  "MinDiskSpaceGB": 50,
  "SupportedWindowsVersions": [
    "Windows Server 2022",
    "Windows Server 2025",
    "Windows 11"
  ],
  "RequiredSQLVersions": [
    "SQL Server 2019",
    "SQL Server 2022"
  ]
}
```

### Ports konfigurieren

Bearbeiten Sie `config/Ports.json`:

```json
{
  "SQL": {
    "TCP": [1433],
    "UDP": [1434]
  },
  "ApplicationServer": {
    "HTTPS_Basic": [5493, 5471, 5472],
    "HTTPS_Windows": [5494, 5473, 5474]
  },
  "Blobstorage": {
    "HTTPS_Basic": [4000, 4001, 4002],
    "HTTPS_Windows": [4010, 4011, 4012]
  }
}
```

---

## 🤝 Beiträge

Dieses Tool wird aktiv weiterentwickelt. Verbesserungsvorschläge und Bug-Reports sind willkommen!

---

## 📜 Lizenz

Dieses Tool ist für den internen Gebrauch bei Sage 100 Installationen konzipiert.

---

## 📞 Support

Bei Fragen oder Problemen:
- GitHub Issues: https://github.com/MJungAktuellis/Sage100-ServerCheck/issues

---

**Version:** 2.0 (GUI-Version)  
**Letzte Aktualisierung:** Februar 2026
