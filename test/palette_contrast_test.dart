import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/l10n/app_localizations.dart';
import 'package:shortim/main.dart';
import 'package:shortim/screens/onboarding_screen.dart';
import 'package:shortim/screens/splash_screen.dart';
import 'package:shortim/services/storage_service.dart';
import 'package:shortim/theme.dart';
import 'package:shortim/widgets/shortim_mark.dart';

import 'fakes.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return ((la > lb ? la : lb) + 0.05) / ((la > lb ? lb : la) + 0.05);
}

void main() {
  setUpAll(configureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpIn(WidgetTester tester, AppPalette palette, Widget home) =>
      tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(palette: palette),
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: home,
        ),
      );

  Color markColor(WidgetTester tester) =>
      (tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((p) => p.painter)
              .whereType<ShortimMarkPainter>()
              .single)
          .color;

  for (final palette in AppPalette.values) {
    testWidgets('splash logo and wordmark readable on ${palette.name}', (
      tester,
    ) async {
      await pumpIn(
        tester,
        palette,
        SplashScreen(next: (_) => const SizedBox()),
      );
      await tester.pump(const Duration(milliseconds: 2600));
      expect(
        contrast(markColor(tester), palette.background),
        greaterThanOrEqualTo(4.5),
      );
      final word = tester.widget<Text>(find.text('Shortim'));
      expect(
        contrast(word.style!.color!, palette.background),
        greaterThanOrEqualTo(4.5),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('onboarding logo readable on ${palette.name}', (tester) async {
      await pumpIn(
        tester,
        palette,
        OnboardingScreen(
          sounds: FakeSoundService(),
          storage: StorageService(),
          onDone: () {},
        ),
      );
      await tester.pumpAndSettle();
      expect(
        contrast(markColor(tester), palette.background),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  test('Endurance cards stand out from the white background', () {
    final p = AppPalette.endurance;
    expect(contrast(p.muted, p.background), greaterThanOrEqualTo(1.15));
  });
}
