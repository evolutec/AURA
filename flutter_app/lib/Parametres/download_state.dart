import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tâche de téléchargement d'un modèle GGUF.
class DownloadTask {
  final String id;
  final String name;

  /// Identifiant du modèle auquel rattacher un mmproj (mapping).
  final String? modelId;

  /// Sous-dossier de destination (ex. `.mmproj`) ou `null` pour la racine.
  final String? subdir;

  /// Nom de fichier explicite (sans extension ajoutée) ou `null`.
  final String? fileName;

  /// Tâche masquée (ex. mmproj) : exclue du panneau et de la pastille.
  final bool hidden;

  double progress = 0;
  bool paused = false;
  bool cancelled = false;
  bool completed = false;
  Timer? timer;
  DownloadTask({
    required this.id,
    required this.name,
    this.modelId,
    this.subdir,
    this.fileName,
    this.hidden = false,
  });
}

/// Gestionnaire de téléchargements partagé entre la page « Modèles locaux »
/// et les modales. Singleton : l'interface (pastille / panneau) est rendue par
/// [DownloadManagerBadge] dans le builder racine de l'application, ce qui la
/// rend visible sur n'importe quelle page ou modale, y compris après avoir
/// fermé puis rouvert les paramètres.
class DownloadManager extends ChangeNotifier {
  DownloadManager._internal()
      : downloading = <String>{},
        downloaded = <String>{},
        tasks = <DownloadTask>[];

  /// Instance unique de l'application.
  static final DownloadManager instance = DownloadManager._internal();

  /// Notificateur de l'instance active, utilisé par [DownloadManagerBadge].
  static final ValueNotifier<DownloadManager?> active =
      ValueNotifier<DownloadManager?>(instance);

  void Function(String)? _showBanner;

  final Set<String> downloading;
  final Set<String> downloaded;
  final List<DownloadTask> tasks;

  /// Mapping identifiant modèle -> chemin du fichier mmproj installé.
  final Map<String, String> mmprojByModel = {};

  /// Noms de fichiers modèles marqués « vision » (mmproj requis).
  final Set<String> visionModels = {};

  /// Dépôt HuggingFace associé à un modèle installé (pour préremplir).
  final Map<String, String> hfRepoByModel = {};
  bool _mmprojLoaded = false;
  bool minimized = false;
  bool closed = false;

  factory DownloadManager({
    void Function(String)? showBanner,
    Set<String>? downloading,
    Set<String>? downloaded,
    List<DownloadTask>? tasks,
  }) {
    final m = instance;
    m._showBanner = showBanner ?? m._showBanner;
    m.downloading.addAll(downloading ?? <String>{});
    m.downloaded.addAll(downloaded ?? <String>{});
    m.tasks.addAll(tasks ?? <DownloadTask>[]);
    return m;
  }

  /// Met à jour le callback de bannière (ex. après un changement de contexte).
  void configure({void Function(String)? showBanner}) {
    if (showBanner != null) _showBanner = showBanner;
  }

  void _banner(String message) => _showBanner?.call(message);

  /// Charge (une seule fois) le mapping mmproj depuis les préférences.
  Future<void> ensureMmprojLoaded() async {
    if (_mmprojLoaded) return;
    _mmprojLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('mmprojByModel');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) => mmprojByModel[k] = v.toString());
      }
      final rawVision = prefs.getString('visionModels');
      if (rawVision != null && rawVision.isNotEmpty) {
        final decoded = jsonDecode(rawVision) as List<dynamic>;
        decoded.forEach((e) => visionModels.add(e.toString()));
      }
      final rawRepo = prefs.getString('hfRepoByModel');
      if (rawRepo != null && rawRepo.isNotEmpty) {
        final decoded = jsonDecode(rawRepo) as Map<String, dynamic>;
        decoded.forEach((k, v) => hfRepoByModel[k] = v.toString());
      }
    } catch (_) {}
  }

  Future<void> _persistMmproj() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mmprojByModel', jsonEncode(mmprojByModel));
      await prefs.setString('visionModels', jsonEncode(visionModels.toList()));
      await prefs.setString('hfRepoByModel', jsonEncode(hfRepoByModel));
    } catch (_) {}
  }

  /// Associe un dépôt HuggingFace à un modèle installé.
  void registerHfRepo(String modelName, String repo) {
    if (hfRepoByModel[modelName] == repo) return;
    hfRepoByModel[modelName] = repo;
    _persistMmproj();
  }

  String? hfRepoFor(String modelName) => hfRepoByModel[modelName];

  /// Marque un modèle comme vision (mmproj requis) et persiste.
  void markVision(String modelName) {
    if (visionModels.add(modelName)) _persistMmproj();
  }

  /// Enregistre un chemin mmproj déjà présent sur le disque pour un modèle.
  void registerMmproj(String modelName, String path) {
    mmprojByModel[modelName] = path;
    visionModels.add(modelName);
    _persistMmproj();
    notifyListeners();
  }

  bool isVision(String modelName) {
    if (visionModels.contains(modelName)) return true;
    final n = modelName.toLowerCase();
    return n.contains('vision') ||
        n.contains('llava') ||
        n.contains('-vl') ||
        n.contains('minicpm-v') ||
        n.contains('gemma-4') ||
        n.contains('gemma-3') ||
        n.contains('e4b') ||
        n.contains('e2b');
  }

  /// Chemin du mmproj installé pour un modèle, s'il existe sur le disque.
  String? mmprojFor(String modelId) {
    final path = mmprojByModel[modelId];
    if (path == null || path.isEmpty) return null;
    return File(path).existsSync() ? path : null;
  }

  bool get hasActive => tasks.any((t) => !t.completed && !t.cancelled);

  List<DownloadTask> get activeTasks =>
      tasks.where((t) => !t.completed && !t.cancelled).toList();

  /// Tâches visibles (hors tâches masquées comme les mmproj).
  List<DownloadTask> get visibleTasks =>
      tasks.where((t) => !t.hidden).toList();

  @override
  void dispose() {
    if (active.value == this) active.value = null;
    for (final task in tasks) {
      task.timer?.cancel();
      task.cancelled = true;
    }
    super.dispose();
  }

  void start(
    String id,
    String name, {
    required BuildContext context,
    required String modelsDir,
    required List<dynamic> models,
    String? subdir,
    String? fileName,
    String? modelId,
    bool hidden = false,
  }) {
    if (tasks.any((t) => t.id == id && !t.completed)) {
      _banner('$name already downloading');
      return;
    }
    final model = models.firstWhere(
      (m) => m['id'] == id,
      orElse: () => <String, dynamic>{},
    );
    final url = model['download_url']?.toString();
    if (url == null || url.isEmpty) {
      _banner('No download URL for $name');
      return;
    }
    if (modelsDir.isEmpty) {
      _banner('Select a models folder first');
      return;
    }
    final task = DownloadTask(
      id: id,
      name: name,
      modelId: modelId,
      subdir: subdir,
      fileName: fileName,
      hidden: hidden,
    );
    tasks.add(task);
    downloading.add(id);
    if (!hidden) {
      minimized = false;
      closed = false;
    }
    notifyListeners();

    task.timer?.cancel();
    _run(task, url, modelsDir);
  }

  Future<void> _run(DownloadTask task, String url, String modelsDir) async {
    final safeName =
        task.fileName ?? task.id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final dir = task.subdir == null
        ? modelsDir
        : '$modelsDir${Platform.pathSeparator}${task.subdir}';
    if (task.subdir != null) {
      Directory(dir).createSync(recursive: true);
    }
    final file = File('$dir${Platform.pathSeparator}$safeName.gguf');
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 302) {
        throw 'HTTP ${res.statusCode}';
      }
      final total = res.contentLength;
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in res) {
        if (task.cancelled) {
          await sink.close();
          await file.delete().catchError((_) => file);
          return;
        }
        while (task.paused) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (task.cancelled) break;
        }
        if (task.cancelled) {
          await sink.close();
          await file.delete().catchError((_) => file);
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          task.progress = received / total;
        } else {
          task.progress = (task.progress + 0.001).clamp(0.0, 0.99);
        }
        notifyListeners();
      }
      await sink.flush();
      await sink.close();
      client.close();
      task.progress = 1.0;
      task.completed = true;
      downloading.remove(task.id);
      downloaded.add(task.id);
      if (task.subdir != null) {
        mmprojByModel[task.modelId ?? task.id] = file.path;
        _persistMmproj();
      }
      notifyListeners();
      _banner('Downloaded ${task.name}');
    } catch (e) {
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      tasks.remove(task);
      downloading.remove(task.id);
      notifyListeners();
      _banner('Failed to download ${task.name}: $e');
    }
  }

  void toggle(DownloadTask task) {
    task.paused = !task.paused;
    notifyListeners();
  }

  void cancel(DownloadTask task) {
    task.cancelled = true;
    task.timer?.cancel();
    tasks.remove(task);
    downloading.remove(task.id);
    notifyListeners();
    _banner('Cancelled ${task.name}');
  }

  void minimize() {
    minimized = true;
    closed = false;
    notifyListeners();
  }

  void expand() {
    minimized = false;
    closed = false;
    notifyListeners();
  }

  void close() {
    closed = true;
    notifyListeners();
  }
}

/// Pastille / panneau flottant persistant, rendu au-dessus de l'application.
/// Déplaçable à la souris/doigt via glisser (sans Overlay).
class DownloadManagerBadge extends StatefulWidget {
  const DownloadManagerBadge({super.key});

  @override
  State<DownloadManagerBadge> createState() => _DownloadManagerBadgeState();
}

class _DownloadManagerBadgeState extends State<DownloadManagerBadge> {
  Offset? _pos;

  void _onPanUpdate(DragUpdateDetails d, Size screen, double w, double h) {
    final base = _pos ?? Offset(screen.width - w - 16, screen.height - h - 16);
    var nx = base.dx + d.delta.dx;
    var ny = base.dy + d.delta.dy;
    nx = nx.clamp(0.0, (screen.width - w).clamp(0.0, screen.width));
    ny = ny.clamp(0.0, (screen.height - h).clamp(0.0, screen.height));
    setState(() => _pos = Offset(nx, ny));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DownloadManager?>(
      valueListenable: DownloadManager.active,
      builder: (context, manager, _) {
        if (manager == null) return const SizedBox.shrink();
        return ListenableBuilder(
          listenable: manager,
          builder: (context, _) {
            if (manager.visibleTasks.isEmpty || manager.closed) {
              return const SizedBox.shrink();
            }
            final screen = MediaQuery.of(context).size;
            final w = manager.minimized ? 220.0 : 320.0;
            final h = manager.minimized ? 44.0 : 300.0;
            final child = GestureDetector(
              onPanUpdate: (d) => _onPanUpdate(d, screen, w, h),
              child: manager.minimized
                  ? _Pill(manager: manager)
                  : _Panel(manager: manager),
            );
            if (_pos == null) {
              return Positioned(right: 16, bottom: 16, child: child);
            }
            return Positioned(left: _pos!.dx, top: _pos!.dy, child: child);
          },
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final DownloadManager manager;
  const _Pill({required this.manager});

  @override
  Widget build(BuildContext context) {
    final active = manager.activeTasks;
    final progress = active.isEmpty
        ? 0.0
        : active.map((t) => t.progress).reduce((a, b) => a + b) /
            active.length;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: manager.expand,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1E222C),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.download, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                active.isEmpty ? 'Téléchargements' : '${active.length} en cours',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              if (active.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 54,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final DownloadManager manager;
  const _Panel({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E222C),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Download manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.minimize, color: Colors.white, size: 18),
                  onPressed: manager.minimize,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: manager.close,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    (MediaQuery.of(context).size.height * 0.35).clamp(
                      110.0,
                      220.0,
                    ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: manager.visibleTasks.take(6).map(
                    (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: t.progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${(t.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (!t.completed && !t.cancelled)
                          TextButton(
                            onPressed: () => manager.toggle(t),
                            child: Text(
                              t.paused ? 'Resume' : 'Pause',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (!t.completed)
                          TextButton(
                            onPressed: () => manager.cancel(t),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ),
            ],
          ),
        ),
      );
  }
}