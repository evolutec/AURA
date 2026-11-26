import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aura_app/l10n/app_localizations.dart';
import 'package:aura_app/Parametres/Parametres/settings_colors.dart';
import 'package:aura_app/Parametres/CloudProviders/cloud_provider.dart';
import 'package:aura_app/Parametres/CloudProviders/page_cloud.dart';

void main() {
  testWidgets('CloudPage: adding a provider does not crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsColorsScope(
          colors: SettingsColors.fromDark(false),
          child: const Scaffold(body: CloudPage()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Add provider'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Mistral');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Mistral'), findsOneWidget);
  });

  test('CloudProvider json round-trip', () {
    const provider = CloudProvider(
      id: 'test-id',
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      apiKey: 'sk-test',
      models: ['gpt-4o', 'gpt-4o-mini'],
    );
    final restored = CloudProvider.fromJsonString(provider.toJsonString());
    expect(restored.id, provider.id);
    expect(restored.name, provider.name);
    expect(restored.baseUrl, provider.baseUrl);
    expect(restored.apiKey, provider.apiKey);
    expect(restored.models, provider.models);
    expect(restored.enabled, isTrue);
    expect(restored.builtIn, isFalse);
  });
}
