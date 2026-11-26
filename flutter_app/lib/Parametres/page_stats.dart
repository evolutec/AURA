import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'Parametres/settings_colors.dart';

class StatsPage extends StatelessWidget {
  final String version;
  final List<dynamic> models;
  final Map<String, dynamic> hardware;

  const StatsPage({
    super.key,
    required this.version,
    required this.models,
    required this.hardware,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.statistics,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow(l10n.coreVersion, version, colors),
        _infoRow(l10n.model, '${models.length}', colors),
        _infoRow('OS', hardware['os']?.toString() ?? '', colors),
      ],
    );
  }

  Widget _infoRow(String label, String value, SettingsColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.muted)),
          ),
          Text(value, style: TextStyle(color: colors.text)),
        ],
      ),
    );
  }
}
