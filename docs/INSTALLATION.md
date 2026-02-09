# 📦 INSTALLATION - Sage100 ServerCheck

## 🎯 Schnellstart (3 Minuten)

### Voraussetzungen
- Windows Server 2016 oder höher
- PowerShell 5.1 oder höher
- Administrator-Rechte

### Installation in 3 Schritten

#### Schritt 1: Repository herunterladen
```powershell
# Via Git
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck

# ODER als ZIP herunterladen
# https://github.com/MJungAktuellis/Sage100-ServerCheck/archive/refs/heads/main.zip
```

#### Schritt 2: Voraussetzungen prüfen
```powershell
.\Tests\Test-Prerequisites.ps1
```

**Erwartete Ausgabe:**
```
✓ PowerShell 5.1 oder höher erkannt
✓ Administrator-Rechte vorhanden
✓ Alle Module gefunden
✓ Konfigurationsdatei vorhanden
```

#### Schritt 3: Installation ausführen
```cmd
EASY-INSTALL-v2.cmd
```

**Erwartete Ausgabe:**
```
[OK] Administrator-Rechte vorhanden
[OK] PowerShell 5.1 erkannt
[OK] Module erfolgreich importiert
Installation abgeschlossen!
```

---

## 🚀 Erster Start

```powershell
.\src\Sage100-ServerCheck.ps1
```

**Sie sehen jetzt das Hauptmenü:**
```
╔═══════════════════════════════════════╗
║   SAGE 100 SERVER CHECK TOOL v1.0    ║
╚═══════════════════════════════════════╝

[1] Vollständiger Check
[2] Netzwerk-Test
[3] System-Analyse
[Q] Beenden

Ihre Wahl:
```

---

## 🔧 Manuelle Installation (falls EASY-INSTALL fehlschlägt)

### 1. PowerShell Execution Policy anpassen
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Module manuell importieren
```powershell
Import-Module .\Modules\SystemCheck.psm1
Import-Module .\Modules\NetworkCheck.psm1
Import-Module .\Modules\ComplianceCheck.psm1
Import-Module .\Modules\DebugLogger.psm1
```

### 3. Konfiguration prüfen
```powershell
Test-Path .\Config\config.json
# Sollte "True" zurückgeben
```

### 4. Hauptskript starten
```powershell
.\src\Sage100-ServerCheck.ps1
```

---

## 📋 Konfiguration

### config.json anpassen

Öffnen Sie `Config\config.json` und passen Sie folgende Werte an:

```json
{
  "ServerName": "IHR-SERVER-NAME",
  "DatabasePath": "C:\\Sage\\Mandanten",
  "LogPath": "C:\\Logs\\Sage100Check",
  "CheckInterval": 3600,
  "AlertEmail": "admin@ihre-firma.de"
}
```

**Wichtige Parameter:**
- `ServerName`: Name Ihres Sage100-Servers
- `DatabasePath`: Pfad zu den Sage100-Mandanten
- `LogPath`: Verzeichnis für Log-Dateien
- `CheckInterval`: Prüfintervall in Sekunden (Standard: 1 Stunde)
- `AlertEmail`: E-Mail für kritische Warnungen

---

## ✅ Installations-Validierung

### Test 1: PowerShell-Version
```powershell
$PSVersionTable.PSVersion
# Erwartete Ausgabe: Major 5, Minor 1 oder höher
```

### Test 2: Module verfügbar
```powershell
Get-Module -ListAvailable | Where-Object { $_.Name -like "*Check*" }
# Sollte SystemCheck, NetworkCheck, ComplianceCheck anzeigen
```

### Test 3: Konfiguration laden
```powershell
$config = Get-Content .\Config\config.json | ConvertFrom-Json
$config.ServerName
# Sollte Ihren Server-Namen anzeigen
```

### Test 4: Vollständiger Funktionstest
```powershell
.\Tests\Test-Prerequisites.ps1
# Alle Checks sollten mit ✓ bestätigt werden
```

---

## 🔐 Sicherheitshinweise

### Code-Signatur (Optional, aber empfohlen)

Für erhöhte Sicherheit können Sie die PowerShell-Skripte signieren:

**Siehe:** [docs/CODE-SIGNING.md](CODE-SIGNING.md)

### Netzwerk-Freigaben

Falls das Tool auf Netzwerk-Shares zugreifen soll:

```powershell
# Credentials speichern (einmalig)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\sage-creds.xml"
```

In `Sage100-ServerCheck.ps1` einbinden:
```powershell
$cred = Import-Clixml -Path "$env:USERPROFILE\sage-creds.xml"
New-PSDrive -Name "SageShare" -PSProvider FileSystem -Root "\\server\share" -Credential $cred
```

---

## 🆘 Problembehandlung

### Problem: "Skript kann nicht geladen werden"

**Fehlermeldung:**
```
Die Datei "Sage100-ServerCheck.ps1" kann nicht geladen werden, da die Ausführung von Skripts auf diesem System deaktiviert ist.
```

**Lösung:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Problem: "Module nicht gefunden"

**Fehlermeldung:**
```
Import-Module: Das angegebene Modul "SystemCheck" wurde nicht geladen.
```

**Lösung:**
```powershell
# Prüfen Sie, ob die Module im richtigen Verzeichnis sind
Get-ChildItem .\Modules\*.psm1

# Module manuell mit vollständigem Pfad importieren
Import-Module "$PSScriptRoot\Modules\SystemCheck.psm1" -Force
```

### Problem: "Zugriff verweigert"

**Fehlermeldung:**
```
UnauthorizedAccessException: Zugriff auf Pfad "C:\Sage\..." verweigert
```

**Lösung:**
```powershell
# PowerShell als Administrator starten
Start-Process powershell -Verb RunAs

# Oder Berechtigungen prüfen
Get-Acl "C:\Sage\Mandanten"
```

**Weitere Hilfe:** [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## 🔄 Updates

### Update auf neueste Version

```powershell
# Via Git
cd Sage100-ServerCheck
git pull origin main

# ODER ZIP herunterladen und Dateien ersetzen
```

### Manuelle Update-Prüfung

```powershell
# Aktuelle Version anzeigen
Get-Content .\src\Sage100-ServerCheck.ps1 | Select-String "Version"

# GitHub-Releases prüfen
# https://github.com/MJungAktuellis/Sage100-ServerCheck/releases
```

---

## 📞 Support

Bei Problemen:

1. **Troubleshooting-Guide:** [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. **GitHub Issues:** https://github.com/MJungAktuellis/Sage100-ServerCheck/issues
3. **Diskussionen:** https://github.com/MJungAktuellis/Sage100-ServerCheck/discussions

---

## ✅ Checkliste: Installation abgeschlossen

- [ ] Repository heruntergeladen
- [ ] `Test-Prerequisites.ps1` erfolgreich ausgeführt
- [ ] `EASY-INSTALL-v2.cmd` abgeschlossen
- [ ] `config.json` angepasst
- [ ] Hauptprogramm startet ohne Fehler
- [ ] Erster Test-Check durchgeführt

**Wenn alle Punkte ✓ sind: Installation erfolgreich abgeschlossen!** 🎉
