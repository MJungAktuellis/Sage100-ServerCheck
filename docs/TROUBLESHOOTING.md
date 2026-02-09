# 🔧 Sage100-ServerCheck - Troubleshooting Guide

> **Zielgruppe:** IT-Administratoren, System Engineers  
> **Schwierigkeitsgrad:** Mittel bis Fortgeschritten  
> **Letzte Aktualisierung:** 2026-02-09

---

## 📋 Inhaltsverzeichnis

1. [Diagnose-Tools](#-diagnose-tools)
2. [Häufige Fehler & Lösungen](#-häufige-fehler--lösungen)
3. [Performance-Probleme](#-performance-probleme)
4. [SQL Server-Verbindungsprobleme](#-sql-server-verbindungsprobleme)
5. [Modul-Ladefehler](#-modul-ladefehler)
6. [Event-Log-Probleme](#-event-log-probleme)
7. [E-Mail-Versand-Probleme](#-e-mail-versand-probleme)
8. [Scheduled Task-Fehler](#-scheduled-task-fehler)
9. [Debug-Modus aktivieren](#-debug-modus-aktivieren)
10. [Support-Anfrage erstellen](#-support-anfrage-erstellen)

---

## 🛠️ Diagnose-Tools

### Voraussetzungsprüfung

Führe dieses Skript aus, um alle Systemvoraussetzungen zu überprüfen:

```powershell
# Speichere als: Test-Prerequisites.ps1
[CmdletBinding()]
param()

Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SAGE100-SERVERCHECK - VORAUSSETZUNGSPRÜFUNG     " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 1. PowerShell-Version
Write-Host "[1/8] PowerShell-Version..." -NoNewline
$PSVersion = $PSVersionTable.PSVersion
if ($PSVersion.Major -ge 5) {
    Write-Host " ✅ OK (Version $($PSVersion.Major).$($PSVersion.Minor))" -ForegroundColor Green
} else {
    Write-Host " ❌ FEHLER (Version $($PSVersion.Major).$($PSVersion.Minor) - Minimum: 5.1)" -ForegroundColor Red
}

# 2. Administrator-Rechte
Write-Host "[2/8] Administrator-Rechte..." -NoNewline
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($IsAdmin) {
    Write-Host " ✅ OK" -ForegroundColor Green
} else {
    Write-Host " ⚠️  WARNUNG (Einige Funktionen benötigen Admin-Rechte)" -ForegroundColor Yellow
}

# 3. .NET Framework
Write-Host "[3/8] .NET Framework..." -NoNewline
$NetVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Release
if ($NetVersion -ge 461808) { # .NET 4.7.2
    Write-Host " ✅ OK (Version 4.7.2+)" -ForegroundColor Green
} else {
    Write-Host " ❌ FEHLER (.NET 4.7.2+ erforderlich)" -ForegroundColor Red
}

# 4. SQL Server Client-Tools
Write-Host "[4/8] SQL Server Client..." -NoNewline
try {
    $null = [System.Data.SqlClient.SqlConnection]
    Write-Host " ✅ OK" -ForegroundColor Green
} catch {
    Write-Host " ❌ FEHLER (SQL Client-Bibliotheken fehlen)" -ForegroundColor Red
}

# 5. SMTP-Konnektivität
Write-Host "[5/8] SMTP-Verbindung (Port 587)..." -NoNewline
$SmtpTest = Test-NetConnection -ComputerName "smtp.office365.com" -Port 587 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($SmtpTest.TcpTestSucceeded) {
    Write-Host " ✅ OK" -ForegroundColor Green
} else {
    Write-Host " ⚠️  WARNUNG (SMTP-Port 587 nicht erreichbar)" -ForegroundColor Yellow
}

# 6. Firewall-Regel für SQL Server
Write-Host "[6/8] SQL Server-Port (1433)..." -NoNewline
$SqlTest = Test-NetConnection -ComputerName "localhost" -Port 1433 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($SqlTest.TcpTestSucceeded) {
    Write-Host " ✅ OK" -ForegroundColor Green
} else {
    Write-Host " ⚠️  WARNUNG (SQL Server-Port 1433 nicht erreichbar)" -ForegroundColor Yellow
}

# 7. Event-Log-Berechtigung
Write-Host "[7/8] Event-Log-Zugriff..." -NoNewline
try {
    $null = Get-EventLog -LogName Application -Newest 1 -ErrorAction Stop
    Write-Host " ✅ OK" -ForegroundColor Green
} catch {
    Write-Host " ⚠️  WARNUNG (Event-Log nicht lesbar)" -ForegroundColor Yellow
}

# 8. Festplattenspeicher
Write-Host "[8/8] Festplattenspeicher (C:)..." -NoNewline
$Disk = Get-PSDrive -Name C
$FreeSpaceGB = [math]::Round($Disk.Free / 1GB, 2)
if ($FreeSpaceGB -gt 10) {
    Write-Host " ✅ OK ($FreeSpaceGB GB frei)" -ForegroundColor Green
} else {
    Write-Host " ⚠️  WARNUNG (Nur $FreeSpaceGB GB frei)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DIAGNOSE ABGESCHLOSSEN                          " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════" -ForegroundColor Cyan
```

**Ausführung:**
```powershell
.\Test-Prerequisites.ps1
```

---

## 🚨 Häufige Fehler & Lösungen

### Fehler 1: "Die Datei kann nicht geladen werden"

**Vollständige Fehlermeldung:**
```
.\Sage100-ServerCheck.ps1 : Die Datei "C:\Sage100-ServerCheck\Sage100-ServerCheck.ps1" 
kann nicht geladen werden, da die Ausführung von Skripts auf diesem System deaktiviert ist.
```

**Ursache:**  
PowerShell Execution Policy verhindert das Ausführen von Skripts.

**Lösung 1 (Empfohlen):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

**Lösung 2 (Temporär für eine Sitzung):**
```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Sage100-ServerCheck.ps1"
```

**Lösung 3 (Permanent für alle Benutzer - benötigt Admin):**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

**Überprüfung:**
```powershell
Get-ExecutionPolicy -List
```

**Erwartete Ausgabe:**
```
        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser    RemoteSigned
 LocalMachine    RemoteSigned
```

---

### Fehler 2: "Zugriff verweigert" beim Schreiben von Logs

**Fehlermeldung:**
```
Write-Error: Der Zugriff auf den Pfad "C:\Program Files\Sage100-ServerCheck\Logs" wurde verweigert.
```

**Ursache:**  
Skript wird ohne Administrator-Rechte ausgeführt.

**Lösung 1 (Temporär):**
```powershell
# Als Administrator starten:
Start-Process powershell -Verb RunAs -ArgumentList "-File `"C:\Sage100-ServerCheck\Sage100-ServerCheck.ps1`""
```

**Lösung 2 (Permanent - Log-Pfad ändern):**

Bearbeite `Config\config.json`:
```json
{
  "Logging": {
    "Path": "C:\\Users\\IhrUsername\\AppData\\Local\\Sage100-ServerCheck\\Logs"
  }
}
```

**Lösung 3 (NTFS-Berechtigungen anpassen):**
```powershell
$LogPath = "C:\Program Files\Sage100-ServerCheck\Logs"
$Acl = Get-Acl $LogPath
$Permission = "BUILTIN\Users", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Permission
$Acl.SetAccessRule($AccessRule)
Set-Acl $LogPath $Acl
```

---

### Fehler 3: "SQL Server nicht gefunden"

**Fehlermeldung:**
```
❌ SQL Server-Verbindung fehlgeschlagen:
Bei der Herstellung einer Verbindung zum Server ist ein Fehler aufgetreten.
(provider: SQL Network Interfaces, error: 26 - Fehler beim Suchen des angegebenen Servers/der angegebenen Instanz)
```

**Diagnoseschritte:**

**1. Verfügbare SQL Server-Instanzen finden:**
```powershell
# Alle lokalen SQL Server-Instanzen:
Get-Service -Name "MSSQL*" | Select-Object Name, DisplayName, Status

# Netzwerk-Scan nach SQL Server:
[System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | Format-Table -AutoSize
```

**2. SQL Server Browser aktivieren:**
```powershell
Set-Service -Name "SQLBrowser" -StartupType Automatic
Start-Service -Name "SQLBrowser"
```

**3. TCP/IP-Protokoll aktivieren:**
- Öffne **SQL Server Configuration Manager**
- Gehe zu **SQL Server-Netzwerkkonfiguration** → **Protokolle für [INSTANZNAME]**
- Aktiviere **TCP/IP**
- Neustart des SQL Server-Dienstes:
  ```powershell
  Restart-Service -Name "MSSQL$SAGE"
  ```

**4. Firewall-Regel hinzufügen:**
```powershell
New-NetFirewallRule `
  -DisplayName "SQL Server (TCP-In)" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 1433 `
  -Action Allow `
  -Profile Domain,Private
```

**5. Verbindung testen:**
```powershell
$ServerName = "DEIN-SERVER\SAGE"
Test-NetConnection -ComputerName $ServerName -Port 1433
```

---

### Fehler 4: "Modul konnte nicht geladen werden"

**Fehlermeldung:**
```
Import-Module : Die angegebene Modul "DebugLogger" wurde nicht geladen,
da in keinem Modulverzeichnis eine gültige Moduldatei gefunden wurde.
```

**Lösung 1 (Relative Pfade korrigieren):**

Bearbeite `Sage100-ServerCheck.ps1` und ändere die Modul-Importe:

```powershell
# VORHER (fehlerhaft):
Import-Module ".\Modules\DebugLogger.psm1"

# NACHHER (korrekt):
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$ScriptRoot\Modules\DebugLogger.psm1" -Force -Verbose
```

**Lösung 2 (Module manuell installieren):**
```powershell
# Alle Module in den Benutzer-Modulpfad kopieren:
$SourcePath = "C:\Sage100-ServerCheck\Modules"
$TargetPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Sage100ServerCheck"

New-Item -Path $TargetPath -ItemType Directory -Force
Copy-Item "$SourcePath\*.psm1" -Destination $TargetPath -Force

# Module importieren:
Import-Module Sage100ServerCheck -Force
```

**Lösung 3 (PSModulePath erweitern):**
```powershell
$env:PSModulePath += ";C:\Sage100-ServerCheck\Modules"
```

**Überprüfung:**
```powershell
Get-Module -ListAvailable -Name *Sage* | Format-Table -AutoSize
```

---

## ⚡ Performance-Probleme

### Problem: Check dauert länger als 10 Minuten

**Diagnose:**
```powershell
# Zeitmessung aktivieren:
Measure-Command {
    .\Sage100-ServerCheck.ps1 -FullCheck -Verbose
}
```

**Optimierung 1: Parallelisierung deaktivieren**

Bearbeite `Config\config.json`:
```json
{
  "SqlServer": {
    "MaxParallelChecks": 1  // Von 4 auf 1 reduzieren
  }
}
```

**Optimierung 2: Datenbank-Checks limitieren**
```json
{
  "SqlServer": {
    "Databases": [
      "Mandant001"  // Nur wichtigste Datenbanken prüfen
    ],
    "SkipSystemDatabases": true,
    "CheckOnlyOnlineDatabases": true
  }
}
```

**Optimierung 3: Performance-Counter deaktivieren**
```json
{
  "Monitoring": {
    "EnablePerformanceCounters": false
  }
}
```

**Optimierung 4: Timeout reduzieren**
```json
{
  "SqlServer": {
    "ConnectionTimeout": 3  // Von 15 auf 3 Sekunden
  }
}
```

---

## 🔐 SQL Server-Verbindungsprobleme

### Problem: "Login failed for user"

**Fehlermeldung:**
```
❌ SQL Server-Verbindung fehlgeschlagen:
Fehler bei der Anmeldung für den Benutzer 'DOMAIN\ServerCheckUser'.
```

**Lösung 1: Windows-Authentifizierung verwenden**

Stelle sicher, dass der Benutzer, der das Skript ausführt, SQL Server-Berechtigungen hat:

```sql
-- In SQL Server Management Studio (SSMS):
USE [master]
GO

-- Login erstellen:
CREATE LOGIN [DOMAIN\ServerCheckUser] FROM WINDOWS
GO

-- Datenbankbenutzer erstellen:
USE [Mandant001]
GO
CREATE USER [DOMAIN\ServerCheckUser] FOR LOGIN [DOMAIN\ServerCheckUser]
GO

-- Leserechte erteilen:
ALTER ROLE [db_datareader] ADD MEMBER [DOMAIN\ServerCheckUser]
GO
```

**Lösung 2: SQL Server-Authentifizierung verwenden**

Bearbeite `Config\config.json`:
```json
{
  "SqlServer": {
    "ServerName": "DEIN-SERVER\\SAGE",
    "AuthenticationMode": "SqlServer",
    "Username": "sage_monitor",
    "PasswordSecure": ""  // Verschlüsseltes Passwort
  }
}
```

Passwort verschlüsseln:
```powershell
$Password = Read-Host "SQL Server-Passwort eingeben" -AsSecureString
$EncryptedPassword = $Password | ConvertFrom-SecureString
$EncryptedPassword | Out-File "Config\sql_password.txt"

# Wert in config.json eintragen:
Get-Content "Config\sql_password.txt"
```

---

## 📧 E-Mail-Versand-Probleme

### Problem: "Der SMTP-Server erfordert eine sichere Verbindung"

**Lösung für Office365/Exchange Online:**

```json
{
  "SMTP": {
    "Server": "smtp.office365.com",
    "Port": 587,
    "UseSsl": true,
    "EnableStartTls": true,
    "From": "sage-monitoring@firma.de",
    "Username": "sage-monitoring@firma.de"
  }
}
```

**Lösung für Gmail:**
```json
{
  "SMTP": {
    "Server": "smtp.gmail.com",
    "Port": 587,
    "UseSsl": true,
    "From": "dein-konto@gmail.com",
    "Username": "dein-konto@gmail.com"
  }
}
```

**WICHTIG für Gmail:**  
Aktiviere "App-Passwörter" unter https://myaccount.google.com/apppasswords

**Test-E-Mail senden:**
```powershell
$SmtpServer = "smtp.office365.com"
$SmtpPort = 587
$SmtpUser = "sage-monitoring@firma.de"
$SmtpPassword = Read-Host "Passwort" -AsSecureString

$Credential = New-Object System.Management.Automation.PSCredential($SmtpUser, $SmtpPassword)

Send-MailMessage `
  -To "admin@firma.de" `
  -From "sage-monitoring@firma.de" `
  -Subject "Sage100-ServerCheck - Test" `
  -Body "Wenn diese E-Mail ankommt, funktioniert der SMTP-Versand." `
  -SmtpServer $SmtpServer `
  -Port $SmtpPort `
  -UseSsl `
  -Credential $Credential
```

---

## ⏰ Scheduled Task-Fehler

### Problem: Task läuft nicht automatisch

**Diagnose:**
```powershell
Get-ScheduledTask -TaskName "Sage100-DailyCheck" | Format-List *
```

**Prüfe Status:**
```powershell
$Task = Get-ScheduledTask -TaskName "Sage100-DailyCheck"
Write-Host "Status: $($Task.State)"
Write-Host "Letzter Lauf: $($Task.LastRunTime)"
Write-Host "Nächster Lauf: $($Task.NextRunTime)"
Write-Host "Ergebnis: $($Task.LastTaskResult)"
```

**Häufige Fehlercode:**
- `0x0` = Erfolgreich
- `0x1` = Fehler beim Ausführen
- `0x41301` = Task wird gerade ausgeführt
- `0x800710E0` = Operator hat Task abgebrochen

**Task-Historie anzeigen:**
```powershell
Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" -MaxEvents 50 | 
  Where-Object { $_.Message -like "*Sage100*" } | 
  Format-Table -Property TimeCreated, Message -Wrap
```

**Task manuell starten:**
```powershell
Start-ScheduledTask -TaskName "Sage100-DailyCheck"
```

**Task neu erstellen:**
```powershell
# Alten Task löschen:
Unregister-ScheduledTask -TaskName "Sage100-DailyCheck" -Confirm:$false

# Neu erstellen:
$Action = New-ScheduledTaskAction `
  -Execute "PowerShell.exe" `
  -Argument "-ExecutionPolicy Bypass -File `"C:\Program Files\Sage100-ServerCheck\Sage100-ServerCheck.ps1`" -FullCheck"

$Trigger = New-ScheduledTaskTrigger -Daily -At 08:00

$Principal = New-ScheduledTaskPrincipal `
  -UserId "SYSTEM" `
  -LogonType ServiceAccount `
  -RunLevel Highest

$Settings = New-ScheduledTaskSettingsSet `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -StartWhenAvailable `
  -RunOnlyIfNetworkAvailable

Register-ScheduledTask `
  -TaskName "Sage100-DailyCheck" `
  -Action $Action `
  -Trigger $Trigger `
  -Principal $Principal `
  -Settings $Settings `
  -Description "Täglicher Sage100 Server-Check"
```

---

## 🐛 Debug-Modus aktivieren

### Ausführliches Logging aktivieren

**Option 1: Kommandozeilen-Parameter**
```powershell
.\Sage100-ServerCheck.ps1 -FullCheck -Verbose -Debug
```

**Option 2: Config-Datei**
```json
{
  "Logging": {
    "Level": "Debug",  // Von "Info" auf "Debug" ändern
    "EnableVerboseOutput": true
  }
}
```

### Log-Level-Beschreibung

| Level | Beschreibung | Beispiel |
|-------|--------------|----------|
| `Error` | Nur kritische Fehler | SQL-Verbindung fehlgeschlagen |
| `Warning` | Warnungen | Dienst gestoppt, aber nicht kritisch |
| `Info` | Normale Ereignisse | Check gestartet, Check abgeschlossen |
| `Debug` | Detaillierte Informationen | SQL-Query ausgeführt, Modul geladen |
| `Trace` | Maximale Details | Jede einzelne Zeile Code |

### PowerShell-Transcription aktivieren

```powershell
# Vollständige Sitzungsaufzeichnung:
Start-Transcript -Path "C:\Logs\Sage100-Debug-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"

.\Sage100-ServerCheck.ps1 -FullCheck -Verbose -Debug

Stop-Transcript
```

---

## 📞 Support-Anfrage erstellen

Wenn keiner der obigen Lösungsansätze hilft, erstelle eine Support-Anfrage mit folgenden Informationen:

### 1. Systeminformationen sammeln

```powershell
# Speichere als: Collect-SupportInfo.ps1
$OutputFile = "C:\Sage100-ServerCheck-Support-$(Get-Date -Format 'yyyy-MM-dd_HHmmss').txt"

@"
════════════════════════════════════════════════════════════
SAGE100-SERVERCHECK - SUPPORT-INFORMATIONEN
════════════════════════════════════════════════════════════

Datum: $(Get-Date)
Computername: $env:COMPUTERNAME
Benutzer: $env:USERNAME
Domain: $env:USERDOMAIN

────────────────────────────────────────────────────────────
BETRIEBSSYSTEM
────────────────────────────────────────────────────────────
$((Get-CimInstance Win32_OperatingSystem).Caption)
Version: $((Get-CimInstance Win32_OperatingSystem).Version)
Build: $((Get-CimInstance Win32_OperatingSystem).BuildNumber)

────────────────────────────────────────────────────────────
POWERSHELL
────────────────────────────────────────────────────────────
Version: $($PSVersionTable.PSVersion)
Edition: $($PSVersionTable.PSEdition)
Execution Policy: $(Get-ExecutionPolicy)

────────────────────────────────────────────────────────────
.NET FRAMEWORK
────────────────────────────────────────────────────────────
$(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' | Select-Object Version, Release)

────────────────────────────────────────────────────────────
SQL SERVER-DIENSTE
────────────────────────────────────────────────────────────
$(Get-Service -Name "MSSQL*" | Format-Table -AutoSize | Out-String)

────────────────────────────────────────────────────────────
NETZWERK-KONNEKTIVITÄT
────────────────────────────────────────────────────────────
SQL Server (Port 1433): $(Test-NetConnection -ComputerName localhost -Port 1433 -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded)
SMTP (Port 587): $(Test-NetConnection -ComputerName smtp.office365.com -Port 587 -WarningAction SilentlyContinue | Select-Object TcpTestSucceeded)

────────────────────────────────────────────────────────────
INSTALLIERTE MODULE
────────────────────────────────────────────────────────────
$(Get-Module -ListAvailable -Name *Sage* | Format-Table -AutoSize | Out-String)

────────────────────────────────────────────────────────────
LETZTE FEHLER IM EVENT-LOG
────────────────────────────────────────────────────────────
$(Get-EventLog -LogName Application -Source "Sage*" -Newest 10 -ErrorAction SilentlyContinue | Format-List | Out-String)

════════════════════════════════════════════════════════════
"@ | Out-File $OutputFile -Encoding UTF8

Write-Host "✅ Support-Informationen gesammelt: $OutputFile" -ForegroundColor Green
notepad $OutputFile
```

### 2. GitHub-Issue erstellen

Gehe zu: https://github.com/MJungAktuellis/Sage100-ServerCheck/issues/new

**Issue-Template:**
```markdown
## 🐛 Fehlerbeschreibung

### Erwartetes Verhalten
[Beschreibe, was passieren sollte]

### Tatsächliches Verhalten
[Beschreibe, was tatsächlich passiert]

### Fehlermeldung
```
[Vollständige Fehlermeldung hier einfügen]
```

### Schritte zur Reproduktion
1. Starte das Skript mit: `.\Sage100-ServerCheck.ps1 -FullCheck`
2. Fehler tritt auf bei: [Beschreibung]
3. ...

### Systeminformationen
- **Betriebssystem:** Windows Server 2019
- **PowerShell-Version:** 5.1.17763.5830
- **SQL Server-Version:** 2019 (15.0.2000.5)
- **Sage100-Version:** [Version]

### Log-Auszug
```
[Relevante Log-Einträge hier einfügen]
```

### Screenshots
[Falls vorhanden, Screenshots anhängen]
```

---

## ✅ Checkliste vor Support-Anfrage

- [ ] Alle Lösungsansätze in diesem Guide ausprobiert
- [ ] `Test-Prerequisites.ps1` ausgeführt
- [ ] Systeminformationen gesammelt
- [ ] Relevante Log-Dateien identifiziert
- [ ] Fehler reproduzierbar
- [ ] Screenshots erstellt (falls GUI-Problem)

---

**Letzte Aktualisierung:** 2026-02-09  
**Maintainer:** DevOps Team  
**Feedback:** https://github.com/MJungAktuellis/Sage100-ServerCheck/issues
