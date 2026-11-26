import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Une mesure ponctuelle d'utilisation d'un modèle.
class MetricEntry {
  final int ts;
  final double? tps;
  final int? tokens;
  final int? elapsedMs;
  final String kind;
  final bool available;

  const MetricEntry({
    required this.ts,
    this.tps,
    this.tokens,
    this.elapsedMs,
    required this.kind,
    required this.available,
  });

  Map<String, dynamic> toJson() => {
        'ts': ts,
        if (tps != null) 'tps': tps,
        if (tokens != null) 'tokens': tokens,
        if (elapsedMs != null) 'elapsedMs': elapsedMs,
        'kind': kind,
        'available': available,
      };

  factory MetricEntry.fromJson(Map<String, dynamic> json) => MetricEntry(
        ts: (json['ts'] as num?)?.toInt() ?? 0,
        tps: (json['tps'] as num?)?.toDouble(),
        tokens: (json['tokens'] as num?)?.toInt(),
        elapsedMs: (json['elapsedMs'] as num?)?.toInt(),
        kind: json['kind']?.toString() ?? 'local',
        available: json['available'] as bool? ?? false,
      );
}

/// Agrégat par modèle sur la fenêtre récente.
class ModelStat {
  final String name;
  final String kind;
  final int runs;
  final double? avgTps;
  final DateTime? lastUsed;
  final bool available;
  final String cost;

  const ModelStat({
    required this.name,
    required this.kind,
    required this.runs,
    this.avgTps,
    this.lastUsed,
    required this.available,
    required this.cost,
  });
}

/// Surveillance et persistance des métriques d'utilisation des modèles.
/// Les entrées de plus de [windowDays] jours sont purgées à chaque écriture.
class ModelMetricsStore {
  static const _key = 'modelMetrics';
  static const windowDays = 7;

  static Future<Map<String, List<MetricEntry>>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, List<MetricEntry>>{};
      decoded.forEach((model, value) {
        if (value is List) {
          result[model] = value
              .whereType<Map>()
              .map((e) => MetricEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(Map<String, List<MetricEntry>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    data.forEach((model, entries) {
      encoded[model] = entries.map((e) => e.toJson()).toList();
    });
    await prefs.setString(_key, jsonEncode(encoded));
  }

  static void _prune(Map<String, List<MetricEntry>> data) {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: windowDays))
        .millisecondsSinceEpoch;
    data.forEach((model, entries) {
      entries.removeWhere((e) => e.ts < cutoff);
    });
    data.removeWhere((_, entries) => entries.isEmpty);
  }

  /// Enregistre une utilisation (génération, démarrage serveur, échec...).
  static Future<void> record({
    required String model,
    required String kind,
    double? tps,
    int? tokens,
    int? elapsedMs,
    bool? available,
  }) async {
    if (model.isEmpty) return;
    final data = await _load();
    _prune(data);
    final entries = data.putIfAbsent(model, () => <MetricEntry>[]);
    entries.add(MetricEntry(
      ts: DateTime.now().millisecondsSinceEpoch,
      tps: tps,
      tokens: tokens,
      elapsedMs: elapsedMs,
      kind: kind,
      available: available ?? true,
    ));
    await _save(data);
  }

  /// Liste des modèles utilisés sur les [days] derniers jours, agrégés.
  static Future<List<ModelStat>> recent({int days = windowDays}) async {
    final data = await _load();
    _prune(data);
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final stats = <ModelStat>[];
    data.forEach((model, entries) {
      final recent = entries.where((e) => e.ts >= cutoff).toList();
      if (recent.isEmpty) return;
      final runs = recent.length;
      final tpsValues =
          recent.map((e) => e.tps).whereType<double>().where((v) => v > 0);
      final avgTps = tpsValues.isEmpty
          ? null
          : tpsValues.reduce((a, b) => a + b) / tpsValues.length;
      final last = recent.map((e) => e.ts).reduce((a, b) => a > b ? a : b);
      final kind = recent.last.kind;
      final available = recent.any((e) => e.available);
      stats.add(ModelStat(
        name: model,
        kind: kind,
        runs: runs,
        avgTps: avgTps,
        lastUsed: DateTime.fromMillisecondsSinceEpoch(last),
        available: available,
        cost: kind == 'cloud' ? '—' : 'Gratuit',
      ));
    });
    stats.sort((a, b) {
      final la = a.lastUsed?.millisecondsSinceEpoch ?? 0;
      final lb = b.lastUsed?.millisecondsSinceEpoch ?? 0;
      return lb.compareTo(la);
    });
    return stats;
  }
}