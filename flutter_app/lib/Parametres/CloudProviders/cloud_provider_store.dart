import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_provider.dart';

/// Persistance des fournisseurs cloud (SharedPreferences, comme le reste
/// des paramètres de l'application).
class CloudProviderStore {
  static const _key = 'aura_cloud_providers_v1';

  Future<List<CloudProvider>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CloudProvider.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<CloudProvider> providers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(providers.map((p) => p.toJson()).toList()),
    );
  }
}
