import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import 'appearance.dart';
import 'settings_colors.dart';

/// Page « Préférences et Apparence » : langue, thème, taille et polices.
class SettingsPage extends StatelessWidget {
  final int themeProfile;
  final String lang;
  final String version;
  final AppearanceSettings appearance;
  final List<(String, String)> languages;
  final ValueChanged<int> onThemeProfileChanged;
  final ValueChanged<String> onSetLang;
  final ValueChanged<AppearanceSettings> onAppearanceChanged;

  const SettingsPage({
    super.key,
    required this.themeProfile,
    required this.lang,
    required this.version,
    required this.appearance,
    required this.languages,
    required this.onThemeProfileChanged,
    required this.onSetLang,
    required this.onAppearanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = SettingsColors.of(context)!;
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 900 ? 32.0 : 20.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appearance,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        version,
                        style: TextStyle(color: colors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _card(colors, l10n.language, [
              _dropdownRow(
                colors,
                DropdownButton<String>(
                  value: lang,
                  dropdownColor: colors.panel2,
                  underline: const SizedBox(),
                  items: languages
                      .map(
                        (l) => DropdownMenuItem<String>(
                          value: l.$1,
                          child: Text(
                            l.$2,
                            style: TextStyle(color: colors.text, fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSetLang(v);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _card(colors, l10n.appearance, [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < kThemeProfiles.length; i++)
                    _profileChip(
                      colors,
                      kThemeProfiles[i],
                      themeProfile == i,
                      () => onThemeProfileChanged(i),
                    ),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            _card(colors, l10n.uiScale, [
              _dropdownRow(
                colors,
                DropdownButton<String>(
                  value: _uiScaleLabel(appearance.uiScale),
                  dropdownColor: colors.panel2,
                  underline: const SizedBox(),
                  items: kUiScaleOptions
                      .map(
                        (o) => DropdownMenuItem<String>(
                          value: o.$1,
                          child: Text(
                            o.$1,
                            style: TextStyle(color: colors.text, fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final scale = kUiScaleOptions
                        .firstWhere((o) => o.$1 == v)
                        .$2;
                    onAppearanceChanged(
                      appearance.copyWith(uiScale: scale),
                    );
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _card(colors, l10n.textSize, [
              _dropdownRow(
                colors,
                DropdownButton<String>(
                  value: _scaleLabel(appearance.textScale),
                  dropdownColor: colors.panel2,
                  underline: const SizedBox(),
                  items: kTextScaleOptions
                      .map(
                        (o) => DropdownMenuItem<String>(
                          value: o.$1,
                          child: Text(
                            o.$1,
                            style: TextStyle(color: colors.text, fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final scale = kTextScaleOptions
                        .firstWhere((o) => o.$1 == v)
                        .$2;
                    onAppearanceChanged(
                      appearance.copyWith(textScale: scale),
                    );
                  },
                ),
              ),
            ]),
            const SizedBox(height: 16),
            _card(colors, l10n.font, [
              _dropdownRowLabel(
                colors,
                l10n.interface,
                _fontDropdown(colors, appearance.interfaceFont, (v) {
                  onAppearanceChanged(
                    appearance.copyWith(interfaceFont: v),
                  );
                }),
              ),
              Divider(height: 1, color: colors.border),
              _dropdownRowLabel(
                colors,
                '${l10n.chat} · ${l10n.me}',
                _fontDropdown(colors, appearance.chatUserFont, (v) {
                  onAppearanceChanged(
                    appearance.copyWith(chatUserFont: v),
                  );
                }),
              ),
              Divider(height: 1, color: colors.border),
              _dropdownRowLabel(
                colors,
                '${l10n.chat} · ${l10n.model}',
                _fontDropdown(colors, appearance.chatModelFont, (v) {
                  onAppearanceChanged(
                    appearance.copyWith(chatModelFont: v),
                  );
                }),
              ),
            ]),
          ],
        );
      },
    );
  }

  String _scaleLabel(double scale) {
    for (final o in kTextScaleOptions) {
      if ((o.$2 - scale).abs() < 0.001) return o.$1;
    }
    return kTextScaleOptions[1].$1;
  }

  String _uiScaleLabel(double scale) {
    for (final o in kUiScaleOptions) {
      if ((o.$2 - scale).abs() < 0.001) return o.$1;
    }
    return kUiScaleOptions[2].$1;
  }

  Widget _card(SettingsColors colors, String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _dropdownRow(SettingsColors colors, Widget control) {
    return Row(
      children: [
        Expanded(child: const SizedBox()),
        control,
      ],
    );
  }

  Widget _dropdownRowLabel(
    SettingsColors colors,
    String label,
    Widget control,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: colors.text),
          ),
        ),
        control,
      ],
    );
  }

  Widget _fontDropdown(
    SettingsColors colors,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      dropdownColor: colors.panel2,
      underline: const SizedBox(),
      items: kAvailableFonts
          .map(
            (f) => DropdownMenuItem<String>(
              value: f,
              child: Text(
                f,
                style: TextStyle(color: colors.text, fontSize: 13),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _profileChip(
    SettingsColors colors,
    ThemeProfile profile,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? profile.accent.withValues(alpha: colors.isDark ? 0.28 : 0.16)
              : colors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? profile.accent : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              profile.icon,
              size: 18,
              color: selected ? profile.accent : colors.muted,
            ),
            const SizedBox(width: 8),
            Text(
              profile.name,
              style: TextStyle(
                color: selected ? colors.text : colors.muted,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}