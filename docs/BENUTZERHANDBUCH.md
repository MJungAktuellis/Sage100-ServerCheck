# 📖 Sage100 ServerCheck - Benutzerhandbuch

## 🚀 Inhaltsverzeichnis

1. [Installation](#installation)
2. [Erste Schritte](#erste-schritte)
3. [Konfiguration](#konfiguration)
4. [Verwendung](#verwendung)
5. [Fehlerbehebung](#fehlerbehebung)
6. [FAQ](#faq)

---

## 📥 Installation

### Systemvoraussetzungen

✅ **Erforderlich:**
- Windows Server 2012 R2 oder höher / Windows 10/11
- PowerShell 5.1 oder höher
- .NET Framework 4.5 oder höher
- Administrator-Rechte
- SQL Server (lokal oder remote)

### Schritt-für-Schritt-Installation

#### **Methode 1: Automatische Installation (Empfohlen)**

1. **ZIP-Datei herunterladen**
   - Gehe zu: https://github.com/MJungAktuellis/Sage100-ServerCheck
   - Klicke auf "Code" → "Download ZIP"

2. **Entpacken**
   ```
   Rechtsklick auf sage100-servercheck-main.zip
   → "Alle extrahieren..."
   → Zielordner wählen (z.B. C:\Temp)
   ```

3. **Installation starten**
   ```
   Rechtsklick auf "AutoSetup.cmd"
   → "Als Administrator ausführen"
   ```

4. **Installer folgen**
   - Der grafische Installations-Wizard startet automatisch
   - Folge den Anweisungen auf dem Bildschirm

#### **Methode 2: Manuelle Installation**

Wenn der automatische Installer nicht funktioniert:

```powershell
# 1. PowerShell als Administrator öffnen
Start-Process powershell -Verb RunAs

# 2. Zum Installations-Verzeichnis navigieren
cd C:\Temp\Sage100-ServerCheck

# 3. Execution Policy setzen
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 4. GUI-Installer starten
.\Installer\GUI-Installer.ps1
```

---

## 🎯 Erste Schritte

### Nach der Installation

1. **Desktop-Verknüpfung verwenden**
   - Doppelklick auf "Sage100 ServerCheck" auf dem Desktop
   - Das Hauptprogramm startet

2. **Oder manuell starten**
   ```powershell
   cd "C:\Program Files\Sage100-ServerCheck"
   .\src\Sage100-ServerCheck.ps1
   ```

### Hauptmenü

Nach dem Start siehst du folgendes Menü:

```
╔═══════════════════════════════════════╗
║   SAGE 100 SERVER CHECK v1.0         ║
╚═══════════════════════════════════════╝

[1] Vollständiger Check
[2] Datenbank-Verbindung testen
[3] Ressourcen überwachen
[4] E-Mail-Test senden
[5] Konfiguration anzeigen
[6] Logs anzeigen
[Q] Beenden

Ihre Wahl:
```

---

## ⚙️ Konfiguration

### Konfigurationsdatei bearbeiten

Die Hauptkonfiguration befindet sich in:
```
C:\Program Files\Sage100-ServerCheck\Config\config.json
```

**Wichtig:** Bearbeite die Datei mit einem Text-Editor (z.B. Notepad++, VS Code)

### Wichtige Einstellungen

#### **SQL Server-Verbindung**

```json
{
  "database": {
    "server": "localhost\\SQLEXPRESS",
    "database": "master",
    "useWindowsAuth": true,
    "username": "",
    "password": "",
    "connectionTimeout": 30
  }
}
```

**Optionen:**
- `server`: SQL Server-Instanz (Format: `ServerName\InstanceName`)
- `database`: Standard-Datenbank für Verbindungstest
- `useWindowsAuth`: `true` = Windows-Auth, `false` = SQL-Auth
- `username`/`password`: Nur bei SQL-Auth erforderlich

#### **E-Mail-Benachrichtigungen**

```json
{
  "email": {
    "enabled": true,
    "smtpServer": "smtp.office365.com",
    "smtpPort": 587,
    "enableSSL": true,
    "from": "servercheck@firma.de",
    "to": ["admin@firma.de", "it@firma.de"],
    "username": "servercheck@firma.de",
    "password": "DeinPasswort"
  }
}
```

**Wichtig:** 
- Bei Office 365: App-Passwort verwenden, nicht normales Passwort
- Bei Gmail: "Weniger sichere Apps" aktivieren oder App-Passwort

#### **Mandanten-Überwachung**

```json
{
  "tenants": [
    {
      "name": "Musterfirma GmbH",
      "database": "Sage100_Musterfirma",
      "enabled": true
    },
    {
      "name": "Testfirma AG",
      "database": "Sage100_Testfirma",
      "enabled": true
    }
  ]
}
```

**Mandanten hinzufügen:**
1. Öffne `config.json`
2. Füge einen neuen Block im `tenants`-Array hinzu
3. Speichern und ServerCheck neu starten

#### **Schwellwerte anpassen**

Datei: `Config\thresholds.json`

```json
{
  "cpu": {
    "warning": 80,
    "critical": 95
  },
  "memory": {
    "warning": 85,
    "critical": 95
  },
  "disk": {
    "warning": 80,
    "critical": 90
  }
}
```

---

## 💻 Verwendung

### Vollständiger Check ausführen

1. Starte das Programm
2. Wähle Option `[1] Vollständiger Check`
3. Das Programm prüft:
   - ✅ SQL Server-Erreichbarkeit
   - ✅ Alle Mandanten-Datenbanken
   - ✅ CPU-Auslastung
   - ✅ RAM-Verfügbarkeit
   - ✅ Festplatten-Speicher
4. Ergebnis wird angezeigt und in `Logs\` gespeichert

### Automatische Überwachung einrichten

#### **Windows Aufgabenplanung (Task Scheduler)**

1. **Task Scheduler öffnen**
   ```
   Windows-Taste → "Aufgabenplanung" eingeben
   ```

2. **Neue Aufgabe erstellen**
   - Rechtsklick auf "Aufgabenplanungsbibliothek"
   - "Einfache Aufgabe erstellen..."

3. **Konfiguration**
   - **Name:** Sage100 ServerCheck
   - **Trigger:** Täglich um 08:00 Uhr
   - **Aktion:** Programm starten
   - **Programm:** `powershell.exe`
   - **Argumente:** 
     ```
     -ExecutionPolicy Bypass -File "C:\Program Files\Sage100-ServerCheck\src\Sage100-ServerCheck.ps1" -FullCheck
     ```
   - **Ausführen als:** SYSTEM oder Admin-Account

4. **Erweiterte Einstellungen**
   - ☑ Auch ausführen, wenn Benutzer nicht angemeldet ist
   - ☑ Mit höchsten Privilegien ausführen

### Logs analysieren

**Log-Dateien finden:**
```
C:\Program Files\Sage100-ServerCheck\Logs\
```

**Log-Typen:**
- `server-check_YYYY-MM-DD.log` - Hauptprotokoll
- `database-check_YYYY-MM-DD.log` - Datenbank-Checks
- `email_YYYY-MM-DD.log` - E-Mail-Versand
- `installer.log` - Installations-Protokoll

**Log-Einträge lesen:**
```
[2024-12-15 08:00:01] [INFO] Server-Check gestartet
[2024-12-15 08:00:02] [SUCCESS] SQL Server erreichbar
[2024-12-15 08:00:03] [WARNING] CPU-Auslastung: 85%
[2024-12-15 08:00:04] [ERROR] Datenbank 'Sage100_Test' nicht erreichbar
```

---

## 🔧 Fehlerbehebung

### Häufige Probleme

#### **Problem: "Skript kann nicht geladen werden" (Execution Policy)**

**Fehlermeldung:**
```
Die Datei kann nicht geladen werden, da die Ausführung von Skripts auf diesem System deaktiviert ist.
```

**Lösung:**
```powershell
# Als Administrator:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

#### **Problem: SQL-Verbindung schlägt fehl**

**Symptome:**
- Fehler: "Server nicht gefunden"
- Timeout-Fehler

**Lösungen:**

1. **SQL Server läuft?**
   ```powershell
   Get-Service -Name MSSQL*
   ```

2. **TCP/IP aktiviert?**
   - SQL Server Configuration Manager öffnen
   - SQL Server-Netzwerkkonfiguration → TCP/IP aktivieren
   - SQL Server-Dienst neu starten

3. **Firewall-Regel?**
   ```powershell
   # Port 1433 freigeben
   New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
   ```

4. **Verbindungsstring prüfen:**
   - Format: `localhost\SQLEXPRESS` (nicht `localhost:SQLEXPRESS`)
   - Named Pipes vs. TCP/IP

#### **Problem: E-Mails werden nicht versendet**

**Checkliste:**

1. **SMTP-Einstellungen korrekt?**
   - Office 365: `smtp.office365.com:587` mit SSL
   - Gmail: `smtp.gmail.com:587` mit SSL
   - Eigener Server: Prüfe Port (25/587/465)

2. **Authentifizierung:**
   - Office 365: App-Passwort erstellen
   - Gmail: "Weniger sichere Apps" oder App-Passwort

3. **Test-E-Mail senden:**
   ```powershell
   # Im Hauptmenü:
   [4] E-Mail-Test senden
   ```

#### **Problem: Hohe CPU-Auslastung durch ServerCheck**

**Ursache:** Zu häufige Checks

**Lösung:** Intervall erhöhen in `config.json`:
```json
{
  "monitoring": {
    "checkIntervalMinutes": 60  // Statt 15
  }
}
```

### Diagnose-Modus

Bei unklaren Problemen:

```powershell
# Detaillierte Fehlerausgabe
.\src\Sage100-ServerCheck.ps1 -Verbose -Debug
```

---

## ❓ FAQ

### Allgemein

**Q: Welche Sage100-Versionen werden unterstützt?**  
A: Alle Versionen ab Sage100 2018. Das Tool überwacht nur SQL Server und Datenbanken, unabhängig von der Sage100-Version.

**Q: Kann ich mehrere SQL Server überwachen?**  
A: Ja, bearbeite `config.json` und füge mehrere Server-Konfigurationen hinzu.

**Q: Funktioniert es auch mit SQL Server Express?**  
A: Ja, vollständig kompatibel.

### Installation

**Q: Muss ich als Administrator installieren?**  
A: Ja, für die Installation und den Betrieb sind Admin-Rechte erforderlich.

**Q: Kann ich einen anderen Installationsordner wählen?**  
A: Ja, während der Installation im GUI-Wizard anpassbar.

**Q: Wie deinstalliere ich das Tool?**  
A: Nutze `Installer\Uninstaller.ps1` oder lösche manuell den Installationsordner und die Desktop-Verknüpfung.

### Konfiguration

**Q: Wo speichere ich sensible Passwörter sicher?**  
A: Nutze Windows Credential Manager oder verschlüssele die `config.json` mit EFS.

**Q: Kann ich mehrere Empfänger für E-Mails eintragen?**  
A: Ja, im `to`-Array mehrere E-Mail-Adressen:
```json
"to": ["admin@firma.de", "it@firma.de", "backup@firma.de"]
```

**Q: Wie oft sollte der Check laufen?**  
A: Empfohlen:
- Produktiv-Systeme: Alle 15-30 Minuten
- Test-Systeme: Alle 60 Minuten

### Betrieb

**Q: Kann das Tool auch auf einem Workstation laufen?**  
A: Ja, solange Zugriff auf den SQL Server besteht.

**Q: Werden alte Logs automatisch gelöscht?**  
A: Nein, manuelle Bereinigung erforderlich. Empfohlen: Logs älter als 30 Tage löschen.

**Q: Kann ich Benachrichtigungen auch per Teams/Slack erhalten?**  
A: Aktuell nur E-Mail. Webhook-Support ist geplant.

---

## 📞 Support

### Logs einsehen

Bei Problemen, prüfe immer zuerst die Logs:
```
C:\Program Files\Sage100-ServerCheck\Logs\
```

### GitHub Issues

Fehler melden oder Features vorschlagen:
https://github.com/MJungAktuellis/Sage100-ServerCheck/issues

### Community

Tausche dich mit anderen Nutzern aus:
- GitHub Discussions: https://github.com/MJungAktuellis/Sage100-ServerCheck/discussions

---

## 📄 Lizenz

Dieses Projekt ist Open Source unter MIT-Lizenz.

---

## 🔄 Updates

### Aktualisierung des Tools

1. **Backup erstellen**
   ```powershell
   Copy-Item "C:\Program Files\Sage100-ServerCheck\Config" "C:\Backup\Sage100-Config" -Recurse
   ```

2. **Neue Version herunterladen**
   - Von GitHub die neueste Release-Version laden

3. **Installation ausführen**
   - Installer überschreibt alte Dateien
   - Config-Dateien bleiben erhalten

4. **Testen**
   ```powershell
   .\src\Sage100-ServerCheck.ps1 -FullCheck
   ```

---

**Version:** 1.0.0  
**Stand:** Dezember 2024  
**Autor:** Professional DevOps Team
