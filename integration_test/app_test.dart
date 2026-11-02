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

    await tester.tap(find.text('Démarrer'));
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Arrêter'));
    await tester.pumpAndSettle();
    expect(find.text('Démarrer'), findsOneWidget);
  });
}
