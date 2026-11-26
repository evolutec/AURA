import 'package:flutter_chromium_webview/flutter_chromium_webview.dart';

/// Registre des contrôleurs Chromium par session navigateur.
class BrowserRegistry {
  static final Map<String, ChromiumWebViewController> _sessions = {};
  static final Map<String, String> _urls = {};

  static void register(String sessionId, ChromiumWebViewController controller) {
    _sessions[sessionId] = controller;
  }

  static void unregister(String sessionId) {
    _sessions.remove(sessionId);
    _urls.remove(sessionId);
  }

  static ChromiumWebViewController? get(String sessionId) =>
      _sessions[sessionId];

  static String? getUrl(String sessionId) => _urls[sessionId];

  static void setUrl(String sessionId, String url) {
    _urls[sessionId] = url;
  }
}
