import '../models/series.dart';

typedef Clock = DateTime Function();

enum TimerStatus { ready, running, paused, finished }

/// Something the UI/audio layer should react to, produced by [TimerEngine.tick].
sealed class TimerEvent {
  const TimerEvent();
}

/// Countdown beep at T-3, T-2 and T-1 of each interval.
class CountdownBeep extends TimerEvent {
  const CountdownBeep(this.secondsLeft);
  final int secondsLeft;

  @override
  bool operator ==(Object other) =>
      other is CountdownBeep && other.secondsLeft == secondsLeft;

  @override
  int get hashCode => secondsLeft.hashCode;

  @override
  String toString() => 'CountdownBeep($secondsLeft)';
}

/// An interval just ended and the next one (possibly of the next round)
/// started. [step] is the new flat step index.
class IntervalChanged extends TimerEvent {
  const IntervalChanged(this.step);
  final int step;

  @override
  bool operator ==(Object other) =>
      other is IntervalChanged && other.step == step;

  @override
  int get hashCode => step.hashCode;

  @override
  String toString() => 'IntervalChanged($step)';
}

/// The last interval of the last round ended.
class SeriesFinished extends TimerEvent {
  const SeriesFinished();

  @override
  bool operator ==(Object other) => other is SeriesFinished;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'SeriesFinished()';
}

/// Immutable view of the engine state at a given instant.
class TimerSnapshot {
  const TimerSnapshot({
    required this.status,
    required this.step,
    required this.totalSteps,
    required this.intervalIndex,
    required this.intervalCount,
    required this.round,
    required this.rounds,
    required this.remaining,
    required this.currentDuration,
    required this.nextDuration,
  });

  final TimerStatus status;

  /// Flat index over all rounds: `round * intervalCount + intervalIndex`.
  final int step;
  final int totalSteps;

  /// 0-based index of the current interval within the series.
  final int intervalIndex;
  final int intervalCount;

  /// 1-based current round.
  final int round;
  final int rounds;

  final Duration remaining;
  final Duration currentDuration;

  /// Duration of the step that follows, or null if this is the last one.
  final Duration? nextDuration;

  bool get isLastStep => nextDuration == null;

  /// Whole seconds left, rounded up: shows 00:45 at the very start of a 45 s
  /// interval and reaches 00:00 exactly when it ends.
  int get secondsLeft => ceilSeconds(remaining);

  /// Fraction of the current interval already elapsed, in [0, 1].
  double get progress => currentDuration == Duration.zero
      ? 1
      : 1 - remaining.inMicroseconds / currentDuration.inMicroseconds;
}

int ceilSeconds(Duration d) =>
    d.isNegative ? 0 : (d.inMicroseconds + 999999) ~/ 1000000;

/// Serializable engine state, used to resume a run after the app was killed.
class TimerRunState {
  const TimerRunState({
    required this.status,
    required this.step,
    required this.endsAt,
    required this.pausedRemaining,
    required this.lastAnnouncedSecond,
  });

  final TimerStatus status;
  final int step;
  final DateTime? endsAt;
  final Duration pausedRemaining;
  final int lastAnnouncedSecond;

  Map<String, Object?> toJson() => {
    'status': status.name,
    'step': step,
    'endsAt': endsAt?.millisecondsSinceEpoch,
    'pausedRemainingMs': pausedRemaining.inMilliseconds,
    'lastAnnouncedSecond': lastAnnouncedSecond,
  };

  factory TimerRunState.fromJson(Map<String, dynamic> json) => TimerRunState(
    status: TimerStatus.values.byName(json['status'] as String),
    step: json['step'] as int,
    endsAt: json['endsAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['endsAt'] as int),
    pausedRemaining: Duration(milliseconds: json['pausedRemainingMs'] as int),
    lastAnnouncedSecond: json['lastAnnouncedSecond'] as int,
  );
}

/// Interval timer driven by a wall clock.
///
/// The engine never counts ticks: while running it stores the instant at
/// which the current interval ends and derives everything from `clock()`.
/// Calling [tick] late (e.g. the app was throttled in background) simply
/// catches up — chained interval end times are computed from the previous
/// end time, so no drift accumulates.
///
/// The engine has no timer of its own; the owner calls [tick] periodically
/// and reacts to the returned events.
class TimerEngine {
  TimerEngine(this.series, {Clock? clock})
    : assert(series.isValid, 'Series must be valid'),
      _clock = clock ?? DateTime.now {
    _pausedRemaining = _durationAt(0);
    _lastAnnouncedSecond = _durationAt(0).inSeconds;
  }

  /// Rebuilds an engine from a persisted [state]. Call [tick] right after to
  /// catch up with the time elapsed since it was saved.
  TimerEngine.restore(this.series, TimerRunState state, {Clock? clock})
    : assert(series.isValid, 'Series must be valid'),
      _clock = clock ?? DateTime.now {
    final total = series.intervals.length * series.rounds;
    if (state.step < 0 ||
        state.step >= total ||
        (state.status == TimerStatus.running && state.endsAt == null)) {
      throw ArgumentError.value(state, 'state', 'Incompatible with series');
    }
    _status = state.status;
    _step = state.step;
    _endsAt = state.endsAt;
    _pausedRemaining = state.pausedRemaining;
    _lastAnnouncedSecond = state.lastAnnouncedSecond;
  }

  /// Seconds-left values at which a [CountdownBeep] is emitted.
  static const int beepFrom = 3;

  final Series series;
  final Clock _clock;

  TimerStatus _status = TimerStatus.ready;
  int _step = 0;

  /// End of the current interval, only set while running.
  DateTime? _endsAt;

  /// Remaining time of the current interval while ready or paused.
  late Duration _pausedRemaining;

  /// Last whole second observed for the current interval, used to emit each
  /// countdown beep exactly once (and never again after a pause/resume).
  late int _lastAnnouncedSecond;

  TimerStatus get status => _status;

  int get totalSteps => series.intervals.length * series.rounds;

  TimerRunState get runState => TimerRunState(
    status: _status,
    step: _step,
    endsAt: _endsAt,
    pausedRemaining: _pausedRemaining,
    lastAnnouncedSecond: _lastAnnouncedSecond,
  );

  Duration _durationAt(int step) =>
      series.intervals[step % series.intervals.length].duration;

  Duration get remaining => switch (_status) {
    TimerStatus.running => _nonNegative(_endsAt!.difference(_clock())),
    TimerStatus.ready || TimerStatus.paused => _pausedRemaining,
    TimerStatus.finished => Duration.zero,
  };

  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;

  TimerSnapshot get snapshot {
    final count = series.intervals.length;
    return TimerSnapshot(
      status: _status,
      step: _step,
      totalSteps: totalSteps,
      intervalIndex: _step % count,
      intervalCount: count,
      round: _step ~/ count + 1,
      rounds: series.rounds,
      remaining: remaining,
      currentDuration: _durationAt(_step),
      nextDuration: _step + 1 < totalSteps ? _durationAt(_step + 1) : null,
    );
  }

  void start() {
    if (_status != TimerStatus.ready) return;
    _status = TimerStatus.running;
    _endsAt = _clock().add(_pausedRemaining);
  }

  /// Pauses the countdown. Returns the events that were due before the pause
  /// (if [tick] had not been called for a while), so none get lost.
  List<TimerEvent> pause() {
    if (_status != TimerStatus.running) return const [];
    final events = tick();
    if (_status != TimerStatus.running) return events;
    _pausedRemaining = remaining;
    _endsAt = null;
    _status = TimerStatus.paused;
    return events;
  }

  void resume() {
    if (_status != TimerStatus.paused) return;
    _status = TimerStatus.running;
    _endsAt = _clock().add(_pausedRemaining);
  }

  /// Advances the state to the current wall-clock time and returns what
  /// happened since the previous call. Only does something while running.
  ///
  /// If several intervals elapsed between two calls, a single
  /// [IntervalChanged] is emitted for the step finally reached, and stale
  /// countdown beeps of skipped intervals are dropped.
  List<TimerEvent> tick() {
    if (_status != TimerStatus.running) return const [];
    final now = _clock();
    final events = <TimerEvent>[];

    var changed = false;
    while (!now.isBefore(_endsAt!)) {
      if (_step + 1 >= totalSteps) {
        _status = TimerStatus.finished;
        _endsAt = null;
        _pausedRemaining = Duration.zero;
        events.add(const SeriesFinished());
        return events;
      }
      _step++;
      _endsAt = _endsAt!.add(_durationAt(_step));
      _lastAnnouncedSecond = _durationAt(_step).inSeconds;
      changed = true;
    }
    if (changed) events.add(IntervalChanged(_step));

    final secondsLeft = ceilSeconds(_endsAt!.difference(now));
    if (secondsLeft < _lastAnnouncedSecond) {
      if (secondsLeft >= 1 && secondsLeft <= beepFrom) {
        events.add(CountdownBeep(secondsLeft));
      }
      _lastAnnouncedSecond = secondsLeft;
    }
    return events;
  }
}
