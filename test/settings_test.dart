import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/services/settings_controller.dart';
import 'package:shortim/services/storage_service.dart';
import 'package:shortim/theme.dart';

import 'fakes.dart';

void main() {
  setUpAll(configureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({'has_onboarded': true}));

  late FakeSoundService sounds;

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale device = const Locale('fr', 'FR'),
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [device];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    sounds = FakeSoundService();
    await tester.pumpWidget(
      ShortimApp(sounds: sounds, storage: StorageService()),
    );
    await tester.pumpAndSettle();
  }

  Future<Map<String, dynamic>> storedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return jsonDecode(prefs.getString('settings')!) as Map<String, dynamic>;
  }

  Future<void> openSettings(
    WidgetTester tester, {
    String tooltip = 'Réglages',
  }) async {
    await tester.tap(find.byTooltip(tooltip));
    await tester.pumpAndSettle();
  }

  /// The settings list is lazy and taller than the screen: scroll first.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Finder swatch(String name) => find.byWidgetPredicate(
    (w) => w is Semantics && w.properties.label == name,
  );

  group('language', () {
    testWidgets('follows a French device', (tester) async {
      await pumpApp(tester);
      expect(find.text('Démarrer'), findsOneWidget);
    });

    testWidgets('falls back to English on any other device', (tester) async {
      await pumpApp(tester, device: const Locale('de', 'DE'));
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Total: 00:30'), findsOneWidget);
    });

    testWidgets('a manual choice applies at once and persists', (tester) async {
      await pumpApp(tester);
      await openSettings(tester);
      expect(
        find.text(
          'Auto suit la langue de l\'appareil '
          '(actuellement : Français).',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget); // No restart needed.
      expect(find.text('LANGUAGE'), findsOneWidget);
      expect((await storedSettings())['language'], 'en');

      await tester.tap(find.byTooltip('Chrono'));
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('the saved choice wins over the device on next launch', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'settings': jsonEncode({'language': 'en'}),
      });
      await pumpApp(tester); // French device.
      expect(find.text('Start'), findsOneWidget);
    });
  });

  testWidgets('palette switches the theme and persists', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await reveal(tester, swatch('Volt'));
    await tester.tap(swatch('Volt'));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.byType(Scaffold).last));
    expect(theme.colorScheme.primary, AppPalette.volt.accent2);
    expect((await storedSettings())['palette'], 'volt');
  });

  testWidgets('choosing a sound theme previews and applies it', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);

    await reveal(tester, find.text('Marimba'));
    await tester.tap(find.text('Marimba'));
    await tester.pumpAndSettle();
    expect(sounds.theme, SoundTheme.marimba);
    expect(sounds.played, ['change']); // The preview.
    expect((await storedSettings())['soundTheme'], 'marimba');

    // Sound off: themes can no longer be picked.
    await reveal(tester, find.text('Sons'));
    await tester.tap(find.text('Sons'));
    await tester.pumpAndSettle();
    expect((await storedSettings())['soundEnabled'], false);
    await tester.tap(find.text('Cloche douce'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(sounds.theme, SoundTheme.marimba);
  });

  testWidgets('vibrations toggle persists', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    await reveal(tester, find.text('Vibrations'));
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect((await storedSettings())['haptics'], false);
  });

  testWidgets('"Gérer mes séries" opens the library; a pick loads it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'has_onboarded': true,
      'saved_series': jsonEncode([
        {
          'id': 'j',
          'name': 'Jambes',
          'intervals': [
            {'id': 'a', 'minutes': 1, 'seconds': 0},
          ],
          'loopMode': 'once',
          'loopCount': 1,
        },
      ]),
    });
    await pumpApp(tester);
    await openSettings(tester);

    await reveal(tester, find.text('Gérer mes séries'));
    await tester.tap(find.text('Gérer mes séries'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jambes'));
    await tester.pumpAndSettle();
    expect(find.text('Durée totale : 01:00'), findsOneWidget);
  });

  testWidgets(
    'a palette change applies live to "Mes séries" without navigating away '
    '(regression guard: library cards must never show a stale palette)',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_onboarded': true,
        'saved_series': jsonEncode([
          {
            'id': 'j',
            'name': 'Jambes',
            'intervals': [
              {'id': 'a', 'minutes': 1, 'seconds': 0},
            ],
            'loopMode': 'once',
            'loopCount': 1,
          },
        ]),
      });
      await pumpApp(tester);

      await tester.tap(find.byTooltip('Mes séries'));
      await tester.pumpAndSettle();
      final before = tester
          .widgetList<Material>(
            find.ancestor(
              of: find.text('Jambes'),
              matching: find.byType(Material),
            ),
          )
          .first
          .color;

      // Change the palette from outside, the way Settings does internally —
      // without navigating away from "Mes séries": if a card's colour was
      // ever cached instead of read fresh from AppColors on every build,
      // this is the scenario that would expose it.
      SettingsScope.of(
        tester.element(find.byType(Scaffold).first),
      ).update((s) => s.copyWith(palette: AppPalette.volt));
      await tester.pumpAndSettle();

      final after = tester
          .widgetList<Material>(
            find.ancestor(
              of: find.text('Jambes'),
              matching: find.byType(Material),
            ),
          )
          .first
          .color;

      expect(before, isNot(after));
      expect(after, AppColors.surface);
    },
  );

  test('settings JSON round-trips, unknown values fall back', () {
    const custom = AppSettings(
      language: AppLanguage.en,
      soundEnabled: false,
      soundTheme: SoundTheme.pulse,
      haptics: false,
      palette: AppPalette.mocha,
    );
    final back = AppSettings.fromJson(custom.toJson());
    expect(back.toJson(), custom.toJson());

    final odd = AppSettings.fromJson({'language': 'klingon', 'palette': 1});
    expect(odd.toJson(), const AppSettings().toJson());
  });
}
