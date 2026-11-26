// Stub for web/non-desktop platforms
// No-op implementations

import 'package:flutter/widgets.dart';
import 'desktop_service.dart';

mixin TrayListener on Widget {
  void onTrayIconMouseDown() {}
  void onTrayIconRightMouseDown() {}
}

mixin HotKeyListener on Widget {
  void onHotKeyReleased(HotKeyEvent event) {}
}

Future<void> initDesktopFeatures() async {
  // No-op on web/mobile
}

void handleTrayEvent(String key) {
  // No-op
}

// Stub classes for web
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