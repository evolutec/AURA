# AURA — Distribution Desktop (Phase 4)

## Formats de distribution par plateforme

| Plateforme | Format | Signature | Store | Build Script |
|---|---|---|---|---|
| **Windows** | MSIX | EV cert (SmartScreen) | Microsoft Store | `windows/build_msix.ps1` |
| **Linux** | Flatpak | Aucune | Flathub | `flatpak/build_flatpak.ps1` |
| **macOS** | .app + .dmg | Notarization Apple | Developer ID | `macos/build_macos.ps1` |

## Windows (MSIX)

### Build
```powershell
cd flutter_app\windows
.\build_msix.ps1
```

### Structure
- `Package.appxmanifest` — Manifest MSIX (capabilities, file associations)
- `build_msix.ps1` — Build Flutter + copie core Rust + package MSIX
- `MakeAppx.exe` (Windows SDK) pour créer le `.msix`

### Distribution
- Microsoft Store (Partner Center)
- Sideloading : `Add-AppxPackage -Path AURA.msix`
- Signature : certificat EV pour SmartScreen

### Permissions MSIX
- `internetClient`, `internetClientServer`, `privateNetworkClientServer`
- `runFullTrust`, `unvirtualizedResources`

---

## Linux (Flatpak)

### Build
```powershell
cd flutter_app\flatpak
.\build_flatpak.ps1
```

### Structure
- `com.aura.Aura.yml` — Manifest Flatpak (org.freedesktop.Platform 24.08)
- `com.aura.Aura.desktop` — Desktop entry
- `com.aura.Aura.metainfo.xml` — AppStream metainfo (Flathub)
- `build_flatpak.ps1` — Build script

### Distribution
- Flathub (soumission PR)
- Local : `flatpak install --user aura.flatpak`
- Run : `flatpak run com.aura.Aura`

### Permissions Flatpak
- `--share=network` (cloud providers)
- `--filesystem=home` (modèles, docs)
- `--socket=pulseaudio` (audio)
- `--device=dri` (GPU)
- `--device=video` (caméra)
- `--talk-name=org.freedesktop.secrets` (Keychain)
- `--talk-name=org.freedesktop.Notifications`

---

## macOS (Notarization)

### Build
```powershell
cd flutter_app\macos
.\build_macos.ps1 -Notarize -AppleId <email> -TeamId <team> -Password <app-specific>
```

### Structure
- `Runner/Aura.entitlements` — entitlements sandbox + hardened runtime
- `notarize_macos.ps1` — Notarization + stapling + DMG
- `build_macos.ps1` — Build + code sign + notarize

### Distribution
- DMG (direct download)
- Mac App Store (nécessite App Store category + review)
- Notarization obligatoire pour Gatekeeper

### Hardened Runtime (requis pour notarization)
- `com.apple.security.cs.allow-jit`
- `com.apple.security.cs.allow-unsigned-executable-memory`
- `com.apple.security.cs.disable-library-validation`

### Compte requis
- Apple Developer Program ($99/an)
- App-specific password pour notarytool

---

## Comparaison des 3 plateformes

| Aspect | Windows MSIX | Linux Flatpak | macOS Notarized |
|---|---|---|---|
| **Signature** | EV cert | Aucune | Developer ID |
| **Sandbox** | Léger | Flatpak sandbox | App Sandbox |
| **Store** | Microsoft Store | Flathub | Direct / MAS |
| **Auto-update** | Store / MSIX | Flatpak | Sparkle (optionnel) |
| **Tray** | ✅ | ✅ (libappindicator) | ✅ |
| **Notifications** | WinRT Toast | libnotify | UserNotifications |
| **Keychain** | DPAPI | Secret Service | Keychain |
| **GPU** | DirectML/CUDA | Vulkan/OpenCL | Metal |
| **Distribution** | .msix | .flatpak | .dmg / .app |

---

## Build all desktop

```powershell
# Windows
cd flutter_app\windows && .\build_msix.ps1

# Linux (sur Linux)
cd flutter_app\flatpak && .\build_flatpak.ps1

# macOS (sur macOS)
cd flutter_app\macos && .\build_macos.ps1 -Notarize ...
```

Chaque script produit un package installable dans le dossier `build/`.