import 'package:material_ui/material_ui.dart';

import '../Parametres/settings_colors.dart';

/// Capacités détectées d'un modèle (affichées sous forme d'icônes).
class ModelCaps {
  final bool vision;
  final bool tools;
  final bool thinking;

  const ModelCaps({this.vision = false, this.tools = false, this.thinking = false});

  bool get any => vision || tools || thinking;

  /// Un modèle vision nécessite un fichier mmproj séparé.
  bool get requiresMmproj => vision;

  static ModelCaps fromCatalog(Map<String, dynamic> m) {
    final modalities = (m['modalities'] as List<dynamic>?) ?? const [];
    final kind = (m['kind']?.toString() ?? '').toLowerCase();
    final name = '${m['id'] ?? ''} ${m['name'] ?? ''}'.toLowerCase();
    final vision = modalities.any((e) => e.toString().toLowerCase() == 'vision') ||
        kind.contains('minicpm') ||
        name.contains('vision') ||
        name.contains('llava') ||
        name.contains('-vl') ||
        name.contains('minicpm-v');
    final tools = name.contains('tool') || name.contains('function');
    final thinking = name.contains('think') ||
        name.contains('reason') ||
        name.contains('r1') ||
        name.contains('qwq');
    return ModelCaps(vision: vision, tools: tools, thinking: thinking);
  }

  static ModelCaps fromHF(Map<String, dynamic> m) {
    final tags = (m['tags'] as List<dynamic>?) ?? const [];
    final tagSet = tags.map((e) => e.toString().toLowerCase()).toSet();
    final name = '${m['id'] ?? ''}'.toLowerCase();
    final vision = tagSet.any((t) =>
            t.contains('vision') ||
            t.contains('image-text') ||
            t.contains('image_text')) ||
        name.contains('llava') ||
        name.contains('-vl') ||
        name.contains('minicpm-v') ||
        name.contains('vision');
    final tools = tagSet.any(
          (t) => t.contains('tool') || t.contains('function') || t == 'agents',
        ) ||
        name.contains('tool') ||
        name.contains('function');
    final thinking = tagSet.any(
          (t) => t.contains('thinking') || t.contains('reasoning'),
        ) ||
        name.contains('think') ||
        name.contains('reason') ||
        name.contains('r1') ||
        name.contains('qwq');
    return ModelCaps(vision: vision, tools: tools, thinking: thinking);
  }
}

/// Petite rangée d'icônes de capacités avec infobulles.
class CapabilityIcons extends StatelessWidget {
  final ModelCaps caps;
  final SettingsColors colors;
  final double size;

  /// État d'installation du mmproj (null = non applicable / inconnu).
  final bool? mmprojInstalled;

  const CapabilityIcons({
    super.key,
    required this.caps,
    required this.colors,
    this.size = 16,
    this.mmprojInstalled,
  });

  @override
  Widget build(BuildContext context) {
    if (!caps.any) return const SizedBox.shrink();
    final items = <(IconData, String)>[
      if (caps.vision) (Icons.visibility, 'Vision'),
      if (caps.tools) (Icons.build, 'Tools'),
      if (caps.thinking) (Icons.psychology, 'Thinking'),
    ];
    final children = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: e.$2,
                  child: Icon(e.$1, size: size, color: colors.accent),
                ),
              ),
            )
            .toList(),
      ),
    ];
    if (caps.requiresMmproj && mmprojInstalled != null) {
      final ok = mmprojInstalled!;
      children.add(
        Tooltip(
          message: ok ? 'mmproj installé' : 'mmproj requis (vision)',
          child: Icon(
            ok ? Icons.check_circle : Icons.warning_amber,
            size: size,
            color: ok ? Colors.green : Colors.orange,
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}