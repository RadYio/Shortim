import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/series.dart';
import 'sound_service.dart';
import 'storage_service.dart';
import 'timer_engine.dart';

/// What accompanies each cue, read when the cue fires (so a settings change
/// applies mid-run).
typedef FeedbackOptions = ({bool sound, bool haptics});

/// Glue between [TimerEngine] and the app: ticks the engine, plays sounds
/// and haptics, keeps the screen/audio session alive and persists the run.
class RunController extends ChangeNotifier {
  RunController({
    required this.series,
    required this.sounds,
    required this.storage,
    TimerRunState? restoreFrom,
    Clock? clock,
    FeedbackOptions Function()? feedback,
  }) : _clock = clock,
       _feedback = feedback ?? _soundOnly,
       _engine = restoreFrom == null
           ? TimerEngine(series, clock: clock)
           : TimerEngine.restore(series, restoreFrom, clock: clock);

  /// Tick period. Only affects UI refresh and sound latency: time itself is
  /// always computed from the wall clock.
  static const tickInterval = Duration(milliseconds: 100);

  final Series series;
  final SoundService sounds;
  final StorageService storage;
  final Clock? _clock;
  final FeedbackOptions Function() _feedback;

  static FeedbackOptions _soundOnly() => (sound: true, haptics: false);

  TimerEngine _engine;
  Timer? _ticker;
  bool _disposed = false;
  final _events = StreamController<TimerEvent>.broadcast();

  /// The event each sound was played for, emitted on the same tick so the
  /// UI can animate in sync with it. Silent (restored) ticks emit nothing.
  Stream<TimerEvent> get events => _events.stream;

  TimerSnapshot get snapshot => _engine.snapshot;
  TimerStatus get status => _engine.status;

  /// Starts a fresh run, or continues a restored one.
  Future<void> start() async {
    await sounds.init();
    if (_disposed) return;
    final restored = _engine.status != TimerStatus.ready;
    if (!restored) {
      _engine.start();
      _cue(const IntervalChanged(0));
    }
    _handle(_engine.tick(), silent: restored);
    if (_engine.status == TimerStatus.finished) return;
    // Keep-alive runs in background: the countdown never waits on platform
    // calls (which may be slow, or never answer in widget tests).
    unawaited(_setActive(true));
    _startTicker();
    _persist();
    notifyListeners();
  }

  void togglePause() {
    switch (_engine.status) {
      case TimerStatus.running:
        _handle(_engine.pause());
      case TimerStatus.paused:
        _engine.resume();
      case TimerStatus.ready || TimerStatus.finished:
        return;
    }
    _persist();
    notifyListeners();
  }

  /// Restarts the same series from the beginning.
  Future<void> restart() async {
    _ticker?.cancel();
    _engine = TimerEngine(series, clock: _clock);
    notifyListeners();
    await start();
  }

  /// Stops the run for good. Cleanup runs in background so leaving the
  /// screen is never blocked by platform calls.
  void stop() {
    _ticker?.cancel();
    unawaited(_setActive(false));
    unawaited(storage.clearRun());
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(tickInterval, (_) {
      final events = _engine.tick();
      _handle(events);
      if (events.isNotEmpty) _persist();
      notifyListeners();
    });
  }

  /// Plays at most one sound per tick, the most significant one.
  void _handle(List<TimerEvent> events, {bool silent = false}) {
    if (events.isEmpty) return;
    if (events.any((e) => e is SeriesFinished)) {
      _ticker?.cancel();
      if (!silent) {
        _cue(const SeriesFinished());
        _emit(const SeriesFinished());
      }
      unawaited(_setActive(false));
      unawaited(storage.clearRun());
      return;
    }
    if (silent) return;
    final change = events.whereType<IntervalChanged>().lastOrNull;
    final beep = events.whereType<CountdownBeep>().lastOrNull;
    if (change != null) {
      _cue(change);
      _emit(change);
    } else if (beep != null) {
      _cue(beep);
      _emit(beep);
    }
  }

  /// Sound and/or haptic for one event, as the settings allow.
  void _cue(TimerEvent event) {
    final options = _feedback();
    if (options.sound) {
      unawaited(switch (event) {
        CountdownBeep() => sounds.beep(),
        IntervalChanged() => sounds.intervalChange(),
        SeriesFinished() => sounds.finish(),
      });
    }
    if (options.haptics) {
      unawaited(switch (event) {
        CountdownBeep() => HapticFeedback.lightImpact(),
        IntervalChanged() => HapticFeedback.mediumImpact(),
        SeriesFinished() => HapticFeedback.heavyImpact(),
      });
    }
  }

  void _emit(TimerEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _persist() {
    if (_engine.status == TimerStatus.finished) return;
    unawaited(storage.saveRun(series, _engine.runState));
  }

  Future<void> _setActive(bool active) async {
    try {
      if (active) {
        await sounds.startKeepAlive();
        await WakelockPlus.enable();
      } else {
        await sounds.stopKeepAlive();
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('Could not toggle keep-alive: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    unawaited(_events.close());
    unawaited(_setActive(false));
    super.dispose();
  }
}
