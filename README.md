# Sage100-ServerCheck

**Automatisches PowerShell-Tool zur Validierung und Konfiguration von Sage 100 Server-Installationen**

## 📋 Überblick

Dieses Tool unterstützt bei der Installation und Wartung von Sage 100 Umgebungen durch:

- ✅ **Automatische Systemprüfung** gegen Sage 100 Systemvoraussetzungen
- ✅ **Validierung** von Hardware, Software, Ports und Netzwerk
- ✅ **Interaktive Behebung** erkannter Probleme (User entscheidet)
- ✅ **Dokumentation** als Markdown-Export (Kundenstammblatt)
- ✅ **Arbeitsprotokoll** für geleistete Tätigkeiten

---

## 🚀 Installation

### Voraussetzungen
- Windows Server 2022/2025 oder Windows 11
- PowerShell 5.1 oder höher
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
```powershell
.\Sage100-ServerCheck.ps1
```

---

## 📁 Struktur

```
Sage100-ServerCheck/
│
├── Sage100-ServerCheck.ps1      # Haupt-Skript (Entry Point)
├── config/
│   ├── SystemRequirements.json  # Sage 100 Systemvoraussetzungen
│   └── Ports.json               # Erforderliche Firewall-Ports
│
├── modules/
│   ├── SystemCheck.psm1         # Hardware/Software-Prüfung
│   ├── PortCheck.psm1           # Netzwerk & Firewall
│   ├── SQLCheck.psm1            # SQL Server Validierung
│   ├── DirectorySetup.psm1      # Ordnerstruktur & Berechtigungen
│   ├── WorkLog.psm1             # Arbeitsprotokoll
│   └── MarkdownExport.psm1      # Kundenstammblatt-Export
│
├── reports/                      # Generierte Reports
└── logs/                         # Arbeitsprotokolle
```

---

## 🛠️ Verwendung

### Standard-Check durchführen

```powershell
.\Sage100-ServerCheck.ps1 -Mode Check
```

**Ausgabe:**
- Liste aller geprüften Komponenten
- Warnungen/Fehler mit Lösungsvorschlägen
- Interaktive Behebung möglich

### Nur Markdown-Export

```powershell
.\Sage100-ServerCheck.ps1 -Mode Export -OutputPath "C:\Reports\Kunde_XYZ.md"
```

### Vollständige Prüfung + Export

```powershell
.\Sage100-ServerCheck.ps1 -Mode Full
```

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

## 📄 Beispiel-Output

```
╔════════════════════════════════════════════════════════╗
║   Sage 100 Server-Check v1.0                          ║
║   Server: SRV-SAGE-01                                 ║
╚════════════════════════════════════════════════════════╝

[✓] Hardware
    CPU: Intel Xeon E5-2680 v4 @ 2.8 GHz (14 Cores)
    RAM: 64 GB
    Disk: SSD, 500 GB frei

[✓] Betriebssystem
    Windows Server 2022 Standard (Build 20348)
    Support bis: 13.10.2026

[⚠] Software
    .NET Framework 4.8 - OK
    Access Runtime 2019 (32-bit) - FEHLT!
    
    → Möchten Sie Access Runtime jetzt installieren? [J/N]

[✓] SQL Server
    Version: SQL Server 2022 Standard Edition
    Instanz: MSSQLSERVER (Default)
    Port: 1433 TCP - OK

[⚠] Firewall
    Port 5493 (Application Server) - BLOCKIERT
    
    → Firewall-Regel erstellen? [J/N]

[✓] Ordnerstruktur
    C:\Sage\Daten - Vorhanden
    Berechtigungen: Korrekt

════════════════════════════════════════════════════════
Zusammenfassung:
  ✓ 4 Checks erfolgreich
  ⚠ 2 Warnungen (Benutzereingriff erforderlich)
  ✗ 0 Kritische Fehler
════════════════════════════════════════════════════════
```

---

## 🔧 Interaktive Problemlösung

Bei erkannten Problemen bietet das Tool:

1. **Detaillierte Erklärung** des Problems
2. **Lösungsvorschlag** basierend auf Sage-Dokumentation
3. **Automatische Behebung** (mit User-Bestätigung)
4. **Manuelle Anleitung** (falls automatisch nicht möglich)

### Beispiel: Fehlende Firewall-Regel

```
[⚠] Port 5493 (Application Server HTTPS Basic) ist blockiert

Problem: 
  Der Sage 100 Application Server benötigt eingehende Verbindungen
  auf Port 5493 für HTTPS Basic Authentication.

Lösung:
  Firewall-Regel erstellen:
  - Name: Sage100-AppServer-HTTPS-Basic
  - Port: 5493 (TCP, Eingehend)
  - Profil: Domain, Private

Aktion:
  [1] Regel jetzt automatisch erstellen
  [2] Manuelle Anleitung anzeigen
  [3] Überspringen
  
Ihre Wahl:
```

---

## 📊 Markdown-Export

Das Tool generiert ein Kundenstammblatt im Markdown-Format:

```markdown
# Kundenstammblatt - [Kunde XYZ]
**Erstellt am:** 07.02.2026

## Server-Informationen
- **Servername:** SRV-SAGE-01
- **Betriebssystem:** Windows Server 2022 Standard
- **RAM:** 64 GB
- **CPU:** Intel Xeon E5-2680 v4 (14 Cores)

## Installierte Software
- Sage 100 Version 9.0.10
- SQL Server 2022 Standard Edition
- Microsoft Access Runtime 2019 (32-bit)

## Netzwerk-Konfiguration
- IP-Adresse: 192.168.1.100
- SQL Port: 1433
- Application Server Ports: 5493, 5494
- Firewall: Konfiguriert

## Terminhistorie
| Datum       | Techniker | Tätigkeit                     | Dauer |
|-------------|-----------|-------------------------------|-------|
| 07.02.2026  | M. Jung   | Initiale Installation         | 4h    |
| 07.02.2026  | M. Jung   | Firewall-Konfiguration        | 1h    |
```

---

## 📝 Arbeitsprotokoll

Erfassen Sie durchgeführte Arbeiten direkt im Tool:

```powershell
.\Sage100-ServerCheck.ps1 -Mode WorkLog -Add
```

**Dialog:**
```
Arbeitsprotokoll hinzufügen
═══════════════════════════════════════
Datum [Enter = heute]:
Techniker:           M. Jung
Tätigkeit:           SQL Server Upgrade auf 2022
Dauer (Stunden):     3
Bemerkungen:         Erfolgreiche Migration, keine Downtime

[✓] Eintrag gespeichert
```

---

## ⚙️ Konfiguration

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

**Version:** 1.0  
**Letzte Aktualisierung:** Februar 2026
