# Sage100-ServerCheck

**PowerShell Tool zur automatischen Prüfung und Konfiguration von Sage 100 Serverumgebungen**

## 🎯 Zweck

Dieses Tool automatisiert die Überprüfung und Dokumentation von Sage 100 Installationen. Es prüft Systemvoraussetzungen, sammelt Serverinformationen und generiert professionelle Kundenstammblätter im Markdown-Format.

## ✨ Features

### 1. Systemprüfung
- ✅ Windows Server Version & Support-Status
- ✅ SQL Server Edition & Konfiguration
- ✅ Hardware-Ressourcen (CPU, RAM, Disk)
- ✅ Netzwerk-Konfiguration & Ports
- ✅ Firewall-Regeln (Sage-spezifisch)
- ✅ .NET Framework & Access Runtime

### 2. Datensammlung
- 📊 Installierte Software & Versionen
- 📊 SQL Server Instanzen & Datenbanken
- 📊 Ordnerstrukturen & Berechtigungen
- 📊 Netzwerk- & Domain-Informationen

### 3. Dokumentation
- 📝 Automatische Markdown-Export
- 📝 Kundenstammblatt-Generierung
- 📝 Arbeitsprotokollierung (Terminhistorie)
- 📝 JSON-Daten für Verlaufsanalyse

### 4. Interaktive Konfiguration
- 🔧 Problem-Erkennung mit Handlungsempfehlungen
- 🔧 User-gesteuerte Lösungen (keine Auto-Fixes)
- 🔧 Firewall-Regel-Vorschläge
- 🔧 Ordnerstruktur-Vorlagen

## 📦 Installation

### Voraussetzungen
- Windows Server 2019/2022/2025 oder Windows 11
- PowerShell 5.1 oder höher
- Administratorrechte für Systemprüfungen

### Quick Start

1. **Repository klonen oder downloaden**
```powershell
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck
```

2. **Tool starten**
```powershell
.\Sage100-ServerCheck.ps1
```

### Alternative: Direkter Download
```powershell
# Als Administrator ausführen
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/MJungAktuellis/Sage100-ServerCheck/main/Sage100-ServerCheck.ps1" -OutFile "Sage100-ServerCheck.ps1"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\Sage100-ServerCheck.ps1
```

## 🚀 Verwendung

### Vollständiger Check
```powershell
.\Sage100-ServerCheck.ps1 -FullCheck
```

### Nur Systemvoraussetzungen prüfen
```powershell
.\Sage100-ServerCheck.ps1 -CheckRequirements
```

### Kundenstammblatt generieren
```powershell
.\Sage100-ServerCheck.ps1 -GenerateReport -CustomerName "Firma XY"
```

### Arbeitsprotokoll hinzufügen
```powershell
.\Sage100-ServerCheck.ps1 -AddWorkLog -Technician "Max Mustermann" -Description "Installation Sage 100" -Duration 120
```

## 📁 Projektstruktur

```
Sage100-ServerCheck/
├── Sage100-ServerCheck.ps1       # Haupt-Skript
├── Modules/
│   ├── SystemCheck.psm1          # System-Prüfungen
│   ├── SQLCheck.psm1             # SQL Server Analysen
│   ├── NetworkCheck.psm1         # Netzwerk & Firewall
│   ├── SoftwareInventory.psm1    # Software-Erkennung
│   ├── DirectoryStructure.psm1   # Ordner-Analysen
│   └── WorkLog.psm1              # Arbeitsprotokoll
├── Templates/
│   ├── Kundenstammblatt.md       # Markdown-Vorlage
│   └── Sage100-Requirements.json # Systemvoraussetzungen
├── Data/                         # Gespeicherte Snapshots
├── Reports/                      # Generierte Berichte
└── README.md
```

## 🔍 Beispiel-Output

```
╔════════════════════════════════════════════════════════════════╗
║         Sage 100 Server Check v1.0                             ║
╚════════════════════════════════════════════════════════════════╝

[✓] System: Windows Server 2022 Standard (Build 20348)
[✓] SQL Server: 2022 Enterprise Edition (16.0.1000.6)
[✓] RAM: 32 GB (Empfohlen: 16 GB)
[✓] CPU: Xeon E5-2680 v4 @ 2.4GHz (28 Cores)
[!] Warnung: Port 5493 (Application Server) nicht freigegeben
[!] Warnung: Ordner C:\Sage100\Data fehlt

════════════════════════════════════════════════════════════════
Probleme gefunden: 2
Möchten Sie Lösungsvorschläge sehen? (J/N)
```

## ⚙️ Konfiguration

Die Datei `Templates/Sage100-Requirements.json` enthält alle Prüfkriterien basierend auf den offiziellen Sage 100 Systemvoraussetzungen (Version 9.0.10).

Anpassungen können direkt in der JSON vorgenommen werden.

## 📄 Lizenz

MIT License - Frei verwendbar für kommerzielle und private Zwecke

## 🤝 Beitragen

Pull Requests sind willkommen! Für größere Änderungen bitte zuerst ein Issue öffnen.

## 📞 Support

Bei Fragen oder Problemen bitte ein [GitHub Issue](https://github.com/MJungAktuellis/Sage100-ServerCheck/issues) erstellen.

---

**Entwickelt für Sage 100 Partner und Systemadministratoren**
