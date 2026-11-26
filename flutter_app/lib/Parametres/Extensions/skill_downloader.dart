import 'dart:convert';
import 'dart:io';

import 'extension_item.dart';

/// Récupère le SKILL.md d'un dépôt GitHub pour rendre un skill utilisable.
class SkillDownloader {
  /// Tente de télécharger SKILL.md depuis l'URL du dépôt (branche main/master).
  /// Retourne l'item enrichi avec config['skill_md'].
  static Future<ExtensionItem> enrich(ExtensionItem item) async {
    if (item.kind != ExtensionKind.skill) return item;
    final url = item.config['url'] ?? '';
    if (url.isEmpty) return item;
    final match = RegExp(r'github\.com/([^/]+)/([^/#]+)').firstMatch(url);
    if (match == null) return item;
    final owner = match.group(1)!;
    final repo = match.group(2)!.replaceAll('.git', '');
    final client = HttpClient();
    try {
      for (final branch in ['main', 'master']) {
        final uri = Uri.parse(
          'https://raw.githubusercontent.com/$owner/$repo/$branch/SKILL.md',
        );
        final req =
            await client.getUrl(uri).timeout(const Duration(seconds: 12));
        req.headers.set('User-Agent', 'Aura/1.0');
        final res = await req.close().timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          final md = await res.transform(utf8.decoder).join();
          final cfg = {...item.config, 'skill_md': md, 'skill_repo': '$owner/$repo'};
          return ExtensionItem(
            id: item.id,
            name: item.name,
            description: item.description,
            kind: item.kind,
            icon: item.icon,
            enabled: item.enabled,
            config: cfg,
          );
        }
      }
    } catch (_) {
    } finally {
      client.close();
    }
    return item;
  }
}