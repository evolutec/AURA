// Native iOS plugins implementation
import 'package:flutter/services.dart';

class AuraKeychain {
  static const MethodChannel _channel = MethodChannel('aura/keychain');

  static Future<bool> set(String key, String value) async {
    final result = await _channel.invokeMethod('set', {'key': key, 'value': value});
    return result as bool? ?? false;
  }

  static Future<String?> get(String key) async {
    return await _channel.invokeMethod('get', {'key': key});
  }

  static Future<bool> delete(String key) async {
    final result = await _channel.invokeMethod('delete', {'key': key});
    return result as bool? ?? false;
  }

  static Future<bool> has(String key) async {
    final result = await _channel.invokeMethod('has', {'key': key});
    return result as bool? ?? false;
  }
}

class AuraShare {
  static const MethodChannel _channel = MethodChannel('aura/share');
  static const EventChannel _eventChannel = EventChannel('aura/share/events');

  static Future<Map<String, dynamic>?> getSharedContent() async {
    return await _channel.invokeMethod('getSharedContent');
  }

  static Future<void> clearSharedContent() async {
    await _channel.invokeMethod('clearSharedContent');
  }

  static Stream<SharedContent> get onSharedContent {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => SharedContent.fromMap(Map<String, dynamic>.from(event)),
    );
  }
}

class AuraWidget {
  static const MethodChannel _channel = MethodChannel('aura/widget');

  static Future<void> update(Map<String, dynamic> stats) async {
    await _channel.invokeMethod('update', stats);
  }

  static Future<void> reload() async {
    await _channel.invokeMethod('reload');
  }
}

class AuraVoice {
  static const MethodChannel _channel = MethodChannel('aura/voice');
  static const EventChannel _eventChannel = EventChannel('aura/voice/events');

  static Future<bool> requestPermission() async {
    final result = await _channel.invokeMethod('requestPermission');
    return result as bool? ?? false;
  }

  static Future<bool> startListening() async {
    return await _channel.invokeMethod('startListening') as bool? ?? false;
  }

  static Future<void> stopListening() async {
    await _channel.invokeMethod('stopListening');
  }

  static Future<void> speak(String text, {String lang = 'fr-FR'}) async {
    await _channel.invokeMethod('speak', {'text': text, 'lang': lang});
  }

  static Future<void> stopSpeaking() async {
    await _channel.invokeMethod('stopSpeaking');
  }

  static Stream<VoiceResult> get onVoiceResult {
    return _eventChannel.receiveBroadcastStream().map(
      (event) {
        final map = Map<String, dynamic>.from(event);
        return VoiceResult(
          text: map['text'] as String? ?? '',
          isFinal: map['is_final'] as bool? ?? false,
        );
      },
    );
  }
}

class SharedContent {
  final String type;
  final String? text;
  final String? imagePath;

  SharedContent({required this.type, this.text, this.imagePath});

  factory SharedContent.fromMap(Map<String, dynamic> map) {
    return SharedContent(
      type: map['type'] as String? ?? 'text',
      text: map['text'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }
}

class VoiceResult {
  final String text;
  final bool isFinal;

  VoiceResult({required this.text, required this.isFinal});
}