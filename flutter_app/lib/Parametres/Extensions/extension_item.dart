/// Type d'extension installée.
enum ExtensionKind { skill, tool, mcp }

extension ExtensionKindX on ExtensionKind {
  String get key => switch (this) {
        ExtensionKind.skill => 'skill',
        ExtensionKind.tool => 'tool',
        ExtensionKind.mcp => 'mcp',
      };

  static ExtensionKind fromKey(String k) => switch (k) {
        'tool' => ExtensionKind.tool,
        'mcp' => ExtensionKind.mcp,
        _ => ExtensionKind.skill,
      };
}

/// Un objet installé (skill, outil ou serveur MCP).
class ExtensionItem {
  final String id;
  final String name;
  final String description;
  final ExtensionKind kind;
  final String icon;
  bool enabled;
  final Map<String, String> config;

  ExtensionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    this.icon = 'extension',
    this.enabled = true,
    Map<String, String>? config,
  }) : config = config ?? <String, String>{};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'kind': kind.key,
        'icon': icon,
        'enabled': enabled,
        'config': config,
      };

  factory ExtensionItem.fromJson(Map<String, dynamic> j) => ExtensionItem(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        kind: ExtensionKindX.fromKey(j['kind']?.toString() ?? 'skill'),
        icon: j['icon']?.toString() ?? 'extension',
        enabled: j['enabled'] != false,
        config: (j['config'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            ) ??
            <String, String>{},
      );
}