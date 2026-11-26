import 'package:material_ui/material_ui.dart';

import '../Parametres/Parametres/settings_colors.dart';
import 'model_metrics.dart';

/// Petite modale listant les statistiques des modèles utilisés sur les
/// 7 derniers jours : disponibilité, vitesse (tokens/s) et coût.
Future<void> showModelStatsModal(
  BuildContext context, {
  required List<ModelStat> stats,
  required SettingsColors colors,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: colors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20, color: colors.accent),
                    const SizedBox(width: 10),
                    Text(
                      'Statistiques (7 jours)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: colors.muted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: stats.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun modèle utilisé récemment',
                          style: TextStyle(color: colors.muted),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: stats.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: colors.border, height: 1),
                        itemBuilder: (context, i) => _row(stats[i], colors),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _row(ModelStat r, SettingsColors colors) {
  final speed = r.avgTps != null ? '${r.avgTps!.toStringAsFixed(1)} tok/s' : '—';
  final availability = r.available ? 'Disponible' : 'Indisponible';
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.panel2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                r.kind == 'cloud' ? 'Cloud' : 'Local',
                style: TextStyle(fontSize: 11, color: colors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _chip(Icons.circle, availability, colors),
            const SizedBox(width: 12),
            _chip(Icons.speed, speed, colors),
            const SizedBox(width: 12),
            _chip(Icons.payments_outlined, r.cost, colors),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${r.runs} utilisation${r.runs > 1 ? 's' : ''}'
          '${r.lastUsed != null ? ' · dernier: ${_fmt(r.lastUsed!)}' : ''}',
          style: TextStyle(fontSize: 10, color: colors.muted),
        ),
      ],
    ),
  );
}

String _fmt(DateTime d) {
  final now = DateTime.now();
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'il y a ${diff.inHours} h';
  return '${d.day}/${d.month}';
}

Widget _chip(IconData icon, String label, SettingsColors colors) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: colors.muted),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: colors.muted),
        ),
      ),
    ],
  );
}