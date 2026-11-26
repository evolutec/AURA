import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';
import '../download_state.dart';
import 'model_capabilities.dart';

/// Contenu de la modale « Catalogue » (liste des modèles filtrés par RAM).
class CatalogueModal extends StatelessWidget {
  final List<dynamic> models;
  final DownloadManager downloads;
  final String modelsDir;

  const CatalogueModal({
    super.key,
    required this.models,
    required this.downloads,
    required this.modelsDir,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
    return _build(context, colors, l10n);
  }

  Future<void> _download(
    BuildContext context,
    String id,
    String name,
    Map<String, dynamic> model,
  ) async {
    downloads.start(
      id,
      name,
      context: context,
      modelsDir: modelsDir,
      models: models,
    );
    final mmprojUrl = model['mmproj_url']?.toString();
    if (mmprojUrl == null || mmprojUrl.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SettingsColors.of(ctx)?.panel,
        title: const Text('mmproj (vision) disponible'),
        content: const Text(
          'Un fichier mmproj est disponible pour ce modèle. '
          'Voulez-vous le télécharger aussi ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, télécharger'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final fileName = mmprojUrl.split('/').last.split('?').first;
    final mpBase = fileName.replaceAll(RegExp(r'\.gguf$'), '');
    downloads.start(
      '$id.mmproj',
      fileName,
      context: context,
      modelsDir: modelsDir,
      models: [
        {'id': '$id.mmproj', 'name': fileName, 'download_url': mmprojUrl},
      ],
      subdir: '.mmproj',
      fileName: mpBase,
      modelId: name,
    );
    downloads.markVision(name);
  }

  Widget _build(BuildContext context, SettingsColors colors, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.filteredByRam.split('.')[0],
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: models.length,
            itemBuilder: (ctx, i) {
              final m = models[i];
              final id = m['id']?.toString() ?? '';
              final name = m['name']?.toString() ?? l10n.model;
              final downloading = downloads.downloading.contains(id);
              final downloaded = downloads.downloaded.contains(id);
              return Card(
                color: downloaded ? Colors.green.shade700 : colors.panel2,
                child: ListTile(
                  leading: Icon(Icons.memory, color: colors.white70),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: downloaded ? Colors.white : colors.text,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m['params_b'] ?? ''}B · ${m['ram_required_mb'] ?? ''} MB RAM',
                        style: TextStyle(
                          color: downloaded ? Colors.white70 : colors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CapabilityIcons(
                        caps: ModelCaps.fromCatalog(
                          Map<String, dynamic>.from(m as Map),
                        ),
                        colors: colors,
                        mmprojInstalled: downloads.mmprojFor(id) != null,
                      ),
                    ],
                  ),
                  trailing: downloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () => _download(
                            context,
                            id,
                            name,
                            Map<String, dynamic>.from(m as Map),
                          ),
                          child: Text(
                            downloaded ? l10n.downloaded : l10n.download,
                            style: TextStyle(
                              color: downloaded ? Colors.white : colors.accent,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
