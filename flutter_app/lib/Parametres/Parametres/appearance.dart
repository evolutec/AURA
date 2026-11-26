import 'package:material_ui/material_ui.dart';

/// Modèle d'apparence partagé (taille du texte + polices) importable dans
/// toutes les pages via [AppearanceScope.of].
class AppearanceSettings {
  final double textScale;
  final double uiScale;
  final String interfaceFont;
  final String chatUserFont;
  final String chatModelFont;

  const AppearanceSettings({
    this.textScale = 1.0,
    this.uiScale = 1.0,
    this.interfaceFont = 'Roboto',
    this.chatUserFont = 'Roboto',
    this.chatModelFont = 'Roboto',
  });

  AppearanceSettings copyWith({
    double? textScale,
    double? uiScale,
    String? interfaceFont,
    String? chatUserFont,
    String? chatModelFont,
  }) {
    return AppearanceSettings(
      textScale: textScale ?? this.textScale,
      uiScale: uiScale ?? this.uiScale,
      interfaceFont: interfaceFont ?? this.interfaceFont,
      chatUserFont: chatUserFont ?? this.chatUserFont,
      chatModelFont: chatModelFont ?? this.chatModelFont,
    );
  }

  Map<String, dynamic> toJson() => {
    'textScale': textScale,
    'uiScale': uiScale,
    'interfaceFont': interfaceFont,
    'chatUserFont': chatUserFont,
    'chatModelFont': chatModelFont,
  };

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    return AppearanceSettings(
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      uiScale: (json['uiScale'] as num?)?.toDouble() ?? 1.0,
      interfaceFont: json['interfaceFont'] as String? ?? 'Roboto',
      chatUserFont: json['chatUserFont'] as String? ?? 'Roboto',
      chatModelFont: json['chatModelFont'] as String? ?? 'Roboto',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppearanceSettings &&
          other.textScale == textScale &&
          other.uiScale == uiScale &&
          other.interfaceFont == interfaceFont &&
          other.chatUserFont == chatUserFont &&
          other.chatModelFont == chatModelFont);

  @override
  int get hashCode =>
      Object.hash(textScale, uiScale, interfaceFont, chatUserFont, chatModelFont);
}

/// Polices proposées dans les paramètres d'apparence.
const List<String> kAvailableFonts = [
  'Roboto',
  'Inter',
  'Poppins',
  'Montserrat',
  'Fira Code',
  'Merriweather',
];

/// Échelles de taille de texte proposées.
const List<(String, double)> kTextScaleOptions = [
  ('Petit', 0.85),
  ('Normal', 1.0),
  ('Grand', 1.15),
  ('Très grand', 1.3),
];

/// Échelles de mise à l'échelle globale de l'interface (texte + éléments).
const List<(String, double)> kUiScaleOptions = [
  ('80 %', 0.8),
  ('90 %', 0.9),
  ('100 %', 1.0),
  ('110 %', 1.1),
  ('125 %', 1.25),
  ('150 %', 1.5),
];

/// InheritedWidget exposant l'apparence à toutes les pages.
class AppearanceScope extends InheritedWidget {
  const AppearanceScope({
    super.key,
    required this.settings,
    required super.child,
  });

  final AppearanceSettings settings;

  static AppearanceSettings? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppearanceScope>()?.settings;

  @override
  bool updateShouldNotify(AppearanceScope oldWidget) =>
      settings != oldWidget.settings;
}