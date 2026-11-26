import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Drives the official `llama-server.exe` (prebuilt llama.cpp release) through
/// its OpenAI-compatible HTTP API.
///
/// Bundled runtimes live next to the executable in
/// `<runner>/llama/<backend>/llama-server.exe` for the backends
/// `cpu`, `vulkan`, `cuda`, `rocm`, `sycl`. The backend is chosen from the
/// detected GPU vendor and falls back automatically when one cannot start.
class LlamaServerProcess {
  Process? _proc;
  int? _port;
  bool _ready = false;
  bool _procExited = false;
  bool _adopted = false;
  String? _activeBackend;
  String? _modelPath;
  String? _mmprojPath;
  int _nPast = 0;
  static const int _contextSize = 8192;
  HttpClient? _activeClient;

  /// Identifiant stable du serveur (persisté) et port fixe associé.
  final int serverId;
  int? fixedPort;

  /// Annule la génération en cours en fermant la connexion HTTP active.
  void cancelGeneration() {
    _activeClient?.close(force: true);
    _activeClient = null;
  }
  final StringBuffer _stderr = StringBuffer();
  Timer? _idleTimer;
  final int idleMinutes;
  final String? gpuVendor;

  LlamaServerProcess({this.idleMinutes = 5, this.gpuVendor, this.serverId = 0});

  /// Backends to try, in priority order, for the detected GPU vendor.
  List<String> _backendOrder() {
    switch ((gpuVendor ?? '').toUpperCase()) {
      case 'NVIDIA':
        return ['cuda', 'vulkan', 'cpu'];
      case 'AMD':
        return ['rocm', 'vulkan', 'cpu'];
      case 'INTEL':
        return ['vulkan', 'sycl', 'cpu'];
      default:
        return ['vulkan', 'cpu'];
    }
  }

  Future<void> start(String modelPath, {String? mmprojPath, int? port}) async {
    _modelPath = modelPath;
    _mmprojPath = mmprojPath;
    if (port != null) fixedPort = port;
    if (fixedPort != null && await _healthCheck(fixedPort!)) {
      _port = fixedPort;
      _ready = true;
      _adopted = true;
      _procExited = false;
      _touchIdle();
      return;
    }
    _adopted = false;
    final baseDir = File(Platform.resolvedExecutable).parent.path;
    final sep = Platform.pathSeparator;
    Object? lastError;
    for (final backend in _backendOrder()) {
      final exe = '$baseDir${sep}llama$sep$backend${sep}llama-server.exe';
      if (!File(exe).existsSync()) continue;
      try {
        await _startWith(exe, modelPath, const Duration(seconds: 120),
            mmprojPath: mmprojPath);
        _activeBackend = backend;
        return;
      } catch (e) {
        lastError = e;
        await kill();
      }
    }
    final legacy = '$baseDir${sep}llama-server.exe';
    if (File(legacy).existsSync()) {
      try {
        await _startWith(legacy, modelPath, const Duration(seconds: 120),
            mmprojPath: mmprojPath);
        _activeBackend = 'legacy';
        return;
      } catch (e) {
        lastError = e;
        await kill();
      }
    }
    throw 'Impossible de démarrer llama.cpp: ${lastError ?? "aucun runtime trouvé"}';
  }

  /// Tente d'adopter un serveur déjà running sur [port] (créé lors d'une
  /// session précédente). Retourne `true` si un serveur sain a été trouvé.
  Future<bool> adopt(int port, {String? modelPath, String? mmprojPath}) async {
    fixedPort = port;
    if (modelPath != null) _modelPath = modelPath;
    if (mmprojPath != null && mmprojPath.isNotEmpty) _mmprojPath = mmprojPath;
    if (await _healthCheck(port)) {
      _port = port;
      _ready = true;
      _adopted = true;
      _procExited = false;
      _touchIdle();
      return true;
    }
    return false;
  }

  Future<void> _startWith(
    String serverExe,
    String modelPath,
    Duration timeout, {
    String? mmprojPath,
  }) async {
    final exeDir = File(serverExe).parent.path;
    final port = await _resolvePort();
    _port = port;
    fixedPort = port;
    _ready = false;
    _adopted = false;
    _procExited = false;
    _stderr.clear();
    _proc = await Process.start(
      serverExe,
      [
        '-m',
        modelPath,
        if (mmprojPath != null && mmprojPath.isNotEmpty) ...[
          '--mmproj',
          mmprojPath,
        ],
        '--host',
        '127.0.0.1',
        '--port',
        '$port',
        '-ngl',
        '999',
        '-c',
        '8192',
        '--jinja',
      ],
      workingDirectory: exeDir,
      mode: ProcessStartMode.normal,
    );
    _proc!.stdout.transform(utf8.decoder).listen((_) {});
    _proc!.stderr.transform(utf8.decoder).listen((data) {
      _stderr.write(data);
    });
    _proc!.exitCode.then((_) {
      _procExited = true;
      _ready = false;
    });

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_procExited) {
        throw 'server exited: ${_stderr.toString().trim()}';
      }
      if (await _healthCheck(port)) {
        _ready = true;
        _touchIdle();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    throw 'startup timeout: ${_stderr.toString().trim()}';
  }

  Future<int> _findFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  /// Réutilise le port fixe s'il est libre, sinon en cherche un nouveau.
  Future<int> _resolvePort() async {
    final fixed = fixedPort;
    if (fixed != null && await _isPortFree(fixed)) return fixed;
    return _findFreePort();
  }

  Future<bool> _isPortFree(int port) async {
    try {
      final socket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _healthCheck(int port) async {
    final client = HttpClient();
    try {
      final req = await client
          .getUrl(Uri.parse('http://127.0.0.1:$port/health'))
          .timeout(const Duration(seconds: 2));
      final res = await req.close().timeout(const Duration(seconds: 2));
      final body = await res.transform(utf8.decoder).join();
      return res.statusCode == 200 && body.contains('ok');
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  void _touchIdle() {
    _idleTimer?.cancel();
    if (idleMinutes <= 0) return;
    _idleTimer = Timer(Duration(minutes: idleMinutes), () {
      kill();
    });
  }

  Future<String> generate(
    String prompt, {
    int maxTokens = 128,
    bool reasoning = false,
    String systemPrompt = '',
    List<Map<String, String>>? history,
  }) async {
    if (!_ready || _port == null) {
      return 'Server not ready';
    }
    _touchIdle();
    final client = HttpClient();
    try {
      final req = await client
          .postUrl(Uri.parse('http://127.0.0.1:$_port/v1/chat/completions'))
          .timeout(const Duration(seconds: 10));
      req.headers.contentType = ContentType.json;
      final body = <String, dynamic>{
        'messages': [
          if (systemPrompt.trim().isNotEmpty)
            {'role': 'system', 'content': systemPrompt.trim()},
          if (history != null) ...history,
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': maxTokens,
        'temperature': 0.7,
        'stream': false,
        if (!reasoning) 'chat_template_kwargs': {'enable_thinking': false},
      };
      req.write(jsonEncode(body));
      final res = await req.close().timeout(const Duration(minutes: 5));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        return 'Error: HTTP ${res.statusCode} $text';
      }
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final msg = first['message'];
          if (msg is Map) {
            return msg['content']?.toString() ?? '';
          }
          return first['text']?.toString() ?? '';
        }
      }
      return text;
    } catch (e) {
      return 'Error: $e';
    } finally {
      client.close();
    }
  }

  /// Génère une réponse en streaming (SSE). `onDelta` est appelé à chaque
  /// fragment. Retourne le texte complet, le nombre de tokens (usage) et le
  /// temps écoulé en millisecondes.
  Future<({String text, int? completionTokens, int elapsedMs})> generateStream(
    String prompt, {
    int maxTokens = 128,
    bool reasoning = false,
    String systemPrompt = '',
    List<Map<String, String>>? history,
    List<String>? images,
    void Function(String delta)? onDelta,
  }) async {
    if (!_ready || _port == null) {
      return (text: 'Server not ready', completionTokens: null, elapsedMs: 0);
    }
    _touchIdle();
    final sw = Stopwatch()..start();
    final client = HttpClient();
    _activeClient = client;
    final buffer = StringBuffer();
    int? completionTokens;
    try {
      final req = await client
          .postUrl(Uri.parse('http://127.0.0.1:$_port/v1/chat/completions'))
          .timeout(const Duration(seconds: 10));
      req.headers.contentType = ContentType.json;
      final body = <String, dynamic>{
        'messages': [
          if (systemPrompt.trim().isNotEmpty)
            {'role': 'system', 'content': systemPrompt.trim()},
          if (history != null) ...history,
          {'role': 'user', 'content': await _userContent(prompt, images)},
        ],
        'max_tokens': maxTokens,
        'temperature': 0.7,
        'stream': true,
        if (!reasoning) 'chat_template_kwargs': {'enable_thinking': false},
      };
      req.write(jsonEncode(body));
      final res = await req.close().timeout(const Duration(minutes: 5));
      if (res.statusCode != 200) {
        final err = await res.transform(utf8.decoder).join();
        return (
          text: 'Error: HTTP ${res.statusCode} $err',
          completionTokens: null,
          elapsedMs: sw.elapsedMilliseconds,
        );
      }
      final lines =
          res.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') break;
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          final usage = decoded['usage'];
          if (usage is Map && usage['completion_tokens'] is int) {
            completionTokens = usage['completion_tokens'] as int;
          }
          final choices = decoded['choices'];
          if (choices is List && choices.isNotEmpty) {
            final first = choices.first;
            if (first is Map) {
              final delta = first['delta'];
              if (delta is Map && delta['content'] != null) {
                final piece = delta['content'].toString();
                buffer.write(piece);
                onDelta?.call(piece);
              }
            }
          }
        } catch (_) {}
      }
      sw.stop();
      return (
        text: buffer.toString(),
        completionTokens: completionTokens,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return (
        text: 'Error: $e',
        completionTokens: completionTokens,
        elapsedMs: sw.elapsedMilliseconds,
      );
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  /// Construit le contenu du message utilisateur. Si des images sont fournies,
  /// renvoie un tableau OpenAI `content` avec une partie texte et une partie
  /// `image_url` (data URI base64) par image. Sinon renvoie la chaîne simple.
  Future<Object> _userContent(String prompt, List<String>? images) async {
    if (images == null || images.isEmpty) return prompt;
    final parts = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
    ];
    for (final path in images) {
      final url = await _imageDataUrl(path);
      if (url == null) continue;
      parts.add({
        'type': 'image_url',
        'image_url': {'url': url},
      });
    }
    return parts;
  }

  /// Lit un fichier image et renvoie une data URI base64. `null` si illisible.
  Future<String?> _imageDataUrl(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      final ext = path.toLowerCase().split('.').last;
      final mime = switch (ext) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        _ => 'image/png',
      };
      final b64 = base64Encode(bytes);
      return 'data:$mime;base64,$b64';
    } catch (_) {
      return null;
    }
  }

  /// Réinitialise le cache KV (à appeler lors d'un changement de chat, d'une
  /// régénération ou d'un changement de modèle).
  void resetCache() {
    _nPast = 0;
  }

  /// Streaming avec réutilisation du cache KV via l'API bas niveau
  /// `/completion` et `n_past`. N'envoie au serveur que le nouveau tour de
  /// l'utilisateur lorsque le cache est chaud. `cached` est `false` en cas
  /// d'échec (repli possible sur [generateStream]).
  Future<({String text, int? completionTokens, int elapsedMs, bool cached})>
      generateStreamCached(
    String prompt, {
    int maxTokens = 128,
    bool reasoning = false,
    String systemPrompt = '',
    List<Map<String, String>>? history,
    void Function(String delta)? onDelta,
  }) async {
    if (!_ready || _port == null) {
      return (
        text: 'Server not ready',
        completionTokens: null,
        elapsedMs: 0,
        cached: false,
      );
    }
    _touchIdle();
    final sw = Stopwatch()..start();
    final client = HttpClient();
    _activeClient = client;
    final buffer = StringBuffer();
    int? completionTokens;
    int tokensEval = 0;
    int tokensPred = 0;

    final full = StringBuffer();
    if (systemPrompt.trim().isNotEmpty) {
      full.write('system: ${systemPrompt.trim()}\n');
    }
    if (history != null) {
      for (final h in history) {
        final role = h['role'] ?? 'user';
        final content = h['content'] ?? '';
        if (content.trim().isEmpty) continue;
        full.write('$role: $content\n');
      }
    }
    final newUser = 'user: $prompt\n';

    // Si le cache risque de déborder le contexte, on repart de zéro.
    if (_nPast > _contextSize - 1500) {
      _nPast = 0;
    }
    final warm = _nPast > 0;
    final requestPrompt = warm ? newUser : (full.toString() + newUser);

    try {
      final req = await client
          .postUrl(Uri.parse('http://127.0.0.1:$_port/completion'))
          .timeout(const Duration(seconds: 10));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(<String, dynamic>{
        'prompt': requestPrompt,
        'n_predict': maxTokens,
        'temperature': 0.7,
        'cache_prompt': true,
        'n_past': _nPast,
        'stream': true,
      }));
      final res = await req.close().timeout(const Duration(minutes: 5));
      if (res.statusCode != 200) {
        final err = await res.transform(utf8.decoder).join();
        return (
          text: 'Error: HTTP ${res.statusCode} $err',
          completionTokens: null,
          elapsedMs: sw.elapsedMilliseconds,
          cached: false,
        );
      }
      final lines =
          res.transform(utf8.decoder).transform(const LineSplitter());
      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') break;
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded['tokens_evaluated'] is int) {
            tokensEval = decoded['tokens_evaluated'] as int;
          }
          if (decoded['tokens_predicted'] is int) {
            tokensPred = decoded['tokens_predicted'] as int;
            completionTokens = tokensPred;
          }
          final content = decoded['content'];
          if (content is String && content.isNotEmpty) {
            final prev = buffer.toString();
            final String delta;
            if (content.length >= prev.length && content.startsWith(prev)) {
              delta = content.substring(prev.length);
            } else {
              delta = content;
            }
            if (delta.isNotEmpty) {
              buffer.write(delta);
              onDelta?.call(delta);
            }
          }
        } catch (_) {}
      }
      sw.stop();
      _nPast = _nPast + tokensEval + tokensPred;
      return (
        text: buffer.toString(),
        completionTokens: completionTokens,
        elapsedMs: sw.elapsedMilliseconds,
        cached: true,
      );
    } catch (e) {
      sw.stop();
      return (
        text: 'Error: $e',
        completionTokens: completionTokens,
        elapsedMs: sw.elapsedMilliseconds,
        cached: false,
      );
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  /// Abandonne le handle du process sans le tuer : le serveur continue de
  /// tourner sur l'OS et pourra être adopté à la prochaine session.
  void detach() {
    _idleTimer?.cancel();
    _proc = null;
    _ready = false;
  }

  Future<void> kill() async {
    _idleTimer?.cancel();
    _ready = false;
    _nPast = 0;
    if (_proc != null) {
      try {
        _proc!.kill();
      } catch (_) {}
    }
    _proc = null;
    _port = null;
    _adopted = false;
  }

  /// Met le serveur en veille : libère la VRAM en terminant le process que
  /// l'on possède, mais conserve le chemin du modèle et le port pour un
  /// redémarrage rapide via [ensureStarted]. Un serveur adopté (créé lors
  /// d'une session précédente) est laissé tourner.
  Future<void> sleep() async {
    _idleTimer?.cancel();
    if (_adopted) {
      _ready = false;
      return;
    }
    await kill();
  }

  /// (Re)démarre le serveur si un modèle est mémorisé et qu'il n'est pas déjà
  /// actif. Réutilise le port fixe. Retourne `true` si prêt après l'appel.
  Future<bool> ensureStarted() async {
    if (isRunning) return true;
    if (_modelPath == null) return false;
    try {
      await start(_modelPath!, mmprojPath: _mmprojPath, port: fixedPort);
    } catch (_) {
      return false;
    }
    return isRunning;
  }

  bool get isSleeping => !_ready && _modelPath != null;

  bool get isRunning => _ready && (_proc != null || _adopted);

  int? get pid => _proc?.pid;

  String? get activeBackend => _activeBackend;
}
