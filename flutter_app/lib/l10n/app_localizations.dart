import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @aura.
  ///
  /// In en, this message translates to:
  /// **'Aura'**
  String get aura;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to AURA'**
  String get welcome;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'The Swiss knife of AI'**
  String get tagline;

  /// No description provided for @placeholder.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get placeholder;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get attach;

  /// No description provided for @agent.
  ///
  /// In en, this message translates to:
  /// **'Agent'**
  String get agent;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Recent chats'**
  String get history;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @settingsHub.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsHub;

  /// No description provided for @cloudModels.
  ///
  /// In en, this message translates to:
  /// **'Cloud models'**
  String get cloudModels;

  /// No description provided for @localModels.
  ///
  /// In en, this message translates to:
  /// **'Local models'**
  String get localModels;

  /// No description provided for @localModelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage the folder and downloaded models'**
  String get localModelsDesc;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents & RAG'**
  String get documents;

  /// No description provided for @sandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox & Terminal'**
  String get sandbox;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device control'**
  String get device;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'LLM server'**
  String get server;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @multiModels.
  ///
  /// In en, this message translates to:
  /// **'Multi-models'**
  String get multiModels;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance & preferences'**
  String get appearance;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @uiScale.
  ///
  /// In en, this message translates to:
  /// **'UI scale'**
  String get uiScale;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @interface.
  ///
  /// In en, this message translates to:
  /// **'Interface'**
  String get interface;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me (user)'**
  String get me;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @ramHeadroom.
  ///
  /// In en, this message translates to:
  /// **'RAM headroom (MB)'**
  String get ramHeadroom;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @topP.
  ///
  /// In en, this message translates to:
  /// **'Top P'**
  String get topP;

  /// No description provided for @topK.
  ///
  /// In en, this message translates to:
  /// **'Top K'**
  String get topK;

  /// No description provided for @maxTokens.
  ///
  /// In en, this message translates to:
  /// **'Max tokens'**
  String get maxTokens;

  /// No description provided for @modelsFolder.
  ///
  /// In en, this message translates to:
  /// **'Models folder'**
  String get modelsFolder;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'models'**
  String get models;

  /// No description provided for @core.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get core;

  /// No description provided for @startWith.
  ///
  /// In en, this message translates to:
  /// **'Start with'**
  String get startWith;

  /// No description provided for @suggestExplain.
  ///
  /// In en, this message translates to:
  /// **'Explain a concept'**
  String get suggestExplain;

  /// No description provided for @suggestWrite.
  ///
  /// In en, this message translates to:
  /// **'Help me write'**
  String get suggestWrite;

  /// No description provided for @suggestCode.
  ///
  /// In en, this message translates to:
  /// **'Write some code'**
  String get suggestCode;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @regenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @reasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning'**
  String get reasoning;

  /// No description provided for @renameChat.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get renameChat;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat title'**
  String get chatTitle;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @cloudProviders.
  ///
  /// In en, this message translates to:
  /// **'Cloud providers'**
  String get cloudProviders;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @addProvider.
  ///
  /// In en, this message translates to:
  /// **'Add provider'**
  String get addProvider;

  /// No description provided for @selectFolderToSaveModels.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to save models'**
  String get selectFolderToSaveModels;

  /// No description provided for @installedModels.
  ///
  /// In en, this message translates to:
  /// **'Installed models'**
  String get installedModels;

  /// No description provided for @noModelsInstalled.
  ///
  /// In en, this message translates to:
  /// **'No models installed'**
  String get noModelsInstalled;

  /// No description provided for @deleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete model'**
  String get deleteModel;

  /// No description provided for @configureModel.
  ///
  /// In en, this message translates to:
  /// **'Configure model'**
  String get configureModel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @readyVram.
  ///
  /// In en, this message translates to:
  /// **'Ready (VRAM)'**
  String get readyVram;

  /// No description provided for @catalogue.
  ///
  /// In en, this message translates to:
  /// **'Catalogue'**
  String get catalogue;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @noDocumentsImported.
  ///
  /// In en, this message translates to:
  /// **'No documents imported.'**
  String get noDocumentsImported;

  /// No description provided for @importDocument.
  ///
  /// In en, this message translates to:
  /// **'Import document'**
  String get importDocument;

  /// No description provided for @sandboxTerminal.
  ///
  /// In en, this message translates to:
  /// **'Sandbox & Terminal'**
  String get sandboxTerminal;

  /// No description provided for @terminalReady.
  ///
  /// In en, this message translates to:
  /// **'Terminal ready...'**
  String get terminalReady;

  /// No description provided for @deviceControl.
  ///
  /// In en, this message translates to:
  /// **'Device control'**
  String get deviceControl;

  /// No description provided for @deviceOverview.
  ///
  /// In en, this message translates to:
  /// **'Hardware overview'**
  String get deviceOverview;

  /// No description provided for @deviceModel.
  ///
  /// In en, this message translates to:
  /// **'Device model'**
  String get deviceModel;

  /// No description provided for @manufacturer.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturer;

  /// No description provided for @androidVersion.
  ///
  /// In en, this message translates to:
  /// **'Android version'**
  String get androidVersion;

  /// No description provided for @deviceModelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Model information unavailable'**
  String get deviceModelUnavailable;

  /// No description provided for @noGpuDetected.
  ///
  /// In en, this message translates to:
  /// **'No GPU detected'**
  String get noGpuDetected;

  /// No description provided for @gpu.
  ///
  /// In en, this message translates to:
  /// **'GPU'**
  String get gpu;

  /// No description provided for @os.
  ///
  /// In en, this message translates to:
  /// **'OS'**
  String get os;

  /// No description provided for @arch.
  ///
  /// In en, this message translates to:
  /// **'Arch'**
  String get arch;

  /// No description provided for @cpu.
  ///
  /// In en, this message translates to:
  /// **'CPU'**
  String get cpu;

  /// No description provided for @cores.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get cores;

  /// No description provided for @ramMb.
  ///
  /// In en, this message translates to:
  /// **'RAM (MB)'**
  String get ramMb;

  /// No description provided for @vramMb.
  ///
  /// In en, this message translates to:
  /// **'VRAM (MB)'**
  String get vramMb;

  /// No description provided for @vendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendor;

  /// No description provided for @runtime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get runtime;

  /// No description provided for @llmServer.
  ///
  /// In en, this message translates to:
  /// **'LLM server'**
  String get llmServer;

  /// No description provided for @serverNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Server not running'**
  String get serverNotRunning;

  /// No description provided for @startServer.
  ///
  /// In en, this message translates to:
  /// **'Start server'**
  String get startServer;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @coreVersion.
  ///
  /// In en, this message translates to:
  /// **'Core version'**
  String get coreVersion;

  /// No description provided for @downloadManager.
  ///
  /// In en, this message translates to:
  /// **'Download manager'**
  String get downloadManager;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get noDownloads;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @contextSize.
  ///
  /// In en, this message translates to:
  /// **'Context size'**
  String get contextSize;

  /// No description provided for @filteredByRam.
  ///
  /// In en, this message translates to:
  /// **'Filtered by available RAM. More models appear on a more powerful PC.'**
  String get filteredByRam;

  /// No description provided for @unloaded.
  ///
  /// In en, this message translates to:
  /// **'Unloaded'**
  String get unloaded;

  /// No description provided for @newAgent.
  ///
  /// In en, this message translates to:
  /// **'New agent'**
  String get newAgent;

  /// No description provided for @editAgent.
  ///
  /// In en, this message translates to:
  /// **'Edit agent'**
  String get editAgent;

  /// No description provided for @deleteAgent.
  ///
  /// In en, this message translates to:
  /// **'Delete agent'**
  String get deleteAgent;

  /// No description provided for @deleteAgentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This cannot be undone.'**
  String deleteAgentConfirmation(Object name);

  /// No description provided for @agentName.
  ///
  /// In en, this message translates to:
  /// **'Agent name'**
  String get agentName;

  /// No description provided for @avatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatar;

  /// No description provided for @systemPrompt.
  ///
  /// In en, this message translates to:
  /// **'System prompt'**
  String get systemPrompt;

  /// No description provided for @quickPrompts.
  ///
  /// In en, this message translates to:
  /// **'Suggested prompts'**
  String get quickPrompts;

  /// No description provided for @quickPromptsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter one suggested prompt per line.'**
  String get quickPromptsHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
