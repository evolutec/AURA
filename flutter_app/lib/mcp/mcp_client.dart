import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Outil exposé par un serveur MCP.
class McpTool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  const McpTool({
    required this.name,
    required this.description,
    this.inputSchema = const {},
  });
}

/// Client MCP minimal (JSON-RPC 2.0 sur stdio).
/// Supporte initialize, tools/list et tools/call.
class McpClient {
  final String command;
  final List<String> args;
  final Map<String, String> env;

  Process? _proc;
  StreamSubscription? _stdoutSub;
  final _responses = <int, Completer<Map<String, dynamic>>>{};
  int _nextId = 1;
  bool _ready = false;

  McpClient({required this.command, this.args = const [], this.env = const {}});

  bool get isReady => _ready;

  Future<void> start({Duration timeout = const Duration(seconds: 20)}) async {
    _proc = await Process.start(
      command,
      args,
      runInShell: true,
      environment: {...Platform.environment, ...env},
    );
    _stdoutSub = _proc!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: () {});

    await _request('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': {},
      'clientInfo': {'name': 'Aura', 'version': '1.0'},
    }, timeout: timeout);
    _notify('notifications/initialized', {});
    _ready = true;
  }

  void _onLine(String line) {
    final t = line.trim();
    if (t.isEmpty || !t.startsWith('{')) return;
    try {
      final msg = jsonDecode(t) as Map<String, dynamic>;
      final id = msg['id'];
      if (id is int && _responses.containsKey(id)) {
        _responses.remove(id)!.complete(msg);
      }
    } catch (_) {}
  }

  void _notify(String method, Map<String, dynamic> params) {
    final msg = {
      'jsonrpc': '2.0',
      'method': method,
      if (params.isNotEmpty) 'params': params,
    };
    _proc?.stdin.writeln(jsonEncode(msg));
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _responses[id] = completer;
    final msg = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };
    _proc?.stdin.writeln(jsonEncode(msg));
    return completer.future.timeout(timeout, onTimeout: () {
      _responses.remove(id);
      throw TimeoutException('MCP $method timeout');
    });
  }

  /// Liste les outils exposés par le serveur.
  Future<List<McpTool>> listTools() async {
    final res = await _request('tools/list', {});
    if (res.containsKey('error')) return [];
    final tools = (res['result'] as Map?)?['tools'] as List?;
    if (tools == null) return [];
    return tools.whereType<Map>().map((t) {
      return McpTool(
        name: t['name']?.toString() ?? '',
        description: t['description']?.toString() ?? '',
        inputSchema:
            (t['inputSchema'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
    }).toList();
  }

  /// Appelle un outil du serveur.
  Future<String> callTool(String name, Map<String, dynamic> args) async {
    final res = await _request('tools/call', {
      'name': name,
      'arguments': args,
    }, timeout: const Duration(seconds: 60));
    if (res.containsKey('error')) {
      return 'Erreur MCP: ${res['error']}';
    }
    final content = (res['result'] as Map?)?['content'] as List?;
    if (content == null) return '(ok)';
    final buf = StringBuffer();
    for (final c in content.whereType<Map>()) {
      if (c['type'] == 'text') buf.writeln(c['text']?.toString() ?? '');
    }
    return buf.toString().trim().isEmpty ? '(ok)' : buf.toString().trim();
  }

  Future<void> dispose() async {
    _stdoutSub?.cancel();
    _proc?.kill();
    _ready = false;
  }
}