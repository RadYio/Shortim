import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/l10n/l10n.dart';
import 'package:shortim/main.dart';
import 'package:shortim/models/series.dart';
import 'package:shortim/models/timer_interval.dart';
import 'package:shortim/screens/run_screen.dart';
import 'package:shortim/services/settings_controller.dart';
import 'package:shortim/services/storage_service.dart';
import 'package:shortim/theme.dart';
import 'package:shortim/widgets/mascot.dart';

import 'fakes.dart';

class FakeClock {
  DateTime now = DateTime(2026, 11, 2, 12);

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

void main() {
  setUpAll(configureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({'has_onboarded': true}));

  late FakeClock clock;
  late FakeSoundService sounds;

  /// Runs a single 4 s interval on a fake wall clock.
  Future<void> pumpRun(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    clock = FakeClock();
    sounds = FakeSoundService();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: RunScreen(
          series: Series(intervals: [TimerInterval(id: 'a', seconds: 4)]),
          sounds: sounds,
          storage: StorageService(),
          clock: clock.call,
        ),
      ),
    );
    await tester.pump(); // start() awaits the sound service.
  }

  /// Advances the wall clock, then lets the controller tick once.
  Future<void> elapse(WidgetTester tester, Duration d) async {
    clock.advance(d);
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Largest scale applied above the digits (the pulse wraps the
  /// interval-change cross-fade, which also uses a scale).
  double digitsScale(WidgetTester tester, String text) => tester
      .widgetList<Transform>(
        find.ancestor(of: find.text(text), matching: find.byType(Transform)),
      )
      .map((t) => t.transform.getMaxScaleOnAxis())
      .reduce(math.max);

  testWidgets('digits pulse on the T-3 beep', (tester) async {
    await pumpRun(tester);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('00:04'), findsOneWidget);
    expect(digitsScale(tester, '00:04'), 1);

    await elapse(tester, const Duration(milliseconds: 1100));
    expect(sounds.played.last, 'beep');
    await tester.pump(const Duration(milliseconds: 60));
    expect(digitsScale(tester, '00:03'), greaterThan(1));

    // The pulse fades out on its own.
    await tester.pump(const Duration(milliseconds: 600));
    expect(digitsScale(tester, '00:03'), 1);
  });

  testWidgets('pause dims the digits, resume restores them', (tester) async {
    await pumpRun(tester);
    Color? digitsColor() =>
        tester.widget<Text>(find.text('00:04')).style!.color;

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('EN PAUSE'), findsOneWidget);
    // Paused: the ring stops repainting, so the screen settles.
    await tester.pumpAndSettle();
    expect(digitsColor(), AppColors.brand500);

    await tester.tap(find.text('Reprendre'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('EN PAUSE'), findsNothing);
    expect(digitsColor(), AppColors.text);
  });

  testWidgets('series end closes the ring and shows "Terminé"', (tester) async {
    await pumpRun(tester);
    await elapse(tester, const Duration(seconds: 5));
    expect(sounds.played.last, 'finish');

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Terminé'), findsNothing); // Ring closes first.

    await tester.pumpAndSettle();
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Relancer'), findsOneWidget);

    // Restart reopens the ring and the countdown.
    await tester.tap(find.text('Relancer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Terminé'), findsNothing);
    expect(find.text('00:04'), findsOneWidget);
  });

  testWidgets('mascot shows below the countdown with an encouraging phrase', (
    tester,
  ) async {
    await pumpRun(tester);
    expect(find.byType(Mascot), findsOneWidget);
    // Fresh state (just started): the first phrase of that pool is picked.
    expect(find.text("C'est parti !"), findsOneWidget);

    // Well into the interval, the mascot should still be there with one of
    // the near-end phrases, and nothing should have thrown.
    await elapse(tester, const Duration(milliseconds: 3100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Mascot), findsOneWidget);
    expect(
      find.text('Derniers efforts !'),
      findsOneWidget,
    );
  });

  testWidgets('settings decide between sound and haptics', (tester) async {
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final settings = SettingsController(StorageService());
    await settings.update(
      (s) => s.copyWith(soundEnabled: false, haptics: true),
    );
    clock = FakeClock();
    sounds = FakeSoundService();
    await tester.pumpWidget(
      SettingsScope(
        notifier: settings,
        child: MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: RunScreen(
            series: Series(intervals: [TimerInterval(id: 'a', seconds: 4)]),
            sounds: sounds,
            storage: StorageService(),
            clock: clock.call,
          ),
        ),
      ),
    );
    await tester.pump();
    await elapse(tester, const Duration(milliseconds: 1100)); // T-3
    await elapse(tester, const Duration(seconds: 4)); // End.

    expect(sounds.played, isEmpty);
    expect(haptics, [
      'HapticFeedbackType.mediumImpact', // Start (interval change).
      'HapticFeedbackType.lightImpact', // T-3 beep.
      'HapticFeedbackType.heavyImpact', // End of series.
    ]);
    await tester.pumpAndSettle();
  });
}
