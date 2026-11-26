import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_app/main.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

/// A 1x1 transparent PNG (base64) used as a mock asset for tests.
final _transparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Mock AssetBundle that returns a transparent PNG for any asset request,
/// a valid empty asset manifest, and empty strings — so widget tests don't
/// fail on missing assets.
class _MockAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async => ByteData.view(_transparentPng.buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';

  @override
  Future<T> loadStructuredData<T>(
    String key,
    Future<T> Function(String value) parser, {
    bool cache = true,
  }) async => parser('');

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser, {
    bool cache = true,
  }) async {
    // Return a valid empty asset manifest (empty map encoded via StandardMessageCodec).
    final codec = StandardMessageCodec();
    final encoded = codec.encodeMessage(<String, Object>{})!;
    final data = ByteData.view(encoded.buffer, encoded.offsetInBytes, encoded.lengthInBytes);
    return parser(data);
  }
}

void main() {
  testWidgets('AURA app launches', (WidgetTester tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _MockAssetBundle(),
        child: const AuraApp(),
      ),
    );

    // The app should build without throwing.
    expect(find.byType(AuraApp), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    // Sidebar toggle icon should be present (chevron_right when expanded).
    expect(find.byIcon(Icons.chevron_right), findsWidgets);

    // Composer should render the agent selector.
    expect(find.byType(DropdownButton<String>), findsWidgets);
  });
}