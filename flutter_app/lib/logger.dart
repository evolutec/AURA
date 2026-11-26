import 'dart:io';

class AppLogger {
  static File? _file;
  static Future<void> init() async {
    try {
      final dir = Directory.current;
      _file = File('${dir.path}${Platform.pathSeparator}aura.log');
    } catch (_) {}
  }

  static void log(String level, String message) {
    final line = '[${DateTime.now().toIso8601String()}] [$level] $message';
    // ignore: avoid_print
    print(line);
    try {
      _file?.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  static void info(String m) => log('INFO', m);
  static void warn(String m) => log('WARN', m);
  static void error(String m) => log('ERROR', m);
  static void debug(String m) => log('DEBUG', m);
}