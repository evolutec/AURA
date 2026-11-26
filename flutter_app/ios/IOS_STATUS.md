# AURA — iOS Implementation Status

## Phase 3 — iOS ✅ (fichiers prêts, build nécessite macOS + Xcode)

## Fichiers créés

### Configuration
- `ios/Runner/Info.plist` — Permissions, ATS, background modes, URL schemes, privacy manifest
- `ios/Runner/Aura.entitlements` — Keychain groups, App Groups, network, sandbox
- `ios/Podfile` — Dependencies (iOS 14+)
- `ios/ExportOptions.plist` — Distribution App Store Connect
- `ios/build_ios.ps1` — Build script (macOS + Xcode)

### Plugins Swift
- `ios/Runner/KeychainPlugin.swift` — Stockage sécurisé clés API (Keychain)
- `ios/Runner/SharePlugin.swift` — Contenu partagé entrant (pasteboard)
- `ios/Runner/WidgetPlugin.swift` — Mise à jour widgets WidgetKit
- `ios/Runner/VoicePlugin.swift` — Mode voix (SFSpeechRecognizer + AVSpeechSynthesizer)
- `ios/Runner/AppIntentsPlugin.swift` — App Intents (Siri/Shortcuts)
- `ios/Runner/AppDelegate.swift` — Enregistrement plugins

### Widgets (WidgetKit)
- `ios/AuraWidget/AuraWidget.swift` — Widgets stats + quick chat
- `ios/AuraWidget/Info.plist` — Configuration extension
- `ios/AuraWidget/AuraWidget.entitlements` — App Groups
- `ios/AuraWidget/WidgetConfig.json` — Config Xcode

### Share Extension
- `ios/ShareExtension/ShareViewController.swift` — Partage vers AURA
- `ios/ShareExtension/Info.plist` — Types supportés (text, URL, image, file)
- `ios/ShareExtension/ShareExtension.entitlements` — App Groups

### Plugins Dart
- `lib/ios_plugins.dart` — Conditional export
- `lib/ios_plugins_stub.dart` — Stub (non-iOS)
- `lib/ios_plugins_native.dart` — Native iOS (Keychain, Share, Widget, Voice)

## Fonctionnalités iOS

| Feature | Statut | Notes |
|---|---|---|
| **Keychain** | ✅ Prêt | Stockage sécurisé clés API |
| **Share Extension** | ✅ Prêt | Texte, URL, images, fichiers |
| **WidgetKit** | ✅ Prêt | Stats (tok/s, RAM) + quick chat |
| **Mode voix** | ✅ Prêt | SFSpeechRecognizer (ASR) + AVSpeechSynthesizer (TTS) |
| **App Intents / Shortcuts** | ✅ Prêt | Siri : "Demande à AURA" |
| **Widget Quick Chat** | ✅ Prêt | Ouvre `aura://chat` |
| **ATS (loopback)** | ✅ Prêt | Cleartext interdit sauf localhost/127.0.0.1 |
| **Background audio** | ✅ Prêt | Mode voix en arrière-plan |
- **URL schemes** | ✅ Prêt | `aura://` deep links |
| **Document import** | ✅ Prêt | LSSupportsOpeningDocumentsInPlace |
| **Bonjour/mDNS** | ✅ Prêt | Découverte Ollama LAN |
- **Privacy manifest** | ✅ Prêt | NSPrivacyCollectedDataTypes |

## Pour builder sur macOS

```bash
# 1. Installer CocoaPods
sudo gem install cocoapods

# 2. Installer les pods
cd ios && pod install

# 3. Build (ou ouvrir Runner.xcworkspace dans Xcode)
flutter build ios --release --no-codesign

# 4. Pour IPA (nécessite compte Apple Developer)
pwsh -File build_ios.ps1 -BuildIpa
```

## Configuration Xcode requise

1. **Signing & Capabilities** :
   - Team : ton Apple Developer Team
   - Bundle ID : `com.aura.aura_app`
   - + Capability : Keychain Sharing
   - + Capability : App Groups (`group.com.aura.aura_app`)
   - + Capability : Background Modes (Audio, Processing)

2. **Extensions** :
   - + Target : Widget Extension (AuraWidget)
   - + Target : Share Extension (ShareExtension)
   - Configurer les App Groups pour chaque extension

3. **Info.plist** : vérifier les `NS*UsageDescription`

---

## Comparaison Android vs iOS

| Aspect | Android | iOS |
|---|---|---|
| **Permissions** | Runtime (SDK 23+) | Info.plist + runtime |
| **Background** | Foreground Service | BGTaskScheduler + audio |
| **Widgets** | AppWidgets (Glance) | WidgetKit |
| **Share** | Intent filters | Share Extension |
| **Keychain** | EncryptedSharedPreferences | Keychain (natif) |
| **ADB** | Shizuku/wireless | ❌ Impossible |
| **Code arbitraire** | ❌ (sans root) | ❌ (impossible) |
| **Sandbox** | Zone isolée | Sandbox stricte |
| **Distribution** | Play Store / sideload | App Store uniquement |