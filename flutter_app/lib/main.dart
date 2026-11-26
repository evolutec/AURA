import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ffi' hide Size;

import 'ffi/ffi_bindings.dart';
import 'llama_server.dart';
import 'logger.dart';
import 'desktop/desktop_service.dart';
import 'settings_shell.dart';
import 'Parametres/Parametres/settings_colors.dart';
import 'Parametres/download_state.dart';
import 'Parametres/Parametres/appearance.dart';
import 'Parametres/Agents/agent_profile.dart';
import 'Parametres/Agents/agent_editor_dialog.dart';
import 'Parametres/CloudProviders/cloud_provider.dart';
import 'Parametres/CloudProviders/cloud_provider_store.dart';
import 'Parametres/LocalModels/model_capabilities.dart';

import 'sidebar/aura_sidebar.dart';
import 'sidebar/model_metrics.dart';
import 'sidebar/model_stats_modal.dart';
import 'chat/chat_message.dart';
import 'chat/chat_composer.dart';
import 'chat/browser_view.dart';
import 'chat/floating_tool_window.dart';
import 'tools/tool_runner.dart';
import 'Parametres/Extensions/extension_item.dart';
import 'Parametres/Extensions/extension_store.dart';
import 'mcp/mcp_client.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  AppLogger.info('Application started');
  if (isDesktop) {
    await desktopService.init();
  }
  final cacheDir = await getApplicationSupportDirectory();
  try {
    final cefReady = await ChromiumWebViewController.initialize(
      cachePath: cacheDir.path,
    );
    if (!cefReady) {
      AppLogger.error('Failed to initialize Chromium runtime');
    }
  } catch (e) {
    AppLogger.error('Chromium init failed: $e');
  }
  runApp(const AuraApp());
}

// ---- Simple i18n ----

const _languages = [
  ('en', 'English'),
  ('fr', 'Français'),
  ('es', 'Español'),
  ('zh', '中文'),
  ('ar', 'العربية'),
  ('ja', '日本語'),
  ('hi', 'हिन्दी'),
];

// ---- Themes ----
ThemeData _buildDarkTheme([String? fontFamily]) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8B5CF6),
      secondary: Color(0xFF06B6D4),
      surface: Color(0xFF0F1117),
      surfaceContainerHighest: Color(0x1AFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFFF1F5F9),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0x33FFFFFF),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 17, color: Color(0xFFF1F5F9)),
      bodySmall: TextStyle(fontSize: 18, color: Color(0xFF94A3B8)),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F5F9),
      ),
    ),
  );
}

ThemeData _buildLightTheme([String? fontFamily]) {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7C3AED),
      secondary: Color(0xFF0891B2),
      surface: Color(0xFFF8FAFC),
      surfaceContainerHighest: Color(0x14000000),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0x1F000000),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 17, color: Color(0xFF0F172A)),
      bodySmall: TextStyle(fontSize: 18, color: Color(0xFF475569)),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
    ),
  );
}

// ---- AuraApp ----
class AuraApp extends StatefulWidget {
  const AuraApp({super.key});

  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  bool _isDark = true;
  int _themeProfile = 1;
  String _lang = 'en';
  AppearanceSettings _appearance = const AppearanceSettings();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    AppearanceSettings appearance = const AppearanceSettings();
    final raw = prefs.getString('appearance');
    if (raw != null && raw.isNotEmpty) {
      try {
        appearance = AppearanceSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      } catch (_) {}
    }
    final profile = prefs.getInt('themeProfile') ?? 1;
    setState(() {
      _themeProfile = profile.clamp(0, kThemeProfiles.length - 1);
      _isDark = kThemeProfiles[_themeProfile].isDark;
      _lang = prefs.getString('lang') ?? 'en';
      _appearance = appearance;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _isDark);
    await prefs.setInt('themeProfile', _themeProfile);
    await prefs.setString('lang', _lang);
    await prefs.setString('appearance', jsonEncode(_appearance.toJson()));
  }

  void _toggleTheme() {
    _setThemeProfile(_isDark ? 0 : 1);
  }

  void _setThemeProfile(int profile) {
    final index = profile.clamp(0, kThemeProfiles.length - 1);
    setState(() {
      _themeProfile = index;
      _isDark = kThemeProfiles[index].isDark;
    });
    _savePrefs();
  }

  void _setLang(String l) {
    setState(() => _lang = l);
    _savePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(_appearance.interfaceFont),
      darkTheme: _buildDarkTheme(_appearance.interfaceFont),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(_lang),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            _appearance.textScale * _appearance.uiScale,
          ),
        ),
        child: Stack(
          children: [
            child ?? const SizedBox(),
            const DownloadManagerBadge(),
          ],
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('en'), Locale('fr'), Locale('es')],
      home: AppearanceScope(
        settings: _appearance,
        child: HomePage(
          isDark: _isDark,
          themeProfile: _themeProfile,
          lang: _lang,
          onToggleTheme: _toggleTheme,
          onThemeProfileChanged: _setThemeProfile,
          onSetLang: _setLang,
          onAppearanceChanged: (value) {
            setState(() => _appearance = value);
            _savePrefs();
          },
        ),
      ),
    );
  }
}

// ---- HomePage ----
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.isDark,
    required this.themeProfile,
    required this.lang,
    required this.onToggleTheme,
    required this.onThemeProfileChanged,
    required this.onSetLang,
    required this.onAppearanceChanged,
  });

  final bool isDark;
  final int themeProfile;
  final String lang;
  final VoidCallback onToggleTheme;
  final ValueChanged<int> onThemeProfileChanged;
  final ValueChanged<String> onSetLang;
  final ValueChanged<AppearanceSettings> onAppearanceChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _ServerMeta {
  final int id;
  final int port;
  final String model;
  final String? mmproj;
  final int? pid;
  const _ServerMeta({
    required this.id,
    required this.port,
    required this.model,
    this.mmproj,
    this.pid,
  });
  Map<String, dynamic> toJson() =>
      {'id': id, 'port': port, 'model': model, 'mmproj': mmproj, 'pid': pid};
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final DownloadManager _downloads;
  String _version = 'Loading...';
  List<dynamic> _models = [];
  Map<String, dynamic> _hardware = {};
  String? get _gpuVendor {
    final gpu = _hardware['gpu'];
    return gpu is Map ? gpu['vendor']?.toString() : null;
  }

  bool _sidebarExpanded = true;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _dockScrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ToolRun> _toolDock = [];
  final Map<String, String> _pinned = {};
  ToolRun? _floating;
  bool _dockOpen = true;
  final List<String> _attachments = [];
  final Map<int, List<ChatMessage>> _chatMessages = {};
  final List<String> _chatTitles = ['New Chat'];
  int _currentChat = 0;
  String get _chatTitle =>
      _chatTitles.isEmpty ? 'New Chat' : _chatTitles[_currentChat];
  AgentProfile get _activeAgent => _agents.firstWhere(
    (agent) => agent.id == _selectedAgent,
    orElse: () => AgentProfile.defaults.first,
  );
  Pointer<Void>? _engine;
  Pointer<Void>? _session;
  String? _engineModelId;
  String _selectedAgent = 'ask';
  List<AgentProfile> _agents = AgentProfile.defaults;
  String _selectedProvider = 'local';
  String? _selectedModel;
  List<CloudProvider> _cloudProviders = [];
  String _modelsDir = 'C:\\Users\\evolu\\Documents\\LIA-X\\Models';
  String _ramHeadroom = '512';
  String _temperature = '0.7';
  String _topP = '0.95';
  String _topK = '40';
  String _maxTokens = '512';
  bool _reasoningEnabled = false;
  bool _toolsEnabled = true;
  bool _toolsAvailable = false;
  bool _isGenerating = false;
  bool _cancelRequested = false;
  final Map<String, String> _multiStatus = {};
  final Map<String, LlamaServerProcess> _multiServers = {};
  final Map<String, McpClient> _mcpClients = {};
  final Map<String, _ServerMeta> _serverMeta = {};
  final Set<String> _loadedModels = {};
  int _nextServerId = 1;
  String _idleMinutes = '5';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Les serveurs sont persistés et adoptés au prochain lancement : on ne les
    // tue pas au cycle de vie. Le timer d'inactivité gère la libération VRAM.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _multiServers.values) {
      s.sleep(); // libère la VRAM (tue le process) à la fermeture de l'appli
    }
    for (final c in _mcpClients.values) {
      c.dispose();
    }
    if (_session != null) auraSessionDispose(_session!);
    if (_engine != null) auraEngineDispose(_engine!);
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _downloads = DownloadManager(showBanner: _showBanner);
    DownloadManager.instance.ensureMmprojLoaded();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _loadPrefs();
    _loadChats();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    var loadedAgents = _agents;
    final rawAgents = prefs.getString('agents');
    if (rawAgents != null) {
      try {
        final decoded = jsonDecode(rawAgents) as List<dynamic>;
        final parsed = decoded
            .whereType<Map<String, dynamic>>()
            .map(AgentProfile.fromJson)
            .where((agent) => agent.id.isNotEmpty && agent.name.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) loadedAgents = parsed;
      } catch (_) {}
    }
    setState(() {
      _agents = loadedAgents;
      final savedAgent = prefs.getString('selectedAgent') ?? _selectedAgent;
      _selectedAgent = _agents.any((agent) => agent.id == savedAgent)
          ? savedAgent
          : _agents.first.id;
      _selectedProvider =
          prefs.getString('selectedProvider') ?? _selectedProvider;
      _selectedModel = prefs.getString('selectedModel');
      _modelsDir = prefs.getString('modelsDir') ?? _modelsDir;
      _ramHeadroom = prefs.getString('ramHeadroom') ?? _ramHeadroom;
      _temperature = prefs.getString('temperature') ?? _temperature;
      _topP = prefs.getString('topP') ?? _topP;
      _topK = prefs.getString('topK') ?? _topK;
      _maxTokens = prefs.getString('maxTokens') ?? _maxTokens;
      _idleMinutes = prefs.getString('idleMinutes') ?? _idleMinutes;
      _sidebarExpanded = prefs.getBool('sidebarExpanded') ?? _sidebarExpanded;
      _toolsEnabled = true;
      final rawLoaded = prefs.getString('loaded_models');
      if (rawLoaded != null && rawLoaded.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawLoaded) as List<dynamic>;
          _loadedModels
            ..clear()
            ..addAll(decoded.map((e) => e.toString()));
        } catch (_) {}
      }
      final rawServers = prefs.getString('servers');
      if (rawServers != null && rawServers.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawServers) as List<dynamic>;
          for (final e in decoded) {
            if (e is! Map) continue;
            final model = e['model']?.toString();
            final id = e['id'];
            final port = e['port'];
            if (model == null || id is! int || port is! int) continue;
            _serverMeta[model] = _ServerMeta(
              id: id,
              port: port,
              model: model,
              mmproj: e['mmproj']?.toString(),
              pid: e['pid'] as int?,
            );
            if (id >= _nextServerId) _nextServerId = id + 1;
          }
        } catch (_) {}
      }
    });
    _cloudProviders = await CloudProviderStore().load();
    await _refreshToolsAvailability();
    _restoreServers();
  }

  /// Au lancement, adopte les serveurs encore vivants (créés à une session
  /// précédente) sans en recréer. Les autres seront relancés à la demande.
  Future<void> _restoreServers() async {
    for (final entry in _serverMeta.values.toList()) {
      final modelFile = File(
        "${_modelsDir}${Platform.pathSeparator}${entry.model}",
      );
      final proc = LlamaServerProcess(
        idleMinutes: int.tryParse(_idleMinutes) ?? 5,
        gpuVendor: _gpuVendor,
        serverId: entry.id,
      );
      proc.fixedPort = entry.port;
      final alive = modelFile.existsSync() &&
          await proc.adopt(entry.port,
              modelPath: modelFile.path, mmprojPath: entry.mmproj);
      if (alive) {
        _multiServers[entry.model] = proc;
        _loadedModels.add(entry.model);
        _multiStatus[entry.model] = "Ready (VRAM)";
        _serverMeta[entry.model] = _ServerMeta(
          id: entry.id,
          port: entry.port,
          model: entry.model,
          mmproj: entry.mmproj,
          pid: proc.pid ?? entry.pid,
        );
      } else if (modelFile.existsSync() && _loadedModels.contains(entry.model)) {
        // Le process a disparu (VRAM libérée à la fermeture) : on le relance
        // avec le même id/port pour que le modèle reste marqué comme chargé.
        try {
          await proc.start(
            modelFile.path,
            mmprojPath: entry.mmproj,
            port: entry.port,
          );
          _multiServers[entry.model] = proc;
          _loadedModels.add(entry.model);
          _multiStatus[entry.model] = "Ready (VRAM)";
          _serverMeta[entry.model] = _ServerMeta(
            id: entry.id,
            port: entry.port,
            model: entry.model,
            mmproj: entry.mmproj,
            pid: proc.pid,
          );
        } catch (e) {
          _multiStatus[entry.model] = "Stopped";
        }
      } else {
        _multiStatus[entry.model] = "Stopped";
      }
    }
    if (mounted) setState(() {});
    await _savePrefs();
  }

  Future<void> _refreshToolsAvailability() async {
    final all = await ExtensionStore.load();
    if (!mounted) return;
    setState(() => _toolsAvailable = all.any((e) => e.enabled));
  }

  Future<void> _reloadCloudProviders() async {
    final providers = await CloudProviderStore().load();
    if (!mounted) return;
    setState(() => _cloudProviders = providers);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAgent', _selectedAgent);
    await prefs.setString('selectedProvider', _selectedProvider);
    if (_selectedModel != null)
      await prefs.setString('selectedModel', _selectedModel!);
    await prefs.setString('modelsDir', _modelsDir);
    await prefs.setString('ramHeadroom', _ramHeadroom);
    await prefs.setString('temperature', _temperature);
    await prefs.setString('topP', _topP);
    await prefs.setString('topK', _topK);
    await prefs.setString('maxTokens', _maxTokens);
    await prefs.setString('idleMinutes', _idleMinutes);
    await prefs.setBool('sidebarExpanded', _sidebarExpanded);
    await prefs.setString('loaded_models', jsonEncode(_loadedModels.toList()));
    await prefs.setString(
      'servers',
      jsonEncode(_serverMeta.values.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _saveAgents() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'agents',
      jsonEncode(_agents.map((agent) => agent.toJson()).toList()),
    );
  }

  Future<void> _updateAgents(List<AgentProfile> agents) async {
    if (agents.isEmpty) return;
    setState(() {
      _agents = agents;
      if (!_agents.any((agent) => agent.id == _selectedAgent)) {
        _selectedAgent = _agents.first.id;
      }
    });
    await _saveAgents();
    await _savePrefs();
  }

  Future<void> _loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('chats');
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final chats = (data['chats'] as List).cast<Map<String, dynamic>>();
      setState(() {
        _chatTitles
          ..clear()
          ..addAll(chats.map((c) => c['title'] as String));
        _chatMessages.clear();
        for (var i = 0; i < chats.length; i++) {
          final msgs = (chats[i]['messages'] as List)
              .cast<Map<String, dynamic>>();
          _chatMessages[i] = msgs
              .map(
                (m) => ChatMessage(
                  isUser: m['isUser'] as bool? ?? true,
                  text: m['text'] as String? ?? '',
                  tokensPerSec: (m['tps'] as num?)?.toDouble(),
                ),
              )
              .toList();
        }
        _currentChat = (data['current'] as int?) ?? 0;
        if (_currentChat >= _chatTitles.length) _currentChat = 0;
        _messages
          ..clear()
          ..addAll(_chatMessages[_currentChat] ?? []);
      });
    } catch (_) {}
  }

  void _saveChats() {
    SharedPreferences.getInstance().then((prefs) {
      final chats = <Map<String, dynamic>>[];
      for (var i = 0; i < _chatTitles.length; i++) {
        final msgs = i == _currentChat ? _messages : (_chatMessages[i] ?? []);
        chats.add({
          'title': _chatTitles[i],
          'messages': msgs
              .map(
                (m) => {
                  'isUser': m.isUser,
                  'text': m.text,
                  'tps': (m.tokensPerSec?.isFinite ?? false)
                      ? m.tokensPerSec
                      : null,
                },
              )
              .toList(),
        });
      }
      try {
        prefs.setString(
          'chats',
          jsonEncode({'chats': chats, 'current': _currentChat}),
        );
      } catch (e) {
        AppLogger.error('save chats failed: $e');
      }
    });
  }

  void _loadData() {
    try {
      setState(() {
        _version = auraVersion();
        _models = json.decode(auraCatalogCompatibleJson());
        _hardware = json.decode(auraHardwareJson());
      });
    } catch (e) {
      setState(() => _version = 'Error: $e');
    }
  }

  SettingsColors get _palette =>
      SettingsColors.fromProfile(widget.themeProfile);
  Color get _bg => _palette.bg;
  Color get _panel => _palette.panel;
  Color get _panel2 => _palette.panel2;
  Color get _border => _palette.border;
  Color get _text => _palette.text;
  Color get _muted => _palette.muted;
  Color get _white70 => _palette.white70;
  Color get _accent => _palette.accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _sidebarExpanded ? 260 : 84,
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border(right: BorderSide(color: _border)),
                ),
                child: _buildSidebar(),
              ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildContent()),
                    _buildComposer(),
                  ],
                ),
              ),
              if (_dockOpen && _toolDock.isNotEmpty) _buildToolDock(),
            ],
          ),
          if (_floating != null)
            Positioned.fill(
              child: FloatingToolWindow(
                key: ValueKey('floatwin_${_floating!.sessionId}'),
                run: _floating!,
                colors: _palette,
                onRedock: _redockFloating,
                onClose: () => setState(() => _floating = null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AuraSidebar(
      expanded: _sidebarExpanded,
      isDesktop: isDesktop,
      chatTitles: _chatTitles,
      currentChat: _currentChat,
      colors: _palette,
      onToggle: () {
        setState(() => _sidebarExpanded = !_sidebarExpanded);
        _savePrefs();
      },
      onNewChat: _newChat,
      onOpenSettings: _openSettings,
      onOpenStats: _openStats,
      onSwitchChat: _switchChat,
      onRenameChat: _renameChat,
      onDeleteChat: _deleteChat,
    );
  }

  // ---- Right dock: sessions d'outils détachées (terminal/sandbox) ----
  Widget _buildToolDock() {
    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: _panel,
        border: Border(left: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                Icon(Icons.terminal, size: 16, color: _accent),
                const SizedBox(width: 8),
                Text(
                  'Outils actifs (${_toolDock.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _text,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: _muted),
                  onPressed: () => setState(() => _dockOpen = false),
                  tooltip: 'Masquer',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _dockScrollController,
              padding: const EdgeInsets.all(10),
              itemCount: _toolDock.length,
              itemBuilder: (context, i) {
                final r = _toolDock[i];
                final isSandbox = r.kind == 'sandbox';
                final isBrowser = r.kind == 'browser';
                final accent = r.ok
                    ? const Color(0xFF3FB950)
                    : const Color(0xFFF85149);
                return Container(
                  key: ValueKey(r.sessionId),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _panel2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isBrowser
                                  ? Icons.public
                                  : isSandbox
                                      ? Icons.code
                                      : Icons.terminal,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                r.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                            ),
                            if (r.kind == 'terminal' ||
                                r.kind == 'sandbox' ||
                                r.kind == 'browser')
                              IconButton(
                                icon: Icon(
                                  r.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                                  size: 13,
                                  color: r.pinned ? _accent : _muted,
                                ),
                                onPressed: () => _togglePin(r),
                                tooltip: r.pinned
                                    ? 'Désépingler (nouvelle session à chaque appel)'
                                    : 'Épingler (réutiliser cette session)',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                              ),
                            if (r.kind == 'terminal' ||
                                r.kind == 'sandbox' ||
                                r.kind == 'browser')
                              IconButton(
                                icon: Icon(
                                  Icons.open_in_new,
                                  size: 13,
                                  color: _muted,
                                ),
                                onPressed: () => _detachToWindow(r),
                                tooltip: 'Ouvrir en fenêtre',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 13,
                                color: _muted,
                              ),
                              onPressed: () =>
                                  setState(() => _toolDock.removeAt(i)),
                              tooltip: 'Retirer',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 22,
                                minHeight: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (r.kind == 'browser' && r.url.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: BrowserView(
                            key: ValueKey('dock_${r.sessionId}'),
                            url: r.url,
                            height: 260,
                            sessionId: r.sessionId,
                          ),
                        )
                      else ...[
                        if (r.input.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                            child: SelectableText(
                              r.input,
                              style: TextStyle(
                                fontSize: 17,
                                color: _text,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                r.output.isEmpty
                                    ? '(aucune sortie)'
                                    : r.output,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: r.ok ? _text : accent,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- Top bar ----
  Widget _buildTopBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: _bg,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _chatTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(height: 2),
                            Text(
                              _selectedModel ??
                                  AppLocalizations.of(context)!.aura,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 17, color: _muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_toolDock.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          _dockOpen ? Icons.chevron_right : Icons.terminal,
                          size: 18,
                          color: _accent,
                        ),
                        onPressed: () => setState(() => _dockOpen = !_dockOpen),
                        tooltip: _dockOpen
                            ? 'Masquer les outils'
                            : 'Afficher les outils',
                        visualDensity: VisualDensity.compact,
                      ),
                    DropdownButton<String>(
                      value: widget.lang,
                      dropdownColor: _panel2,
                      underline: const SizedBox(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: _white70,
                      ),
                      items: _languages
                          .map(
                            (l) => DropdownMenuItem<String>(
                              value: l.$1,
                              child: Text(
                                l.$2,
                                style: TextStyle(color: _text, fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) widget.onSetLang(v);
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        widget.isDark ? Icons.brightness_4 : Icons.brightness_2,
                        size: 20,
                      ),
                      color: _white70,
                      onPressed: widget.onToggleTheme,
                      tooltip: widget.isDark
                          ? AppLocalizations.of(context)!.lightMode
                          : AppLocalizations.of(context)!.darkMode,
                    ),
                    if (isDesktop) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.minimize, size: 20),
                        color: _white70,
                        onPressed: () => desktopService.minimize(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: _white70,
                        onPressed: () => desktopService.close(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- Content area ----
  Widget _buildContent() {
    if (_messages.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _accent.withOpacity(0.25),
                    ),
                  ),
                  child: Image.asset('assets/logo.jpg'),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcome,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: _muted),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.memory,
                        size: 16,
color: _accent,
                  ),
                      const SizedBox(width: 8),
                      Text(
                        '${_models.length} ${AppLocalizations.of(context)!.models.toLowerCase()}',
                        style: TextStyle(fontSize: 18, color: _muted),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _border,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${AppLocalizations.of(context)!.core} $_version',
                        style: TextStyle(fontSize: 18, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.startWith,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _activeAgent.quickPrompts.isNotEmpty
                      ? _activeAgent.quickPrompts
                            .map(
                              (prompt) => _suggestionChip(
                                prompt,
                                Icons.flash_on_outlined,
                              ),
                            )
                            .toList()
                      : [
                          _suggestionChip(
                            AppLocalizations.of(context)!.suggestExplain,
                            Icons.lightbulb_outline,
                          ),
                          _suggestionChip(
                            AppLocalizations.of(context)!.suggestWrite,
                            Icons.edit_note,
                          ),
                          _suggestionChip(
                            AppLocalizations.of(context)!.suggestCode,
                            Icons.code,
                          ),
                        ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        return ChatMessageBubble(
          message: m,
          modelName: _selectedModel,
          colors: _palette,
          onRegenerate: () => _regenerate(index),
          onDetachTool: m.isUser ? null : (r) => _detachTool(index, r),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController
          .jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _scrollDockToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dockScrollController.hasClients) return;
      _dockScrollController
          .jumpTo(_dockScrollController.position.maxScrollExtent);
    });
  }

  Widget _suggestionChip(String label, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 17, color: _accent),
      label: Text(label, style: TextStyle(fontSize: 18, color: _text)),
      backgroundColor: _panel,
      side: BorderSide(color: _border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        _textController.text = label;
        _composerFocusNode.requestFocus();
      },
    );
  }

  // ---- Composer ----
  Widget _buildComposer() {
    return ChatComposer(
      controller: _textController,
      focusNode: _composerFocusNode,
      colors: _palette,
      reasoningEnabled: _reasoningEnabled,
      toolsEnabled: _toolsEnabled,
      toolsAvailable: _toolsAvailable,
      isGenerating: _isGenerating,
      onToggleReasoning: () => setState(
        () => _reasoningEnabled = !_reasoningEnabled,
      ),
      onToggleTools: () {
        setState(() => _toolsEnabled = !_toolsEnabled);
        _savePrefs();
      },
      onSend: _sendMessage,
      onStop: _stopGeneration,
      onAttach: _attachContext,
      attachments: _attachments,
      onRemoveAttachment: _removeAttachment,
      selectorRow: _buildSelectorRow(),
    );
  }

  Widget _buildSelector(String label, String? value, List<String> items) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        dropdownColor: _panel2,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, size: 16, color: _white70),
        borderRadius: BorderRadius.circular(8),
        isDense: true,
        menuMaxHeight: 200,
        items: items
            .map(
              (m) => DropdownMenuItem<String>(
                value: m,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(m, style: TextStyle(fontSize: 16, color: _text)),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {},
      ),
    );
  }

  void _showBanner(String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        right: 16,
        bottom: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E222C),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black26),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => entry.remove(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  List<String> get _installedModels {
    if (_modelsDir.isEmpty) return [];
    try {
      return Directory(_modelsDir)
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .where((n) => !n.toLowerCase().contains('mmproj'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static final RegExp _toolCallRe =
      RegExp(r'<tool_call[^>]*>[\s\S]*?</tool_call>', caseSensitive: false);

  String _stripToolCalls(String s) {
    var out = s.replaceAll(_toolCallRe, '');
    final open = out.toLowerCase().indexOf('<tool_call');
    if (open >= 0) out = out.substring(0, open);
    return out.trim();
  }

  String _toolInputSummary(String name, Map<String, String> args) {
    for (final k in const ['command', 'cmd', 'code', 'script', 'query',
      'queries', 'q', 'search', 'term', 'url', 'path', 'input', 'text']) {
      final v = args[k];
      if (v != null && v.trim().isNotEmpty) return v;
    }
    if (args.isEmpty) return '';
    return args.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  String _normUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'https://$u';
    }
    return u;
  }

  String? _browserSessionId() {
    if (_floating != null && _floating!.kind == 'browser') {
      return _floating!.sessionId;
    }
    final idx = _toolDock.indexWhere((d) => d.kind == 'browser');
    if (idx >= 0) return _toolDock[idx].sessionId;
    return null;
  }

  String? _extractUrl(String text) {
    final re = RegExp(
      r'(https?://[^\s)\]"' + "'" + r']+|www\.[^\s)\]"' + "'" + r']+)',
      caseSensitive: false,
    );
    final m = re.firstMatch(text);
    final u = m?.group(0)?.replaceAll(RegExp(r'[.,;]+$'), '');
    return (u == null || u.isEmpty) ? null : u;
  }

  String _toolKind(String name) {
    if (name.contains('terminal') ||
        name.contains('shell') ||
        name.contains('bash')) {
      return 'terminal';
    }
    if (name.contains('sandbox') || name.contains('python')) return 'sandbox';
    if (name.contains('browser')) return 'browser';
    if (name.contains('clipboard')) return 'clipboard';
    if (name.contains('process')) return 'process';
    if (name.contains('fs_list') || name.contains('file')) return 'fs';
    return 'other';
  }

  String _dockContext() {
    final pinned = _pinned.entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    final recent = _toolDock
        .where((r) => r.kind == 'terminal' || r.kind == 'sandbox')
        .take(6)
        .toList();
    if (pinned.isEmpty && recent.isEmpty) return '';
    final b = StringBuffer();
    b.writeln('\nSessions d\'outils DANS LE DOCK (tu peux les voir et les '
        'réutiliser réellement) :');
    for (final e in pinned) {
      b.writeln('- ${e.key} ÉPINGLÉ, session="${e.value}" : réutilise-la en '
          'passant {"session":"${e.value}"} dans args (même session, ne recrée '
          'pas de nouvelle fenêtre).');
    }
    for (final r in recent) {
      if (pinned.any((e) => e.value == r.sessionId)) continue;
      b.writeln('- ${r.kind} session="${r.sessionId}" (non épinglée) : '
          'requête: ${_oneLine(r.input, 80)}');
    }
    b.writeln('Si une session est épinglée, utilise TOUJOURS son "session" '
        'pour la suite des commandes de ce type.');
    return b.toString();
  }

  String _oneLine(String s, int max) {
    final t = s.replaceAll('\n', ' ').trim();
    return t.length > max ? '${t.substring(0, max)}…' : t;
  }

  void _detachTool(int messageIndex, ToolRun run) {
    setState(() {
      final msg = _messages[messageIndex];
      final remaining = msg.toolRuns.where((r) => r != run).toList();
      _messages[messageIndex] = ChatMessage(
        isUser: msg.isUser,
        text: msg.text,
        tokensPerSec: msg.tokensPerSec,
        toolRuns: remaining,
      );
      if (!_toolDock.contains(run)) _toolDock.add(run);
      _dockOpen = true;
    });
  }

  void _detachToWindow(ToolRun run) {
    setState(() {
      _floating = run;
      _toolDock.removeWhere((d) => d.sessionId == run.sessionId);
    });
  }

  void _redockFloating() {
    final run = _floating;
    if (run == null) return;
    setState(() {
      if (!_toolDock.any((d) => d.sessionId == run.sessionId)) {
        _toolDock.add(run);
      }
      _floating = null;
      _dockOpen = true;
    });
    _scrollDockToBottom();
  }

  void _togglePin(ToolRun run) {
    if (run.kind != 'terminal' &&
        run.kind != 'sandbox' &&
        run.kind != 'browser') {
      return;
    }
    setState(() {
      if (_pinned[run.kind] == run.sessionId) {
        _pinned.remove(run.kind);
      } else {
        _pinned[run.kind] = run.sessionId;
      }
      for (var i = 0; i < _toolDock.length; i++) {
        final d = _toolDock[i];
        _toolDock[i] = ToolRun(
          name: d.name,
          input: d.input,
          output: d.output,
          ok: d.ok,
          kind: d.kind,
          sessionId: d.sessionId,
          pinned: _pinned[d.kind] == d.sessionId && d.sessionId.isNotEmpty,
          url: d.url,
        );
      }
      for (var i = 0; i < _messages.length; i++) {
        final m = _messages[i];
        if (m.toolRuns.isEmpty) continue;
        _messages[i] = ChatMessage(
          isUser: m.isUser,
          text: m.text,
          tokensPerSec: m.tokensPerSec,
          toolRuns: m.toolRuns
              .map(
                (r) => ToolRun(
                  name: r.name,
                  input: r.input,
                  output: r.output,
                  ok: r.ok,
                  kind: r.kind,
                  sessionId: r.sessionId,
                  pinned: _pinned[r.kind] == r.sessionId && r.sessionId.isNotEmpty,
                  url: r.url,
                ),
              )
              .toList(),
        );
      }
    });
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final imagePaths = _attachments.where(_isImagePath).toList();
    final prompt = await _buildPromptWithContext(text);
    final history = _messages
        .where(
          (m) =>
              m.text.trim().isNotEmpty &&
              !m.text.startsWith('Error:') &&
              m.text != 'Model not installed.',
        )
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();
    setState(() => _messages.add(ChatMessage(isUser: true, text: text)));
    _textController.clear();
    if (_attachments.isNotEmpty) setState(() => _attachments.clear());
    _scrollToBottom();

    final modelIndex = _messages.length;
    setState(() => _messages.add(ChatMessage(isUser: false, text: '')));
    _scrollToBottom();
    _cancelRequested = false;
    setState(() => _isGenerating = true);

    Future<void> streamInto(
      LlamaServerProcess server, {
      String? promptOverride,
      List<Map<String, String>>? historyOverride,
      int depth = 0,
      List<ToolRun>? runs,
    }) async {
      runs ??= <ToolRun>[];
      String? lastToolOutput;
      String lastToolKind = '';
      final effPrompt = promptOverride ?? prompt;
      final effHistory = historyOverride ?? history;
      String sys = _activeAgent.systemPrompt;
      if (_toolsEnabled && depth < 3) {
        final all = await ExtensionStore.load();
        final tools = all
            .where((e) => e.kind == ExtensionKind.tool && e.enabled)
            .toList();
        final skills = all
            .where((e) => e.kind == ExtensionKind.skill && e.enabled)
            .toList();
        final mcpServers = all
            .where((e) => e.kind == ExtensionKind.mcp && e.enabled)
            .toList();
        final mcpTools = await _startMcpAndListTools(mcpServers);
        if (tools.isNotEmpty || skills.isNotEmpty || mcpTools.isNotEmpty) {
          sys = ToolRunner.buildSystemPrompt(
            _activeAgent.systemPrompt,
            tools: tools,
            skills: skills,
            mcpTools: mcpTools,
          );
          final dock = _dockContext();
          if (dock.isNotEmpty) sys = '$sys\n$dock';
          final probe = await server.generate(
            effPrompt,
            maxTokens: int.tryParse(_maxTokens) ?? 512,
            reasoning: _reasoningEnabled,
            systemPrompt: sys,
            history: effHistory,
          );
          var call = ToolRunner.extractToolCall(probe);
          if (call == null && depth == 0) {
            final detected = _extractUrl(probe);
            if (detected != null) {
              call = (name: 'tool_browser', args: {'url': detected});
              AppLogger.info('FALLBACK browser url=$detected');
            }
          }
          AppLogger.info(
              'PROBE call=${call?.name} args=${call?.args} text=${probe.replaceAll('\n', ' ').substring(0, probe.length > 160 ? 160 : probe.length)}');
          if (call != null) {
            _showBanner('Outil: ${call.name}...');
            final kind = _toolKind(call.name);
            final pinnedSession = _pinned[kind];
            final sessionId = kind == 'browser'
                ? (_browserSessionId() ??
                    's_${DateTime.now().microsecondsSinceEpoch}')
                : (pinnedSession ?? 's_${DateTime.now().microsecondsSinceEpoch}');
            final callArgs = <String, String>{
              ...call.args,
              if (kind == 'terminal' || kind == 'sandbox' || kind == 'browser')
                'session': sessionId,
            };
            final res = await _executeToolCall(call.name, callArgs);
            AppLogger.info(
                'TOOL ${call.name} ok=${res.ok} out=${res.output.replaceAll('\n', ' ').substring(0, res.output.length > 200 ? 200 : res.output.length)}');
            final inputSummary = _toolInputSummary(call.name, call.args);
            lastToolOutput = res.output;
            lastToolKind = kind;

            if (kind == 'browser') {
              final url = _normUrl(call.args['url'] ?? '');
              if (_floating != null && _floating!.kind == 'browser') {
                _floating = ToolRun(
                  name: call.name,
                  input: inputSummary,
                  output: res.output,
                  ok: res.ok,
                  kind: 'browser',
                  sessionId: _floating!.sessionId,
                  pinned: true,
                  url: url.isNotEmpty ? url : _floating!.url,
                );
              } else {
                final idx = _toolDock.indexWhere((d) => d.kind == 'browser');
                if (idx >= 0) {
                  final prev = _toolDock[idx];
                  _toolDock[idx] = ToolRun(
                    name: prev.name,
                    input: inputSummary,
                    output: res.output,
                    ok: res.ok,
                    kind: 'browser',
                    sessionId: prev.sessionId,
                    pinned: true,
                    url: url.isNotEmpty ? url : prev.url,
                  );
                } else {
                  _toolDock.add(ToolRun(
                    name: call.name,
                    input: inputSummary,
                    output: res.output,
                    ok: res.ok,
                    kind: 'browser',
                    sessionId: sessionId,
                    pinned: true,
                    url: url,
                  ));
                }
              }
              _dockOpen = true;
              setState(() {});
              _scrollDockToBottom();
            } else {
              final reusedIndex =
                  _toolDock.indexWhere((d) => d.sessionId == sessionId);
              final reusable = pinnedSession != null && reusedIndex >= 0;
              if (reusable) {
                final prev = _toolDock[reusedIndex];
                _toolDock[reusedIndex] = ToolRun(
                  name: prev.name,
                  input: '${prev.input}\n\n> $inputSummary',
                  output: '${prev.output}\n\n${res.output}',
                  ok: res.ok,
                  kind: prev.kind,
                  sessionId: prev.sessionId,
                  pinned: true,
                  url: prev.url,
                );
                _dockOpen = true;
                setState(() {});
                _scrollDockToBottom();
              } else {
                runs.add(
                  ToolRun(
                    name: call.name,
                    input: inputSummary,
                    output: res.output,
                    ok: res.ok,
                    kind: kind,
                    sessionId: sessionId,
                    pinned: pinnedSession != null,
                  ),
                );
                if (modelIndex < _messages.length) {
                  _messages[modelIndex] = ChatMessage(
                    isUser: false,
                    text: _messages[modelIndex].text,
                    toolRuns: List.of(runs),
                  );
                  setState(() {});
                  _scrollToBottom();
                }
              }
            }
            final nextHistory = [
              ...effHistory,
              {'role': 'assistant', 'content': probe},
              {
                'role': 'user',
                'content':
                    'Résultat de ${call.name}:\n${res.output}\n'
                    'Utilise ce résultat pour répondre à l\'utilisateur.',
              },
            ];
            await streamInto(
              server,
              promptOverride: '',
              historyOverride: nextHistory,
              depth: depth + 1,
              runs: runs,
            );
            return;
          }
        }
      }
      final result = await server.generateStream(
        effPrompt,
        maxTokens: int.tryParse(_maxTokens) ?? 512,
        reasoning: _reasoningEnabled,
        systemPrompt: sys,
        history: effHistory,
        images: imagePaths,
        onDelta: (delta) {
          if (_cancelRequested) return;
          if (modelIndex >= _messages.length) return;
          _messages[modelIndex] = ChatMessage(
            isUser: false,
            text: _messages[modelIndex].text + delta,
            toolRuns: runs,
          );
          setState(() {});
          _scrollToBottom();
        },
      );
      if (_cancelRequested) {
        setState(() => _isGenerating = false);
        return;
      }
      final resultText = _stripToolCalls(result.text);
      final elapsedMs = result.elapsedMs;
      final completionTokens = result.completionTokens;
      final elapsed = elapsedMs / 1000.0;
      final tokens = completionTokens ??
          resultText.split(RegExp(r"\s+")).where((e) => e.isNotEmpty).length;
      final tps = elapsed > 0 ? tokens / elapsed : 0.0;
      if (_selectedModel != null) {
        ModelMetricsStore.record(
          model: _selectedModel!,
          kind: _selectedProvider,
          tps: tps,
          tokens: tokens,
          elapsedMs: elapsedMs,
          available: true,
        );
      }
      if (modelIndex < _messages.length) {
        var finalText = resultText;
        if (finalText.isEmpty && lastToolOutput != null) {
          final label = lastToolKind == 'sandbox'
              ? 'Le code a été exécuté'
              : 'La commande a été exécutée';
          final o = lastToolOutput!;
          final tail = o.isEmpty
              ? ''
              : '\n\n```\n${o.length > 1500 ? o.substring(0, 1500) + '…' : o}\n```';
          finalText = '$label. Voir la sortie ci-dessus.$tail';
        }
        _messages[modelIndex] = ChatMessage(
          isUser: false,
          text: finalText,
          tokensPerSec: tps,
          toolRuns: runs,
        );
      }
      setState(() {});
      _scrollToBottom();
      setState(() => _isGenerating = false);
    }

    final server = _multiServers[_selectedModel];
    if (server != null && server.isRunning) {
      try {
        await streamInto(server);
      } catch (e) {
        _setMessageText(modelIndex, "Error: $e");
        _showBanner("Error: $e");
      }
      setState(() => _isGenerating = false);
      _saveChats();
      return;
    }
    if (server != null && server.isSleeping) {
      _showBanner("Réveil de $_selectedModel...");
      final ok = await server.ensureStarted();
      if (ok) {
        _loadedModels.add(_selectedModel!);
        _savePrefs();
        try {
          await streamInto(server);
        } catch (e) {
          _setMessageText(modelIndex, "Error: $e");
          _showBanner("Error: $e");
        }
        setState(() => _isGenerating = false);
        _saveChats();
        return;
      }
    }

    if (_selectedModel == null) {
      setState(() => _isGenerating = false);
      _setMessageText(modelIndex, "Aucun modèle sélectionné.");
      _showBanner("Sélectionnez un modèle avant de générer.");
      return;
    }

    final modelPath = "$_modelsDir${Platform.pathSeparator}$_selectedModel";
    final modelExists =
        _modelsDir.isNotEmpty && File(modelPath).existsSync();
    final serverKnown = _multiServers.containsKey(_selectedModel);
    if (!modelExists && !serverKnown) {
      setState(() => _isGenerating = false);
      _setMessageText(modelIndex, "Model not installed.");
      _showBanner("Model not installed. Téléchargez-le d'abord.");
      return;
    }
    _showBanner("Starting llama_server.exe for $_selectedModel...");
    final meta = _serverMeta[_selectedModel] ??
        _ServerMeta(
          id: _nextServerId++,
          port: 64100 + _nextServerId * 7,
          model: _selectedModel!,
          mmproj: DownloadManager.instance.mmprojFor(_selectedModel!),
        );
    _serverMeta[_selectedModel!] = meta;
    final newServer = LlamaServerProcess(
      idleMinutes: int.tryParse(_idleMinutes) ?? 5,
      gpuVendor: _gpuVendor,
      serverId: meta.id,
    );
    newServer.fixedPort = meta.port;
    _multiServers[_selectedModel!] = newServer;
    setState(() => _multiStatus[_selectedModel!] = "Loading...");
    try {
      final mmproj = meta.mmproj;
      await newServer.start(
        modelPath,
        mmprojPath: mmproj,
        port: meta.port,
      );
      _serverMeta[_selectedModel!] = _ServerMeta(
        id: meta.id,
        port: meta.port,
        model: meta.model,
        mmproj: meta.mmproj,
        pid: newServer.pid,
      );
      setState(() => _multiStatus[_selectedModel!] = "Ready (VRAM)");
      _loadedModels.add(_selectedModel!);
      _savePrefs();
      ModelMetricsStore.record(
        model: _selectedModel!,
        kind: 'local',
        available: true,
      );
    } catch (e) {
      _multiServers.remove(_selectedModel);
      _loadedModels.remove(_selectedModel);
      _serverMeta.remove(_selectedModel);
      setState(() => _multiStatus[_selectedModel!] = "Error: $e");
      ModelMetricsStore.record(
        model: _selectedModel!,
        kind: 'local',
        available: false,
      );
      _showBanner("Failed to start server: $e");
      _setMessageText(modelIndex, "Failed to load model: $e");
      setState(() => _isGenerating = false);
      return;
    }
    try {
      await streamInto(newServer);
    } catch (e) {
      _setMessageText(modelIndex, "Error: $e");
      _showBanner("Error: $e");
    }
    setState(() => _isGenerating = false);
    _saveChats();
    _savePrefs();
  }

  void _stopGeneration() {
    _cancelRequested = true;
    for (final server in _multiServers.values) {
      server.cancelGeneration();
    }
    setState(() => _isGenerating = false);
  }

  void _attachContext() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image_outlined, color: _white70),
                title: Text('Image', style: TextStyle(color: _text)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAttachment(FileType.image);
                },
              ),
              ListTile(
                leading: Icon(Icons.attach_file, color: _white70),
                title: Text('Fichier', style: TextStyle(color: _text)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAttachment(FileType.any);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment(FileType type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowMultiple: true,
      );
      if (result == null) return;
      final paths = result.paths.whereType<String>().toList();
      if (paths.isEmpty) return;
      setState(() => _attachments.addAll(paths));
      _showBanner('${paths.length} contexte(s) ajouté(s)');
    } catch (e) {
      _showBanner('Échec de la sélection: $e');
    }
  }

  void _removeAttachment(int index) {
    if (index < 0 || index >= _attachments.length) return;
    setState(() => _attachments.removeAt(index));
  }

  static const Set<String> _imageExts = {
    'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp',
  };

  bool _isImagePath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return _imageExts.contains(ext);
  }

  Future<String> _buildPromptWithContext(String text) async {
    if (_attachments.isEmpty) return text;
    final buffer = StringBuffer();
    for (final path in _attachments) {
      if (_isImagePath(path)) continue;
      final name = path.split(Platform.pathSeparator).last;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      const textExts = {
        'txt', 'md', 'json', 'csv', 'log', 'yaml', 'yml', 'xml', 'html',
        'css', 'js', 'ts', 'py', 'rs', 'dart', 'java', 'c', 'cpp', 'h',
        'hpp', 'go', 'rb', 'php', 'sh', 'ps1', 'ini', 'toml', 'sql',
      };
      if (textExts.contains(ext)) {
        try {
          final content = await File(path).readAsString();
          buffer.writeln('--- Fichier: $name ---');
          buffer.writeln(content);
          buffer.writeln('--- Fin: $name ---');
          continue;
        } catch (_) {}
      }
      buffer.writeln('[Pièce jointe: $name]');
    }
    buffer.writeln();
    buffer.write(text);
    return buffer.toString();
  }

  void _setMessageText(int index, String text) {
    if (index < 0 || index >= _messages.length) return;
    _messages[index] = ChatMessage(isUser: false, text: text);
    setState(() {});
    _scrollToBottom();
  }

  void _resetServerCaches() {
    for (final server in _multiServers.values) {
      server.resetCache();
    }
  }

  void _newChat() {
    _resetServerCaches();
    ToolRunner.resetSessions();
    setState(() {
      _chatMessages[_currentChat] = List.of(_messages);
      _messages.clear();
      _toolDock.clear();
      _pinned.clear();
      _chatTitles.add('Chat ${_chatTitles.length + 1}');
      _currentChat = _chatTitles.length - 1;
      _textController.clear();
    });
    _savePrefs();
    _saveChats();
  }

  void _switchChat(int index) {
    if (index == _currentChat) return;
    _resetServerCaches();
    setState(() {
      _chatMessages[_currentChat] = List.of(_messages);
      _currentChat = index;
      _messages
        ..clear()
        ..addAll(_chatMessages[index] ?? []);
    });
  }

  void _deleteChat(int index) {
    setState(() {
      _chatMessages.remove(index);
      final newMap = <int, List<ChatMessage>>{};
      _chatMessages.forEach((k, v) {
        if (k < index) {
          newMap[k] = v;
        } else if (k > index) {
          newMap[k - 1] = v;
        }
      });
      _chatMessages
        ..clear()
        ..addAll(newMap);
      _chatTitles.removeAt(index);
      if (_currentChat > index) _currentChat--;
      if (_currentChat >= _chatTitles.length)
        _currentChat = _chatTitles.length - 1;
      if (_chatTitles.isEmpty) {
        _chatTitles.add(AppLocalizations.of(context)!.newChat);
        _currentChat = 0;
      }
      _messages
        ..clear()
        ..addAll(_chatMessages[_currentChat] ?? []);
    });
    _saveChats();
  }

  Future<void> _renameChat(int index) async {
    final controller = TextEditingController(text: _chatTitles[index]);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: Text(
          AppLocalizations.of(context)!.renameChat,
          style: TextStyle(color: _text),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: _text),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.chatTitle,
            hintStyle: TextStyle(color: _muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: _muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
            ),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty) {
      setState(() => _chatTitles[index] = newTitle);
      _saveChats();
    }
  }

  void _regenerate(int index) {
    if (index <= 0) return;
    final userMsg = _messages[index - 1];
    if (!userMsg.isUser) return;
    _resetServerCaches();
    setState(() {
      if (index < _messages.length) {
        _messages.removeAt(index);
      }
    });
    _textController.text = userMsg.text;
    _sendMessage();
  }

  Future<void> _openStats() async {
    final stats = await ModelMetricsStore.recent();
    if (!mounted) return;
    showModelStatsModal(context, stats: stats, colors: _palette);
  }

  Future<List<McpTool>> _startMcpAndListTools(
    List<ExtensionItem> servers,
  ) async {
    final result = <McpTool>[];
    for (final s in servers) {
      final client = _mcpClients[s.id] ??= McpClient(
        command: s.config['command'] ?? '',
        env: s.config['token'] != null
            ? {'GITHUB_TOKEN': s.config['token']!}
            : const {},
      );
      try {
        if (!client.isReady && (s.config['command'] ?? '').isNotEmpty) {
          await client.start();
        }
        if (client.isReady) {
          for (final t in await client.listTools()) {
            result.add(McpTool(
              name: ToolRunner.mcpName(s.id, t.name),
              description: t.description,
              inputSchema: t.inputSchema,
            ));
          }
        }
      } catch (_) {}
    }
    return result;
  }

  Future<ToolResult> _executeToolCall(
    String name,
    Map<String, String> args,
  ) async {
    final mcp = ToolRunner.parseMcpName(name);
    if (mcp != null) {
      final client = _mcpClients[mcp.serverId];
      if (client == null || !client.isReady) {
        return ToolResult(false, 'Serveur MCP indisponible: ${mcp.serverId}');
      }
      final out = await client.callTool(mcp.tool, args);
      return ToolResult(true, out);
    }
    return ToolRunner.execute(name, args);
  }

  void _openSettings() {
    _downloads.configure(showBanner: _showBanner);
    final downloads = _downloads;
    final appearance =
        AppearanceScope.of(context) ?? const AppearanceSettings();
    showDialog(
      context: context,
      builder: (_) => SettingsShell(
        languages: _languages,
        themeProfile: widget.themeProfile,
        lang: widget.lang,
        version: _version,
        models: _models,
        hardware: _hardware,
        modelsDir: _modelsDir,
        idleMinutes: _idleMinutes,
        multiServers: _multiServers,
        multiStatus: _multiStatus,
        showBanner: _showBanner,
        onThemeProfileChanged: widget.onThemeProfileChanged,
        onSetLang: widget.onSetLang,
        onModelsDirChanged: (v) {
          setState(() => _modelsDir = v);
          _savePrefs();
        },
        onIdleMinutesChanged: (v) {
          setState(() => _idleMinutes = v);
          _savePrefs();
        },
        appearance: appearance,
        onAppearanceChanged: widget.onAppearanceChanged,
        downloads: downloads,
        agents: _agents,
        onAgentsChanged: _updateAgents,
      ),
    ).then((_) {
      _reloadCloudProviders();
      _refreshToolsAvailability();
    });
  }

  // ---- Android / Desktop platform check ----
  bool get isDesktop => kIsWeb
      ? false
      : (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // ---- Bottom-anchored selector row ----
  Widget _buildSelectorRow() {
    final l = AppLocalizations.of(context)!;
    final agent = _agents.firstWhere(
      (a) => a.id == _selectedAgent,
      orElse: () => _agents.first,
    );
    final isCloud = _selectedProvider == 'cloud';
    final cloudModels = <String>[];
    for (final p in _cloudProviders) {
      if (p.enabled) cloudModels.addAll(p.models);
    }
    final localModels = <String>{
      ..._multiServers.keys.where((m) => _multiServers[m]?.isRunning == true),
    };
    final modelItems = isCloud ? cloudModels : localModels.toList();
    final modelValue =
        (_selectedModel != null && modelItems.contains(_selectedModel))
            ? _selectedModel
            : (modelItems.isNotEmpty ? modelItems.first : null);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChip(
          tooltip: agent.name,
          onTap: () => _showDropdownMenu(
            l.agent,
            _selectedAgent,
            _agents.map((a) => a.id).toList(),
            (value) {
              setState(() => _selectedAgent = value!);
              _savePrefs();
            },
            {for (final a in _agents) a.id: a.name},
          ),
          child: Text(
            agent.name.isNotEmpty ? agent.name.substring(0, 1).toUpperCase() : '?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _white70,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildChip(
          tooltip: l.provider,
          onTap: () => _showDropdownMenu(
            l.provider,
            _selectedProvider,
            ['local', 'cloud'],
            (value) {
              setState(() {
                _selectedProvider = value!;
                _selectedModel = null;
              });
              _savePrefs();
            },
            const {},
          ),
          child: isCloud
              ? Icon(Icons.cloud_outlined, size: 18, color: _white70)
              : Text(
                  '*',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _white70,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        _buildChip(
          tooltip: l.model,
          onTap: () => _showDropdownMenu(
            l.model,
            modelValue,
            modelItems,
            (value) {
              setState(() {
                _selectedModel = value;
                _engineModelId = null;
                if (_session != null) {
                  auraSessionDispose(_session!);
                  _session = null;
                }
                if (_engine != null) {
                  auraEngineDispose(_engine!);
                  _engine = null;
                }
              });
              _savePrefs();
            },
            const {},
            itemCaps: {
              for (final m in modelItems) m: _capsForModel(m, isCloud),
            },
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  modelValue ?? l.select,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, color: _text),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down, size: 16, color: _white70),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: child,
        ),
      ),
    );
  }

  // Bouton avec menu déroulant qui s'affiche en bas du champ
  Widget _buildBottomAnchoredSelector({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Map<String, String> itemLabels = const {},
  }) {
    return InkWell(
      onTap: () =>
          _showDropdownMenu(label, value, items, onChanged, itemLabels),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _panel2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 16, color: _muted)),
            const SizedBox(width: 4),
            Text(
              value == null
                  ? AppLocalizations.of(context)!.select
                  : itemLabels[value] ?? value,
              style: TextStyle(fontSize: 16, color: _text),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 16, color: _white70),
          ],
        ),
      ),
    );
  }

  // Méthode pour afficher le menu déroulant ancré en bas (style Android)
  ModelCaps _capsForModel(String name, bool isCloud) {
    if (isCloud) return const ModelCaps();
    final n = name.toLowerCase();
    final vision = DownloadManager.instance.isVision(name);
    final tools = n.contains('tool') || n.contains('function');
    final thinking = n.contains('think') ||
        n.contains('reason') ||
        n.contains('r1') ||
        n.contains('qwq');
    return ModelCaps(vision: vision, tools: tools, thinking: thinking);
  }

  void _showDropdownMenu(
    String label,
    String? currentValue,
    List<String> items,
    ValueChanged<String?> onChanged,
    Map<String, String> itemLabels, {
    Map<String, ModelCaps> itemCaps = const {},
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _panel2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _text,
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (String item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: InkWell(
                    onTap: () {
                      onChanged(item);
                      Navigator.of(bottomSheetContext).pop();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _selectedModel == item ||
                                _selectedProvider == item ||
                                _selectedAgent == item
                            ? _accent
                            : _panel,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              itemLabels[item] ?? item,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          if (itemCaps[item] != null &&
                              itemCaps[item]!.any) ...[
                            const SizedBox(width: 8),
                            CapabilityIcons(
                              caps: itemCaps[item]!,
                              colors: SettingsColors.fromProfile(
                                widget.themeProfile,
                              ),
                              size: 15,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Bouton "Annuler" en bas
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  child: Text(
                    AppLocalizations.of(context)!.close,
                    style: TextStyle(color: _muted, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
