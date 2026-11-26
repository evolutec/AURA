// AURA Share Target Plugin
// Reçoit du texte/images depuis le menu de partage Android

import 'package:flutter/services.dart';

class AuraShareTarget {
  static const MethodChannel _channel = MethodChannel('aura/share_target');

  /// Initialise le plugin (à appeler dans main())
  static Future<void> init() async {
    // Le plugin est enregistré automatiquement via le manifest
  }

  /// Récupère le texte partagé (si l'app a été lancée via "Partager")
  static Future<String?> getSharedText() async {
    final result = await _channel.invokeMethod('getSharedText');
    return result as String?;
  }

  /// Récupère le chemin de l'image partagée
  static Future<String?> getSharedImagePath() async {
    final result = await _channel.invokeMethod('getSharedImagePath');
    return result as String?;
  }

  /// Si du contenu a été partagé
  static Future<bool> hasSharedContent() async {
    final text = await getSharedText();
    final image = await getSharedImagePath();
    return (text != null && text.isNotEmpty) || (image != null && image.isNotEmpty);
  }

  /// Stream des événements de partage entrant
  static Stream<SharedContent> get onSharedContent {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => SharedContent.fromMap(Map<String, dynamic>.from(event)),
    );
  }

  static const EventChannel _eventChannel = EventChannel('aura/share_target/events');
}

class SharedContent {
  final String? text;
  final String? imagePath;
  final String mimeType;

  SharedContent({this.text, this.imagePath, required this.mimeType});

  factory SharedContent.fromMap(Map<String, dynamic> map) {
    return SharedContent(
      text: map['text'] as String?,
      imagePath: map['image_path'] as String?,
      mimeType: map['mime_type'] as String? ?? 'text/plain',
    );
  }
}