# 🆘 TROUBLESHOOTING - Sage100 ServerCheck

## 🔍 Häufige Probleme & Lösungen

### ❌ Problem 1: "Skript kann nicht geladen werden"

**Fehlermeldung:**
```
Die Datei "Sage100-ServerCheck.ps1" kann nicht geladen werden, da die Ausführung 
von Skripts auf diesem System deaktiviert ist.
```

**Ursache:** PowerShell Execution Policy ist zu restriktiv.

**Lösung:**
```powershell
# Als Administrator ausführen
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Überprüfen
Get-ExecutionPolicy -List
```

**Erwartete Ausgabe:**
```
Scope            ExecutionPolicy
-----            ---------------
MachinePolicy    Undefined
UserPolicy       Undefined
Process          Undefined
CurrentUser      RemoteSigned
LocalMachine     Undefined
```

---

### ❌ Problem 2: "Module nicht gefunden"

**Fehlermeldung:**
```
Import-Module: Das angegebene Modul "SystemCheck" wurde nicht geladen, 
da in keinem Modulverzeichnis eine gültige Moduldatei gefunden wurde.
```

**Diagnose:**
```powershell
# Prüfen, ob Module vorhanden sind
Get-ChildItem .\Modules\*.psm1

# Sollte ausgeben:
# SystemCheck.psm1
# NetworkCheck.psm1
# ComplianceCheck.psm1
# DebugLogger.psm1
```

**Lösung A: Module manuell importieren**
```powershell
$ModulePath = "$PSScriptRoot\Modules"
Import-Module "$ModulePath\SystemCheck.psm1" -Force
Import-Module "$ModulePath\NetworkCheck.psm1" -Force
Import-Module "$ModulePath\ComplianceCheck.psm1" -Force
Import-Module "$ModulePath\DebugLogger.psm1" -Force
```

**Lösung B: PSModulePath erweitern**
```powershell
$env:PSModulePath += ";$PSScriptRoot\Modules"
Import-Module SystemCheck
```

---

### ❌ Problem 3: "Zugriff verweigert"

**Fehlermeldung:**
```
UnauthorizedAccessException: Zugriff auf Pfad "C:\Sage\Mandanten" verweigert.
```

**Diagnose:**
```powershell
# Berechtigungen prüfen
Get-Acl "C:\Sage\Mandanten" | Format-List

# Aktueller Benutzer
whoami
```

**Lösung A: Als Administrator ausführen**
```powershell
# PowerShell als Administrator starten
Start-Process powershell -Verb RunAs
```

**Lösung B: Berechtigungen anpassen**
```powershell
# NTFS-Rechte setzen (als Admin)
$acl = Get-Acl "C:\Sage\Mandanten"
$permission = "DOMAIN\User","Read","Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.SetAccessRule($accessRule)
Set-Acl "C:\Sage\Mandanten" $acl
```

---

### ❌ Problem 4: "config.json nicht gefunden"

**Fehlermeldung:**
```
Get-Content: Pfad "C:\...\Config\config.json" nicht gefunden.
```

**Diagnose:**
```powershell
# Prüfen, ob Datei existiert
Test-Path .\Config\config.json

# Verzeichnisstruktur anzeigen
Get-ChildItem -Recurse
```

**Lösung: Beispiel-Konfiguration erstellen**
```powershell
# Verzeichnis erstellen (falls nicht vorhanden)
New-Item -ItemType Directory -Force -Path .\Config

# Beispiel-config.json erstellen
@"
{
  "ServerName": "SAGE-SERVER",
  "DatabasePath": "C:\\Sage\\Mandanten",
  "LogPath": "C:\\Logs\\Sage100Check",
  "CheckInterval": 3600,
  "AlertEmail": "admin@firma.de"
}
"@ | Out-File -FilePath .\Config\config.json -Encoding UTF8
```

---

### ❌ Problem 5: "PowerShell-Version zu alt"

**Fehlermeldung:**
```
Dieses Skript erfordert PowerShell 5.1 oder höher.
```

**Diagnose:**
```powershell
$PSVersionTable.PSVersion
```

**Erwartete Ausgabe (mindestens):**
```
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      ...    ...
```

**Lösung: PowerShell aktualisieren**

**Windows Server 2016/2019:**
```powershell
# Windows Management Framework 5.1 installieren
# Download: https://www.microsoft.com/en-us/download/details.aspx?id=54616
```

**Windows Server 2022+:**
```powershell
# PowerShell 7 installieren (empfohlen)
winget install Microsoft.PowerShell
```

---

### ❌ Problem 6: "Netzwerk-Timeouts"

**Fehlermeldung:**
```
Test-NetConnection: Es konnte keine Verbindung zu '192.168.1.100' hergestellt werden.
```

**Diagnose:**
```powershell
# Netzwerkverbindung testen
Test-NetConnection -ComputerName 192.168.1.100 -Port 445

# Firewall-Regeln prüfen
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*Sage*"}
```

**Lösung A: Firewall-Regel hinzufügen**
```powershell
New-NetFirewallRule -DisplayName "Sage100 Server" `
                    -Direction Inbound `
                    -Protocol TCP `
                    -LocalPort 445 `
                    -Action Allow
```

**Lösung B: Timeout erhöhen**

In `config.json`:
```json
{
  "NetworkTimeout": 10000,
  "RetryAttempts": 3
}
```

Im Skript:
```powershell
$timeout = $config.NetworkTimeout
Test-NetConnection -ComputerName $server -Timeout $timeout
```

---

### ❌ Problem 7: "Fehler beim Laden von Assemblies"

**Fehlermeldung:**
```
Add-Type: Die Datei oder Assembly "System.Management.Automation" konnte nicht geladen werden.
```

**Lösung:**
```powershell
# .NET Framework aktualisieren
# Download: https://dotnet.microsoft.com/download/dotnet-framework

# Alternativ: Assembly manuell laden
Add-Type -AssemblyName System.Management.Automation
```

---

### ❌ Problem 8: "Encoding-Probleme (Umlaute)"

**Fehlermeldung:**
```
Ausgabe zeigt "M�nchen" statt "München"
```

**Lösung:**
```powershell
# Konsole auf UTF-8 stellen
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# In config.json speichern mit UTF-8
Get-Content .\Config\config.json | ConvertFrom-Json | ConvertTo-Json -Depth 10 | 
  Out-File -FilePath .\Config\config.json -Encoding UTF8
```

---

## 🛠️ Erweiterte Diagnose

### Vollständiger Systemcheck

```powershell
# Skript-Diagnose ausführen
.\Tests\Test-Prerequisites.ps1 -Verbose

# Detaillierte Ausgabe
$DebugPreference = "Continue"
.\src\Sage100-ServerCheck.ps1
```

### Log-Analyse

```powershell
# Letzte Fehler anzeigen
Get-Content C:\Logs\Sage100Check\error.log -Tail 50

# Nach bestimmtem Fehler suchen
Select-String -Path C:\Logs\Sage100Check\*.log -Pattern "ERROR"
```

### Event-Log prüfen

```powershell
# PowerShell-Events anzeigen
Get-WinEvent -LogName "Windows PowerShell" -MaxEvents 50 | 
  Where-Object {$_.LevelDisplayName -eq "Error"}
```

---

## 📊 Performance-Probleme

### Problem: Skript läuft sehr langsam

**Diagnose:**
```powershell
# Measure-Command verwenden
Measure-Command { .\src\Sage100-ServerCheck.ps1 }
```

**Lösung A: Caching aktivieren**
```powershell
# In config.json
{
  "EnableCaching": true,
  "CacheTimeout": 300
}
```

**Lösung B: Checks parallelisieren**
```powershell
# Workflow mit PowerShell Jobs
$jobs = @()
$jobs += Start-Job -ScriptBlock { Test-SystemCheck }
$jobs += Start-Job -ScriptBlock { Test-NetworkCheck }
$jobs | Wait-Job | Receive-Job
```

---

## 🔐 Sicherheits-Warnungen

### Problem: "Script is not digitally signed"

**Lösung: Code signieren**

Siehe: [CODE-SIGNING.md](CODE-SIGNING.md)

**Temporäre Lösung:**
```powershell
# Nur für Entwicklung/Tests
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

---

## 📞 Support

### Wenn nichts hilft:

1. **GitHub Issue erstellen:**  
   https://github.com/MJungAktuellis/Sage100-ServerCheck/issues/new

   **Bitte angeben:**
   - Windows-Version (`winver`)
   - PowerShell-Version (`$PSVersionTable.PSVersion`)
   - Fehlermeldung (vollständig kopieren)
   - Schritte zur Reproduktion

2. **Debug-Log sammeln:**
   ```powershell
   $DebugPreference = "Continue"
   .\src\Sage100-ServerCheck.ps1 | Tee-Object -FilePath debug.log
   ```

3. **System-Informationen:**
   ```powershell
   Get-ComputerInfo | Select-Object WindowsVersion, OsArchitecture, CsSystemType
   ```

---

## ✅ Checkliste: Problemlösung

Vor dem Support-Kontakt prüfen:

- [ ] PowerShell-Version 5.1 oder höher
- [ ] Als Administrator ausgeführt
- [ ] Execution Policy auf `RemoteSigned`
- [ ] Alle Module vorhanden (`.\Modules\*.psm1`)
- [ ] `config.json` existiert und ist gültig
- [ ] Berechtigungen für Ziel-Verzeichnisse
- [ ] Firewall-Regeln erlauben Verbindungen
- [ ] Event-Log auf Fehler geprüft

**Wenn alle Punkte ✓ sind und das Problem besteht: Issue erstellen!**
