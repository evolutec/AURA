# AURA — Différences par plateforme (Android / iOS / macOS / Linux / Windows)

> Ce document recense ce qui diffère entre plateformes pour AURA, et ce qui doit être adapté. Il couvre UI, permissions, notifications, accès système, sandbox, et build.

---

## 1. Vue d'ensemble des plateformes cibles

| Plateforme | Forme | Usage typique | Restrictions clés |
|---|---|---|---|
| **Android** | Mobile (téléphone/tablette) | Assistant local, caméra, micro | Play Store (PairIP), permissions runtime, pas de code natif arbitraire sans root |
| **iOS** | Mobile (iPhone/iPad) | Assistant local | **Pas d'ADB**, pas de code natif arbitraire, sandbox stricte, App Store review |
| **macOS** | Desktop portable | Assistant local, dev | Gatekeeper/notarisation, sandbox App Store (optionnel) |
| **Linux** | Desktop | Assistant local, serveur | Pas de Play Store, liberté totale (proot, terminal, RPC) |
| **Windows** | Desktop | Assistant local, serveur | SmartScreen, antivirus, Defender |

---

## 2. UI / UX — ce qui diffère

### 2.1 Layout adaptatif
| Élément | Mobile (Android/iOS) | Desktop (Win/Linux/macOS) |
|---|---|---|
| **Sidebar** | Coulissante (overlay, bouton hamburger) | Fixe ou repliable (largeur 64↔280px) |
| **Navigation** | Bottom nav bar ou drawer | Sidebar latérale permanente |
| **Composer** | Barre collée en bas, boutons icônes | Barre avec plus d'espace, raccourcis clavier |
| **Modale settings** | Plein écran (bottom sheet) | Modale centrée avec sidebar interne |
| **Police** | Dynamic Type / Text Size adaptatif | Tailles fixes, plus dense |
| **Touch targets** | ≥44pt iOS / ≥48dp Android | ≥32px desktop (souris) |
| **Safe areas** | Notch, status bar, gesture area | Barre de titre, menu bar macOS |
| **Orientation** | Portrait + paysage | Paysage uniquement |

### 2.2 Ce qui doit être adapté dans AURA
- **Détecter le form factor** au runtime (`Platform.isAndroid/iOS` vs desktop)
- **Sidebar** : overlay drawer sur mobile, fixe sur desktop
- **Modale settings** : bottom sheet plein écran sur mobile, modale centrée sur desktop
- **Composer** : icônes compactes sur mobile, labels sur desktop
- **Raccourcis clavier** : desktop uniquement (Cmd/Ctrl+K, etc.)

---

## 3. Permissions — ce qui diffère

### 3.1 Tableau des permissions par plateforme
| Permission | Android | iOS | macOS | Linux | Windows |
|---|---|---|---|---|---|
| **Micro (ASR/voix)** | `RECORD_AUDIO` (runtime) | `NSMicrophoneUsageDescription` | `NSMicrophoneUsageDescription` | PulseAudio/PipeWire | Microphone (privacy settings) |
| **Caméra (vision)** | `CAMERA` (runtime) | `NSCameraUsageDescription` | `NSCameraUsageDescription` | V4L2 | Camera (privacy) |
| **Stockage/fichiers** | Scoped Storage, `MANAGE_EXTERNAL_STORAGE` (optionnel) | Sandbox (Documents/) | Sandbox (optionnel) | Libre | Libre (UAC pour Program Files) |
| **Localisation** | `ACCESS_FINE_LOCATION` (runtime) | `NSLocationWhenInUse` | `NSLocationWhenInUse` | Libre | Location (privacy) |
| **Calendrier** | `READ/WRITE_CALENDAR` (runtime) | `NSCalendarsUsageDescription` | `NSCalendarsUsageDescription` | N/A (via CalDAV) | N/A (via Graph API) |
| **Notifications** | `POST_NOTIFICATIONS` (Android 13+) | Autorisation user | Autorisation user | D-Bus (libnotify) | Toast (WinRT) |
| **Internet** | `INTERNET` (normal) | `NSAppTransportSecurity` | `NSAppTransportSecurity` | Libre | Pare-feu Windows |
| **Réseau local** | `ACCESS_NETWORK_STATE` | `NSLocalNetworkUsageDescription` | `NSLocalNetworkUsageDescription` | Libre | Pare-feu |
| **Overlay** | `SYSTEM_ALERT_WINDOW` | ❌ Impossible | N/A | N/A | N/A |
| **Usage stats** | `PACKAGE_USAGE_STATS` | ❌ Impossible | N/A | N/A | N/A |
| **ADB** | Wireless debugging / Shizuku | ❌ Impossible | N/A | N/A | N/A |

### 3.2 Ce qui doit être adapté dans AURA
- **Gestion des permissions runtime** : Android (13+) et iOS demandent au runtime ; desktop non
- **Fallback gracieux** : si micro/caméra refusé → désactiver la feature concernée
- **`NS*UsageDescription`** : strings obligatoires dans `Info.plist` iOS/macOS
- **`usesCleartextTraffic`** : Android (manifest) ; iOS ATS (Info.plist) ; desktop libre
- **Permissions overlay/usage stats** : Android uniquement (Shizuku pour ADB)

---

## 4. Notifications — ce qui diffère

| Aspect | Android | iOS | macOS | Linux | Windows |
|---|---|---|---|---|---|
| **API** | NotificationManager / FCM | UserNotifications | UserNotifications | libnotify (D-Bus) | WinRT Toast |
| **Permission** | `POST_NOTIFICATIONS` (13+) | Autorisation user | Autorisation user | Aucune | Aucune |
| **Push distant** | FCM | APNs | APNs | N/A | WNS |
| **Actions** | Oui (boutons) | Oui | Oui | Limité | Oui |
| **Badges** | Oui | Oui | Oui | Limité | Oui |
| **Silent** | Oui (canaux) | Oui (critical alerts) | Oui | N/A | Oui |

### Ce qui doit être adapté
- **Canaux de notification** Android (importance, son, vibration)
- **Catégories** iOS (identifier les types de notifs)
- **Fallback** : si pas de permission → notifs in-app uniquement
- **Push** : FCM (Android) + APNs (iOS) nécessitent un backend ; optionnel pour AURA

---

## 5. Contrôle appareil (ADB) — ce qui diffère

| Plateforme | Accès | Méthode |
|---|---|---|
| **Android** | ✅ Partiel | Wireless debugging pairing, ou **Shizuku** (sans root) |
| **iOS** | ❌ Impossible | Pas d'équivalent ADB (restrictions Apple) |
| **macOS/Linux/Windows** | ✅ (contrôler un Android) | Embarquer `adb` et contrôler un appareil connecté |

### Ce qui doit être adapté
- **Android** : Shizuku (privilèges shell sans root) ou ADB sans fil
- **Desktop** : embarquer `adb` pour contrôler un Android connecté (USB/réseau)
- **iOS** : désactivé, proposer App Intents / Shortcuts à la place
- **Fallback** : message "non supporté sur cette plateforme"

---

## 6. Sandbox / Terminal — ce qui diffère

| Plateforme | Sandbox | Terminal | Code natif arbitraire |
|---|---|---|---|
| **Android** | Zone isolée + WorkManager | ❌ (pas de shell) | ❌ (sans root) |
| **iOS** | Sandbox stricte | ❌ | ❌ (impossible) |
| **macOS** | App Sandbox (optionnel) | ✅ (Process.run) | ✅ (avec notarisation) |
| **Linux** | bubblewrap/nsjail | ✅ | ✅ |
| **Windows** | Windows Sandbox / Job Objects | ✅ (conhost) | ✅ |

### Ce qui doit être adapté
- **Android/iOS** : WASM uniquement (Wasmtime), pas de code natif arbitraire
- **Desktop** : sandbox natif (bubblewrap Linux, Windows Sandbox) + terminal réel
- **Fallback** : WASM pour tous, natif sur desktop

---

## 7. Widgets / Intégration OS — ce qui diffère

| Feature | Android | iOS | Desktop |
|---|---|---|---|
| **Widgets écran d'accueil** | AppWidgets (Glance) | WidgetKit | ❌ (pas de widgets desktop) |
| **Tuile Quick Settings** | QS Tile | ❌ | ❌ |
| **PROCESS_TEXT** | Intent (traiter texte sélectionné) | Share Extension | ❌ |
| **Share target** | Intent filter | Share Extension | Menu contextuel (desktop) |
| **App Functions / Shortcuts** | App Functions (Android 16+) | App Intents / Shortcuts | Quick Actions (Win/Linux) |
| **Icônes alternatives** | App shortcuts / launcher | Alternate icons (iOS) | N/A |
| **Mode stealth** | Icon hiding (launcher) | N/A | N/A |

### Ce qui doit être adapté
- **Android** : AppWidgets (Glance), QS Tile, PROCESS_TEXT, App Functions
- **iOS** : WidgetKit, Share Extension, App Intents
- **Desktop** : menu contextuel, raccourcis clavier
- **Commun** : icône dans la barre système (tray) desktop

---

## 8. Background / Cycle de vie — ce qui diffère

| Aspect | Android | iOS | Desktop |
|---|---|---|---|
| **Exécution background** | Foreground Service + WorkManager | Background Tasks (BGTaskScheduler) | Libre (process persistant) |
| **Contrainte RAM** | Doze mode, kill agressif | Jetsam (kill mémoire) | Libre |
| **Persistance** | Service persistant | BGProcessingTask | Service/agent |
| **Auto-start au boot** | BootReceiver | ❌ (notifications push) | Login items / systemd |

### Ce qui doit être adapté
- **Android** : Foreground Service pour l'inférence (avec notification persistante)
- **iOS** : BGTaskScheduler pour tâches courtes ; inférence longue impossible en background
- **Desktop** : process persistant, pas de contrainte
- **Fallback** : inférence au premier plan uniquement sur mobile

---

## 9. Chargement des libs natives — ce qui diffère

| Plateforme | Format | Emplacement | Chargement |
|---|---|---|---|
| **Android** | `.so` (arm64-v8a) | `jniLibs/arm64-v8a/` | `DynamicLibrary.open('libaura_core.so')` |
| **iOS** | `.a` (static) + framework | `Runner/` | Linké statiquement |
| **macOS** | `.dylib` (universal) | `Runner/` | `DynamicLibrary.open('libaura_core.dylib')` |
| **Linux** | `.so` | `bundle/lib/` | `DynamicLibrary.open('libaura_core.so')` |
| **Windows** | `.dll` | `runner/` | `DynamicLibrary.open('aura_core.dll')` |
| **Web** | N/A | N/A | `ffi_stub.dart` (mock) |

### Ce qui doit être adapté
- **iOS** : libs statiques (`.a`), pas de `.dylib` (App Store n'autorise pas le dlopen)
- **Android** : une `.so` par ABI (arm64-v8a, armeabi-v7a, x86_64)
- **Desktop** : `.dylib`/`.so`/`.dll` dans le bundle
- **Fallback** : stub web

---

## 10. Build & Distribution — ce qui diffère

| Plateforme | Format | Signature | Distribution |
|---|---|---|---|
| **Android** | APK / AAB | Keystore | Play Store / sideload |
| **iOS** | IPA | Apple Developer | App Store uniquement |
| **macOS** | .app / .dmg | Notarisation Apple | Notarisation requise (Gatekeeper) |
| **Linux** | AppImage / .deb / Flatpak | Aucune | Libre |
| **Windows** | .exe / MSIX | SmartScreen / EV cert | Libre / Microsoft Store |

### Ce qui doit être adapté
- **iOS** : Apple Developer account ($99/an), provisioning profiles
- **macOS** : Notarisation (compte Apple requis)
- **Android** : Keystore de signature, Play Console
- **Windows** : Signature de code (EV cert pour SmartScreen)
- **Windows (prérequis build)** : `nuget.exe` dans le PATH (requis par le plugin `webview_flutter_windows` / WebView2). Si absent, Flutter le télécharge automatiquement dans le dossier de build ; pour l'installateur/CI, fournir `nuget` à l'avance (ex. `C:\Users\evolu\bin\nuget.exe`).
- **Linux** : AppImage (portable) + Flatpak

---

## 11. Stockage sécurisé — ce qui diffère

| Plateforme | Clés API | Base de données | Chiffrement |
|---|---|---|---|
| **Android** | EncryptedSharedPreferences / Keystore | SQLite / Room / ObjectBox | SQLCipher (optionnel) |
| **iOS** | Keychain | Core Data / SQLite | Data Protection (natif) |
| **macOS** | Keychain | SQLite / Core Data | FileVault (natif) |
| **Linux** | Secret Service (libsecret) | SQLite | LUKS (optionnel) |
| **Windows** | DPAPI / Credential Manager | SQLite | BitLocker (natif) |

### Ce qui doit être adapté
- **iOS/macOS** : Keychain (natif)
- **Android** : EncryptedSharedPreferences
- **Windows** : DPAPI
- **Linux** : Secret Service
- **Fallback** : fichier chiffré (AES-256-GCM)

---

## 12. Réseau / Cleartext — ce qui diffère

| Plateforme | Cleartext HTTP | Configuration |
|---|---|---|
| **Android** | Bloqué par défaut (API 28+) | `usesCleartextTraffic` dans manifest |
| **iOS** | Bloqué par ATS | `NSAppTransportSecurity` dans Info.plist |
| **macOS** | Bloqué par ATS | `NSAppTransportSecurity` |
| **Linux/Windows** | Autorisé | Aucune |

### Ce qui doit être adapté
- **Loopback uniquement** : autoriser cleartext pour `127.0.0.1`/`localhost` (serveur llama local)
- **HTTPS partout else** : providers cloud, mises à jour
- **Fallback** : whitelist loopback

---

## 13. RAM / Performance — ce qui diffère

| Plateforme | RAM typique | Contrainte | Stratégie |
|---|---|---|---|
| **Android** | 4–16 Go | Kill agressif (Doze, low memory killer) | Un seul moteur lourd, déchargement agressif |
| **iOS** | 4–8 Go | Jetsam (pas de swap) | Un seul moteur, déchargement immédiat |
| **Desktop** | 8–64+ Go | Libre (swap) | Plusieurs moteurs possibles |

### Ce qui doit être adapté
- **Mobile** : `RamMonitor` strict, un seul moteur à la fois
- **Desktop** : `RamMonitor` souple, plusieurs moteurs si RAM suffisante
- **Fallback** : CPU uniquement si pas de GPU/NPU

---

## 14. Ce qui doit être implémenté par plateforme (résumé)

### Commun (toutes plateformes)
- ✅ Core Rust FFI (déjà fait)
- ✅ Chat local + cloud
- ✅ Catalogue modèles
- ✅ RAG, agents, skills, MCP
- ✅ i18n, thème, glassmorphism

### Android (spécifique)
- [ ] AppWidgets (Glance)
- [ ] QS Tile
- [ ] PROCESS_TEXT + Share target
- [ ] App Functions (Android 16+)
- [ ] Shizuku pour ADB
- [ ] Foreground Service pour inférence
- [ ] EncryptedSharedPreferences
- [ ] Canaux de notification
- [ ] `usesCleartextTraffic=false` + loopback

### iOS (spécifique)
- [ ] WidgetKit
- [ ] Share Extension
- [ ] App Intents / Shortcuts
- [ ] Keychain
- [ ] BGTaskScheduler (tâches courtes)
- [ ] `NS*UsageDescription` dans Info.plist
- [ ] ATS loopback exception
- [ ] Libs statiques (.a)

### macOS (spécifique)
- [ ] Menu bar tray
- [ ] Touch Bar (optionnel)
- [ ] Keychain
- [ ] Notarisation
- [ ] Universal binary (Intel + ARM)

### Linux (spécifique)
- [ ] AppImage / Flatpak
- [ ] System tray (libappindicator)
- [ ] Secret Service (libsecret)
- [ ] bubblewrap sandbox
- [ ] proot pour terminal

### Windows (spécifique)
- [ ] System tray
- [ ] Toast notifications (WinRT)
- [ ] DPAPI (Credential Manager)
- [ ] Windows Sandbox
- [ ] Signature de code (EV cert)
- [ ] Prérequis build installateur : `nuget.exe` dans le PATH (WebView2)

---

## 15. Priorités d'implémentation par plateforme

### Phase 1 (MVP) — Desktop uniquement
1. Windows/Linux/macOS avec Flutter
2. Core Rust FFI
3. Chat local (llama.cpp) + cloud
4. Pas de widgets/mobile-specific

### Phase 2 — Android
1. Build APK/AAB
2. Shizuku pour ADB
3. Foreground Service
4. AppWidgets + QS Tile
5. Share target + PROCESS_TEXT

### Phase 3 — iOS
1. Build IPA
2. Keychain
3. WidgetKit
4. Share Extension
5. App Intents

### Phase 4 — Polish
1. Notarisation macOS
2. Flatpak Linux
3. MSIX Windows
4. Widgets desktop (tray)
5. Mode stealth / icônes alternatives