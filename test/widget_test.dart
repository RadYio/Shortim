import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/screens/splash_screen.dart';
import 'package:shortim/services/storage_service.dart';

import 'fakes.dart';

void main() {
  setUpAll(configureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpApp(WidgetTester tester, {bool settle = true}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ShortimApp(sounds: FakeSoundService(), storage: StorageService()),
    );
    if (settle) await tester.pumpAndSettle();
  }

  /// The run screen repaints every frame while running, so it never
  /// settles: pump through a page transition instead.
  Future<void> pumpTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Opacity of the nearest entrance/exit fade above [finder].
  double cardOpacity(WidgetTester tester, Finder finder) => tester
      .widget<FadeTransition>(
        find.ancestor(of: finder, matching: find.byType(FadeTransition)).first,
      )
      .opacity
      .value;

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
    await pumpTransition(tester);

    expect(find.text('INTERVALLE 1/2'), findsOneWidget);
    expect(find.text('TOUR 1/2'), findsOneWidget);
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

  testWidgets('splash draws the mark, then opens the setup screen', (
    tester,
  ) async {
    await pumpApp(tester, settle: false);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Démarrer'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Démarrer'), findsOneWidget);
  });

  testWidgets('tapping the splash skips it', (tester) async {
    await pumpApp(tester, settle: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(SplashScreen));
    // Well before the 2.9 s timeline ends: the tap did the navigation.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(find.text('Démarrer'), findsOneWidget);
  });

  testWidgets('added cards animate in, removed cards animate out', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Ajouter un intervalle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(cardOpacity(tester, find.text('2.')), lessThan(1));
    await tester.pumpAndSettle();
    expect(cardOpacity(tester, find.text('2.')), 1);

    // The series updates at once; the card stays until it has collapsed.
    await tester.tap(find.byTooltip('Supprimer').last);
    await tester.pump();
    expect(find.text('Durée totale : 00:30'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('2.'), findsOneWidget);
    expect(cardOpacity(tester, find.text('2.')), lessThan(1));

    await tester.pumpAndSettle();
    expect(find.text('2.'), findsNothing);
    expect(find.text('1.'), findsOneWidget);
  });
}
