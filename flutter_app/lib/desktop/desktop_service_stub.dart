// Stub implementation for web
import 'desktop_service.dart';

class DesktopServiceStub implements DesktopService {
  @override
  Future<void> init() async {}
  
  @override
  void addTrayListener(TrayListener listener) {}
  
  @override
  void addHotKeyListener(HotKeyListener listener) {}
  
  @override
  void show() {}
  
  @override
  void hide() {}
  
  @override
  void minimize() {}
  
  @override
  void close() {}
  
  @override
  void destroy() {}
}

final desktopService = DesktopServiceStub();