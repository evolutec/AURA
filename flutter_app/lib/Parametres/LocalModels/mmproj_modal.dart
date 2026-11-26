import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../Parametres/settings_colors.dart';
import '../download_state.dart';

/// Modale permettant de fournir le fichier mmproj (vision) d'un modèle déjà
/// installé, soit depuis un dépôt HuggingFace, soit depuis un fichier local.
class MmprojModal extends StatefulWidget {
  final SettingsColors colors;
  final DownloadManager downloads;
  final String modelsDir;

  /// Nom du fichier modèle installé (avec extension .gguf).
  final String modelName;

  final void Function(String) showBanner;

  /// Dépôt HuggingFace prérempli (si connu).
  final String? initialRepo;

  const MmprojModal({
    super.key,
    required this.colors,
    required this.downloads,
    required this.modelsDir,
    required this.modelName,
    required this.showBanner,
    this.initialRepo,
  });

  @override
  State<MmprojModal> createState() => _MmprojModalState();
}

class _MmprojModalState extends State<MmprojModal> {
  final _repoController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialRepo != null && widget.initialRepo!.isNotEmpty) {
      _repoController.text = widget.initialRepo!;
    }
  }

  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  Future<void> _downloadFromHF() async {
    final repo = _repoController.text.trim();
    if (repo.isEmpty) {
      setState(() => _error = 'Entrez un dépôt HuggingFace (ex. org/model-GGUF)');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final client = HttpClient();
      final req = await client.getUrl(
        Uri.parse('https://huggingface.co/api/models/$repo/tree/main'),
      );
      req.headers.set('User-Agent', 'Aura/1.0');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      final files = (jsonDecode(body) as List<dynamic>)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((f) => (f['path']?.toString() ?? '').endsWith('.gguf'))
          .toList();
      final mmproj = files.firstWhere(
        (f) => (f['path']?.toString() ?? '').toLowerCase().contains('mmproj'),
        orElse: () => <String, dynamic>{},
      );
      if (mmproj.isEmpty) {
        throw 'Aucun fichier mmproj trouvé dans $repo';
      }
      final path = mmproj['path'].toString();
      final mpName = path.split('/').last;
      final mpBase = mpName.replaceAll(RegExp(r'\.gguf$'), '');
      final url = 'https://huggingface.co/$repo/resolve/main/$path';
      widget.downloads.start(
        '${widget.modelName}.mmproj',
        mpName,
        context: context,
        modelsDir: widget.modelsDir,
        models: [
          {'id': '${widget.modelName}.mmproj', 'name': mpName, 'download_url': url},
        ],
        subdir: '.mmproj',
        fileName: mpBase,
        modelId: widget.modelName,
      );
      widget.showBanner('Téléchargement du mmproj en cours...');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _pickLocal() async {
    try {
      final path = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gguf'],
      );
      final picked = path?.files.single.path;
      if (picked == null) return;
      final base = picked.split(Platform.pathSeparator).last;
      final mpBase = base.replaceAll(RegExp(r'\.gguf$'), '');
      final dir = widget.modelsDir.isEmpty
          ? '.mmproj'
          : '${widget.modelsDir}${Platform.pathSeparator}.mmproj';
      Directory(dir).createSync(recursive: true);
      final dest = '$dir${Platform.pathSeparator}$mpBase.gguf';
      File(picked).copySync(dest);
      widget.downloads.registerMmproj(widget.modelName, dest);
      widget.showBanner('mmproj installé');
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Dialog(
      backgroundColor: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'mmproj requis',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Modèle : ${widget.modelName}',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                'Dépôt HuggingFace',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _repoController,
                style: TextStyle(color: colors.text),
                decoration: InputDecoration(
                  hintText: 'ex: lmstudio-community/gemma-4-E4B-it-GGUF',
                  hintStyle: TextStyle(color: colors.muted),
                  filled: true,
                  fillColor: colors.panel2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
                onSubmitted: (_) => _downloadFromHF(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : _downloadFromHF,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Télécharger le mmproj'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickLocal,
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Fichier local'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}