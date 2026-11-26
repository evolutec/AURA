// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get newChat => 'New chat';

  @override
  String get chat => 'Chat';

  @override
  String get aura => 'Aura';

  @override
  String get welcome => 'Welcome to AURA';

  @override
  String get tagline => 'The Swiss knife of AI';

  @override
  String get placeholder => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get attach => 'Attach';

  @override
  String get agent => 'Agent';

  @override
  String get provider => 'Provider';

  @override
  String get model => 'Model';

  @override
  String get settings => 'Settings';

  @override
  String get about => 'About';

  @override
  String get history => 'Recent chats';

  @override
  String get user => 'User';

  @override
  String get online => 'Online';

  @override
  String get settingsHub => 'Settings';

  @override
  String get cloudModels => 'Cloud models';

  @override
  String get localModels => 'Local models';

  @override
  String get localModelsDesc => 'Manage the folder and downloaded models';

  @override
  String get agents => 'Agents';

  @override
  String get documents => 'Documents & RAG';

  @override
  String get sandbox => 'Sandbox & Terminal';

  @override
  String get device => 'Device control';

  @override
  String get server => 'LLM server';

  @override
  String get stats => 'Statistics';

  @override
  String get multiModels => 'Multi-models';

  @override
  String get appearance => 'Appearance & preferences';

  @override
  String get textSize => 'Text size';

  @override
  String get uiScale => 'UI scale';

  @override
  String get font => 'Font';

  @override
  String get interface => 'Interface';

  @override
  String get me => 'Me (user)';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get ramHeadroom => 'RAM headroom (MB)';

  @override
  String get temperature => 'Temperature';

  @override
  String get topP => 'Top P';

  @override
  String get topK => 'Top K';

  @override
  String get maxTokens => 'Max tokens';

  @override
  String get modelsFolder => 'Models folder';

  @override
  String get browse => 'Browse';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get models => 'models';

  @override
  String get core => 'Core';

  @override
  String get startWith => 'Start with';

  @override
  String get suggestExplain => 'Explain a concept';

  @override
  String get suggestWrite => 'Help me write';

  @override
  String get suggestCode => 'Write some code';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get you => 'You';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get copy => 'Copy';

  @override
  String get reasoning => 'Reasoning';

  @override
  String get renameChat => 'Rename chat';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String get chatTitle => 'Chat title';

  @override
  String get select => 'Select';

  @override
  String get cloudProviders => 'Cloud providers';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connect => 'Connect';

  @override
  String get addProvider => 'Add provider';

  @override
  String get selectFolderToSaveModels => 'Select a folder to save models';

  @override
  String get installedModels => 'Installed models';

  @override
  String get noModelsInstalled => 'No models installed';

  @override
  String get deleteModel => 'Delete model';

  @override
  String get configureModel => 'Configure model';

  @override
  String get loading => 'Loading...';

  @override
  String get readyVram => 'Ready (VRAM)';

  @override
  String get catalogue => 'Catalogue';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get download => 'Download';

  @override
  String get noDocumentsImported => 'No documents imported.';

  @override
  String get importDocument => 'Import document';

  @override
  String get sandboxTerminal => 'Sandbox & Terminal';

  @override
  String get terminalReady => 'Terminal ready...';

  @override
  String get deviceControl => 'Device control';

  @override
  String get deviceOverview => 'Hardware overview';

  @override
  String get deviceModel => 'Device model';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get androidVersion => 'Android version';

  @override
  String get deviceModelUnavailable => 'Model information unavailable';

  @override
  String get noGpuDetected => 'No GPU detected';

  @override
  String get gpu => 'GPU';

  @override
  String get os => 'OS';

  @override
  String get arch => 'Arch';

  @override
  String get cpu => 'CPU';

  @override
  String get cores => 'Cores';

  @override
  String get ramMb => 'RAM (MB)';

  @override
  String get vramMb => 'VRAM (MB)';

  @override
  String get vendor => 'Vendor';

  @override
  String get runtime => 'Runtime';

  @override
  String get llmServer => 'LLM server';

  @override
  String get serverNotRunning => 'Server not running';

  @override
  String get startServer => 'Start server';

  @override
  String get statistics => 'Statistics';

  @override
  String get coreVersion => 'Core version';

  @override
  String get downloadManager => 'Download manager';

  @override
  String get noDownloads => 'No downloads';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get contextSize => 'Context size';

  @override
  String get filteredByRam =>
      'Filtered by available RAM. More models appear on a more powerful PC.';

  @override
  String get unloaded => 'Unloaded';

  @override
  String get newAgent => 'New agent';

  @override
  String get editAgent => 'Edit agent';

  @override
  String get deleteAgent => 'Delete agent';

  @override
  String deleteAgentConfirmation(Object name) {
    return 'Delete $name? This cannot be undone.';
  }

  @override
  String get agentName => 'Agent name';

  @override
  String get avatar => 'Avatar';

  @override
  String get systemPrompt => 'System prompt';

  @override
  String get quickPrompts => 'Suggested prompts';

  @override
  String get quickPromptsHint => 'Enter one suggested prompt per line.';
}
