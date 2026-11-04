import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n/l10n.dart';
import '../models/series.dart';
import '../models/timer_interval.dart';
import '../services/run_controller.dart';
import '../services/settings_controller.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/timer_engine.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

/// Screen 2: runs the series. Starts as soon as it is displayed.
class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.series,
    required this.sounds,
    required this.storage,
    this.restoreFrom,
    this.clock,
  });

  final Series series;
  final SoundService sounds;
  final StorageService storage;

  /// When set, continues an interrupted run instead of starting a new one.
  final TimerRunState? restoreFrom;

  /// Wall clock override, for tests.
  final Clock? clock;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> with TickerProviderStateMixin {
  late final RunController _controller = RunController(
    series: widget.series,
    sounds: widget.sounds,
    storage: widget.storage,
    restoreFrom: widget.restoreFrom,
    clock: widget.clock,
    feedback: () => _feedback,
  );

  /// Sound / haptics as currently set (defaults outside a [SettingsScope]).
  FeedbackOptions _feedback = (sound: true, haptics: false);

  /// Fraction of the current interval still to run, sampled from the wall
  /// clock on every frame while running, so the ring never steps.
  final _remaining = ValueNotifier<double>(1);
  late final Ticker _frames = createTicker((_) => _sample());

  /// Swell of the ring and digits on each beep and interval change.
  late final _pulse = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// 0 = accent colours, 1 = desaturated (paused).
  late final _pause = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// Ring sweeping back to full at the start of each interval.
  late final _refill = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  /// End of series: the ring closes in one stroke, then "Terminé" zooms in.
  late final _finish = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  StreamSubscription<TimerEvent>? _events;
  TimerStatus? _status;

  @override
  void initState() {
    super.initState();
    _events = _controller.events.listen(_onEvent);
    _controller.addListener(_onChange);
    _onChange();
    unawaited(_controller.start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = SettingsScope.maybeOf(context)?.settings;
    if (settings != null) {
      _feedback = (sound: settings.soundEnabled, haptics: settings.haptics);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    unawaited(_events?.cancel());
    _frames.dispose();
    _pulse.dispose();
    _pause.dispose();
    _refill.dispose();
    _finish.dispose();
    _remaining.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _sample() {
    _remaining.value = (1 - _controller.snapshot.progress).clamp(0.0, 1.0);
  }

  /// Visual beats, fired on the same tick as their sound.
  void _onEvent(TimerEvent event) {
    switch (event) {
      case CountdownBeep():
        _pulse.forward(from: 0);
      case IntervalChanged():
        _pulse.forward(from: 0);
        _refill.forward(from: 0);
      case SeriesFinished():
        break; // Handled by the status change.
    }
  }

  void _onChange() {
    _sample();
    final status = _controller.status;
    if (status == _status) return;
    final previous = _status;
    _status = status;

    if (status == TimerStatus.running) {
      if (!_frames.isActive) _frames.start();
    } else if (_frames.isActive) {
      _frames.stop();
    }

    switch (status) {
      case TimerStatus.ready: // First display or restart.
        _finish.value = 0;
        _refill.forward(from: 0);
      case TimerStatus.running:
        _pause.reverse();
      case TimerStatus.paused:
        _pause.forward();
      case TimerStatus.finished:
        _pause.reverse();
        if (previous == null) {
          _finish.value = 1;
        } else {
          _finish.forward(from: 0);
        }
    }
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.stopTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.continueRun),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.stop),
          ),
        ],
      ),
    );
    if ((stop ?? false) && mounted) _leave();
  }

  void _leave() {
    _controller.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final snap = _controller.snapshot;
        final finished = snap.status == TimerStatus.finished;
        return PopScope(
          canPop: finished,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmStop();
          },
          child: Scaffold(
            backgroundColor: AppColors.ink,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Progress(snapshot: snap),
                    const Spacer(),
                    _Dial(
                      snapshot: snap,
                      remaining: _remaining,
                      pulse: _pulse,
                      pause: _pause,
                      refill: _refill,
                      finish: _finish,
                    ),
                    const SizedBox(height: 8),
                    Mascot(
                      progress: snap.progress,
                      paused: snap.status == TimerStatus.paused,
                      finished: finished,
                    ),
                    const SizedBox(height: 8),
                    _NextLabel(snapshot: snap),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: AppMotion.base,
                      switchInCurve: AppMotion.brand,
                      switchOutCurve: AppMotion.brand.flipped,
                      child: finished
                          ? _FinishedActions(
                              onRestart: _controller.restart,
                              onNew: _leave,
                            )
                          : _RunActions(
                              paused: snap.status == TimerStatus.paused,
                              onTogglePause: _controller.togglePause,
                              onStop: _confirmStop,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Quick rise then soft fall, applied to a 0..1 pulse controller.
final _swell = TweenSequence<double>([
  TweenSequenceItem(
    tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
    weight: 25,
  ),
  TweenSequenceItem(
    tween: Tween(
      begin: 1.0,
      end: 0.0,
    ).chain(CurveTween(curve: AppMotion.brand)),
    weight: 75,
  ),
]);

class _Progress extends StatelessWidget {
  const _Progress({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final style = AppText.label();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            context.l10n.runInterval(
              snapshot.intervalIndex + 1,
              snapshot.intervalCount,
            ),
            style: style,
          ),
        ),
        if (snapshot.rounds > 1)
          Flexible(
            child: Text(
              context.l10n.runRound(snapshot.round, snapshot.rounds),
              style: style,
            ),
          ),
      ],
    );
  }
}

/// Countdown ring with the digits (or "Terminé") in its centre.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.snapshot,
    required this.remaining,
    required this.pulse,
    required this.pause,
    required this.refill,
    required this.finish,
  });

  final TimerSnapshot snapshot;
  final ValueListenable<double> remaining;
  final Animation<double> pulse;
  final Animation<double> pause;
  final Animation<double> refill;
  final Animation<double> finish;

  static final _digitsOut = Interval(0, 0.35, curve: AppMotion.brand);
  static final _doneIn = Interval(0.55, 1, curve: AppMotion.emphasis);

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final paused = snapshot.status == TimerStatus.paused;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, 340.0);
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RingPainter(
                      remaining: remaining,
                      pulse: pulse,
                      pause: pause,
                      refill: refill,
                      finish: finish,
                      accent: accent,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: Listenable.merge([pulse, pause, finish]),
                  builder: (context, _) {
                    final swell = _swell.transform(pulse.value);
                    final dim = AppMotion.brand.transform(pause.value);
                    final digits = 1 - _digitsOut.transform(finish.value);
                    final done = _doneIn.transform(finish.value);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (digits > 0)
                          Opacity(
                            opacity: digits,
                            child: Transform.scale(
                              scale: 1 + 0.05 * swell,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: size * 0.66,
                                    child: _Digits(
                                      snapshot: snapshot,
                                      dim: dim,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 18,
                                    child: paused || pause.value > 0
                                        ? Opacity(
                                            opacity: dim,
                                            child: Text(
                                              context.l10n.paused,
                                              style: AppText.label(),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (done > 0)
                          Opacity(
                            opacity: done.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.85 + 0.15 * done,
                              child: Text(
                                context.l10n.done,
                                style: AppText.wordmark(fontSize: 44),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// MM:SS, cross-fading with a slight scale when the interval changes.
class _Digits extends StatelessWidget {
  const _Digits({required this.snapshot, required this.dim});

  final TimerSnapshot snapshot;

  /// 0..1 desaturation while paused.
  final double dim;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.brand,
      switchOutCurve: AppMotion.brand.flipped,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: FittedBox(
        key: ValueKey(snapshot.step),
        fit: BoxFit.scaleDown,
        child: Text(
          formatDuration(Duration(seconds: snapshot.secondsLeft)),
          style: AppText.mono(
            fontSize: 76,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -3,
            color: Color.lerp(AppColors.text, AppColors.brand500, dim),
          ),
        ),
      ),
    );
  }
}

/// Track + accent arc for the time left, drawn from 12 o'clock clockwise.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.remaining,
    required this.pulse,
    required this.pause,
    required this.refill,
    required this.finish,
    required this.accent,
  }) : super(
         repaint: Listenable.merge([remaining, pulse, pause, refill, finish]),
       );

  final ValueListenable<double> remaining;
  final Animation<double> pulse;
  final Animation<double> pause;
  final Animation<double> refill;
  final Animation<double> finish;
  final Color accent;

  static const _stroke = 8.0;
  static final _closing = Interval(0, 0.6, curve: AppMotion.brand);
  static final _afterglow = Interval(0.5, 1);

  @override
  void paint(Canvas canvas, Size size) {
    final glow = math.max(
      _swell.transform(pulse.value),
      0.6 * math.sin(math.pi * _afterglow.transform(finish.value)),
    );
    final radius = size.width / 2 - 24;
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..scale(1 + 0.025 * _swell.transform(pulse.value));
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    canvas.drawCircle(
      Offset.zero,
      radius,
      line..color = AppColors.brand700.withValues(alpha: 0.6),
    );

    final sweep = finish.value > 0
        ? _closing.transform(finish.value)
        : remaining.value * AppMotion.brand.transform(refill.value);
    if (sweep <= 0) return;

    final color = Color.lerp(
      accent,
      AppColors.brand600,
      AppMotion.brand.transform(pause.value),
    )!;
    const start = -math.pi / 2;
    final angle = 2 * math.pi * sweep;
    if (glow > 0.01) {
      canvas.drawArc(
        rect,
        start,
        angle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _stroke + 14 * glow
          ..color = color.withValues(alpha: 0.3 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawArc(rect, start, angle, false, line..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      accent != oldDelegate.accent ||
      remaining != oldDelegate.remaining ||
      pulse != oldDelegate.pulse;
}

class _NextLabel extends StatelessWidget {
  const _NextLabel({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = switch (snapshot) {
      TimerSnapshot(status: TimerStatus.finished) => '',
      TimerSnapshot(nextDuration: final next?) => context.l10n.nextInterval(
        formatDuration(next),
      ),
      _ => context.l10n.lastInterval,
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: AppText.mono(fontSize: 20, color: AppColors.brand300),
    );
  }
}

class _RunActions extends StatelessWidget {
  const _RunActions({
    required this.paused,
    required this.onTogglePause,
    required this.onStop,
  });

  final bool paused;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onTogglePause,
            child: Text(paused ? context.l10n.resume : context.l10n.pause),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: onStop,
            child: Text(context.l10n.stop),
          ),
        ),
      ],
    );
  }
}

class _FinishedActions extends StatelessWidget {
  const _FinishedActions({required this.onRestart, required this.onNew});

  final VoidCallback onRestart;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onRestart,
            child: Text(context.l10n.restart),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: onNew,
            child: Text(context.l10n.newSeries),
          ),
        ),
      ],
    );
  }
}
