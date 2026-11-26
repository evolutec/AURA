# AURA — Liste de tâches d'implémentation

> Générée à partir de `README.md` (spec) + demandes UI/UX complémentaires.
> Statuts : `[ ]` à faire · `[~]` en cours · `[x]` fait.

## 0. Socle & core natif
- [x] Core Rust `aura-core` (détection HW, catalogue, EngineManager RAM-aware, MockEngine)
- [x] LlamaEngine (llama.cpp) — génération streamée + embeddings
- [x] OnnxEngine (ONNX Runtime) — embeddings multi-inputs
- [x] Binding N-API `aura-node` (Node/Electron)
- [x] ABI C stable (`include/aura_core.h`)
- [x] Tests smoke (5) verts en default + `--features full`
- [x] Shell Electron + JS (`app/`) consommant le core
- [x] Tokenizer réel pour ONNX (crate `tokenizers`) — embeddings sémantiques
- [x] LiteRT-LM backend (`engine/litert.rs`) — Gemma / `.litertlm`
- [x] sherpa-onnx backend (`engine/sherpa.rs`) — TTS/ASR
- [x] Événements RAM (callback/stream) pour moniteur UI temps réel
- [x] Persistance des sessions (métadonnées côté core)
- [x] Détection NPU/GPU fine via JNI (Android) / platform channels
- [x] Sélection avancée (scoring backend × RAM × modalité)
- [x] Chat templates (Jinja) et sortie structurée (GBNF)
- [x] LoRA adapters + speculative decoding
- [x] RPC / inférence distribuée (ggml-rpc)

## 1. Internationalisation (i18n)
- [x] Système i18n léger (JSON par langue + sélecteur)
- [x] Langues : 🇫🇷 Français, 🇬🇧 Anglais, 🇪🇸 Espagnol, 🇨🇳 Chinois, 🇸🇦 Arabe, 🇯🇵 Japonais, 🇮🇳 Hindi
- [x] Support RTL pour l'arabe
- [x] Persistance de la langue choisie (settings)
- [x] Traduction de toutes les chaînes UI (menus, boutons, messages système, erreurs)

## 2. Design & navigation (inspiration app Android classique)
- [x] Page générale **Chat** (écran principal)
- [x] **Sidebar dépliable/repliable** (animation) :
  - [x] Repliée : icônes uniquement (nouveau chat, recherche, paramètres)
  - [x] Dépliée : liste historique des conversations + section bas **Utilisateur** + bouton **Paramètres**
- [x] Header de chat : titre conversation + actions (renommer, supprimer, exporter)
- [x] Composer (champ prompt) avec :
  - [x] Sélecteur **Agent** (Code, Ask, …) comme Copilot VS Code
  - [x] Sélecteur **Provider** (local / cloud)
  - [x] Sélecteur **Modèle**
  - [x] Boutons : envoyer, voix, joindre fichier/image
- [x] Thème sombre par défaut + clair (toggle)
- [x] Responsive (desktop + tablette + mobile)
- [x] Logo AURA (`Aura-icon.jpg`) comme icône app + splash + avatar assistant

## 3. Pages dédiées
- [x] **Page Chat** (principale) — conversation active
- [x] **Page Gestion des modèles Cloud** (providers) :
  - [x] Liste des providers (OpenAI, Anthropic, Google, Grok, Ollama, OpenClaw, OpenCode, …)
  - [ ] Ajout/édition/suppression d'un provider (base_url, clé API, OAuth)
  - [x] Test de connexion, liste des modèles disponibles, activation
  - [ ] Stockage sécurisé des clés (keystore/keychain via core)
- [x] **Page Gestion des modèles locaux** (catalogue) :
  - [x] Catalogue filtré par specs matériel (RAM, NPU, GPU, ISA)
  - [x] Téléchargement en arrière-plan avec reprise
  - [x] Gestion stockage (quota, suppression, quantisations)
  - [x] Modèles par catégorie : LLM, Vision, Image, Audio, Embeddings
- [x] **Page Paramètres** :
  - [x] Langue, thème, moteur par défaut, headroom RAM
  - [x] Paramètres de génération (temp, top_p, top_k, max tokens, seed)
  - [ ] Confidentialité (analytics opt-in, chiffrement au repos)
  - [x] Export/backup conversations
- [x] **Page Statistiques** :
  - [ ] tok/s, temps 1er token, latence, RAM/VRAM, température
  - [x] Par modèle/moteur/backend, historique, export
- [x] **Page Agents & Skills** :
  - [x] Liste agents (rôles + outils + skills)
  - [x] Création/édition d'agent
  - [x] Bibliothèque de Skills (à la Claude) + import
  - [x] Serveurs MCP manageables (ajout/suppression/activation/statut/outils)
  - [x] Orchestrateur + communication inter-agents (mode réunion)
- [x] **Page Mémoire & Personas** :
  - [x] Mémoire persistante inter-conversations (faits/préférences, éditable)
  - [x] Personas personnalisées
- [x] **Page Documents & RAG** :
  - [x] Bibliothèque (import PDF/TXT/MD/DOCX/code)
  - [x] Indexation embeddings + recherche hybride
  - [x] Ingestion web (scraper)
- [x] **Page Sandbox / Terminal** :
  - [x] Exécution code (WASM + natif selon plateforme)
  - [x] Terminal/shell intégré
- [x] **Page Contrôle appareil** (ADB Android + équivalents)
- [x] **Page Mode serveur LLM** (API OpenAI/Anthropic/Ollama + WebUI/Swagger)

## 4. Fonctionnalités chat
- [x] Streaming des tokens (SSE/NDJSON) dans l'UI
- [x] Rendu riche : Markdown, LaTeX/KaTeX, Mermaid, coloration syntaxique
- [x] Chat templates (Jinja) par modèle + system prompts
- [x] Édition/régénération de réponses, branches alternatives, favoris
- [x] Multimodal : vision (images), audio (ASR Whisper), TTS (sherpa-onnx)
- [x] Mode **full voice** (ASR streaming + TTS continu, barge-in, tour de parole)
- [x] Génération d'images (Flux / Nano Banana / SD)
- [x] Sortie structurée (JSON/GBNF) pour agents
- [x] Mémoire de conversation (long-terme) injectée au contexte
- [x] Quick actions système : PROCESS_TEXT, share target, overlay, tuile QS, widgets
- [x] Notifications (locales + push optionnel)
- [x] Tâches planifiées / rappels / prompts programmés

## 5. Voix & audio
- [x] ASR streaming (Whisper) avec barge-in
- [x] TTS neural (sherpa-onnx / Piper) multilingue
- [x] Réduction de bruit / annulation d'écho pour full voice
- [x] Sélection de voix par langue

## 6. RAG & documents
- [x] Import documents (PDF/DOCX/MD/TXT/code)
- [x] Chunking + embeddings (modèle local via ONNX/llama.cpp)
- [x] Base vectorielle locale (sqlite-vec)
- [x] Recherche hybride (vectorielle + plein texte)
- [x] Citations de sources dans les réponses
- [x] Ingestion web (scraper) → RAG

## 7. Sécurité & confidentialité
- [x] Analytics/ads désactivés par défaut (opt-in)
- [x] Stockage sécurisé des clés (keystore/keychain)
- [x] Chiffrement au repos (SQLCipher) — optionnel
- [x] Garde-fous agents (confirmation actions sensibles, anti-injection)
- [x] Sandbox d'exécution de code (WASM + natif selon plateforme)
- [x] `usesCleartextTraffic=false` par défaut (sauf loopback)

## 8. Observabilité
- [x] Moniteur RAM temps réel (UI)
- [x] Bug reporter type logcat (collecte logs + crashs, export)
- [x] Page statistiques (tok/s, latence, RAM, historique, export)

## 9. Plateformes & distribution
- [x] Build Android (APK/AAB) avec Shizuku/ADB
- [x] Build iOS (limitations documentées : pas d'ADB, pas de code natif arbitraire)
- [x] Build Windows / Linux / macOS
- [x] Icône app = `Aura-icon.jpg` (toutes plateformes)
- [x] Splash screen + icônes adaptatives
- [x] (Optionnel) Android XR / lunettes
- [x] (Optionnel) Icônes alternatives / mode stealth
- [x] (Optionnel) Fenêtres flottantes (desktop)

## 10. Qualité
- [x] Tests unitaires core (Rust) — couverture moteurs
- [x] Tests d'intégration (chat end-to-end)
- [x] Tests UI (Electron) — Playwright
- [x] CI/CD multiplateforme
- [x] Documentation développeur (`core/README.md` à jour)

---

## Ordre de traitement recommandé (priorité)
1. **i18n + layout sidebar** (fondation UI)
2. **Composer avec sélecteurs agent/provider/modèle** (Copilot-like)
3. **Pages Cloud providers & Modèles locaux**
4. **Paramètres + Statistiques**
5. **Agents/Skills/MCP + Mémoire/Personas**
6. **Documents/RAG + Sandbox/Terminal**
7. **Voix full voice + multimodal**
8. **Mode serveur LLM + Contrôle appareil**
9. **Backends manquants (tokenizer, LiteRT, sherpa)**
10. **Plateformes mobiles + distribution**