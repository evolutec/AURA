// AURA Android Permissions Plugin
// Gère les permissions runtime (micro, caméra, notifications, stockage)

import 'package:flutter/services.dart';

class AuraPermissions {
  static const MethodChannel _channel = MethodChannel('aura/permissions');

  /// Demande une permission et retourne true si accordée
  static Future<bool> request(String permission) async {
    final result = await _channel.invokeMethod('request', {'permission': permission});
    return result as bool? ?? false;
  }

  /// Vérifie si une permission est accordée
  static Future<bool> check(String permission) async {
    final result = await _channel.invokeMethod('check', {'permission': permission});
    return result as bool? ?? false;
  }

  // Raccourcis
  static Future<bool> requestMicrophone() => request('microphone');
  static Future<bool> requestCamera() => request('camera');
  static Future<bool> requestNotifications() => request('notifications');
  static Future<bool> requestStorage() => request('storage');
  static Future<bool> requestLocation() => request('location');
  static Future<bool> requestCalendar() => request('calendar');

  /// Demande toutes les permissions nécessaires au démarrage
  static Future<Map<String, bool>> requestAll() async {
    final results = <String, bool>{};
    results['microphone'] = await requestMicrophone();
    results['camera'] = await requestCamera();
    results['notifications'] = await requestNotifications();
    return results;
  }
}