# 🧹 CLEANUP GUIDE - Alte Dateien entfernen

**ACHTUNG:** Dieses Dokument listet alle **veralteten Dateien** auf, die manuell gelöscht werden sollten.

---

## ❌ **DATEIEN DIE GELÖSCHT WERDEN SOLLEN:**

### **Alte Installer (5 Dateien):**
```
/AutoSetup.cmd
/EASY-INSTALL.cmd
/EASY-INSTALL-v2.cmd
/Install.ps1
/START-HERE.cmd
```

### **Alte Haupt-Skripte (3 Dateien):**
```
/Sage100-ServerCheck.ps1
/Sage100-ServerCheck-GUI.ps1
/Quick-Start.ps1
```

### **Alte Hilfs-Skripte (1 Datei):**
```
/Test-Prerequisites.ps1
```

### **Veraltete Ordner (4 Ordner):**
```
/Config/          → Ersetzt durch /config/
/GUI/             → Veraltet, GUI ist jetzt in /app/
/Installer/       → Ersetzt durch /setup/
/Modules/         → Ersetzt durch /app/modules/
```

---

## ✅ **NEUE SAUBERE STRUKTUR:**

```
📁 Sage100-ServerCheck/
├── 📄 INSTALL.cmd                  ← EINZIGER Einstiegspunkt
├── 📄 README.md                    ← Hauptdokumentation
├── 📄 LICENSE                      ← MIT Lizenz
├── 📄 .gitignore                   ← Git-Konfiguration
│
├── 📁 app/                         ← Hauptanwendung
│   ├── Sage100ServerCheck.ps1      ← Core-Programm
│   └── 📁 modules/                 ← Module
│       ├── ServiceMonitor.psm1
│       ├── ProcessChecker.psm1
│       └── Notifier.psm1
│
├── 📁 config/                      ← Konfiguration
│   ├── defaults.json               ← Standardwerte
│   └── config.json.template        ← Vorlage
│
├── 📁 setup/                       ← Installation
│   ├── FirstRunWizard.ps1          ← Installationsassistent
│   └── Uninstall.ps1               ← Deinstallation
│
└── 📁 docs/                        ← Dokumentation
    └── ARCHITECTURE.md             ← Technische Doku
```

---

## 🛠️ **MANUELLE LÖSCHUNG:**

**Option 1: GitHub Web Interface**
1. Gehe zu https://github.com/MJungAktuellis/Sage100-ServerCheck
2. Klicke auf jede Datei oben
3. Klicke auf "Delete file" (Mülleimer-Symbol)
4. Commit mit Nachricht: `Cleanup: Remove old files`

**Option 2: Git Kommandozeile**
```bash
git clone https://github.com/MJungAktuellis/Sage100-ServerCheck.git
cd Sage100-ServerCheck

# Alte Installer löschen
git rm AutoSetup.cmd EASY-INSTALL.cmd EASY-INSTALL-v2.cmd Install.ps1 START-HERE.cmd

# Alte Skripte löschen
git rm Sage100-ServerCheck.ps1 Sage100-ServerCheck-GUI.ps1 Quick-Start.ps1 Test-Prerequisites.ps1

# Alte Ordner löschen
git rm -r Config/ GUI/ Installer/ Modules/

# Commit & Push
git commit -m "Cleanup: Remove old files, use new structure"
git push origin main
```

---

## ✅ **NACH DEM CLEANUP:**

Nach der Bereinigung sollte das Repository **nur noch** folgende Dateien enthalten:

- ✅ `INSTALL.cmd`
- ✅ `README.md`
- ✅ `LICENSE`
- ✅ `.gitignore`
- ✅ `app/` Ordner (mit Sage100ServerCheck.ps1 und modules/)
- ✅ `config/` Ordner (mit defaults.json und config.json.template)
- ✅ `setup/` Ordner (mit FirstRunWizard.ps1 und Uninstall.ps1)
- ✅ `docs/` Ordner (mit ARCHITECTURE.md)

---

**Nach dem Cleanup kann diese Datei (`CLEANUP-GUIDE.md`) ebenfalls gelöscht werden.**
