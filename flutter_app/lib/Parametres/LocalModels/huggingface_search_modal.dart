import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../Parametres/settings_colors.dart';
import '../download_state.dart';
import 'model_capabilities.dart';

/// Modale de recherche HuggingFace pour télécharger des modèles GGUF
/// autres que ceux du catalogue préconisé.
class HuggingFaceSearchModal extends StatefulWidget {
  final SettingsColors colors;
  final DownloadManager downloads;
  final String modelsDir;
  final void Function(String) showBanner;

  const HuggingFaceSearchModal({
    super.key,
    required this.colors,
    required this.downloads,
    required this.modelsDir,
    required this.showBanner,
  });

  @override
  State<HuggingFaceSearchModal> createState() =>
      _HuggingFaceSearchModalState();
}

class _HuggingFaceSearchModalState extends State<HuggingFaceSearchModal> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;
  final Map<String, int> _fileSizes = {};
  final Set<String> _resolving = {};

  static const _engines = <String, String>{
    'Tous': '',
    'llama.cpp': 'llama.cpp',
    'gguf': 'gguf',
    'ik_llama.cpp': 'ik_llama.cpp',
    'mlx': 'mlx',
  };
  static const _sizes = <String, String>{
    'Toutes tailles': '',
    '< 1B': 'lt1',
    '1–3B': '1to3',
    '3–7B': '3to7',
    '7–13B': '7to13',
    '13B+': 'gt13',
  };
  static const _sorts = <String, String>{
    'Téléchargements': 'downloads',
    'J’aime': 'likes',
    'Modifiés récemment': 'lastModified',
    'Créés récemment': 'createdAt',
  };
  String _engine = 'Tous';
  String _size = 'Toutes tailles';
  String _sort = 'Téléchargements';

  double? _paramsB(String id) {
    final m = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*b(?![a-z])',
      caseSensitive: false,
    ).firstMatch(id.toLowerCase());
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', '.'));
  }

  bool _matchSize(String id) {
    if (_size == 'Toutes tailles') return true;
    final b = _paramsB(id);
    if (b == null) return false;
    switch (_size) {
      case '< 1B':
        return b < 1;
      case '1–3B':
        return b >= 1 && b < 3;
      case '3–7B':
        return b >= 3 && b < 7;
      case '7–13B':
        return b >= 7 && b < 13;
      case '13B+':
        return b >= 13;
    }
    return true;
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = HttpClient();
      final engineTag = _engines[_engine] ?? '';
      final filter = engineTag.isEmpty ? 'gguf' : 'gguf,$engineTag';
      final sortField = _sorts[_sort] ?? 'downloads';
      final uri = Uri.parse(
        'https://huggingface.co/api/models?search=$q&filter=$filter&limit=50&sort=$sortField&direction=-1&full=true',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Aura/1.0');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      client.close();
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}';
      }
      final decoded = jsonDecode(body) as List<dynamic>;
      final list = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((m) => (m['id']?.toString() ?? '').isNotEmpty)
          .where((m) => _matchSize(m['id'].toString()))
          .toList();
      if (!mounted) return;
      setState(() => _results = list);
      _resolveSizes(list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} Go';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} Ko';
  }

  Future<void> _resolveSizes(List<Map<String, dynamic>> list) async {
    final client = HttpClient();
    var index = 0;
    Future<void> worker() async {
      while (index < list.length) {
        final m = list[index];
        index++;
        final id = m['id'].toString();
        if (_fileSizes.containsKey(id)) continue;
        if (mounted) setState(() => _resolving.add(id));
        try {
          final req = await client.getUrl(
            Uri.parse('https://huggingface.co/api/models/$id/tree/main'),
          );
          req.headers.set('User-Agent', 'Aura/1.0');
          final res = await req.close();
          final body = await res.transform(utf8.decoder).join();
          if (res.statusCode == 200) {
            final files = (jsonDecode(body) as List<dynamic>)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .where(
                  (f) => (f['path']?.toString() ?? '').endsWith('.gguf'),
                )
                .toList();
            if (files.isNotEmpty) {
              final size = (files.first['size'] as num?)?.toInt();
              if (size != null && mounted) {
                setState(() => _fileSizes[id] = size);
              }
            }
          }
        } catch (_) {}
        if (mounted) setState(() => _resolving.remove(id));
      }
    }

    await Future.wait(List.generate(5, (_) => worker()));
    client.close();
  }

  Future<void> _download(Map<String, dynamic> model) async {
    final id = model['id'].toString();
    widget.showBanner('Résolution des fichiers GGUF pour $id...');
    try {
      final client = HttpClient();
      final treeUri = Uri.parse(
        'https://huggingface.co/api/models/$id/tree/main',
      );
      final treeReq = await client.getUrl(treeUri);
      treeReq.headers.set('User-Agent', 'Aura/1.0');
      final treeRes = await treeReq.close();
      final treeBody = await treeRes.transform(utf8.decoder).join();
      client.close();
      if (treeRes.statusCode != 200) throw 'HTTP ${treeRes.statusCode}';
      final ggufs = (jsonDecode(treeBody) as List<dynamic>)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((f) => (f['path']?.toString() ?? '').endsWith('.gguf'))
          .toList();
      if (ggufs.isEmpty) {
        widget.showBanner('Aucun fichier GGUF trouvé pour $id');
        return;
      }
      final isMmproj = (Map<String, dynamic> f) =>
          (f['path']?.toString() ?? '').toLowerCase().contains('mmproj');
      final mainFile = ggufs.firstWhere(
        (f) => !isMmproj(f),
        orElse: () => ggufs.first,
      );
      final path = mainFile['path'].toString();
      final url = 'https://huggingface.co/$id/resolve/main/$path';
      final name = path.split('/').last;
      final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      widget.downloads.start(
        safeId,
        name,
        context: context,
        modelsDir: widget.modelsDir,
        models: [
          {'id': safeId, 'name': name, 'download_url': url},
        ],
      );
      if (ModelCaps.fromHF(model).vision) {
        widget.downloads.markVision(name);
      }
      widget.downloads.registerHfRepo(name, id);
      final mmprojFile = ggufs.firstWhere(
        isMmproj,
        orElse: () => <String, dynamic>{},
      );
      if (mmprojFile.isNotEmpty) {
        final mpPath = mmprojFile['path'].toString();
        final mpName = mpPath.split('/').last;
        final mpBase = mpName.replaceAll(RegExp(r'\.gguf$'), '');
        final mpUrl = 'https://huggingface.co/$id/resolve/main/$mpPath';
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: widget.colors.panel,
            title: const Text('mmproj (vision) disponible'),
            content: Text(
              'Un fichier mmproj a été trouvé pour ce modèle.\n'
              'Voulez-vous le télécharger aussi ? ($mpName)',
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
        if (ok == true) {
          widget.downloads.start(
            '$safeId.mmproj',
            mpName,
            context: context,
            modelsDir: widget.modelsDir,
            models: [
              {'id': '$safeId.mmproj', 'name': mpName, 'download_url': mpUrl},
            ],
            subdir: '.mmproj',
            fileName: mpBase,
            modelId: name,
          );
          widget.showBanner('mmproj vision, téléchargement en cours...');
        }
      }
    } catch (e) {
      widget.showBanner('Échec de la résolution pour $id: $e');
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    final s = value.toString();
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  String _formatCount(dynamic value) {
    final n = value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  Widget _detailChip(SettingsColors colors, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: colors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    SettingsColors colors,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.18)
              : colors.panel2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.accent : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.accent : colors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(SettingsColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Moteur',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ..._engines.keys.map(
                (e) => _filterChip(
                  colors,
                  e,
                  _engine == e,
                  () => setState(() {
                    _engine = e;
                    _search();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Taille',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ..._sizes.keys.map(
                (s) => _filterChip(
                  colors,
                  s,
                  _size == s,
                  () => setState(() {
                    _size = s;
                    _search();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Trier par',
                style: TextStyle(
                  color: colors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ..._sorts.keys.map(
                (s) => _filterChip(
                  colors,
                  s,
                  _sort == s,
                  () => setState(() {
                    _sort = s;
                    _search();
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> m) {
    final colors = widget.colors;
    final id = m['id'].toString();
    final author = (m['author'] ?? id.split('/').first).toString();
    final downloads = _formatCount(m['downloads']);
    final likes = _formatCount(m['likes']);
    final lastModified = _formatDate(m['lastModified']);
    final pipeline = (m['pipeline_tag'] ?? '').toString();
    final library = (m['library_name'] ?? '').toString();
    final tags = (m['tags'] as List<dynamic>?) ?? const [];
    final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final downloading = widget.downloads.downloading.contains(safeId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: colors.panel2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.model_training,
                    color: colors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'par $author',
                        style: TextStyle(color: colors.muted, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      CapabilityIcons(
                        caps: ModelCaps.fromHF(m),
                        colors: colors,
                        mmprojInstalled:
                            widget.downloads.mmprojFor(safeId) != null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (downloading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => _download(m),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Télécharger'),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _detailChip(colors, Icons.download, '$downloads téléchargements'),
                if (_fileSizes.containsKey(id))
                  _detailChip(
                    colors,
                    Icons.straighten,
                    _formatSize(_fileSizes[id]!),
                  )
                else if (_resolving.contains(id))
                  _detailChip(colors, Icons.hourglass_empty, 'Taille…'),
                _detailChip(colors, Icons.favorite, '$likes j’aime'),
                _detailChip(colors, Icons.schedule, 'Modifié $lastModified'),
                if (pipeline.isNotEmpty)
                  _detailChip(colors, Icons.category, pipeline),
                if (library.isNotEmpty)
                  _detailChip(colors, Icons.extension, library),
              ],
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: tags
                    .take(8)
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          t.toString(),
                          style: TextStyle(
                            color: colors.accent,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final screen = MediaQuery.of(context).size;
    return ListenableBuilder(
      listenable: widget.downloads,
      builder: (ctx, _) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: screen.width < 1200 ? screen.width * 0.94 : 1200,
        height: screen.height < 900 ? screen.height * 0.92 : 900,
        child: Container(
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.travel_explore,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recherche HuggingFace',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Explorez et téléchargez des modèles GGUF',
                            style: TextStyle(
                              color: colors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colors.muted),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: colors.text),
                        decoration: InputDecoration(
                          hintText: 'ex: qwen2.5 gguf',
                          hintStyle: TextStyle(color: colors.muted),
                          prefixIcon: Icon(Icons.search, color: colors.muted),
                          filled: true,
                          fillColor: colors.panel2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _loading ? null : _search,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Rechercher'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_results.length} résultat${_results.length > 1 ? 's' : ''}',
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildFilters(colors),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Divider(color: colors.border, height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                    ? Center(
                        child: Text(
                          'Recherchez un modèle pour commencer',
                          style: TextStyle(color: colors.muted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, i) => _buildModelCard(
                          _results[i],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
