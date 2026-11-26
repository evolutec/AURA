import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'llama_server.dart';
import 'l10n/app_localizations.dart';
import 'Parametres/Parametres/settings_colors.dart';
import 'Parametres/Parametres/appearance.dart';
import 'Parametres/Parametres/page_settings.dart';
import 'Parametres/CloudProviders/page_cloud.dart';
import 'Parametres/LocalModels/page_local_models.dart';
import 'Parametres/Agents/page_agents.dart';
import 'Parametres/Agents/agent_profile.dart';
import 'Parametres/Extensions/page_extensions.dart';
import 'Parametres/Extensions/extension_item.dart';
import 'Parametres/Device/page_device.dart';
import 'Parametres/LLMServer/page_server.dart';
import 'Parametres/page_stats.dart';
import 'Parametres/About/page_about.dart';
import 'Parametres/LocalModels/catalogue_modal.dart';
import 'Parametres/download_state.dart' show DownloadManager;

class SettingsShell extends StatefulWidget {
  const SettingsShell({
    super.key,
    required this.languages,
    required this.themeProfile,
    required this.lang,
    required this.version,
    required this.models,
    required this.hardware,
    required this.modelsDir,
    required this.idleMinutes,
    required this.multiServers,
    required this.multiStatus,
    required this.showBanner,
    required this.onThemeProfileChanged,
    required this.onSetLang,
    required this.onModelsDirChanged,
    required this.onIdleMinutesChanged,
    required this.appearance,
    required this.onAppearanceChanged,
    required this.downloads,
    required this.agents,
    required this.onAgentsChanged,
  });

  final List<(String, String)> languages;
  final int themeProfile;
  final String lang;
  final String version;
  final List<dynamic> models;
  final Map<String, dynamic> hardware;
  final String modelsDir;
  final String idleMinutes;
  final Map<String, LlamaServerProcess> multiServers;
  final Map<String, String> multiStatus;
  final ValueChanged<String> showBanner;
  final ValueChanged<int> onThemeProfileChanged;
  final ValueChanged<String> onSetLang;
  final ValueChanged<String> onModelsDirChanged;
  final ValueChanged<String> onIdleMinutesChanged;
  final AppearanceSettings appearance;
  final ValueChanged<AppearanceSettings> onAppearanceChanged;
  final DownloadManager downloads;
  final List<AgentProfile> agents;
  final Future<void> Function(List<AgentProfile>) onAgentsChanged;

  @override
  State<SettingsShell> createState() => _SettingsShellState();
}

class _SettingsShellState extends State<SettingsShell> {
  late int _themeProfile;
  late String _lang;

  bool get _isDark => kThemeProfiles[_themeProfile].isDark;
  late String _modelsDir;
  late String _idleMinutes;
  late AppearanceSettings _appearance;
  late List<AgentProfile> _agents;

  String _selectedCategory = 'settings';

  final Map<String, Map<String, String>> _modelConfigs = {};

  @override
  void initState() {
    super.initState();
    _themeProfile = widget.themeProfile;
    _lang = widget.lang;
    _modelsDir = widget.modelsDir;
    _idleMinutes = widget.idleMinutes;
    _appearance = widget.appearance;
    _agents = List.of(widget.agents);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SettingsColors.fromProfile(_themeProfile);
    final screenSize = MediaQuery.sizeOf(context);
    return AppearanceScope(
      settings: _appearance,
      child: SettingsColorsScope(
        colors: palette,
        child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: screenSize.width < 1200 ? screenSize.width * 0.94 : 1200,
          height: screenSize.height < 900 ? screenSize.height * 0.92 : 900,
          child: Container(
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                _buildHeader(palette),
                Expanded(
                  child: Row(
                    children: [
                      _buildSidebar(palette),
                      Expanded(child: _buildContent(palette)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader(SettingsColors colors) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 30),
          const Icon(Icons.tune, size: 17, color: Color(0xFF9B7BFF)),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.settingsHub,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(SettingsColors colors) {
    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: colors.panel2,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Material(
        color: Colors.transparent,
        child: SizedBox.expand(
          child: Column(children: [Expanded(child: _buildMenuItems(colors))]),
        ),
      ),
    );
  }

  Widget _buildMenuItems(SettingsColors colors) {
    final items = [
      {
        'icon': Icons.cloud,
        'label': AppLocalizations.of(context)!.cloudProviders,
        'id': 'cloud',
      },
      {
        'icon': Icons.file_download,
        'label': AppLocalizations.of(context)!.localModels,
        'id': 'local',
      },
      {
        'icon': Icons.smart_toy,
        'label': AppLocalizations.of(context)!.agents,
        'id': 'agents',
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Skills',
        'id': 'skills',
      },
      {
        'icon': Icons.build,
        'label': 'Outils',
        'id': 'tools',
      },
      {
        'icon': Icons.hub,
        'label': 'MCP',
        'id': 'mcp',
      },
      {
        'icon': Icons.devices,
        'label': AppLocalizations.of(context)!.device,
        'id': 'device',
      },
      {
        'icon': Icons.dns,
        'label': AppLocalizations.of(context)!.server,
        'id': 'server',
      },
      {
        'icon': Icons.bar_chart,
        'label': AppLocalizations.of(context)!.stats,
        'id': 'stats',
      },
      {
        'icon': Icons.tune,
        'label': AppLocalizations.of(context)!.settings,
        'id': 'settings',
      },
      {
        'icon': Icons.info_outline,
        'label': AppLocalizations.of(context)!.about,
        'id': 'about',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final cat = items[index];
        final isSelected = _selectedCategory == cat['id'];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: ListTile(
            leading: Icon(
              cat['icon'] as IconData,
              color: isSelected ? Color(0xFF9B7BFF) : colors.white70,
              size: 19,
            ),
            title: Text(
              cat['label'] as String,
              style: TextStyle(
                color: isSelected ? Color(0xFF9B7BFF) : colors.text,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            selectedTileColor: colors.accent.withOpacity(_isDark ? 0.12 : 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minTileHeight: 44,
            onTap: () =>
                setState(() => _selectedCategory = cat['id'] as String),
          ),
        );
      },
    );
  }

  Widget _buildContent(SettingsColors colors) {
    switch (_selectedCategory) {
      case 'settings':
        return SettingsPage(
          themeProfile: _themeProfile,
          lang: _lang,
          version: widget.version,
          appearance: _appearance,
          languages: widget.languages,
          onThemeProfileChanged: (value) {
            setState(() => _themeProfile = value);
            widget.onThemeProfileChanged(value);
          },
          onSetLang: (value) {
            setState(() => _lang = value);
            widget.onSetLang(value);
          },
          onAppearanceChanged: (value) {
            setState(() => _appearance = value);
            widget.onAppearanceChanged(value);
          },
        );
      case 'cloud':
        return const CloudPage();
      case 'local':
        return LocalModelsPage(
          modelsDir: _modelsDir,
          idleMinutes: int.tryParse(_idleMinutes) ?? 5,
          hardware: widget.hardware,
          multiServers: widget.multiServers,
          multiStatus: widget.multiStatus,
          onModelsDirChanged: (value) {
            setState(() => _modelsDir = value);
            widget.onModelsDirChanged(value);
          },
          onIdleMinutesChanged: widget.onIdleMinutesChanged,
          showBanner: widget.showBanner,
          onOpenCatalogue: _showCatalogueModal,
          downloads: widget.downloads,
          onConfigureModel: _configureModel,
          onDeleteModelFile: _deleteModelFile,
        );
      case 'agents':
        return AgentsPage(agents: _agents, onChanged: _updateAgents);
      case 'skills':
        return const PageExtensions(
          kind: ExtensionKind.skill,
          title: 'Skills',
          icon: Icons.auto_awesome,
        );
      case 'tools':
        return const PageExtensions(
          kind: ExtensionKind.tool,
          title: 'Outils',
          icon: Icons.build,
        );
      case 'mcp':
        return const PageExtensions(
          kind: ExtensionKind.mcp,
          title: 'MCP',
          icon: Icons.hub,
        );
      case 'device':
        return DevicePage(hardware: widget.hardware);
      case 'server':
        return ServerPage(onStartServer: () {});
      case 'stats':
        return StatsPage(
          version: widget.version,
          models: widget.models,
          hardware: widget.hardware,
        );
      case 'about':
        return const AboutPage();
      default:
        return _buildPlaceholder(_selectedCategory);
    }
  }

  Widget _buildPlaceholder(String label) {
    final colors = SettingsColors.fromProfile(_themeProfile);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 48, color: colors.muted),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(fontSize: 16, color: colors.muted)),
        ],
      ),
    );
  }

  Future<void> _updateAgents(List<AgentProfile> agents) async {
    setState(() => _agents = agents);
    await widget.onAgentsChanged(agents);
  }

  // Download management (stays in shell per task requirements)

  void _deleteModelFile(String name) {
    final path = '$_modelsDir${Platform.pathSeparator}$name';
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
      setState(() {});
      widget.showBanner('Deleted $name');
    } catch (e) {
      widget.showBanner('Failed to delete $name: $e');
    }
  }

  void _configureModel(String name) {
    final colors = SettingsColors.fromProfile(_themeProfile);
    final config =
        _modelConfigs[name] ??
        {'context': '2048', 'temperature': '0.7', 'maxTokens': '512'};
    final contextController = TextEditingController(text: config['context']);
    final temperatureController = TextEditingController(
      text: config['temperature'],
    );
    final maxTokensController = TextEditingController(
      text: config['maxTokens'],
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.panel,
        title: Text(
          '${AppLocalizations.of(context)!.configureModel} $name',
          style: TextStyle(color: colors.text),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: contextController,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.contextSize,
                labelStyle: TextStyle(color: colors.muted),
              ),
            ),
            TextField(
              controller: temperatureController,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.temperature,
                labelStyle: TextStyle(color: colors.muted),
              ),
            ),
            TextField(
              controller: maxTokensController,
              style: TextStyle(color: colors.text),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.maxTokens,
                labelStyle: TextStyle(color: colors.muted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: colors.muted),
            ),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _modelConfigs[name] = {
                  'context': contextController.text,
                  'temperature': temperatureController.text,
                  'maxTokens': maxTokensController.text,
                };
              });
              Navigator.pop(dialogContext);
              widget.showBanner('Configuration saved for $name');
            },
            style: FilledButton.styleFrom(backgroundColor: colors.accent),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    ).then((_) {
      contextController.dispose();
      temperatureController.dispose();
      maxTokensController.dispose();
    });
  }

  // Catalogue modal (calls showDialog, stays in shell)

  void _showCatalogueModal() {
    final colors = SettingsColors.fromProfile(_themeProfile);
    showDialog(
      context: context,
      builder: (ctx) => SettingsColorsScope(
        colors: colors,
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(ctx)!.catalogue,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.downloads,
                  builder: (context, _) => CatalogueModal(
                    models: widget.models,
                    downloads: widget.downloads,
                    modelsDir: _modelsDir,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
