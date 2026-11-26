import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';

/// Page « À propos » : informations de version (mock data pour le moment).
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    final rows = <_AboutEntry>[
      _AboutEntry('AURA', '1.0.0', Icons.bolt_rounded),
      _AboutEntry(l10n.coreVersion, '0.1.0', Icons.memory_rounded),
      _AboutEntry('Build', 'b12651', Icons.build_rounded),
      _AboutEntry('License', 'MIT', Icons.description_outlined),
      _AboutEntry('Website', 'https://aura.local', Icons.language_rounded),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.info_outline_rounded, color: colors.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.about,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'AURA 1.0.0',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BoxDecoration(
                color: colors.panel2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0) Divider(height: 1, color: colors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(rows[index].icon, size: 18, color: colors.muted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rows[index].label,
                              style: TextStyle(color: colors.muted),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              rows[index].value,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                color: colors.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AboutEntry {
  final String label;
  final String value;
  final IconData icon;

  const _AboutEntry(this.label, this.value, this.icon);
}