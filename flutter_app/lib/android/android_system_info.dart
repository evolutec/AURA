// AURA Android System Info Plugin
// Expose le Foreground Service et les stats à Flutter

import 'package:flutter/services.dart';

class AuraSystemInfo {
  static const MethodChannel _channel = MethodChannel('aura/system_info');

  /// Démarre le Foreground Service d'inférence
  static Future<void> startInference({required String model}) async {
    await _channel.invokeMethod('startInference', {'model': model});
  }

  /// Arrête le Foreground Service
  static Future<void> stopInference() async {
    await _channel.invokeMethod('stopInference');
  }

  /// Récupère les statistiques temps réel
  static Future<Map<String, dynamic>> getStats() async {
    final result = await _channel.invokeMethod('getStats');
    return Map<String, dynamic>.from(result ?? {});
  }

  /// Informations sur l'appareil
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMethod('getDeviceInfo');
    return Map<String, dynamic>.from(result ?? {});
  }

  /// tok/s actuel (0 si pas d'inférence)
  static Future<double> getTokensPerSec() async {
    final stats = await getStats();
    return (stats['tok_s'] as num?)?.toDouble() ?? 0.0;
  }

  /// RAM utilisée (MB)
  static Future<int> getRamMb() async {
    final stats = await getStats();
    return (stats['ram_mb'] as num?)?.toInt() ?? 0;
  }

  /// Si l'inférence est en cours
  static Future<bool> isInferencing() async {
    final stats = await getStats();
    return stats['is_running'] as bool? ?? false;
  }
}