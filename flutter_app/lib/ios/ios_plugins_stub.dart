// Stub pour plateformes non-iOS
// Retourne des valeurs par défaut

import 'package:flutter/services.dart';

class AuraKeychain {
  static const MethodChannel _channel = MethodChannel('aura/keychain');

  static Future<bool> set(String key, String value) async => false;
  static Future<String?> get(String key) async => null;
  static Future<bool> delete(String key) async => false;
  static Future<bool> has(String key) async => false;
}

class AuraShare {
  static const MethodChannel _channel = MethodChannel('aura/share');

  static Future<Map<String, dynamic>?> getSharedContent() async => null;
  static Future<void> clearSharedContent() async {}

  static Stream<SharedContent> get onSharedContent => const Stream.empty();
}

class AuraWidget {
  static const MethodChannel _channel = MethodChannel('aura/widget');

  static Future<void> update(Map<String, dynamic> stats) async {}
  static Future<void> reload() async {}
}

class AuraVoice {
  static const MethodChannel _channel = MethodChannel('aura/voice');

  static Future<bool> requestPermission() async => false;
  static Future<bool> startListening() async => false;
  static Future<void> stopListening() async {}
  static Future<void> speak(String text, {String lang = 'en-US'}) async {}
  static Future<void> stopSpeaking() async {}

  static Stream<VoiceResult> get onVoiceResult => const Stream.empty();
}

class SharedContent {
  final String type;
  final String? text;
  final String? imagePath;
  SharedContent({required this.type, this.text, this.imagePath});
}

class VoiceResult {
  final String text;
  final bool isFinal;
  VoiceResult({required this.text, required this.isFinal});
}