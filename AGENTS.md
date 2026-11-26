# AGENTS.md — AURA (Flutter + Rust core)

## Langue de l'agent
toujours repondre en francais

## Présentation du projet
AURA est un assistant IA multiplateforme (Android, iOS, Windows, Linux, macOS) construit avec Flutter, reposant sur un cœur Rust (`core/`) exposé via FFI (`flutter_app/lib/ffi_bindings.dart`). Il cible les LLM locaux et cloud, les agents, les skills, MCP, RAG, le sandbox, le contrôle d'appareil, les statistiques, et un mode serveur LLM. Voir `README.md` pour la spécification complète, `TASKS.md` pour la checklist d'implémentation, et `PLATEFORMS.md` pour les différences par plateforme.

## Structure du dépôt
- `core/` — crate Rust `aura-core` (détection matérielle, catalogue de modèles, gestionnaire de moteurs, FFI). Sorties de build dans `core/dist/` et `core/target/...`.
- `flutter_app/` — UI Flutter. Point d'entrée `lib/main.dart`. Bindings natifs dans `lib/ffi_bindings.dart` / `ffi_native.dart` / `ffi_stub.dart`.
- `app/` — shell Electron (legacy, consomme `aura_node.node`).
- `Analyses/`, `Sources_inspiration/` — matériel de référence.

## Workflow de développement (Windows)
- Garder l'application Windows à l'écran en permanence pendant le développement.
- Lancer avec hot reload activé :
  ```
  cd flutter_app
  C:\Users\evolu\flutter\bin\flutter.bat run -d windows
  ```
- Après modification des fichiers Dart, appuyer sur `r` dans la console pour hot reload ou `R` pour hot restart afin de voir les changements immédiatement. Ne pas fermer la fenêtre ; la garder visible.
- La DLL native du cœur (`aura_core.dll`) doit être présente à côté de l'exécutable du runner (`build/windows/x64/runner/Debug/` ou `Release/`). La reconstruire avec :
  ```
  cd core
  cargo build --target x86_64-pc-windows-msvc --release -p aura-core
  ```
  puis copier `target/x86_64-pc-windows-msvc/release/aura_core.dll` dans le répertoire du runner Flutter.
- Lancer `flutter analyze` avant de committer ; zéro erreur requis.

## Architecture
- UI : Flutter + Material 3. L'état est géré dans des `StatefulWidget` (`AuraApp`, `HomePage`).
- Cœur : Rust `aura-core` via `dart:ffi`. Fonctions : `auraVersion`, `auraCatalogJson`, `auraHardwareJson`, `auraStringFree`.
- Persistance : `shared_preferences` (multiplateforme) pour les paramètres (langue, thème, barre latérale, agent/fournisseur/modèle, paramètres de génération, dossier des modèles, catégorie de paramètres).
- Abstractions de plateforme : `desktop_service.dart` (import conditionnel), `ffi_bindings.dart` (import conditionnel).

## Conventions clés
- Pas de commentaires dans le code sauf demande explicite.
- Respecter le style existant (indentation 2 espaces, virgules trailing).
- Utiliser `const` quand possible ; éviter `const` avec des arguments non constants.
- Toutes les chaînes visibles par l'utilisateur passent par `_t(key)` avec les entrées dans `_translations`.
- Les paramètres sont persistés via `_savePrefs()` ; l'appeler après tout changement d'état qui doit survivre au redémarrage.
- La modale de paramètres utilise `StatefulBuilder` pour que la navigation de la barre latérale reconstruise le dialogue.

## Notes par plateforme
- Windows : `.dll` dans le répertoire du runner ; SmartScreen/AV peut bloquer les builds non signés.
- Android : `.so` par ABI ; permissions à l'exécution ; service de premier plan pour l'inférence.
- iOS/macOS : bibliothèques statiques (`.a`), Keychain, exception ATS loopback.
- Linux : `.so` dans le bundle ; AppImage/Flatpak.
- Web : mock `ffi_stub.dart` (pas de cœur natif).

## Tests
- `flutter analyze` (zéro erreur).
- `cargo test -p aura-core` (tests smoke du cœur).
- Manuel : lancer l'app Windows, vérifier la navigation de la barre latérale des paramètres, la persistance de la langue, la sélection du dossier des modèles locaux et le téléchargement.

## Règles
- Toute page/écran avec une liste de contenu long doit être rendue dans un `SingleChildScrollView` (ou `ListView`) pour éviter le "bottom overflowed".

## Statut actuel
- Navigation de la barre latérale de la modale de paramètres corrigée.
- Toutes les catégories de paramètres ont des pages.
- Modèles locaux : sélecteur de dossier + téléchargement simulé.
- Les paramètres persistent après redémarrage.
- La DLL native du cœur se charge avec succès sur Windows.