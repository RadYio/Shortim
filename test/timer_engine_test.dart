import 'package:flutter_test/flutter_test.dart';
import 'package:shortim/models/series.dart';
import 'package:shortim/models/timer_interval.dart';
import 'package:shortim/services/timer_engine.dart';

/// Manually advanced clock.
class FakeClock {
  DateTime now = DateTime(2026, 1, 1, 12);
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}

Series seriesOf(
  List<int> seconds, {
  LoopMode loopMode = LoopMode.once,
  int loopCount = 1,
}) => Series(
  intervals: [
    for (final (i, s) in seconds.indexed)
      TimerInterval(id: '$i', minutes: s ~/ 60, seconds: s % 60),
  ],
  loopMode: loopMode,
  loopCount: loopCount,
);

const ms100 = Duration(milliseconds: 100);

/// Advances [clock] by [total] in 100 ms steps, ticking the engine each time,
/// and returns every event emitted.
List<TimerEvent> run(TimerEngine engine, FakeClock clock, Duration total) {
  final events = <TimerEvent>[];
  for (var t = Duration.zero; t < total; t += ms100) {
    clock.advance(ms100);
    events.addAll(engine.tick());
  }
  return events;
}

void main() {
  late FakeClock clock;

  setUp(() => clock = FakeClock());

  group('remaining time', () {
    test('is the full first interval before start', () {
      final engine = TimerEngine(seriesOf([45, 15]), clock: clock.call);
      expect(engine.status, TimerStatus.ready);
      expect(engine.snapshot.remaining, const Duration(seconds: 45));
      expect(engine.snapshot.secondsLeft, 45);
    });

    test('follows the wall clock, not the number of ticks', () {
      final engine = TimerEngine(seriesOf([45]), clock: clock.call)..start();
      clock.advance(const Duration(seconds: 10, milliseconds: 300));
      // A single tick after a long gap is enough.
      engine.tick();
      expect(
        engine.snapshot.remaining,
        const Duration(seconds: 34, milliseconds: 700),
      );
      expect(engine.snapshot.secondsLeft, 35);
    });

    test('is frozen while paused and resumes from the same value', () {
      final engine = TimerEngine(seriesOf([30]), clock: clock.call)..start();
      clock.advance(const Duration(seconds: 5));
      engine.pause();
      expect(engine.status, TimerStatus.paused);

      clock.advance(const Duration(minutes: 3));
      expect(engine.tick(), isEmpty);
      expect(engine.snapshot.remaining, const Duration(seconds: 25));

      engine.resume();
      clock.advance(const Duration(seconds: 5));
      engine.tick();
      expect(engine.snapshot.remaining, const Duration(seconds: 20));
    });
  });

  group('interval transitions', () {
    test('moves to the next interval exactly when the current one ends', () {
      final engine = TimerEngine(seriesOf([5, 10]), clock: clock.call)
        ..start();
      clock.advance(const Duration(milliseconds: 4999));
      expect(engine.tick().whereType<IntervalChanged>(), isEmpty);
      expect(engine.snapshot.intervalIndex, 0);

      clock.advance(const Duration(milliseconds: 1));
      expect(engine.tick(), contains(const IntervalChanged(1)));
      expect(engine.snapshot.intervalIndex, 1);
      expect(engine.snapshot.remaining, const Duration(seconds: 10));
    });

    test('exposes the next interval duration, null on the last one', () {
      final engine = TimerEngine(seriesOf([5, 30]), clock: clock.call)
        ..start();
      expect(engine.snapshot.nextDuration, const Duration(seconds: 30));
      expect(engine.snapshot.isLastStep, isFalse);

      clock.advance(const Duration(seconds: 5));
      engine.tick();
      expect(engine.snapshot.nextDuration, isNull);
      expect(engine.snapshot.isLastStep, isTrue);
    });

    test('catches up without drift after a long gap (background)', () {
      final engine = TimerEngine(seriesOf([5, 5, 20]), clock: clock.call)
        ..start();
      clock.advance(const Duration(seconds: 12));
      final events = engine.tick();
      // Only one transition sound for the step finally reached.
      expect(events, [const IntervalChanged(2)]);
      expect(engine.snapshot.remaining, const Duration(seconds: 18));
    });

    test('finishes after the last interval', () {
      final engine = TimerEngine(seriesOf([3, 2]), clock: clock.call)..start();
      final events = run(engine, clock, const Duration(seconds: 5));
      expect(events.last, const SeriesFinished());
      expect(events.whereType<SeriesFinished>(), hasLength(1));
      expect(engine.status, TimerStatus.finished);
      expect(engine.snapshot.remaining, Duration.zero);
      expect(engine.tick(), isEmpty);
    });

    test('pause processes transitions that were already due', () {
      final engine = TimerEngine(seriesOf([5, 10]), clock: clock.call)
        ..start();
      clock.advance(const Duration(seconds: 6));
      expect(engine.pause(), contains(const IntervalChanged(1)));
      expect(engine.snapshot.remaining, const Duration(seconds: 9));
    });
  });

  group('countdown beeps', () {
    test('beeps once at T-3, T-2 and T-1 of each interval', () {
      final engine = TimerEngine(seriesOf([10, 5]), clock: clock.call)
        ..start();
      final events = run(engine, clock, const Duration(seconds: 15));
      expect(events, const [
        CountdownBeep(3),
        CountdownBeep(2),
        CountdownBeep(1),
        IntervalChanged(1),
        CountdownBeep(3),
        CountdownBeep(2),
        CountdownBeep(1),
        SeriesFinished(),
      ]);
    });

    test('fires each beep when crossing the exact second', () {
      final engine = TimerEngine(seriesOf([10]), clock: clock.call)..start();
      clock.advance(const Duration(milliseconds: 6999));
      expect(engine.tick(), isEmpty);
      clock.advance(const Duration(milliseconds: 1));
      expect(engine.tick(), [const CountdownBeep(3)]);
    });

    test('short intervals only beep on the seconds they contain', () {
      final engine = TimerEngine(seriesOf([2]), clock: clock.call)..start();
      final events = run(engine, clock, const Duration(seconds: 2));
      expect(events, const [CountdownBeep(1), SeriesFinished()]);
    });

    test('no beep while paused, no duplicate after resume', () {
      final engine = TimerEngine(seriesOf([10]), clock: clock.call)..start();
      var events = run(engine, clock, const Duration(milliseconds: 7500));
      expect(events, [const CountdownBeep(3)]);

      engine.pause();
      clock.advance(const Duration(seconds: 10));
      expect(engine.tick(), isEmpty);

      engine.resume();
      events = run(engine, clock, const Duration(milliseconds: 2500));
      expect(events, const [
        CountdownBeep(2),
        CountdownBeep(1),
        SeriesFinished(),
      ]);
    });

    test('drops stale beeps of intervals skipped in background', () {
      final engine = TimerEngine(seriesOf([10, 10]), clock: clock.call)
        ..start();
      clock.advance(const Duration(seconds: 12));
      expect(engine.tick(), [const IntervalChanged(1)]);
    });
  });

  group('series repetition', () {
    test('repeats the whole series loopCount times', () {
      final engine = TimerEngine(
        seriesOf([4, 6], loopMode: LoopMode.repeatN, loopCount: 3),
        clock: clock.call,
      )..start();
      expect(engine.totalSteps, 6);
      expect(engine.snapshot.round, 1);
      expect(engine.snapshot.rounds, 3);

      final events = run(engine, clock, const Duration(seconds: 30));
      expect(
        events.whereType<IntervalChanged>().map((e) => e.step),
        [1, 2, 3, 4, 5],
      );
      expect(events.whereType<CountdownBeep>(), hasLength(18));
      expect(events.last, const SeriesFinished());
    });

    test('reports round and interval position across rounds', () {
      final engine = TimerEngine(
        seriesOf([4, 6], loopMode: LoopMode.repeatN, loopCount: 2),
        clock: clock.call,
      )..start();
      clock.advance(const Duration(seconds: 10));
      // The round change also triggers the interval change sound.
      expect(engine.tick(), [const IntervalChanged(2)]);
      final snap = engine.snapshot;
      expect(snap.round, 2);
      expect(snap.intervalIndex, 0);
      expect(snap.nextDuration, const Duration(seconds: 6));

      clock.advance(const Duration(seconds: 4));
      engine.tick();
      expect(engine.snapshot.isLastStep, isTrue);
    });

    test('once mode ignores loopCount', () {
      final engine = TimerEngine(
        seriesOf([4], loopCount: 5),
        clock: clock.call,
      );
      expect(engine.totalSteps, 1);
      expect(engine.snapshot.rounds, 1);
    });
  });

  group('persistence', () {
    test('restored engine catches up with time spent while killed', () {
      final series = seriesOf([10, 10]);
      final engine = TimerEngine(series, clock: clock.call)..start();
      clock.advance(const Duration(seconds: 3));
      engine.tick();
      final json = engine.runState.toJson();

      clock.advance(const Duration(seconds: 10));
      final restored = TimerEngine.restore(
        series,
        TimerRunState.fromJson(json),
        clock: clock.call,
      );
      expect(restored.tick(), [const IntervalChanged(1)]);
      expect(restored.snapshot.remaining, const Duration(seconds: 7));
    });

    test('rejects a state that does not match the series', () {
      final state = TimerEngine(
        seriesOf([5, 5, 5], loopMode: LoopMode.repeatN, loopCount: 2),
      ).runState;
      final bigger = TimerRunState.fromJson({
        ...state.toJson(),
        'step': 5,
      });
      expect(
        () => TimerEngine.restore(seriesOf([5]), bigger),
        throwsArgumentError,
      );
    });
  });

  test('series total duration includes repetitions', () {
    final series = seriesOf([45, 15], loopMode: LoopMode.repeatN, loopCount: 3);
    expect(series.roundDuration, const Duration(minutes: 1));
    expect(series.totalDuration, const Duration(minutes: 3));
    expect(formatDuration(const Duration(minutes: 12, seconds: 30)), '12:30');
    expect(formatDuration(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });
}
