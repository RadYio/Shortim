import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/services/sound_service.dart';
import 'package:shortim/services/storage_service.dart';

/// End-to-end run on a device/simulator with the real audio and wakelock
/// plugins: `flutter test integration_test -d <device>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  configureFonts();

  testWidgets('full flow with real plugins', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // The simulator's language is unknown: pin French, as the test expects.
    await prefs.setString('settings', '{"language":"fr"}');

    await tester.pumpWidget(
      ShortimApp(sounds: AudioplayersSoundService(), storage: StorageService()),
    );
    await tester.pumpAndSettle();

    // Three intervals, reorder the last one to the top, repeat twice.
    await tester.tap(find.byTooltip('Ajouter un intervalle'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter un intervalle'));
    await tester.pumpAndSettle();
    expect(find.text('3.'), findsOneWidget);
    await tester.tap(find.byTooltip('Supprimer').last);
    await tester.pumpAndSettle();
    expect(find.text('3.'), findsNothing);

    await tester.tap(find.text('Répéter x fois'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Plus de répétitions'));
    await tester.pumpAndSettle();
    expect(find.text('3 fois'), findsOneWidget);
    expect(find.text('Durée totale : 03:00  (3 × 01:00)'), findsOneWidget);

    // The run screen repaints every frame while running: it never settles.
    await tester.tap(find.text('Démarrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('INTERVALLE 1/2'), findsOneWidget);
    expect(find.text('TOUR 1/3'), findsOneWidget);
    expect(find.text('Suivant : 00:30'), findsOneWidget);

    // Let it run for real (screenshot window), then pause / resume.
    await tester.pump(const Duration(seconds: 6));
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 6)));
    await tester.pump();
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Reprendre'), findsOneWidget);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 4)));
    await tester.tap(find.text('Reprendre'));
    await tester.pump();

    await tester.tap(find.text('Arrêter'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.widgetWithText(TextButton, 'Arrêter'));
    await tester.pumpAndSettle();
    expect(find.text('Démarrer'), findsOneWidget);

    // Save the series, find it in "Mes séries" and load it back.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Muscu1');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mes séries'));
    await tester.pumpAndSettle();
    expect(find.text('Muscu1'), findsOneWidget);
    expect(find.text('2 intervalles · 01:00 · ×3'), findsOneWidget);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await tester.tap(find.text('Muscu1'));
    await tester.pumpAndSettle();
    expect(find.text('Durée totale : 03:00  (3 × 01:00)'), findsOneWidget);

    // Settings: preview a sound theme (real audio session + ducking), then
    // switch the whole UI to English without restarting.
    await tester.tap(find.byTooltip('Réglages'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marimba'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Total: 03:00  (3 × 01:00)'), findsOneWidget);
  });
}
