import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/services/sound_service.dart';
import 'package:shortim/services/storage_service.dart';

class FakeSoundService implements SoundService {
  final played = <String>[];

  @override
  Future<void> init() async {}
  @override
  Future<void> beep() async => played.add('beep');
  @override
  Future<void> intervalChange() async => played.add('change');
  @override
  Future<void> finish() async => played.add('finish');
  @override
  Future<void> startKeepAlive() async {}
  @override
  Future<void> stopKeepAlive() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShortimApp(sounds: FakeSoundService(), storage: StorageService()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('builds a series, runs it, pauses and stops', (tester) async {
    await pumpApp(tester);

    expect(find.text('Durée totale : 00:30'), findsOneWidget);

    // Add a second interval (copies the current one).
    await tester.tap(find.byTooltip('Ajouter un intervalle'));
    await tester.pumpAndSettle();
    expect(find.text('2.'), findsOneWidget);
    expect(find.text('Durée totale : 01:00'), findsOneWidget);

    // Repeat the series twice.
    await tester.tap(find.text('Répéter x fois'));
    await tester.pumpAndSettle();
    expect(find.text('2 fois'), findsOneWidget);
    expect(find.text('Durée totale : 02:00  (2 × 01:00)'), findsOneWidget);

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();

    expect(find.text('Intervalle 1/2'), findsOneWidget);
    expect(find.text('Tour 1/2'), findsOneWidget);
    expect(find.text('Suivant : 00:30'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Reprendre'), findsOneWidget);
    expect(find.text('EN PAUSE'), findsOneWidget);

    await tester.tap(find.text('Arrêter'));
    await tester.pumpAndSettle();
    expect(find.text('Arrêter la série ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Arrêter'));
    await tester.pumpAndSettle();

    expect(find.text('Démarrer'), findsOneWidget);
  });

  testWidgets('removes an interval and caps the list at 30', (tester) async {
    await pumpApp(tester);

    for (var i = 0; i < 29; i++) {
      await tester.tap(find.byTooltip('Ajouter un intervalle'));
      await tester.pump();
    }
    expect(find.text('Durée totale : 15:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter un intervalle'));
    await tester.pump();
    expect(find.text('30 intervalles maximum'), findsOneWidget);
    expect(find.text('Durée totale : 15:00'), findsOneWidget);

    await tester.tap(find.byTooltip('Supprimer').first);
    await tester.pump();
    expect(find.text('Durée totale : 14:30'), findsOneWidget);
  });
}
