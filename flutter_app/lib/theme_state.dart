import 'package:material_ui/material_ui.dart';

/// InheritedWidget providing color theming data to descendant widgets,
/// avoiding passing _panel, _panel2, _border, _accent, _text, _muted, _white70
/// to every page via the constructor.
class ThemeState extends InheritedWidget {
  final Color panel;
  final Color panel2;
  final Color border;
  final Color accent;
  final Color text;
  final Color muted;
  final Color white70;

  const ThemeState({
    required super.child,
    required this.panel,
    required this.panel2,
    required this.border,
    required this.accent,
    required this.text,
    required this.muted,
    required this.white70,
  });

  static ThemeState? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeState>();

  @override
  bool updateShouldNotify(covariant ThemeState old) => false;
}
