# 📘 Installationsanleitung - Sage100-ServerCheck

## 🎯 Übersicht

Diese Anleitung führt dich Schritt für Schritt durch die Installation und den ersten Start des **Sage100-ServerCheck** Tools.

---

## ⚙️ Systemvoraussetzungen

### Minimale Anforderungen:

| Komponente | Anforderung |
|------------|-------------|
| **Betriebssystem** | Windows Server 2012 R2 oder neuer / Windows 10/11 |
| **PowerShell** | Version 5.1 oder höher |
| **Benutzerrechte** | Administrator-Rechte erforderlich |
| **.NET Framework** | Version 4.7.2 oder höher |
| **Festplattenspeicher** | Mindestens 50 MB frei |

### Empfohlene Konfiguration:

- Windows Server 2019/2022
- PowerShell 7.x
- 4 GB RAM
- SQL Server Management Tools (optional, für erweiterte DB-Checks)

---

## 📦 Installation

### Methode 1: Automatische Installation (Empfohlen)

#### Schritt 1: Repository klonen oder herunterladen

**Option A: Mit Git**
```powershell
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck
```

**Option B: ZIP-Download**
1. Gehe zu https://github.com/MJungAktuellis/Sage100-ServerCheck
2. Klicke auf **Code** → **Download ZIP**
3. Entpacke die ZIP-Datei in ein Verzeichnis deiner Wahl (z.B. `C:\Tools\Sage100-ServerCheck`)

#### Schritt 2: Voraussetzungen prüfen

Öffne PowerShell **als Administrator** und führe aus:

```powershell
cd C:\Tools\Sage100-ServerCheck
.\Tests\Test-Prerequisites.ps1
```

**Erwartete Ausgabe:**
```
✅ PowerShell-Version: 5.1.19041.4894 (OK)
✅ .NET Framework: 4.8 (OK)
✅ Administrator-Rechte: Ja
✅ Alle Module gefunden: 6/6
✅ Konfigurationsdatei: Vorhanden

SYSTEM BEREIT FÜR INSTALLATION
```

#### Schritt 3: Installation ausführen

**Starte den Installer:**

```cmd
EASY-INSTALL-v2.cmd
```

Der Installer führt automatisch folgende Schritte aus:
1. ✅ Prüfung der Admin-Rechte
2. ✅ Validierung der PowerShell-Version
3. ✅ Import aller benötigten Module
4. ✅ Konfigurationsprüfung
5. ✅ Erstellen der Arbeitsverzeichnisse

**Erfolgreiche Installation:**
```
===========================================
  SAGE100-SERVERCHECK INSTALLATION
===========================================
✓ Admin-Rechte: OK
✓ PowerShell 5.1: OK
✓ Module importiert: 6/6
✓ Konfiguration geladen: OK

Installation abgeschlossen!

Starten Sie das Tool mit:
  .\src\Sage100-ServerCheck.ps1
```

---

### Methode 2: Manuelle Installation

Falls der automatische Installer nicht funktioniert:

#### 1. Ordnerstruktur validieren

Stelle sicher, dass folgende Struktur vorhanden ist:

```
Sage100-ServerCheck/
├── src/
│   └── Sage100-ServerCheck.ps1
├── Modules/
│   ├── DebugLogger.psm1
│   ├── SystemCheck.psm1
│   ├── NetworkCheck.psm1
│   ├── ComplianceCheck.psm1
│   ├── WorkLog.psm1
│   └── ReportGenerator.psm1
├── Config/
│   └── config.json
├── Tests/
│   └── Test-Prerequisites.ps1
└── docs/
```

#### 2. ExecutionPolicy anpassen

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### 3. Module manuell importieren

```powershell
$ModulePath = "C:\Tools\Sage100-ServerCheck\Modules"
Get-ChildItem "$ModulePath\*.psm1" | ForEach-Object {
    Import-Module $_.FullName -Force
}
```

#### 4. Konfiguration prüfen

```powershell
$Config = Get-Content ".\Config\config.json" -Encoding UTF8 -Raw | ConvertFrom-Json
$Config
```

---

## 🚀 Erster Start

### Start des Hauptprogramms

```powershell
cd C:\Tools\Sage100-ServerCheck
.\src\Sage100-ServerCheck.ps1
```

### Erwartete Ausgabe - Banner

```
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║        SAGE 100 - SERVER HEALTH CHECK TOOL                ║
║                    Version 2.1.0                          ║
║                                                            ║
║  Entwickelt für: Sage 100 Server-Infrastruktur           ║
║  Lizenz: MIT                                               ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
```

### Hauptmenü

```
===========================================
  HAUPTMENÜ - SAGE100 SERVERCHECK
===========================================

1. 🔍 Schnell-Scan (Quick Check)
2. 🛠️  Vollständiger System-Check
3. 🌐 Netzwerk-Diagnose
4. 📊 Compliance-Prüfung
5. 📁 Report generieren
6. ⚙️  Einstellungen
7. 📜 Work-Log anzeigen
8. ❌ Beenden

Wähle eine Option (1-8):
```

---

## ✅ Funktionstest

### Test 1: Schnell-Scan

Wähle Option **1** im Hauptmenü:

```
Starte Schnell-Scan...
✓ CPU-Auslastung: 23% (OK)
✓ RAM-Verfügbar: 8.2 GB (OK)
✓ Festplatte C:\ : 45% belegt (OK)
✓ Sage100-Dienste: 4/4 laufen

Schnell-Scan abgeschlossen - Keine Probleme erkannt.
```

### Test 2: Vollständiger Check

Wähle Option **2** im Hauptmenü:

```
╔═══════════════════════════════════════════════════════════╗
║           VOLLSTÄNDIGER SYSTEM-CHECK                      ║
╚═══════════════════════════════════════════════════════════╝

[1/8] Hardware-Prüfung...
  ✓ CPU: Intel Xeon E5-2680 v4 @ 2.40GHz
  ✓ RAM: 16 GB (12.4 GB frei)
  ✓ Festplatten: Alle OK

[2/8] Betriebssystem-Check...
  ✓ Windows Server 2019 Standard
  ✓ Alle kritischen Updates installiert

[3/8] Sage100-Dienste...
  ✓ Sage100_ApplicationServer: Running
  ✓ Sage100_DatabaseEngine: Running
  ✓ Sage100_WebService: Running
  ✓ Sage100_ReportServer: Running

[4/8] Datenbank-Verbindung...
  ✓ SQL Server 2019: Erreichbar
  ✓ Sage100_PROD Datenbank: Online

[5/8] Netzwerk-Konnektivität...
  ✓ DNS-Auflösung: OK
  ✓ Internet-Verbindung: OK
  ✓ Interne Netzwerk-Shares: Erreichbar

[6/8] Sicherheits-Check...
  ✓ Firewall: Aktiv
  ✓ Antivirus: Aktiv & aktuell
  ✓ Windows Defender: Aktiviert

[7/8] Performance-Metriken...
  ✓ Durchschnittliche CPU-Last (24h): 18%
  ✓ RAM-Auslastung: Normal
  ✓ Disk I/O: Keine Engpässe

[8/8] Compliance-Prüfung...
  ✓ Backup-Status: Letztes Backup vor 8 Stunden
  ✓ Log-Rotation: Konfiguriert
  ✓ Audit-Logs: Werden geschrieben

═══════════════════════════════════════════════════════════
ERGEBNIS: ✅ SYSTEM GESUND - Keine kritischen Probleme
═══════════════════════════════════════════════════════════

Detaillierter Report gespeichert unter:
  C:\Tools\Sage100-ServerCheck\Reports\SystemCheck_20240209_143022.html
```

---

## 🎯 Kommandozeilen-Parameter

Das Tool unterstützt auch direkte Parameter:

### Schnell-Scan ohne Menü:
```powershell
.\src\Sage100-ServerCheck.ps1 -QuickScan
```

### Vollcheck mit automatischem Report:
```powershell
.\src\Sage100-ServerCheck.ps1 -FullCheck -ExportReport
```

### Nur Netzwerk-Diagnose:
```powershell
.\src\Sage100-ServerCheck.ps1 -NetworkCheck
```

### Compliance-Check mit E-Mail-Versand:
```powershell
.\src\Sage100-ServerCheck.ps1 -ComplianceCheck -SendEmail
```

---

## 📊 Report-Generierung

### Automatische Reports

Reports werden standardmäßig gespeichert unter:
```
C:\Tools\Sage100-ServerCheck\Reports\
```

### Report-Formate

- **HTML**: Interaktiver Web-Report mit Grafiken
- **PDF**: Druckbares Dokument (benötigt wkhtmltopdf)
- **JSON**: Maschinenlesbare Rohdaten
- **CSV**: Excel-Import-fähig

### Beispiel: Report per E-Mail versenden

Bearbeite `Config\config.json`:

```json
{
  "EmailSettings": {
    "Enabled": true,
    "SMTPServer": "smtp.deinefirma.de",
    "Port": 587,
    "From": "servercheck@deinefirma.de",
    "To": "admin@deinefirma.de",
    "UseSSL": true
  }
}
```

Dann ausführen:
```powershell
.\src\Sage100-ServerCheck.ps1 -FullCheck -SendEmail
```

---

## 🔧 Konfiguration

### Hauptkonfigurationsdatei

Die Datei `Config\config.json` enthält alle Einstellungen:

```json
{
  "General": {
    "LogLevel": "Info",
    "RetentionDays": 30,
    "AutoBackup": true
  },
  "Thresholds": {
    "CPU_Warning": 75,
    "CPU_Critical": 90,
    "RAM_Warning": 80,
    "RAM_Critical": 95,
    "Disk_Warning": 70,
    "Disk_Critical": 85
  },
  "Sage100": {
    "InstallPath": "C:\\Program Files\\Sage\\Sage100",
    "DatabaseServer": "localhost\\SAGE100",
    "Services": [
      "Sage100_ApplicationServer",
      "Sage100_DatabaseEngine"
    ]
  }
}
```

### Anpassung der Schwellwerte

Bearbeite die Werte im `Thresholds`-Abschnitt nach deinen Anforderungen.

---

## 📅 Automatisierung mit Task Scheduler

### Täglicher automatischer Check um 2:00 Uhr nachts

```powershell
# Task Scheduler Task erstellen
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
  -Argument "-ExecutionPolicy Bypass -File C:\Tools\Sage100-ServerCheck\src\Sage100-ServerCheck.ps1 -FullCheck -ExportReport -SendEmail"

$Trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Sage100-ServerCheck-Daily" `
  -Action $Action `
  -Trigger $Trigger `
  -Principal $Principal `
  -Description "Täglicher automatischer Server-Check für Sage100"
```

### Überprüfung des Tasks

```powershell
Get-ScheduledTask -TaskName "Sage100-ServerCheck-Daily"
```

---

## 🆘 Problembehandlung

Falls Probleme auftreten, siehe **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)**.

### Häufige Probleme:

#### Problem: "Datei kann nicht geladen werden, da die Ausführung von Skripts auf diesem System deaktiviert ist"

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Problem: "Module nicht gefunden"

**Lösung:**
```powershell
# Überprüfe den Modul-Pfad
$env:PSModulePath -split ';'

# Importiere Module manuell
Import-Module "C:\Tools\Sage100-ServerCheck\Modules\SystemCheck.psm1" -Force
```

#### Problem: "Zugriff verweigert"

**Lösung:**
- Starte PowerShell als Administrator
- Prüfe NTFS-Berechtigungen auf dem Tool-Ordner

---

## 📚 Weitere Ressourcen

- **[Troubleshooting Guide](./TROUBLESHOOTING.md)** - Detaillierte Fehlerbehandlung
- **[Code-Signing Anleitung](./CODE-SIGNING.md)** - Für erhöhte Sicherheit
- **[GitHub Repository](https://github.com/MJungAktuellis/Sage100-ServerCheck)** - Neueste Version
- **[Changelog](../CHANGELOG.md)** - Versionshistorie

---

## ✅ Installation abgeschlossen!

Du kannst jetzt mit dem Tool arbeiten. Für weitere Hilfe starte:

```powershell
.\src\Sage100-ServerCheck.ps1 -Help
```

**Viel Erfolg mit dem Sage100-ServerCheck Tool!** 🚀
