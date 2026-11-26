import 'package:material_ui/material_ui.dart';

/// Profil de thème (nom, icône, mode sombre, couleur d'accent).
class ThemeProfile {
  final String name;
  final IconData icon;
  final bool isDark;
  final Color accent;

  const ThemeProfile(this.name, this.icon, this.isDark, this.accent);
}

/// Profils de couleurs proposés (au-delà de clair/sombre).
const List<ThemeProfile> kThemeProfiles = [
  ThemeProfile('Light', Icons.light_mode_rounded, false, Color(0xFF9B7BFF)),
  ThemeProfile('Dark', Icons.dark_mode_rounded, true, Color(0xFF9B7BFF)),
  ThemeProfile('Midnight', Icons.nightlight_rounded, true, Color(0xFF5B8CFF)),
  ThemeProfile('Sunset', Icons.wb_twilight_rounded, true, Color(0xFFFF8A5B)),
  ThemeProfile('Forest', Icons.park_rounded, true, Color(0xFF4ADE80)),
];

/// Palette partagée de la modale paramètres (thème clair/sombre).
class SettingsColors {
  final Color bg;
  final Color panel;
  final Color panel2;
  final Color border;
  final Color accent;
  final Color text;
  final Color muted;
  final Color white70;
  final bool isDark;

  const SettingsColors({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.border,
    required this.accent,
    required this.text,
    required this.muted,
    required this.white70,
    required this.isDark,
  });

  static SettingsColors? of(BuildContext context) =>
      SettingsColorsScope.of(context)?.colors;

  factory SettingsColors.fromDark(bool isDark) => SettingsColors(
    isDark: isDark,
    bg: isDark ? const Color(0xFF0B0D12) : const Color(0xFFF5F6F8),
    panel: isDark ? const Color(0xFF12151C) : const Color(0xFFFFFFFF),
    panel2: isDark ? const Color(0xFF191D26) : const Color(0xFFF1F2F5),
    border: isDark ? const Color(0xFF252A35) : const Color(0xFFE5E7EB),
    accent: const Color(0xFF9B7BFF),
    text: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
    muted: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
    white70: isDark ? Colors.white70 : Colors.black54,
  );

  factory SettingsColors.fromProfile(int index) {
    final profile = kThemeProfiles[index.clamp(0, kThemeProfiles.length - 1)];
    switch (profile.name) {
      case 'Midnight':
        return SettingsColors(
          isDark: true,
          bg: const Color(0xFF020617),
          panel: const Color(0xFF0F172A),
          panel2: const Color(0xFF1E293B),
          border: const Color(0xFF334155),
          accent: profile.accent,
          text: const Color(0xFFE2E8F0),
          muted: const Color(0xFF94A3B8),
          white70: Colors.white70,
        );
      case 'Sunset':
        return SettingsColors(
          isDark: true,
          bg: const Color(0xFF0F0A07),
          panel: const Color(0xFF1A1410),
          panel2: const Color(0xFF241A14),
          border: const Color(0xFF3A2A20),
          accent: profile.accent,
          text: const Color(0xFFF5E9E0),
          muted: const Color(0xFFC9A99A),
          white70: Colors.white70,
        );
      case 'Forest':
        return SettingsColors(
          isDark: true,
          bg: const Color(0xFF07110B),
          panel: const Color(0xFF0F1A14),
          panel2: const Color(0xFF15241C),
          border: const Color(0xFF24382C),
          accent: profile.accent,
          text: const Color(0xFFE7F5EC),
          muted: const Color(0xFF9CB8A6),
          white70: Colors.white70,
        );
      default:
        return SettingsColors.fromDark(profile.isDark).copyWith(
          accent: profile.accent,
        );
    }
  }

  SettingsColors copyWith({
    Color? bg,
    Color? panel,
    Color? panel2,
    Color? border,
    Color? accent,
    Color? text,
    Color? muted,
    Color? white70,
    bool? isDark,
  }) =>
      SettingsColors(
        bg: bg ?? this.bg,
        panel: panel ?? this.panel,
        panel2: panel2 ?? this.panel2,
        border: border ?? this.border,
        accent: accent ?? this.accent,
        text: text ?? this.text,
        muted: muted ?? this.muted,
        white70: white70 ?? this.white70,
        isDark: isDark ?? this.isDark,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsColors &&
          isDark == other.isDark &&
          bg == other.bg &&
          panel == other.panel &&
          panel2 == other.panel2 &&
          border == other.border &&
          accent == other.accent &&
          text == other.text &&
          muted == other.muted &&
          white70 == other.white70);

  @override
  int get hashCode => Object.hash(
    isDark,
    bg,
    panel,
    panel2,
    border,
    accent,
    text,
    muted,
    white70,
  );
}

/// InheritedWidget exposant la palette à toutes les pages de paramètres.
class SettingsColorsScope extends InheritedWidget {
  const SettingsColorsScope({
    super.key,
    required this.colors,
    required super.child,
  });

  final SettingsColors colors;

  static SettingsColorsScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsColorsScope>();

  @override
  bool updateShouldNotify(SettingsColorsScope oldWidget) =>
      colors != oldWidget.colors;
}
