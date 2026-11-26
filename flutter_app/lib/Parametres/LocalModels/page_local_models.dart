import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:file_picker/file_picker.dart';

import '../../llama_server.dart';
import '../../l10n/app_localizations.dart';
import '../Parametres/settings_colors.dart';
import '../download_state.dart';
import 'huggingface_search_modal.dart';
import 'mmproj_modal.dart';

/// Page « Modèles locaux » : dossier, liste installée, configuration par modèle.
class LocalModelsPage extends StatefulWidget {
  final String modelsDir;
  final int idleMinutes;
  final Map<String, dynamic> hardware;
  final Map<String, LlamaServerProcess> multiServers;
  final Map<String, String> multiStatus;
  final ValueChanged<String> onModelsDirChanged;
  final ValueChanged<String> onIdleMinutesChanged;
  final ValueChanged<String> showBanner;
  final VoidCallback onOpenCatalogue;
  final DownloadManager downloads;
  final void Function(String name) onConfigureModel;
  final ValueChanged<String> onDeleteModelFile;

  const LocalModelsPage({
    super.key,
    required this.modelsDir,
    required this.idleMinutes,
    required this.hardware,
    required this.multiServers,
    required this.multiStatus,
    required this.onModelsDirChanged,
    required this.onIdleMinutesChanged,
    required this.showBanner,
    required this.onOpenCatalogue,
    required this.downloads,
    required this.onConfigureModel,
    required this.onDeleteModelFile,
  });

  @override
  State<LocalModelsPage> createState() => _LocalModelsPageState();
}

class _LocalModelsPageState extends State<LocalModelsPage> {
  List<FileSystemEntity> get _installed => widget.modelsDir.isEmpty
      ? <FileSystemEntity>[]
      : Directory(widget.modelsDir)
            .listSync()
            .whereType<File>()
            .where(
              (f) => !f.path
                  .split(Platform.pathSeparator)
                  .last
                  .toLowerCase()
                  .contains('mmproj'),
            )
            .toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.downloads,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;
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
                  child: Icon(
                    Icons.view_module_rounded,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.localModels,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_installed.length} ${l10n.installedModels}',
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _openHuggingFace(context, colors),
                  icon: const Icon(Icons.travel_explore, size: 18),
                  label: const Text('HuggingFace'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: widget.onOpenCatalogue,
                  icon: const Icon(Icons.list, size: 18),
                  label: Text(l10n.catalogue),
                ),
              ],
            ),
            const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true,
                controller: TextEditingController(text: widget.modelsDir),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.panel2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                style: TextStyle(color: colors.text),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _pickModelsDir,
              child: Text(AppLocalizations.of(context)!.browse),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text(
            AppLocalizations.of(context)!.installedModels,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          initiallyExpanded: true,
          children: _installed.isEmpty
              ? [
                  Text(
                    AppLocalizations.of(context)!.noModelsInstalled,
                    style: TextStyle(color: colors.muted),
                  ),
                ]
              : _installed.map((f) {
                  final name = f.path.split(Platform.pathSeparator).last;
                  final enabled =
                      widget.multiServers.containsKey(name) &&
                      (widget.multiServers[name]?.isRunning ?? false);
                  final status = widget.multiStatus[name] ?? 'Idle';
                  return Card(
                    color: enabled ? Colors.green.shade700 : colors.panel2,
                    child: ListTile(
                      leading: Icon(
                        Icons.insert_drive_file,
                        color: enabled ? Colors.white : colors.white70,
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: enabled ? Colors.white : colors.text,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              color: enabled ? Colors.white70 : colors.muted,
                              fontSize: 12,
                            ),
                          ),
                          if (widget.downloads.isVision(name)) ...[
                            const SizedBox(height: 4),
                            _VisionChip(
                              installed:
                                  widget.downloads.mmprojFor(name) != null,
                              onTap: widget.downloads.mmprojFor(name) == null
                                  ? () => _openMmproj(name)
                                  : null,
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.settings,
                              color: enabled ? Colors.white : colors.muted,
                              size: 18,
                            ),
                            tooltip: AppLocalizations.of(context)!
                                .configureModel,
                            onPressed: () => widget.onConfigureModel(name),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: enabled ? Colors.white : colors.muted,
                              size: 18,
                            ),
                            tooltip: AppLocalizations.of(context)!.deleteModel,
                            onPressed: () => widget.onDeleteModelFile(name),
                          ),
                          Switch(
                            value: enabled,
                            activeColor: Colors.green,
                            activeTrackColor: Colors.green,
                            onChanged: (v) async {
                              if (v) {
                                final server = LlamaServerProcess(
                                  idleMinutes:
                                      int.tryParse(
                                        widget.idleMinutes.toString(),
                                      ) ??
                                      5,
                                  gpuVendor: (widget.hardware['gpu'] is Map)
                                      ? (widget.hardware['gpu']
                                                as Map)['vendor']
                                            ?.toString()
                                      : null,
                                );
                                widget.multiServers[name] = server;
                                setState(
                                  () => widget.multiStatus[name] =
                                      AppLocalizations.of(context)!.loading,
                                );
                                widget.showBanner(
                                  'Starting llama.cpp server for $name...',
                                );
                                 try {
                                   final mmproj = widget.downloads
                                       .mmprojFor(name);
                                   await server.start(
                                     f.path,
                                     mmprojPath: mmproj,
                                   );
                                  if (!mounted) return;
                                  setState(
                                    () => widget.multiStatus[name] =
                                        AppLocalizations.of(context)!.readyVram,
                                  );
                                } catch (e) {
                                  widget.multiServers.remove(name);
                                  if (!mounted) return;
                                  setState(
                                    () =>
                                        widget.multiStatus[name] = 'Error: $e',
                                  );
                                  widget.showBanner(
                                    'Failed to start server for $name: $e',
                                  );
                                }
                              } else {
                                final server = widget.multiServers.remove(name);
                                await server?.kill();
                                if (!mounted) return;
                                setState(
                                  () => widget.multiStatus[name] =
                                      AppLocalizations.of(context)!.unloaded,
                                );
                                widget.showBanner('Unloading $name...');
                              }
                              if (!mounted) return;
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ),
          ],
        );
      },
    );
  }

  void _openHuggingFace(BuildContext context, SettingsColors colors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => HuggingFaceSearchModal(
        colors: colors,
        downloads: widget.downloads,
        modelsDir: widget.modelsDir,
        showBanner: widget.showBanner,
      ),
    );
  }

  void _openMmproj(String name) {
    final colors = SettingsColors.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => MmprojModal(
        colors: colors,
        downloads: widget.downloads,
        modelsDir: widget.modelsDir,
        modelName: name,
        showBanner: widget.showBanner,
        initialRepo: widget.downloads.hfRepoFor(name),
      ),
    );
  }

  Future<void> _pickModelsDir() async {
    try {
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir != null) {
        setState(() {});
        widget.onModelsDirChanged(dir);
        widget.showBanner('Selected folder: $dir');
      }
    } catch (e) {
      widget.showBanner('Failed to open folder picker: $e');
    }
  }
}

/// Puce indiquant l'état du mmproj pour un modèle vision.
class _VisionChip extends StatelessWidget {
  final bool installed;
  final VoidCallback? onTap;
  const _VisionChip({required this.installed, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = installed ? Colors.green : Colors.orange;
    final label = installed ? 'Vision · mmproj installé' : 'Vision · mmproj requis';
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            installed ? Icons.check_circle : Icons.warning_amber,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          if (!installed && onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.download, size: 13, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: chip,
    );
  }
}
