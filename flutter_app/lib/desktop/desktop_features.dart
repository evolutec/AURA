// Desktop features stub - avoids importing desktop-only packages
// The native implementation uses method channels, not direct imports

import 'desktop_service.dart';

// No-op implementation for platforms without desktop packages
// The actual tray/hotkey/window management is handled via platform channels
// in desktop_service_native.dart

// Stub classes for web/analysis
class HotKeyEvent {
  final String hotKey;
  HotKeyEvent(this.hotKey);
}

class Menu {
  Menu addItem(MenuItem item) => this;
  Menu addSeparator() => this;
}

class MenuItem {
  final String key;
  final String label;
  MenuItem({required this.key, required this.label});
}