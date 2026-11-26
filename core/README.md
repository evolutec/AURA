# AURA — Core natif portable (Rust)

Cœur **UI-agnostique** d'AURA : abstraction multi-moteurs, détection matérielle,
sélection de moteur **pilotée par la RAM**, catalogue de modèles, sessions de chat,
et **ABI C stable** consommable par Flutter, Kotlin Multiplatform, Tauri, C/C++ **et
Node.js/Electron** (ton équipe reste en JS).

## Pourquoi Rust
- Portatif (Android, iOS, Windows, Linux, macOS) avec cross-compilation native.
- FFI de première classe vers les moteurs C/C++ (llama.cpp, ONNX Runtime, LiteRT, sherpa).
- Sûr en mémoire (pas de UB), et exposable au JS via **N-API** (`napi-rs`).

## Structure
```
core/
  Cargo.toml                 workspace
  include/aura_core.h        header C stable (Flutter/KMP/C)
  crates/
    aura-core/               lib portable (cdylib + rlib)
      src/lib.rs
      src/error.rs           AuraError
      src/types.rs           EngineKind, Modality, Backend, ModelDescriptor, HardwareCaps, ...
      src/hardware.rs        détection matérielle (OS, arch, RAM, backends)
      src/ram.rs             RamMonitor temps réel + garde-fou RAM
      src/model.rs           ModelRegistry + catalogue + filtrage par specs
      src/engine/mod.rs      trait InferenceEngine + create_engine()
      src/engine/mock.rs     MockEngine (fonctionne sans dépendance native)
      src/engine/selector.rs EngineManager (1 seul moteur lourd, swap, RAM guard)
      src/engine/llama.rs    backend llama.cpp (feature `llama`, à câbler)
      src/session.rs         ChatSession
      src/ffi.rs             ABI C stable
      examples/demo.rs       démo CLI
    aura-node/               binding N-API (JS)
```

## Construire
```bash
cargo build -p aura-core            # lib + cdylib
cargo build -p aura-node            # binding Node (.node)
cargo run   -p aura-core --example demo
```

## Consommer

### Depuis Node.js / Electron (ton équipe JS)
```js
const aura = require('./aura_node.node')
console.log(aura.detectHardware())
const engine = aura.AuraEngine.create('aura-mock-1b')
console.log(engine.generate('Bonjour AURA'))
```
Build du `.node` recommandé via `@napi-rs/cli` (voir `crates/aura-node/package.json`),
ou copie du `aura_node.dll`/`libaura_node.so` renommé en `aura_node.node`.

### Depuis Flutter (dart:ffi)
```dart
final dylib = DynamicLibrary.open('libaura_core.so'); // ou .dll / .dylib
final hardwareJson = dylib
    .lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>('aura_hardware_json')();
// ... lire la chaîne, puis aura_string_free(ptr)
```

### Depuis C / C++ / Kotlin (cinterop)
```c
#include "aura_core.h"
char* hw = aura_hardware_json();
AuraEngine* e = aura_engine_create("aura-mock-1b");
char* out = aura_engine_generate(e, "Bonjour", NULL);
aura_string_free(out);
aura_engine_free(e);
aura_string_free(hw);
```

## API (ABI C)
- `aura_version`, `aura_string_free`, `aura_last_error`
- `aura_hardware_json`, `aura_catalog_json`, `aura_catalog_compatible_json`
- `aura_engine_create`, `aura_engine_generate`, `aura_engine_generate_stream`,
  `aura_engine_embed`, `aura_engine_loaded_model`, `aura_engine_unload`, `aura_engine_free`
- `aura_session_create`, `aura_session_send`, `aura_session_messages_json`, `aura_session_free`

## Règles clés implémentées
- **Un seul moteur lourd à la fois** : `EngineManager` décharge l'ancien avant de charger le nouveau.
- **Garde-fou RAM** : refus de chargement si `RAM dispo < RAM requise + headroom` (512 Mo par défaut).
- **Streaming** : tokens poussés via callback (`on_token` / `AuraTokenCb`).
- **Fallback** : `EngineKind` non supporté → `AuraError::Unsupported` (l'UI peut basculer).

## Cross-compilation (cibles)
| Plateforme | Target |
|---|---|
| Android | `aarch64-linux-android` (+ NDK) |
| iOS | `aarch64-apple-ios` |
| Windows | `x86_64-pc-windows-msvc` |
| Linux | `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu` |
| macOS | `aarch64-apple-darwin`, `x86_64-apple-darwin` |

## État actuel
- ✅ **llama.cpp câblé** : `engine/llama.rs` (feature `llama`) — génération streamée + embeddings. Validé sur Windows avec Llama 3.2 1B.
- ✅ **ONNX Runtime câblé** : `engine/onnx.rs` (feature `onnx`) — embeddings (inputs multiples : input_ids / attention_mask / token_type_ids). Validé avec all-MiniLM-L6-v2.
- ✅ MockEngine pour développer/tester sans dépendance native.
- ✅ Sélection de moteur pilotée par la RAM (`EngineManager`).
- ✅ Catalogue de modèles filtré par specs.
- ✅ Détection matérielle.
- ✅ ABI C stable + binding Node.js (N-API).
- ✅ 5 tests smoke verts (default + `--features full`).

## Roadmap du core
1. **Tokenizer réel** pour ONNX (crate `tokenizers`) — embeddings sémantiquement corrects.
2. **LiteRT-LM** (`engine/litert.rs`) : Gemma / `.litertlm`.
3. **sherpa-onnx** (`engine/sherpa.rs`) : TTS/ASR.
4. **Événements RAM** : callback/stream pour l'UI (moniteur temps réel).
5. **Persistance des sessions** (métadonnées côté core).
6. **Détection NPU/GPU fine** via JNI (Android) / platform channels.
7. **Sélection avancée** : scoring par backend disponible × RAM × modalité.
8. **Chat templates (Jinja)** et sortie structurée (GBNF).

> Le `MockEngine` permet de développer toute la chaîne (sélection, RAM, sessions, FFI,
> UI) **avant** de brancher les moteurs réels.
