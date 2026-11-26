import 'dart:convert';

/// Type d'authentification d'un fournisseur cloud (inspiré de RikkaHub
/// `ProviderSetting` : ApiKey, Account/OAuth, ChatGPT, Claude, Google, Grok, OpenAI).
enum CloudAuthType {
  apiKey,
  account,
}

/// En-tête HTTP personnalisé envoyé aux requêtes du fournisseur
/// (équivalent de `CustomHeader` de RikkaHub).
class CloudCustomHeader {
  final String name;
  final String value;

  const CloudCustomHeader({required this.name, required this.value});

  Map<String, dynamic> toJson() => {'name': name, 'value': value};

  factory CloudCustomHeader.fromJson(Map<String, dynamic> json) =>
      CloudCustomHeader(name: json['name'] as String? ?? '', value: json['value'] as String? ?? '');
}

/// Modèle d'un fournisseur cloud enregistré.
///
/// Champ par champ, c'est le pendant Dart de `ProviderSetting` de RikkaHub :
/// - [id] : identifiant unique (uuid)
/// - [name] : nom affiché
/// - [baseUrl] : endpoint de l'API (OpenAI-compatible par défaut)
/// - [apiKey] : clé API (vide pour les comptes OAuth)
/// - [authType] : apiKey ou account (OAuth)
/// - [models] : modèles exposés par ce fournisseur
/// - [customHeaders] : en-têtes HTTP supplémentaires
/// - [enabled] : activé/désactivé
/// - [builtIn] : fournisseur intégré (non supprimable)
class CloudProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String apiKey;
  final CloudAuthType authType;
  final List<String> models;
  final List<CloudCustomHeader> customHeaders;
  final bool enabled;
  final bool builtIn;

  const CloudProvider({
    required this.id,
    required this.name,
    this.baseUrl = '',
    this.apiKey = '',
    this.authType = CloudAuthType.apiKey,
    this.models = const [],
    this.customHeaders = const [],
    this.enabled = true,
    this.builtIn = false,
  });

  CloudProvider copyWith({
    String? id,
    String? name,
    String? baseUrl,
    String? apiKey,
    CloudAuthType? authType,
    List<String>? models,
    List<CloudCustomHeader>? customHeaders,
    bool? enabled,
    bool? builtIn,
  }) {
    return CloudProvider(
      id: id ?? this.id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      authType: authType ?? this.authType,
      models: models ?? this.models,
      customHeaders: customHeaders ?? this.customHeaders,
      enabled: enabled ?? this.enabled,
      builtIn: builtIn ?? this.builtIn,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'authType': authType.name,
    'models': models,
    'customHeaders': customHeaders.map((h) => h.toJson()).toList(),
    'enabled': enabled,
    'builtIn': builtIn,
  };

  factory CloudProvider.fromJson(Map<String, dynamic> json) => CloudProvider(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    baseUrl: json['baseUrl'] as String? ?? '',
    apiKey: json['apiKey'] as String? ?? '',
    authType: CloudAuthType.values.firstWhere(
      (t) => t.name == (json['authType'] as String? ?? ''),
      orElse: () => CloudAuthType.apiKey,
    ),
    models: (json['models'] as List<dynamic>?)?.cast<String>() ?? const [],
    customHeaders: (json['customHeaders'] as List<dynamic>?)
            ?.map((e) => CloudCustomHeader.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    enabled: json['enabled'] as bool? ?? true,
    builtIn: json['builtIn'] as bool? ?? false,
  );

  String toJsonString() => jsonEncode(toJson());

  factory CloudProvider.fromJsonString(String s) =>
      CloudProvider.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
