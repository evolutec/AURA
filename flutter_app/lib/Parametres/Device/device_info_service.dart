import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeviceInfoService {
  static const _androidChannel = MethodChannel('aura/system_info');
  static const _windowsChannel = MethodChannel('aura/device_info');

  static Future<Map<String, String>> read() async {
    final channel = switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidChannel,
      TargetPlatform.windows => _windowsChannel,
      _ => null,
    };
    if (channel == null) return const {};

    try {
      final result = await channel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      return result?.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ) ??
          const {};
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }
}
