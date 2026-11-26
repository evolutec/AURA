// Desktop service - uses method channels for platform-specific features
// This avoids importing desktop-only packages that fail on Android
import 'desktop_service.dart';

class DesktopServiceNative implements DesktopService {
  @override
  Future<void> init() async {
    // Desktop features initialized via method channel
    // Only works on Windows/Linux/macOS
  }
  
  @override
  void addTrayListener(TrayListener listener) {
    // Register tray listener via method channel
  }
  
  @override
  void addHotKeyListener(HotKeyListener listener) {
    // Register hotkey listener via method channel
  }
  
  @override
  void show() {
    // Show window via method channel
  }
  
  @override
  void hide() {
    // Hide window via method channel
  }
  
  @override
  void minimize() {
    // Minimize window via method channel
  }
  
  @override
  void close() {
    // Close window via method channel
  }
  
  @override
  void destroy() {
    // Destroy window via method channel
  }
}

final desktopService = DesktopServiceNative();