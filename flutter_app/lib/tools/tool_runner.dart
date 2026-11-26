import 'dart:convert';
import 'dart:io';

import '../Parametres/Extensions/extension_item.dart';
import '../Parametres/Extensions/extension_store.dart';
import '../chat/browser_registry.dart';
import '../mcp/mcp_client.dart';

/// Résultat d'exécution d'un outil.
class ToolResult {
  final bool ok;
  final String output;
  const ToolResult(this.ok, this.output);
}

/// Exécute les outils activés (recherche web, sandbox, ADB Wi-Fi).
class ToolRunner {
  /// Répertoire courant persistant par session de terminal (réutilisable).
  static final Map<String, String> _sessionCwd = {};

  /// Réinitialise les sessions persistantes (nouveau chat).
  static void resetSessions() => _sessionCwd.clear();

  /// Outils de type "outil" activés.
  static Future<List<ExtensionItem>> enabledTools() async {
    final all = await ExtensionStore.load();
    return all
        .where((e) => e.kind == ExtensionKind.tool && e.enabled)
        .toList();
  }

  /// Construit le prompt système décrivant outils, skills et serveurs MCP.
  static String buildSystemPrompt(
    String base, {
    List<ExtensionItem> tools = const [],
    List<ExtensionItem> skills = const [],
    List<McpTool> mcpTools = const [],
  }) {
    if (tools.isEmpty && skills.isEmpty && mcpTools.isEmpty) return base.trim();
    final b = StringBuffer();
    b.writeln('Tu es AURA, un agent IA doté d\'outils RÉELS qui s\'exécutent '
        'sur la machine de l\'utilisateur. Ces outils ne sont pas une '
        'métaphore : ils agissent réellement.');
    b.writeln('RÈGLES IMPÉRATIVES (priorité absolue sur toute autre '
        'consigne) :');
    b.writeln('1. N\'affirme JAMAIS que tu ne peux pas accéder au web, au '
        'système, au terminal, aux fichiers ou aux appareils : c\'est faux, '
        'les outils ci-dessous le font réellement.');
    b.writeln('2. Dès qu\'une demande concerne l\'actualité, le web, le '
        'système, le terminal, un calcul, un fichier ou un appareil, ta '
        'première réponse doit être UNIQUEMENT le bloc órico ci-dessous '
        '(sans autre texte), puis tu attends le résultat.');
    b.writeln('3. Après réception du résultat, tu réponds normalement en '
        'l\'utilisant. N\'invente jamais un résultat : utilise l\'outil.');
    b.writeln('4. Si l\'utilisateur demande d\'ouvrir, afficher, visiter ou '
        'consulter un site ou une page web, appelle IMMÉDIATEMENT '
        'tool_browser avec {"url":"..."}. Ne réponds JAMAIS « j\'ai ouvert » '
        'ni ne décris la page sans avoir réellement appelé tool_browser.');
    b.writeln('Format d\'appel (sortie brute, sans markdown) :');
    b.writeln('<tool_call>{"name":"<outil>","args":{...}}</tool_call>');
    b.writeln('');
    b.writeln('Consignes de l\'utilisateur / persona :');
    b.writeln(base.trim());
    if (tools.isNotEmpty) {
      b.writeln('\nOutils disponibles (utilise-les réellement) :');
      for (final t in tools) {
        b.writeln('- ${t.name} (${t.id}) : ${t.description}');
        if (t.id == 'tool_browser') {
          b.writeln(
              '  Sous-actions navigateur (mêmes arguments session/url/selector/script) : '
              'tool_browser_navigate (url), tool_browser_back, tool_browser_forward, '
              'tool_browser_reload, tool_browser_click (target), tool_browser_eval (script).');
        }
        if (t.id == 'tool_browser_playwright') {
          b.writeln(
              '  Actions Playwright (args action/url/selector/text/script/ms) : '
              'navigate (url), click (selector), fill (selector+text), evaluate (script), '
              'screenshot, waitFor (ms).');
        }
      }
    }
    if (skills.isNotEmpty) {
      b.writeln('\nSkills disponibles (connaissances/instructions) :');
      for (final s in skills) {
        b.writeln('- ${s.name} : ${s.description}');
        final md = s.config['skill_md'];
        if (md != null && md.isNotEmpty) {
          b.writeln('  Instructions: ${md.length > 800 ? md.substring(0, 800) + '…' : md}');
        }
      }
    }
    if (mcpTools.isNotEmpty) {
      b.writeln('\nOutils MCP disponibles :');
      for (final t in mcpTools) {
        b.writeln('- ${t.name} : ${t.description}');
      }
    }
    return b.toString();
  }

  /// Préfixe le nom d'un outil MCP pour identifier son serveur.
  static String mcpName(String serverId, String tool) =>
      'mcp__${serverId}__$tool';

  /// Décompose un nom d'outil MCP préfixé.
  static ({String serverId, String tool})? parseMcpName(String name) {
    if (!name.startsWith('mcp__')) return null;
    final rest = name.substring(5);
    final sep = rest.indexOf('__');
    if (sep < 0) return null;
    return (serverId: rest.substring(0, sep), tool: rest.substring(sep + 2));
  }

  /// Détecte un appel d'outil dans la sortie du modèle.
  static ({String name, Map<String, String> args})? extractToolCall(
    String text,
  ) {
    final patterns = [
      RegExp(r'<tool_call>\s*(\{.*?\})\s*</tool_call>', dotAll: true),
      RegExp(r'```tool\s*(\{.*?\})\s*```', dotAll: true),
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m == null) continue;
      try {
        final j = jsonDecode(m.group(1)!) as Map<String, dynamic>;
        final name = j['name']?.toString();
        if (name == null || name.isEmpty) continue;
        final args = (j['args'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            ) ??
            <String, String>{};
        return (name: name, args: args);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Récupère la requête de recherche en acceptant plusieurs clés/valeurs
  /// (`query`, `queries`, `q`, `search`), y compris les listes JSON.
  static String _queryArg(Map<String, String> args) {
    for (final k in ['query', 'queries', 'q', 'search', 'term']) {
      final v = args[k];
      if (v == null || v.trim().isEmpty) continue;
      var s = v.trim();
      if (s.startsWith('[') && s.endsWith(']')) {
        s = s.substring(1, s.length - 1);
      }
      s = s.replaceAll('"', '').replaceAll("'", '').trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  /// Exécute un outil par son id.
  static Future<ToolResult> execute(
    String toolId,
    Map<String, String> args,
  ) async {
    switch (toolId) {
      case 'tool_web_search':
        return _webSearch(_queryArg(args));
      case 'tool_browser':
        return _browserOpen(args['url'] ?? '', args['session'] ?? '');
      case 'tool_browser_navigate':
        return _browserNavigate(args['url'] ?? '', args['session'] ?? '');
      case 'tool_browser_back':
      case 'tool_browser_forward':
        return _browserGo(args, back: toolId == 'tool_browser_back');
      case 'tool_browser_reload':
        return _browserReload(args['session'] ?? '');
      case 'tool_browser_eval':
        return _browserEval(args['script'] ?? args['js'] ?? '', args['session'] ?? '');
      case 'tool_browser_click':
        return _browserClick(args['text'] ?? args['selector'] ?? '', args['session'] ?? '');
      case 'tool_browser_playwright':
        return _browserPlaywright(args, args['session'] ?? '');
      case 'tool_sandbox_exec':
      case 'tool_python':
        return _sandboxExec(
          args['code'] ?? '',
          runtime: args['runtime'] ?? 'python',
          timeoutS: int.tryParse(args['timeout_s'] ?? '') ?? 30,
        );
      case 'tool_bash':
      case 'tool_terminal':
      case 'tool_shell':
        return _shell(
          args['command'] ?? args['cmd'] ?? args['q'] ?? '',
          session: args['session'],
        );
      case 'tool_adb_wifi':
        return _adbWifi(
          host: args['host'] ?? '127.0.0.1',
          port: args['port'] ?? '5555',
          command: args['command'] ?? 'echo ok',
        );
      case 'tool_fetch_url':
        return _fetchUrl(args['url'] ?? '');
      case 'tool_http_request':
      case 'tool_http_client':
        return _httpRequest(
          url: args['url'] ?? '',
          method: (args['method'] ?? 'GET').toUpperCase(),
          body: args['body'],
        );
      case 'tool_calculator':
        return _calculator(args['expression'] ?? '');
      case 'tool_datetime':
        return _dateTime(args['timezone'] ?? 'UTC');
      case 'tool_file_read':
      case 'tool_file_reader':
        return _fileRead(args['path'] ?? '');
      case 'tool_file_writer':
        return _fileWrite(args['path'] ?? '', args['content'] ?? '');
      case 'tool_sql_query':
        return _sql(args['database'] ?? '', args['query'] ?? '');
      case 'tool_git':
        return _shell('git ${args['args'] ?? ''}');
      case 'tool_docker':
        return _shell('docker ${args['args'] ?? ''}');
      case 'tool_ocr':
        return _binaryTool('tesseract', ['stdin', 'stdout'], args['image'] ?? '');
      case 'tool_stt':
        return _binaryTool('whisper', ['--no-timestamps'], args['audio'] ?? '');
      case 'tool_tts':
        return _tts(args['text'] ?? '');
      case 'tool_image_gen':
        return const ToolResult(
            false, 'Génération d\'image : service externe à configurer.');
      case 'tool_clipboard':
        return _clipboard(args['action'] ?? args['op'] ?? 'read',
            args['text'] ?? args['content'] ?? '');
      case 'tool_process':
        return _process(args['action'] ?? 'list', args);
      case 'tool_fs_list':
        return _fsList(args['path'] ?? '.', args['ext'] ?? '');
      default:
        return ToolResult(false, 'Outil inconnu: $toolId');
    }
  }

  static Future<ToolResult> _webSearch(String query) async {
    if (query.trim().isEmpty) {
      return const ToolResult(false, 'Requête vide');
    }
    final results = <String>[];
    final wiki = await _wikiSummary(query);
    if (wiki != null) results.add(wiki);
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://html.duckduckgo.com/html/?q=${Uri.encodeQueryComponent(query)}',
      );
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      req.headers.set('User-Agent', 'Aura/1.0');
      final res = await req.close().timeout(const Duration(seconds: 20));
      final html = await res.transform(utf8.decoder).join();
      if (res.statusCode == 200) {
        final linkRe = RegExp(
          r'<a[^>]*class="result__a"[^>]*>(.*?)</a>',
          dotAll: true,
        );
        final snipRe = RegExp(
          r'<a[^>]*class="result__snippet"[^>]*>(.*?)</a>',
          dotAll: true,
        );
        String clean(String s) => s
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&', '&')
            .replaceAll('"', '"')
            .replaceAll('&x27;', "'")
            .replaceAll('<', '<')
            .replaceAll('>', '>')
            .trim();
        final links = linkRe.allMatches(html).toList();
        final snips = snipRe.allMatches(html).toList();
        for (var i = 0; i < links.length && i < 5; i++) {
          final title = clean(links[i].group(1) ?? '');
          final snip = i < snips.length ? clean(snips[i].group(1) ?? '') : '';
          results.add('${i + 1}. $title\n   $snip');
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    if (results.isEmpty) {
      return const ToolResult(true, 'Aucun résultat.');
    }
    return ToolResult(true, results.join('\n\n'));
  }

  /// Récupère un résumé depuis l'API REST Wikipédia (fr puis en).
  static Future<String?> _wikiSummary(String query) async {
    final q = query
        .replaceAll(RegExp(r'wikip[ée]dia', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'recherche|cherche|sur|about|summary|résumé|resume',
                caseSensitive: false),
            '')
        .trim();
    if (q.isEmpty) return null;
    final client = HttpClient();
    try {
      for (final lang in ['fr', 'en']) {
        final uri = Uri.parse(
          'https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(q)}',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 12));
        req.headers.set('User-Agent', 'Aura/1.0');
        final res = await req.close().timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) continue;
        final body = await res.transform(utf8.decoder).join();
        final j = jsonDecode(body) as Map<String, dynamic>;
        final extract = j['extract']?.toString() ?? '';
        if (extract.isNotEmpty) {
          final title = j['title']?.toString() ?? q;
          return 'Wikipédia ($lang) — $title : $extract';
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return null;
  }

  static Future<ToolResult> _sandboxExec(
    String code, {
    required String runtime,
    required int timeoutS,
  }) async {
    if (code.trim().isEmpty) return const ToolResult(false, 'Code vide');
    final isJs = runtime == 'js' || runtime == 'javascript';
    final ext = isJs ? 'js' : 'py';
    final tmpDir = Directory.systemTemp;
    final file = File(
      '${tmpDir.path}${Platform.pathSeparator}aura_sandbox_${DateTime.now().microsecondsSinceEpoch}.$ext',
    );
    try {
      await file.writeAsString(code);
      final candidates = isJs
          ? <List<String>>[
              ['node', file.path],
            ]
          : <List<String>>[
              ['py', '-3', file.path],
              ['python', file.path],
              ['python3', file.path],
            ];
      Object? lastErr;
      for (final c in candidates) {
        try {
          final exe = c.first;
          final cArgs = c.sublist(1);
          final proc = await Process.start(
            exe,
            cArgs,
            runInShell: true,
          ).timeout(const Duration(seconds: 5));
          final out = StringBuffer();
          final err = StringBuffer();
          proc.stdout.transform(utf8.decoder).listen(out.write);
          proc.stderr.transform(utf8.decoder).listen(err.write);
          final codeExit = await proc.exitCode.timeout(
            Duration(seconds: timeoutS),
          );
          final text = out.toString().trim();
          final e = err.toString().trim();
          if (codeExit == 0) {
            return ToolResult(true, text.isEmpty ? '(aucune sortie)' : text);
          }
          return ToolResult(false, e.isEmpty ? 'exit $codeExit' : e);
        } catch (e) {
          lastErr = e;
          continue;
        }
      }
      final missing = isJs ? 'Node.js (node)' : 'Python (py/python)';
      return ToolResult(
        false,
        '$missing introuvable ou échec: ${lastErr ?? 'exécutable absent'}',
      );
    } catch (e) {
      return ToolResult(false, 'Échec sandbox: $e');
    } finally {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  static Future<ToolResult> _adbWifi({
    required String host,
    required String port,
    required String command,
  }) async {
    try {
      final connect = await Process.run(
        'adb',
        ['connect', '$host:$port'],
        runInShell: true,
      ).timeout(const Duration(seconds: 20));
      final connectOut = (connect.stdout + connect.stderr).toString().trim();
      if (connect.exitCode != 0) {
        return ToolResult(false, 'adb connect: $connectOut');
      }
      final shell = await Process.run(
        'adb',
        ['-s', '$host:$port', 'shell', command],
        runInShell: true,
      ).timeout(const Duration(seconds: 30));
      final out = shell.stdout.toString().trim();
      final err = shell.stderr.toString().trim();
      if (shell.exitCode == 0) {
        return ToolResult(true, out.isEmpty ? '(ok)' : out);
      }
      return ToolResult(false, err.isEmpty ? 'exit ${shell.exitCode}' : err);
    } catch (e) {
      return ToolResult(false, 'ADB indisponible: $e');
    }
  }

  static Future<ToolResult> _fetchUrl(String url) async {
    if (url.trim().isEmpty) return const ToolResult(false, 'URL vide');
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      req.headers.set('User-Agent', 'Aura/1.0');
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        return ToolResult(false, 'HTTP ${res.statusCode}');
      }
      final text = body.length > 4000 ? body.substring(0, 4000) + '…' : body;
      return ToolResult(true, text);
    } catch (e) {
      return ToolResult(false, 'Erreur: $e');
    } finally {
      client.close();
    }
  }

  static Future<ToolResult> _httpRequest({
    required String url,
    required String method,
    String? body,
  }) async {
    if (url.trim().isEmpty) return const ToolResult(false, 'URL vide');
    final client = HttpClient();
    try {
      final req = method == 'POST'
          ? (await client.postUrl(Uri.parse(url)))
          : await client.getUrl(Uri.parse(url));
      req.headers.contentType = ContentType.json;
      if (body != null) req.write(body);
      final res = await req.close().timeout(const Duration(seconds: 20));
      final text = await res.transform(utf8.decoder).join();
      final out = text.length > 4000 ? text.substring(0, 4000) + '…' : text;
      return ToolResult(res.statusCode >= 200 && res.statusCode < 300,
          'HTTP ${res.statusCode}\n$out');
    } catch (e) {
      return ToolResult(false, 'Erreur: $e');
    } finally {
      client.close();
    }
  }

  static Future<ToolResult> _calculator(String expression) =>
      Future.value(_evalArith(expression));

  static ToolResult _evalArith(String src) {
    final tokens = RegExp(r'\d+\.?\d*|[+\-*/()]')
        .allMatches(src.replaceAll(' ', ''))
        .map((m) => m.group(0)!)
        .toList();
    var pos = 0;
    late double Function() parseExpr;
    double parseFactor() {
      final t = tokens[pos++];
      if (t == '(') {
        final v = parseExpr();
        if (tokens[pos++] != ')') throw const FormatException();
        return v;
      }
      if (t == '-') return -parseFactor();
      return double.parse(t);
    }

    double parseTerm() {
      var v = parseFactor();
      while (pos < tokens.length &&
          (tokens[pos] == '*' || tokens[pos] == '/')) {
        final op = tokens[pos++];
        final r = parseFactor();
        v = op == '*' ? v * r : v / r;
      }
      return v;
    }

    parseExpr = () {
      var v = parseTerm();
      while (pos < tokens.length &&
          (tokens[pos] == '+' || tokens[pos] == '-')) {
        final op = tokens[pos++];
        final r = parseTerm();
        v = op == '+' ? v + r : v - r;
      }
      return v;
    };

    try {
      final v = parseExpr();
      if (pos != tokens.length) return const ToolResult(false, 'Expression invalide');
      return ToolResult(true, v.toString());
    } catch (_) {
      return const ToolResult(false, 'Expression invalide');
    }
  }

  static Future<ToolResult> _dateTime(String tz) async {
    final now = DateTime.now();
    final offset = switch (tz.toUpperCase()) {
      'UTC' => 'Z',
      'PARIS' || 'CET' => '+01:00',
      'NEW_YORK' || 'EST' => '-05:00',
      'TOKYO' => '+09:00',
      _ => 'local',
    };
    return ToolResult(true, '${now.toIso8601String()} ($offset)');
  }

  static Future<ToolResult> _fileRead(String path) async {
    if (path.trim().isEmpty) return const ToolResult(false, 'Chemin vide');
    try {
      final f = File(path);
      if (!f.existsSync()) return ToolResult(false, 'Introuvable: $path');
      final text = await f.readAsString();
      return ToolResult(
          true, text.length > 4000 ? text.substring(0, 4000) + '…' : text);
    } catch (e) {
      return ToolResult(false, 'Erreur: $e');
    }
  }

  static Future<ToolResult> _fileWrite(String path, String content) async {
    if (path.trim().isEmpty) return const ToolResult(false, 'Chemin vide');
    try {
      final f = File(path);
      await f.writeAsString(content);
      return ToolResult(true, 'Écrit ${content.length} caractères dans $path');
    } catch (e) {
      return ToolResult(false, 'Erreur: $e');
    }
  }

  static Future<ToolResult> _shell(String command, {String? session}) async {
    if (command.trim().isEmpty) return const ToolResult(false, 'Commande vide');
    final key = (session == null || session.trim().isEmpty)
        ? 'fresh_${DateTime.now().microsecondsSinceEpoch}'
        : session.trim();
    final startCwd = _sessionCwd[key];
    try {
      String full;
      if (Platform.isWindows) {
        final sb = StringBuffer();
        if (startCwd != null && startCwd.isNotEmpty) {
          sb.write('cd /d "${startCwd.replaceAll('"', '')}" & ');
        }
        sb.write(command);
        sb.write(' & cd');
        full = sb.toString();
      } else {
        final sb = StringBuffer();
        if (startCwd != null && startCwd.isNotEmpty) {
          sb.write('cd "${startCwd.replaceAll('"', '')}" && ');
        }
        sb.write(command);
        sb.write(' && pwd');
        full = sb.toString();
      }
      final res = await Process.run(
        full,
        [],
        runInShell: true,
      ).timeout(const Duration(seconds: 60));
      final rawOut = res.stdout.toString();
      final err = res.stderr.toString().trim();
      final lines = rawOut
          .split('\n')
          .map((e) => e.trimRight())
          .where((e) => e.isNotEmpty)
          .toList();
      String? newCwd;
      if (lines.isNotEmpty) {
        final candidate = lines.last.trim();
        if (Directory(candidate).existsSync()) {
          newCwd = candidate;
          lines.removeLast();
        }
      }
      if (newCwd != null) _sessionCwd[key] = newCwd;
      final out = lines.join('\n').trim();
      if (res.exitCode == 0) {
        return ToolResult(true, out.isEmpty ? '(ok)' : out);
      }
      return ToolResult(false, err.isEmpty ? 'exit ${res.exitCode}' : err);
    } catch (e) {
      return ToolResult(false, 'Échec: $e');
    }
  }

  static Future<ToolResult> _sql(String database, String query) async {
    if (database.trim().isEmpty || query.trim().isEmpty) {
      return const ToolResult(false, 'Base ou requête vide');
    }
    try {
      final res = await Process.run(
        'sqlite3',
        [database, query],
        runInShell: true,
      ).timeout(const Duration(seconds: 30));
      final out = res.stdout.toString().trim();
      final err = res.stderr.toString().trim();
      if (res.exitCode == 0) {
        return ToolResult(true, out.isEmpty ? '(ok)' : out);
      }
      return ToolResult(false, err.isEmpty ? 'exit ${res.exitCode}' : err);
    } catch (e) {
      return ToolResult(false, 'sqlite3 indisponible: $e');
    }
  }

  static Future<ToolResult> _binaryTool(
    String exe,
    List<String> baseArgs,
    String input,
  ) async {
    if (input.trim().isEmpty) return const ToolResult(false, 'Entrée vide');
    try {
      final res = await Process.run(
        exe,
        [...baseArgs, input],
        runInShell: true,
      ).timeout(const Duration(seconds: 60));
      final out = res.stdout.toString().trim();
      if (res.exitCode == 0) {
        return ToolResult(true, out.isEmpty ? '(ok)' : out);
      }
      return ToolResult(false, '$exe indisponible ou erreur exit ${res.exitCode}');
    } catch (e) {
      return ToolResult(false, '$exe indisponible: $e');
    }
  }

  static Future<ToolResult> _tts(String text) async {
    if (text.trim().isEmpty) return const ToolResult(false, 'Texte vide');
    try {
      await Process.run(
        'powershell',
        ['-Command', 'Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak("${text.replaceAll('"', '')}")'],
        runInShell: true,
      ).timeout(const Duration(seconds: 60));
      return const ToolResult(true, 'Synthèse vocale jouée.');
    } catch (e) {
      return ToolResult(false, 'TTS indisponible: $e');
    }
  }

  static Future<ToolResult> _clipboard(String action, String text) async {
    try {
      final isWrite = action == 'write' || action == 'set' || action == 'copy';
      if (Platform.isWindows) {
        if (isWrite) {
          final tmp = File(
            '${Directory.systemTemp.path}${Platform.pathSeparator}aura_clip_${DateTime.now().microsecondsSinceEpoch}.txt',
          );
          await tmp.writeAsString(text);
          final res = await Process.run(
            'powershell',
            [
              '-Command',
              'Get-Content -Raw -LiteralPath \'${tmp.path}\' | Set-Clipboard',
            ],
            runInShell: true,
          ).timeout(const Duration(seconds: 20));
          try {
            if (await tmp.exists()) await tmp.delete();
          } catch (_) {}
          if (res.exitCode == 0) {
            return ToolResult(true, 'Presse-papier écrit (${text.length} car.).');
          }
          return ToolResult(false, 'Échec écriture presse-papier');
        }
        final res = await Process.run(
          'powershell',
          ['-Command', 'Get-Clipboard -Raw'],
          runInShell: true,
        ).timeout(const Duration(seconds: 20));
        final out = res.stdout.toString().trim();
        if (res.exitCode == 0) {
          return ToolResult(true, out.isEmpty ? '(presse-papier vide)' : out);
        }
        return ToolResult(false, 'Échec lecture presse-papier');
      } else if (Platform.isMacOS) {
        if (isWrite) {
          final p = await Process.start('pbcopy', []);
          p.stdin.write(text);
          await p.stdin.close();
          await p.exitCode.timeout(const Duration(seconds: 20));
          return ToolResult(true, 'Presse-papier écrit (${text.length} car.).');
        }
        final res = await Process.run('pbpaste', [])
            .timeout(const Duration(seconds: 20));
        return ToolResult(true, res.stdout.toString().trim());
      } else {
        if (isWrite) {
          final p = await Process.start('xclip', ['-selection', 'clipboard']);
          p.stdin.write(text);
          await p.stdin.close();
          await p.exitCode.timeout(const Duration(seconds: 20));
          return ToolResult(true, 'Presse-papier écrit (${text.length} car.).');
        }
        final res = await Process.run('xclip',
            ['-selection', 'clipboard', '-o']).timeout(const Duration(seconds: 20));
        return ToolResult(true, res.stdout.toString().trim());
      }
    } catch (e) {
      return ToolResult(false, 'Presse-papier indisponible: $e');
    }
  }

  static Future<ToolResult> _process(String action, Map<String, String> args) async {
    try {
      if (action == 'kill' || action == 'stop') {
        final target = args['pid'] ?? args['name'] ?? '';
        if (target.trim().isEmpty) {
          return const ToolResult(false, 'pid ou name requis');
        }
        if (Platform.isWindows) {
          final a = int.tryParse(target) != null
              ? ['/PID', target, '/F']
              : ['/IM', target, '/F'];
          final res = await Process.run('taskkill', a, runInShell: true)
              .timeout(const Duration(seconds: 20));
          final out = (res.stdout + res.stderr).toString().trim();
          return ToolResult(
              res.exitCode == 0, out.isEmpty ? 'exit ${res.exitCode}' : out);
        }
        final res = await Process.run('kill', ['-9', target], runInShell: true)
            .timeout(const Duration(seconds: 20));
        return ToolResult(res.exitCode == 0, 'kill $target');
      }
      final res = Platform.isWindows
          ? await Process.run('tasklist', [], runInShell: true)
              .timeout(const Duration(seconds: 20))
          : await Process.run('ps', ['-eo', 'pid,comm'], runInShell: true)
              .timeout(const Duration(seconds: 20));
      var out = res.stdout.toString().trim();
      final filter = args['filter'] ?? args['name'] ?? '';
      if (filter.isNotEmpty) {
        out = out
            .split('\n')
            .where((l) => l.toLowerCase().contains(filter.toLowerCase()))
            .join('\n');
      }
      final lines = out.split('\n');
      final capped = lines.length > 60
          ? '${lines.take(60).join('\n')}\n… (${lines.length} lignes)'
          : out;
      return ToolResult(true, capped.isEmpty ? '(aucun processus)' : capped);
    } catch (e) {
      return ToolResult(false, 'Gestion processus indisponible: $e');
    }
  }

  static Future<ToolResult> _fsList(String path, String ext) async {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        return ToolResult(false, 'Dossier introuvable: $path');
      }
      final entities = dir.listSync();
      final filtered = ext.isEmpty
          ? entities
          : entities
              .where((e) => e.path.toLowerCase().endsWith('.$ext') ||
                  e.path.toLowerCase().endsWith(ext.toLowerCase()))
              .toList();
      filtered.sort((a, b) {
        if (a is Directory && b is! Directory) return -1;
        if (a is! Directory && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      final lines = filtered.take(200).map((e) {
        if (e is Directory) return '[DIR]  ${e.path}';
        final size = e is File ? e.lengthSync() : 0;
        return '       ${e.path}  ($size o)';
      }).toList();
      final out = lines.join('\n');
      return ToolResult(
          true, out.isEmpty ? '(dossier vide)' : '$path\n$out');
    } catch (e) {
      return ToolResult(false, 'Erreur listage: $e');
    }
  }

  static Future<ToolResult> _browserOpen(String url, String session) async {
    var u = url.trim();
    if (u.isEmpty) return const ToolResult(false, 'URL vide');
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    return ToolResult(true, 'Navigateur : $u');
  }

  static Future<ToolResult> _browserNavigate(String url, String session) async {
    final c = BrowserRegistry.get(session);
    if (c == null) {
      return const ToolResult(false, 'Aucun navigateur ouvert pour cette session');
    }
    var u = url.trim();
    if (u.isEmpty) return const ToolResult(false, 'URL vide');
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    BrowserRegistry.setUrl(session, u);
    await c.loadRequest(u);
    return ToolResult(true, 'Navigation vers $u');
  }

  static Future<ToolResult> _browserGo(Map<String, String> args, {required bool back}) async {
    final c = BrowserRegistry.get(args['session'] ?? '');
    if (c == null) {
      return const ToolResult(false, 'Aucun navigateur ouvert pour cette session');
    }
    if (back) {
      await c.goBack();
      return const ToolResult(true, 'Retour arrière');
    }
    await c.goForward();
    return const ToolResult(true, 'Avancer');
  }

  static Future<ToolResult> _browserReload(String session) async {
    final c = BrowserRegistry.get(session);
    if (c == null) {
      return const ToolResult(false, 'Aucun navigateur ouvert pour cette session');
    }
    await c.reload();
    return const ToolResult(true, 'Rechargé');
  }

  static Future<ToolResult> _browserEval(String script, String session) async {
    final c = BrowserRegistry.get(session);
    if (c == null) {
      return const ToolResult(false, 'Aucun navigateur ouvert pour cette session');
    }
    if (script.trim().isEmpty) return const ToolResult(false, 'Script vide');
    final r = await c.evaluateJavaScript(script);
    return ToolResult(true, 'JS: ${r.toString()}');
  }

  static Future<ToolResult> _browserClick(String target, String session) async {
    final c = BrowserRegistry.get(session);
    if (c == null) {
      return const ToolResult(false, 'Aucun navigateur ouvert pour cette session');
    }
    final t = target.trim();
    if (t.isEmpty) return const ToolResult(false, 'Cible vide');
    final js = '(() => { const t = ${jsonEncode(t)}; const els = [...document.querySelectorAll("a,button,[role=button],input[type=submit],input[type=button],textarea,select,[onclick]")]; const bySel = (t.startsWith("#") || t.startsWith(".")) ? document.querySelector(t) : null; const el = bySel || els.find(e => (e.textContent||"").toLowerCase().includes(t.toLowerCase())); if (!el) return "not found: "+t; el.click(); return "clicked: "+t; })()';
    final r = await c.evaluateJavaScript(js);
    return ToolResult(true, 'Clic: ${r.toString()}');
  }

  /// Pont Node.js Playwright (CDP) pour l'automatisation riche.
  static final _playwrightBridge = _initPlaywrightBridge();

  static Future<Process> _initPlaywrightBridge() async {
    return await Process.start(
      'node',
      ['playwright_bridge.js'],
      workingDirectory: Platform.isWindows
          ? 'C:/Users/evolu/Documents/Github-repo/Aura'
          : '',
    );
  }

  static Future<ToolResult> _browserPlaywright(Map<String, String> args, String session) async {
    try {
      final payload = jsonEncode({
        'action': args['action'] ?? '',
        'url': args['url'],
        'selector': args['selector'],
        'text': args['text'],
        'script': args['script'],
        'ms': args['ms'],
      });
      final bridge = await _playwrightBridge;
      bridge.stdin.writeln(payload);
      final respLine = await bridge.stdout.first;
      final resp = jsonDecode(respLine.toString());
      if ((resp['ok'] as bool?) ?? false) {
        return ToolResult(true, resp['result'] ?? resp);
      }
      return ToolResult(false, resp['error'] ?? 'Unknown playwright error');
    } catch (e) {
      return ToolResult(false, 'Playwright bridge error: ${e.toString()}');
    }
  }

}