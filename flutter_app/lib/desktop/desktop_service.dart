// Desktop service abstraction
// Provides a unified interface for desktop features

import 'dart:io';

// Conditional import
export 'desktop_service_stub.dart'
    if (dart.library.io) 'desktop_service_native.dart';

// Desktop service interface
abstract class DesktopService {
  Future<void> init();
  void addTrayListener(TrayListener listener);
  void addHotKeyListener(HotKeyListener listener);
  void show();
  void hide();
  void minimize();
  void close();
  void destroy();
}

// Tray listener interface
abstract class TrayListener {
  void onTrayIconMouseDown() {}
  void onTrayIconRightMouseDown() {}
}

// Hotkey listener interface
abstract class HotKeyListener {
  void onHotKeyReleased(String hotKey) {}
}

// Check if running on desktop
bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;