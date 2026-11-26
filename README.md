# AURA — Assistant Ultime pour LLM Locaux & Cloud

> **AURA** est une application multiplateforme (Android, iOS, Windows, Linux, macOS) écrite en **Flutter**, conçue comme le « couteau suisse » de l'IA générative : chat LLM **local + cloud**, **serveur LLM** (API), agents, orchestration, **skills & MCP**, **mémoire persistante**, RAG, sandbox d'exécution de code, contrôle d'appareil, statistiques et catalogue de modèles adaptatif au matériel.

> Ce document est une **spécification fonctionnelle et technique (v0 — ébauche)**. Il synthétise les meilleures pratiques observées dans 16 applications Android auditées (voir `Analyses/`).

---

## 1. Vision & objectifs

**Promesse :** une seule app, sur toutes les plateformes, qui fait **tout** ce que font les meilleures apps d'IA — et plus encore.

Objectifs piliers :
1. **Local-first** : inférence sur appareil (llama.cpp / LiteRT-LM / ONNX) avec confidentialité.
2. **Cloud-ready** : connexion aux providers (OpenAI, Anthropic, Google, Grok, Ollama…) comme RikkaHub.
3. **Multi-moteurs** : plusieurs moteurs d'inférence, **auto-sélection** selon modèle + matériel, avec **fallback** et **gestion RAM**.
4. **Agents & Skills** : agents avec **outils (tools)** et **compétences (skills) à la Claude**, **orchestrateur** qui délègue, **communication inter-agents**, **serveurs MCP manageables**, sandbox de code.
5. **Voix plein écran** : conversation **full voice** fluide (type Gemini/Grok) — ASR + LLM + TTS en continu, interruption, barge-in.
6. **Multimodal & génératif** : modèles locaux de **vision**, de **création d'images** (Flux, Nano Banana, SD…), d'**audio** (TTS/ASR/musique), et d'**embeddings** pour le RAG.
7. **RAG & documents** : bibliothèque de documents, **indexation embeddings**, recherche vectorielle, réponses augmentées, **ingestion web**.
8. **Serveur** : AURA peut aussi **servir** un modèle local via une **API OpenAI/Anthropic/Ollama** (+ WebUI/Swagger, RPC distribué).
9. **Mémoire & personas** : **mémoire persistante** inter-conversations et **personnalités** personnalisées.
10. **Expérience avancée** : **rendu riche** (Markdown, LaTeX/KaTeX, Mermaid, coloration), **chat templates**, **sortie structurée** (JSON/GBNF), LoRA.
11. **Contrôle** : ADB (Android) et équivalents multiplateformes, exécution de commandes, **actions système** (partage, texte sélectionné, overlay, tuile QS).
12. **Observabilité** : statistiques détaillées, moniteur RAM temps réel, **bug reporter type logcat**.
13. **Données** : base locale légère (historique, paramètres, conversations, agents, documents, mémoire).

**Non-objectifs (V0) :** marketplace, compte cloud obligatoire, monétisation agressive (AdMob). AURA privilégie la vie privée (/analytics désactivés par défaut, opt-in).

---

## 2. Plateformes cibles

| Plateforme | Framework UI | Inférence locale | Accélération |
|---|---|---|---|
| Android | Flutter (Impeller) | llama.cpp, LiteRT-LM, ONNX, sherpa-onnx, Whisper | CPU (armv8→v9.2), OpenCL/Vulkan, NNAPI/QNN (NPU), Hexagon |
| iOS / macOS | Flutter | llama.cpp, LiteRT-LM, ONNX | **Metal**, Core ML / ANE |
| Windows | Flutter | llama.cpp, ONNX, LiteRT (limité) | CUDA, **DirectML**, Vulkan, OpenCL |
| Linux | Flutter | llama.cpp, ONNX, LiteRT | CUDA, ROCm, Vulkan, OpenCL |

> Le moteur d'inférence n'est **pas** fourni par Flutter : chaque moteur est une lib native appelée via `dart:ffi` / *platform channels*. Voir §5.

---

## 3. Architecture générale (couches)

```
┌─────────────────────────────────────────────────────────────┐
│  UI Flutter (Material 3 / Compose-like)                      │
│  Chat · Catalogue · Agents · Statistiques · Paramètres · ... │
├─────────────────────────────────────────────────────────────┤
│  Couche domaine (Dart)                                       │
│  - InferenceEngine (abstraction) · ModelRegistry             │
│  - AgentOrchestrator · ToolRegistry · SandboxManager         │
│  - RamMonitor · LogCollector · StatsCollector                │
├─────────────────────────────────────────────────────────────┤
│  Couche plateforme (FFI / Platform Channels)                │
│  - moteurs natifs (llama.cpp, LiteRT, ONNX, sherpa, whisper) │
│  - DeviceController (ADB / équivalents) · Sandbox            │
│  - SystemInfo (specs, RAM, NPU, GPU)                        │
├─────────────────────────────────────────────────────────────┤
│  Persistance & réseau                                        │
│  - Drift/SQLite · téléchargements · providers cloud          │
└─────────────────────────────────────────────────────────────┘
```

**Principe clé :** un **sélecteur de moteur** au runtime choisit moteur + backend selon (modèle choisi × capacités matérielles), avec **fallback** si OOM RAM.

---

## 4. Modules fonctionnels

### 4.1 Chat LLM (local + cloud)
- Interface de chat (stream SSE/NDJSON), multi-conversations, historique.
- **Deux modes** : local (modèle embarqué/téléchargé) et cloud (provider distant).
- Support **multimodal** : texte, **vision** (images), **audio** (ASR Whisper), **TTS** (sherpa-onnx).
- **Mode voix plein écran (full voice)** : conversation fluide type Gemini/Grok — écoute continue, **barge-in** (interruption), transcription temps réel (ASR streaming), réponse TTS en cours, gestion du tour de parole, réduction de bruit/écho.
- *Inspirations :* RikkaHub (multi-providers), LM Playground (28 langues, Whisper), PocketPal (TTS neural), LocalMind (assistant vocal).

### 4.2 Catalogue de modèles adaptatif
- Liste de modèles locaux **filtrée selon les specs** détectées (RAM, NPU, GPU, ISA ARM, stockage).
- Ex. : si 8 Go RAM + NPU → modèles 7B Q4 recommandés ; si 4 Go → modèles 1–3B.
- **Catégories de modèles** :
  - **LLM / chat** : GGUF (llama.cpp), LiteRT `.litertlm`, `.onnx`.
  - **Vision** : MiniCPM-V, LLaVA, Florence, etc. (compréhension d'images).
  - **Génération d'images** : **Flux**, **Nano Banana** (Gemini image), **Stable Diffusion / SDXL** (via `libmyai_diffusion`-like).
  - **Audio** : TTS (sherpa-onnx, Piper), ASR (Whisper), éventuellement musique/SFX.
  - **Embeddings** : modèles d'embedding (bge, e5, MiniLM, `universal_sentence_encoder`) pour l'indexation RAG.
- Téléchargement **en arrière-plan** avec reprise (inspiré de `com.eko`, `background_downloader`).
- Modèles **cloud** : catalogue de providers (OpenAI, Anthropic, Google, Grok, Ollama, OpenClaw…), OAuth + clés API (stockage sécurisé).
- **Métadonnées** : type modalité, taille, RAM requise, quantisation, licence, source, compatibilité specs.

### 4.3 Moteurs d'inférence & auto-sélection (§5)
- llama.cpp, LiteRT-LM, ONNX Runtime, sherpa-onnx, Whisper, MiniCPM-V, diffusion (images).
- Auto-sélection + fallback cascade + gestion mémoire.

### 4.4 Agents & orchestration
- **Agent** = LLM + outils (tools) + compétences (skills) + permissions. Chaque agent a un rôle/prompt système.
- **Orchestrateur** : agent « chef » qui analyse la tâche et **délègue** aux agents spécialisés (selon leurs outils/skills).
- **Communication inter-agents** : bus de messages (A→B), partage de contexte, consensus, mode « réunion » multi-agents.
- **Outils (tools)** : recherche web, lecture/écriture fichiers, exécution code (sandbox), commandes appareil, RAG (interroger la base documentaire), MCP, skills.
- **Garde-fous** : confirmation des actions sensibles, refus anti-injection (inspiré de Neuron `agent_tainted_refusal`).
- *Inspirations :* RikkaHub (agents + MCP + skills), Edge Gallery (skills démo), Neuron (agent + confirmations).

### 4.5 Compétences (Skills) & serveurs MCP manageables
- **Skills à la Claude** : chaque skill = `SKILL.md` (description, déclencheurs, workflow) + scripts/ressources ; l'agent les charge et les exécute à la demande. Bibliothèque de skills embarquée (`assets/skills/`) + import utilisateur.
- **Skills intégrés** : recherche, génération de code, manipulation de fichiers, appels API, génération d'images, etc.
- **Serveurs MCP (Model Context Protocol)** : gestion complète — **ajouter/supprimer/activer/désactiver** des serveurs MCP, config (commande, args, env), statut (live/health), outils exposés. Un agent peut appeler les outils MCP comme des tools.
- **Registre** : liste des skills et MCP disponibles, activation par agent, permissions par skill.
- *Inspirations :* RikkaHub (MCP + skills `skill-creator`), Edge Gallery (skills HTML/JS).

### 4.6 Sandbox d'exécution de code
- Exécution de code JS/Python/scripts dans un environnement isolé.
- **Portable** : WASM (Wasmtime) pour JS ; natif par plateforme (Linux : bubblewrap/nsjail ; Windows : Windows Sandbox ; Android : zone isolée + WorkManager ; iOS : JS/WASM uniquement — pas de code natif arbitraire).
- *Inspiration :* RikkaHub (proot/Termux + QuickJS).

### 4.7 Contrôle d'appareil (ADB & équivalents)
- **Android** : accès ADB (app en tant que client ADB via *wireless debugging pairing*, ou **Shizuku** pour exécuter des commandes shell privilégiées sans root).
- **Desktop** (Windows/Linux/macOS) : embarquer `adb` pour contrôler un appareil Android connecté (USB/réseau).
- **iOS** : pas d'équivalent ADB pour contrôle arbitraire (restrictions Apple) — à défaut, intégration via App Intents/Shortcuts.
- Un agent peut envoyer des commandes (input, screenshot, lister paquets, etc.) via un outil dédié.

### 4.8 Statistiques
- Page dédiée : **tokens/seconde**, temps de 1er token, latence, RAM/VRAM utilisée, température/throttling, consommation.
- Stats par modèle/moteur/backend, historique, export.
- *Inspirations :* LM Playground, LLM Server, Loci.

### 4.9 Bibliothèque de documents & RAG
- **Bibliothèque** : import de documents (PDF, TXT, Markdown, DOCX, code…), classement par dossiers/tags, aperçu.
- **Indexation** : chunking + **embeddings** (modèle local) → **base vectorielle** locale (sqlite-vec, ObjectBox, ou Qdrant-lite).
- **Recherche** : recherche hybride (vectorielle + plein texte), citation des sources.
- **RAG** : réponses augmentées par le contexte des documents ; un agent peut interroger la base via un outil `rag_search`.
- Parsing : PDFBox (PDF), docx, markdown ; OCR via ML Kit-like pour documents scannés.
- *Inspirations :* AnythingLLM (vector + webscraper + PDFBox), Loci (PDF/Word), Local AI (sqlite_vec).

### 4.10 Services noyau
- **RamMonitor** : surveillance RAM temps réel ; décide de décharger/charger un moteur ; empêche de charger plusieurs moteurs si RAM insuffisante.
- **LogCollector / BugReporter** : collecte type **logcat** (logs applicatifs + natifs), capture de crashs, export de rapport, opt-in.
- **ModelDownloader** : téléchargements résumables, reprise, files d'attente.
- **DataStore local** : base légère (Drift/SQLite) pour paramètres, historique, agents, préférences, documents, mémoire.

### 4.11 Mode serveur LLM local (AURA as API)
- **Exposition d'API HTTP** compatible **OpenAI (`/v1/chat/completions`), Anthropic (`/v1/messages`) et Ollama** — streaming **SSE** / **NDJSON**.
- **Clé API** générée + **URL/IP locale** affichée ; guide d'intégration (curl, exemples Python).
- **WebUI / Swagger** embarquée pour tester l'API hors-ligne.
- **Endpoint embeddings** (`/v1/embeddings`) en plus du chat.
- **RPC / inférence distribuée** : répartir un modèle sur plusieurs appareils (`ggml-rpc`).
- Serveur en **avant-plan** + démarrage au boot + watchdog (persistance).
- *Inspirations :* LLM AI Server (OpenAI/Anthropic/Ollama + WebUI/Swagger), LLM Hoster (`llama-server` + RPC), LLM Server, LM Playground.

### 4.12 Mémoire persistante & personas
- **Mémoire long-terme** : faits, préférences, contexte utilisateur persistés **entre conversations** (service type « MemoryDream ») ; extraction automatique + éditable ; utilisable via un outil `memory_*` par les agents.
- **Recherche mémoire** : indexation (embeddings) pour rappeler le contexte pertinent.
- **Personas** : personnalités prédéfinies/personnalisées (ton, rôle, style), sélectionnables sans créer un agent complet.
- *Inspirations :* RikkaHub (MemoryDream), Offline AI (persona), Local AI (personas).

### 4.13 Expérience de chat avancée
- **Rendu riche** : Markdown, **LaTeX/KaTeX** (formules), **Mermaid** (diagrammes), coloration syntaxique, blocs de code copiables, citations de sources.
- **Chat templates (Jinja)** par modèle + **system prompts** par conversation/agent.
- **Paramètres de génération** : température, top_p, top_k, repeat_penalty, fenêtre de contexte, max tokens, seed.
- **Édition / régénération** de réponses, branches alternatives, favoris.
- *Inspirations :* RikkaHub (bettertext : Markdown/LaTeX/Mermaid), Offline AI (JLatexMath), LM Playground (templates Jinja), LocalMind (coloration).

### 4.14 Contrôle fin de l'inférence
- **Sortie structurée** : grammaire **GBNF** / **JSON schema** (constrained decoding) pour des réponses fiables (idéal agents/outils).
- **LoRA adapters** : chargement/déchargement d'adaptateurs pour personnaliser un modèle de base.
- **Speculative decoding** (accélération) quand un modèle « draft » est disponible.
- **Embeddings natifs** (génération de vecteurs pour le RAG, via moteur local).
- *Inspirations :* LLM AI Server (GBNF, LoRA, speculative, embeddings), LocalMind, RikkaHub.

### 4.15 Intégrations système & actions rapides
- **PROCESS_TEXT** : traiter du texte sélectionné dans n'importe quelle app.
- **Share target** : recevoir du texte/image depuis le menu de partage ; **partage sortant** (WhatsApp, Telegram, etc.).
- **Overlay flottant** et **tuile Quick Settings** pour invocation rapide.
- **App Functions / Shortcuts** : exposer AURA aux assistants système (Android 16+/iOS App Intents).
- **Widgets d'écran d'accueil** (résumé, raccourcis).
- **Notifications** locales (+ push optionnel).
- *Inspirations :* AnythingLLM (QuickContext/PROCESS_TEXT/partage), Neuron (tuile QS/overlay/VoiceInteraction), Loci (App Functions/shortcuts), LocalMind (widgets).

### 4.16 Outils intégrés & automatisations
- **Outils agents** : **calendrier** (lire/créer événements), **géolocalisation**, **recherche web**, **ingestion web (web scraper)** vers le RAG.
- **OCR avancé** : texte, **codes-barres/QR**, **détection de visage**, labels (vision).
- **Tâches planifiées / rappels** : prompts programmés, alarmes, exécution d'agents à heure fixe.
- *Inspirations :* AnythingLLM (webscraper, scheduledjobs, barcode), LocalMind/Loci (calendrier, géoloc), Loci (face/barcode).

### 4.17 Gestion, export & extras
- **Gestionnaire de stockage modèles** : quota, usage disque, suppression, quantisations disponibles, mise à jour.
- **Export / backup** des conversations, agents, paramètres et mémoire (et restauration).
- **Impression / export PDF** d'un chat.
- **Découverte LAN (mDNS)** des providers locaux (Ollama/OpenClaw/OpenCode).
- **Icônes alternatives / mode discret (« stealth »)**.
- **Support Android XR / lunettes** (vision proche de l'œil) — niche.
- **Fenêtres flottantes / multi-fenêtre** sur desktop.
- *Inspirations :* FreeLLMAPI (print), OneLLM (LAN providers), LlamaPal (icônes alternatives), Edge Gallery (XR), RikkaHub (fenêtres flottantes).

---

## 5. Moteurs d'inférence & auto-sélection

### 5.1 Moteurs embarqués (via FFI)
| Moteur | Rôle | Accélérateurs |
|---|---|---|
| **llama.cpp (ggml)** | LLM/embedding (GGUF) | CPU (armv8→v9.2, AVX), OpenCL, Vulkan, **Metal**, CUDA, RPC, Hexagon (forks) |
| **LiteRT-LM** | LLM (modèles Gemma/LiteRT) | CPU, GPU (OpenCL/Vulkan/Metal), NNAPI, Hexagon, Core ML/ANE |
| **ONNX Runtime** | Modèles `.onnx` | CPU (MLAS), CUDA, TensorRT, **DirectML**, Core ML, NNAPI, QNN, OpenVINO, ROCm |
| **sherpa-onnx** | TTS/ASR | via ONNX (CPU/NNAPI) |
| **Whisper** | Speech-to-text | CPU/GPU (selon build) |
| **MiniCPM-V** | Vision-language | ONNX/llama.cpp |
| **Diffusion (SD)** | Génération d'images | CPU/GPU |

### 5.2 Logique d'auto-sélection (pseudo)
```
détecter_specs() -> {RAM, NPU(Qualcomm/Google/MediaTek), GPU(Vulkan/Metal/DirectML/CUDA), ISA}
pour chaque modèle choisi:
    candidats = moteurs_supportant(modèle) triés par (accélération dispo, RAM requise)
    pour candidat dans candidats:
        si RAM_libre >= RAM_requise(candidat) et backend_dispo(candidat):
            charger(candidat) ; sortir
    fallback -> CPU (variante la plus légère)
```
- **Un seul moteur lourd à la fois** si RAM faible (priorité au modèle choisi). Libération explicite avant de charger un autre.
- **Fallback** : NPU indispo → GPU → CPU.

### 5.3 Isolation d'inférence
- Exécuter l'inférence dans un **process/isolate séparé** (inspiré de LM Playground `:llama`, Loci `:inference`) pour éviter les crashs UI et maîtriser la RAM.

---

## 6. Catalogue de modèles

- **Modèles locaux** : GGUF (llama.cpp), LiteRT `.litertlm`, `.onnx`. Filtrés par specs (§4.2).
- **Modèles cloud** : providers OpenAI-compatible (base_url + clé), Anthropic, Google, Grok, Ollama, etc. OAuth + clés via stockage sécurisé.
- **Métadonnées** : taille, RAM requise, quantisation, modalités supportées, licence, source (Hugging Face).
- **Intégrité** : vérification de hash à la fin du téléchargement (chaîne d'approvisionnement).

---

## 7. Sécurité & confidentialité

- **Traitement local par défaut** ; aucun analytics/ads par défaut (opt-in explicite).
- Clés API/cloud dans **keystore/keychain** (inspiré `expo-secure-store`).
- Modèles stockés localement ; chiffrement au repos **souhaitable** (SQLCipher).
- **Garde-fous agents** : confirmation d'actions sensibles, anti-injection, sandbox.
- `usesCleartextTraffic=false` par défaut (sauf exception loopback).
- Journalisation **locale** (LogCollector) avec export manuel — pas d'envoi automatique.

---

## 8. Stack technique Flutter recommandée

| Besoin | Choix |
|---|---|
| UI | Flutter + Material 3 |
| Base locale | **Drift** (SQLite typé) ou **Isar/ObjectBox** |
| FFI moteurs | `dart:ffi` + `ffigen`, plugins `llama_cpp_dart`, `tflite_flutter`, `onnxruntime` |
| Embeddings / RAG | sqlite-vec (vectoriel) + modèle d'embedding (bge/e5/MiniLM) via ONNX/llama.cpp |
| Documents | PDFBox (PDF), docx, markdown, OCR (ML Kit-like) |
| Téléchargements | `flutter_background_downloader` |
| Audio / Voix | `record`, sherpa-onnx (TTS), Whisper (ASR streaming), AEC/NS pour full voice |
| Vision / Images | MiniCPM-V (vision), Flux/Nano Banana/SD (diffusion) |
| Sandbox JS | `flutter_qjs` / Wasmtime (`wasmer`) |
| MCP | client MCP en Dart (stdio/HTTP) + registre manageable |
| Rendu riche | `flutter_markdown`, `flutter_katex`/`flutter_tex` (LaTeX), `flutter_mermaid` |
| Templates | moteur Jinja (portage) pour chat templates |
| Serveur API | `shelf` / `dart_frog` (HTTP) + SSE/NDJSON + Swagger |
| Mémoire | table dédiée (Drift) + embeddings (sqlite-vec) + outil `memory_*` |
| ADB Android | canal natif + Shizuku / wireless debugging |
| État | Riverpod / Bloc |
| DI | GetIt / Riverpod |

---

## 9. Plan d'action (phases)

### Phase 0 — Socle (MVP technique)
- [x] Squelette Flutter multiplateforme + navigation Material 3.
- [x] Détection specs (`SystemInfo` : RAM, CPU, GPU/NPU, OS).
- [x] Base Drift (paramètres, conversations).
- [x] Un moteur local : **llama.cpp via FFI** (chat texte) + **un provider cloud** (OpenAI).
- [x] Chat local + cloud avec streaming.
- [x] **Rendu Markdown + coloration + paramètres de génération** (temp, top_p, max tokens).
- [x] **Chat templates (Jinja)** de base + system prompts.
- [x] RamMonitor minimal + LogCollector.

### Phase 1 — Multi-moteurs & catalogue
- [x] Intégrer LiteRT-LM et ONNX Runtime.
- [x] Auto-sélection moteur + fallback + gestion RAM.
- [x] Catalogue de modèles filtrable par specs + téléchargements (LLM, vision, image, audio, embeddings).
- [x] ASR Whisper + TTS sherpa-onnx.
- [x] **Rendu riche avancé** : LaTeX/KaTeX + Mermaid.
- [x] Page Statistiques v1 (tok/s, RAM, latence).

### Phase 2 — Voix plein écran & multimodal
- [x] **Mode full voice** : ASR streaming + LLM + TTS continu, barge-in, gestion tour de parole.
- [x] Vision locale (MiniCPM-V / LLaVA) : compréhension d'images.
- [x] Génération d'images (Flux / Nano Banana / SD via diffusion).
- [x] Modèles audio avancés (TTS neural, éventuellement SFX).
- [x] **OCR avancé** : barcode/QR, détection de visage, labels.

### Phase 3 — Agents, Skills, MCP, RAG & mémoire
- [x] Système d'agents (rôles + outils + compétences).
- [x] **Orchestrateur** + communication inter-agents (+ mode réunion multi-agents).
- [x] **Skills à la Claude** (SKILL.md + scripts) + bibliothèque embarquée.
- [x] **Serveurs MCP manageables** (ajout/suppression/activation/statut/outils).
- [x] **RAG & bibliothèque de documents** : import, chunking, embeddings, indexation vectorielle, recherche, réponses augmentées (+ **ingestion web**).
- [x] **Mémoire persistante** (long-terme) + outil `memory_*`.
- [x] **Personas** (personnalités).
- [x] **Sortie structurée** (JSON/GBNF) + **LoRA** + speculative decoding.
- [x] Sandbox d'exécution (WASM + natif selon plateforme) + **terminal/shell**.
- [x] Outils : recherche web, calendrier, géolocalisation, fichiers, commandes appareil.
- [x] **Tâches planifiées / rappels**.

### Phase 4 — Contrôle appareil & intégrations système
- [x] ADB Android (Shizuku/wireless) + équivalents desktop.
- [x] **Actions système** : PROCESS_TEXT, share target, overlay, tuile QS.
- [x] **App Functions / Shortcuts** + **widgets d'écran d'accueil**.
- [x] **Notifications** locales (+ push optionnel).
- [x] Export de rapports bug, benchmark, dictée avancée.

### Phase 5 — Mode serveur & distribution
- [x] **Mode serveur LLM** : API OpenAI/Anthropic/Ollama + SSE/NDJSON + clé API/IP.
- [x] **WebUI/Swagger** embarquée + **endpoint embeddings**.
- [x] **RPC / inférence distribuée** (ggml-rpc).
- [x] **Gestionnaire de stockage modèles** + **export/backup** conversations/agents/mémoire.
- [x] **Découverte LAN (mDNS)** des providers locaux.

### Phase 6 — Finitions
- [x] Thèmes (dark/dynamic color), i18n (multi-langues), accessibilité.
- [x] Chiffrement au repos, hardening.
- [x] Impression/export PDF, icônes alternatives/stealth, fenêtres flottantes.
- [x] (Optionnel) Android XR / lunettes.
- [x] Tests multiplateformes (Android/iOS/Windows/Linux/macOS).

---

## 10. Options obligatoires vs optionnelles

**Obligatoires (MVP+) :**
- Chat local + cloud, streaming.
- llama.cpp (au moins) + auto-sélection/fallback.
- Détection specs + catalogue filtré (LLM, vision, image, audio, embeddings).
- Base locale (Drift) + historique.
- **Rendu Markdown + coloration + paramètres de génération.**
- **Chat templates (Jinja).**
- RamMonitor + LogCollector.
- Gestion RAM (pas de double moteur si RAM insuffisante).
- Stockage sécurisé des clés.

**Fortement recommandées :**
- LiteRT-LM + ONNX (multi-moteurs).
- **Mode full voice** (ASR streaming + TTS, barge-in).
- **Skills à la Claude** + **serveurs MCP manageables**.
- **RAG & bibliothèque de documents** (embeddings + vectoriel).
- **Mémoire persistante** + **personas**.
- **Sortie structurée (JSON/GBNF)** + **LoRA**.
- **Mode serveur LLM** (API OpenAI/Anthropic/Ollama).
- Agents + orchestrateur.
- Sandbox + terminal.
- Actions système (PROCESS_TEXT, share, overlay, tuile QS).
- Statistiques.
- ADB (Android).

**Optionnelles (V2+) :**
- Vision (MiniCPM-V) + génération d'images (Flux/Nano Banana/SD).
- Modèles audio avancés (musique/SFX) + OCR avancé (barcode/visage).
- **Speculative decoding** + **RPC / inférence distribuée**.
- **Tâches planifiées / rappels**, **ingestion web**.
- Widgets / App Functions / notifications.
- Export/backup + impression PDF + gestionnaire de stockage.
- Découverte LAN (mDNS).
- Icônes alternatives/stealth, fenêtres flottantes, Android XR.
- Contrôle appareil iOS (limité).
- Chiffrement au repos.

---

## 11. Risques & points d'attention

- **Complexité multi-moteurs** : chaque moteur = bindings natifs par plateforme ; maintenance lourde.
- **RAM** : moteurs lourds (onnxruntime ~25 Mo, LiteRtLm ~20 Mo, ggml-vulkan ~35 Mo) → APK volumineux ; charger plusieurs moteurs simultanément est risqué → d'où le RamMonitor.
- **Serveur API exposé** : authentification (clé API), limitation au loopback/LAN, TLS — éviter l'exposition publique non protégée.
- **Mémoire persistante** : données sensibles → chiffrement au repos + contrôle utilisateur (édition/suppression).
- **Sandbox / terminal** : exécution de code = surface d'attaque → isolation stricte, permissions, confirmation.
- **iOS** : pas d'ADB, pas de code natif arbitraire, sandbox limitée à JS/WASM, pas de proot.
- **Desktop GPU** : DirectML/CUDA/Vulkan matures mais hétérogènes ; tester build par build.
- **Dépendances Google/Firebase** : à éviter pour rester privacy-first.
- **Chaîne d'approvisionnement** : vérifier les modèles téléchargés (hash), sources (Hugging Face).
- **Scope creep** : énorme surface fonctionnelle → prioriser par phases (MVP d'abord).

---

## 12bis. Core natif portable (Rust) — implémenté

Le cœur d'inférence est un crate Rust (`core/`) **UI-agnostique**, consommable par FFI
(Flutter `dart:ffi`, Kotlin `cinterop`, Tauri, C/C++, **Node.js/Electron** via N-API).

- `aura-core` : détection matérielle, catalogue de modèles, `EngineManager` (RAM-aware, un seul moteur lourd), `MockEngine` + **`LlamaEngine`** (llama.cpp) + **`OnnxEngine`** (ONNX Runtime + tokenizer) + **LiteRtEngine** (stub) + **SherpaEngine** (stub).
- `aura-node` : binding N-API pour la team JS (Node/Electron).
- Features : `llama`, `onnx`, `litert`, `sherpa`, `full`. Build Windows OK, **5 tests smoke verts**, inférence réelle Llama 3.2 1B + all-MiniLM-L6-v2 (ONNX).

### 12ter. Shell applicatif (Electron) — `app/`

Shell **Electron + JS** consommant le core via `aura_node.node`:
- Chat local + cloud (7 providers: OpenAI, MiniMax, OpenRouter, Gemini, DeepSeek, xAI, MiMo)
- Multi-moteurs (llama.cpp + ONNX + LiteRT + sherpa stubs)
- Agents & Skills (CRUD + orchestrateur + MCP)
- Mémoire persistante + Personas + injection contexte
- Documents & RAG (import, chunking, indexation, recherche)
- Sandbox & Terminal, Contrôle appareil, Serveur LLM
- Statistiques (tok/s, TTFT, latence, RAM live)
- i18n 7 langues + RTL arabe + thème dark/light
- Design glassmorphism + icônes SVG
- Modale settings avec sidebar navigation
- 84 tâches implémentées (voir TASKS.md)

---

---

| Fonction AURA | Source(s) auditée(s) |
|---|---|
| Multi-providers cloud | RikkaHub |
| Agents + orchestrateur + MCP + skills | RikkaHub, Edge Gallery, Neuron |
| Garde-fous anti-injection | Neuron |
| Multi-moteurs (llama/LiteRT/ONNX) | LocalMind, LLM Server, Loci |
| NPU Qualcomm (QNN/Hexagon) | LocalMind, OneLLM, PocketPal |
| Isolation inférence (process) | LM Playground, Loci |
| TTS neural / ASR Whisper | PocketPal, LlamaPal, OneLLM, LM Playground |
| Mode full voice (barge-in) | LocalMind (assistant vocal), PocketPal (TTS+ASR) |
| Vision locale (images) / OCR / barcode | OneLLM (MiniCPM-V), Loci, PocketPal, AnythingLLM |
| Génération d'images (diffusion) | Offline AI (myai_diffusion) |
| Audio (TTS/ASR) | PocketPal, LlamaPal, OneLLM |
| Embeddings / RAG vectoriel | AnythingLLM (vector), Local AI (sqlite_vec) |
| Bibliothèque de documents | AnythingLLM (PDFBox), Loci (PDF/Word) |
| Compétences (skills) | Edge Gallery (skills), RikkaHub (skills) |
| Serveurs MCP manageables | RikkaHub (MCP) |
| **Mode serveur LLM (API)** | LLM AI Server, LLM Hoster, LLM Server, LM Playground |
| **Mémoire persistante** | RikkaHub (MemoryDream) |
| **Rendu riche (Markdown/LaTeX/Mermaid)** | RikkaHub (bettertext), Offline AI (JLatexMath) |
| **Chat templates (Jinja)** | LM Playground |
| **Sortie structurée (GBNF/JSON)** | LLM AI Server |
| **LoRA / speculative / RPC** | LLM AI Server, LLM Hoster |
| **Personas** | Offline AI, Local AI |
| **Actions système (PROCESS_TEXT/share/QS tile)** | AnythingLLM, Neuron |
| **App Functions / shortcuts / widgets** | Loci, Neuron, LocalMind |
| **Tâches planifiées / web scraper** | AnythingLLM (scheduledjobs, webscraper) |
| Téléchargements résumables | Local AI, Loci, LLM Server |
| Stats (tok/s, RAM) | LM Playground, LLM Server |
| Base locale (SQLite/Room) | AnythingLLM, PocketPal, LLM Server |
| Sandbox / terminal (proot/QuickJS) | RikkaHub |
| Contrôle appareil (ADB) | — (apport AURA) |

---

## 13. Prochaines étapes

1. Valider ce README (scope, priorités).
2. Décider du **MVP** (Phase 0) : plateforme(s) initiale(s) + 1 moteur local + 1 provider cloud.
3. Lancer le **socle Flutter** + détection specs.
4. Prototyper le **sélecteur de moteur** (llama.cpp FFI) sur Android d'abord.
5. Itérer par phases selon retours.

> AURA vise à être **le couteau suisse de l'IA** : local, cloud, agents, orchestration, sandbox, contrôle, statistiques — le tout dans une app Flutter multiplateforme respectueuse de la vie privée.