import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'extension_item.dart';

/// Persistance et catalogue des extensions (skills, outils, MCP).
class ExtensionStore {
  static const String _prefsKey = 'extensions';

  /// Outils de base proposés par défaut à l'installation.
  static List<ExtensionItem> defaultTools() => [
        ExtensionItem(
          id: 'tool_web_search',
          name: 'Recherche web',
          description:
              'Recherche des informations en temps réel sur le web (DuckDuckGo) '
              'et renvoie les résultats. À utiliser pour toute question d\'actualité '
              'ou nécessitant une source externe (ex: Wikipédia).',
          kind: ExtensionKind.tool,
          icon: 'search',
          config: {'provider': 'duckduckgo', 'max_results': '5'},
        ),
        ExtensionItem(
          id: 'tool_terminal',
          name: 'Terminal PC',
          description:
              'Exécute RÉELLEMENT une commande dans le terminal du PC '
              '(Windows cmd / PowerShell / shell) et renvoie la sortie. '
              'Utilise-le pour ipconfig, dir, git, ping, systeminfo, etc. '
              'Args: {"command":"<commande>"}.',
          kind: ExtensionKind.tool,
          icon: 'terminal',
          config: {'timeout_s': '60'},
        ),
        ExtensionItem(
          id: 'tool_sandbox_exec',
          name: 'Exécution sandbox',
          description:
              'Exécute du code isolé (Python/JS) dans le sandbox Aura pour les calculs et scripts.',
          kind: ExtensionKind.tool,
          icon: 'terminal',
          config: {'runtime': 'python', 'timeout_s': '30'},
        ),
        ExtensionItem(
          id: 'tool_adb_wifi',
          name: 'Contrôle smartphone (ADB Wi-Fi)',
          description:
              'Pilote un appareil Android via ADB over Wi-Fi (adb connect ip:port) : '
              'installer des APK, envoyer des commandes shell, captures. '
              'Alternative PC : contrôler le PC via un agent local (HTTP/CLI) plutôt qu\'ADB.',
          kind: ExtensionKind.tool,
          icon: 'phone_android',
          config: {'host': '127.0.0.1', 'port': '5555'},
        ),
        ExtensionItem(
          id: 'tool_clipboard',
          name: 'Presse-papier',
          description:
              'Lit ou écrit le presse-papier du système. '
              'Args: {"action":"read"} ou {"action":"write","text":"..."}.',
          kind: ExtensionKind.tool,
          icon: 'content_copy',
          config: {},
        ),
        ExtensionItem(
          id: 'tool_process',
          name: 'Processus',
          description:
              'Liste ou tue des processus du système. '
              'Args: {"action":"list","filter":"chrome"} ou '
              '{"action":"kill","pid":1234} / {"action":"kill","name":"app.exe"}.',
          kind: ExtensionKind.tool,
          icon: 'memory',
          config: {},
        ),
        ExtensionItem(
          id: 'tool_fs_list',
          name: 'Lister un dossier',
          description:
              'Liste le contenu d\'un dossier (fichiers + dossiers, tailles). '
              'Args: {"path":"C:/Users","ext":"gguf"}.',
          kind: ExtensionKind.tool,
          icon: 'folder',
          config: {},
        ),
        ExtensionItem(
          id: 'tool_browser',
          name: 'Ouvrir le navigateur',
          description:
              'Ouvre une URL dans un navigateur Chromium embarqué (CEF) affiché '
              'dans la conversation et le dock. Args: {"url":"https://..."}.',
          kind: ExtensionKind.tool,
          icon: 'public',
          config: {},
        ),
        ExtensionItem(
          id: 'tool_browser_playwright',
          name: 'Playwright Browser',
          description:
              'Pilote un navigateur Chromium via Playwright (CDP) avec actions '
              'régies : navigate, click, fill, screenshot, evaluate, waitFor. '
              'Args: {"action":"navigate","url":"https://..."} ou {"action":"click","selector":"..."}.',
          kind: ExtensionKind.tool,
          icon: 'public',
          config: {},
        ),
      ];

  static Future<List<ExtensionItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final defaults = defaultTools();
      await save(defaults);
      return defaults;
    }
      try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ExtensionItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // Supprime les anciens outils navigateur disparus : seul tool_browser
      // doit rester visible (tous les handlers navigateur passent par celui-ci).
      final legacyBrowser = {
        'tool_browser_navigate',
        'tool_browser_back',
        'tool_browser_forward',
        'tool_browser_reload',
        'tool_browser_click',
        'tool_browser_eval',
      };
      final kept = list.where((e) => !legacyBrowser.contains(e.id)).toList();
      var changed = kept.length != list.length;
      list.clear();
      list.addAll(kept);
      final existing = list.map((e) => e.id).toSet();
      for (final def in defaultTools()) {
        if (existing.contains(def.id)) continue;
        list.add(def);
        changed = true;
      }
      if (changed) await save(list);
      return list;
    } catch (_) {
      final defaults = defaultTools();
      await save(defaults);
      return defaults;
    }
  }

  static Future<void> save(List<ExtensionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }
}