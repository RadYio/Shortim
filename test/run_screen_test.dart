import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shortim/main.dart';
import 'package:shortim/models/series.dart';
import 'package:shortim/models/timer_interval.dart';
import 'package:shortim/screens/run_screen.dart';
import 'package:shortim/services/storage_service.dart';
import 'package:shortim/theme.dart';

import 'fakes.dart';

class FakeClock {
  DateTime now = DateTime(2026, 11, 2, 12);

  DateTime call() => now;

  void advance(Duration d) => now = now.add(d);
}

void main() {
  setUpAll(configureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
}
