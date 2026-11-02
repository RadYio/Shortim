import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/screens/run_screen.dart';
import 'package:shortim/services/storage_service.dart';

import 'fakes.dart';

void main() {
  setUpAll(configureFonts);
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

  /// Starts the app with one saved series: "Jambes", 2 × 00:20, repeated 3×.
  Future<void> pumpWithLibrary(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_series': jsonEncode([
        {
          'id': 'j',
          'name': 'Jambes',
          'intervals': [
            {'id': 'a', 'minutes': 0, 'seconds': 20},
            {'id': 'b', 'minutes': 0, 'seconds': 20},
          ],
          'loopMode': 'repeatN',
          'loopCount': 3,
        },
      ]),
    });
    await pumpApp(tester);
  }

  Future<void> openLibrary(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Mes séries'));
    await tester.pumpAndSettle();
  }

  Future<void> tapMenu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('saves the current series under a name', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Enregistrer la série'), findsOneWidget);
    expect(find.text('Muscu1'), findsOneWidget); // Placeholder only.

    // Empty names cannot be saved.
    final confirm = find.widgetWithText(TextButton, 'Enregistrer');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Jambes ');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('« Jambes » enregistrée'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    final stored = jsonDecode(prefs.getString('saved_series')!) as List;
    expect((stored.single as Map)['name'], 'Jambes');

    await openLibrary(tester);
    expect(find.text('Jambes'), findsOneWidget);
    expect(find.text('1 intervalle · 00:30'), findsOneWidget);
    expect(find.text('1 SÉRIE'), findsOneWidget);
  });

  testWidgets('tapping a saved series loads it into the editor', (
    tester,
  ) async {
    await pumpWithLibrary(tester);
    expect(find.text('Durée totale : 00:30'), findsOneWidget);

    await openLibrary(tester);
    expect(find.text('2 intervalles · 00:40 · ×3'), findsOneWidget);
    await tester.tap(find.text('Jambes'));
    await tester.pumpAndSettle();

    expect(find.text('Durée totale : 02:00  (3 × 00:40)'), findsOneWidget);
    expect(find.text('3 fois'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);

    // Saving again offers to replace the loaded series, pre-filled.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Jambes'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Remplacer'));
    await tester.pumpAndSettle();
    expect(find.text('« Jambes » mise à jour'), findsOneWidget);
  });

  testWidgets('renames, refusing a name already used', (tester) async {
    await pumpWithLibrary(tester);
    // A second series to clash with.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Bras');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    await openLibrary(tester);
    expect(find.text('2 SÉRIES'), findsOneWidget);
    // Newest first, so the last "Options" belong to "Jambes".
    await tester.tap(find.byTooltip('Options').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bras');
    await tester.pump();
    expect(find.text('Ce nom est déjà utilisé.'), findsOneWidget);
    final confirm = find.widgetWithText(TextButton, 'Renommer');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Cuisses');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Cuisses'), findsOneWidget);
    expect(find.text('Jambes'), findsNothing);
  });

  testWidgets('deletes with an exit animation, and undo brings it back', (
    tester,
  ) async {
    await pumpWithLibrary(tester);
    await openLibrary(tester);

    await tapMenu(tester, 'Supprimer');
    expect(find.text('Jambes'), findsNothing);
    expect(find.text('« Jambes » supprimée'), findsOneWidget);
    expect(find.text('Aucune série enregistrée'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('saved_series')!), isEmpty);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Jambes'), findsOneWidget);
    expect(jsonDecode(prefs.getString('saved_series')!), hasLength(1));
  });

  testWidgets('"Lancer" starts the saved series right away', (tester) async {
    await pumpWithLibrary(tester);
    await openLibrary(tester);

    await tester.tap(find.byTooltip('Lancer'));
    // The run screen repaints every frame: pump through the transitions.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(find.byType(RunScreen), findsOneWidget);
    expect(find.text('INTERVALLE 1/2'), findsOneWidget);
    expect(find.text('TOUR 1/3'), findsOneWidget);
  });
}
