import 'dart:async';

import 'package:flutter/material.dart';

import '../models/series.dart';
import '../models/timer_interval.dart';
import '../services/run_controller.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/timer_engine.dart';
import '../theme.dart';

/// Screen 2: runs the series. Starts as soon as it is displayed.
class RunScreen extends StatefulWidget {
  const RunScreen({
    super.key,
    required this.series,
    required this.sounds,
    required this.storage,
    this.restoreFrom,
  });

  final Series series;
  final SoundService sounds;
  final StorageService storage;

  /// When set, continues an interrupted run instead of starting a new one.
  final TimerRunState? restoreFrom;

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  late final RunController _controller = RunController(
    series: widget.series,
    sounds: widget.sounds,
    storage: widget.storage,
    restoreFrom: widget.restoreFrom,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrêter la série ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arrêter'),
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
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Progress(snapshot: snap),
                    const Spacer(),
                    _Countdown(snapshot: snap),
                    const SizedBox(height: 16),
                    _NextLabel(snapshot: snap),
                    const Spacer(),
                    if (finished)
                      _FinishedActions(
                        onRestart: _controller.restart,
                        onNew: _leave,
                      )
                    else
                      _RunActions(
                        paused: snap.status == TimerStatus.paused,
                        onTogglePause: _controller.togglePause,
                        onStop: _confirmStop,
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

class _Progress extends StatelessWidget {
  const _Progress({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 16,
      color: AppColors.muted,
      fontFeatures: tabularFigures,
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Intervalle ${snapshot.intervalIndex + 1}/${snapshot.intervalCount}',
                style: style,
              ),
            ),
            if (snapshot.rounds > 1)
              Flexible(
                child: Text(
                  'Tour ${snapshot.round}/${snapshot.rounds}',
                  style: style,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: snapshot.status == TimerStatus.finished
                ? 1
                : snapshot.progress.clamp(0, 1),
            minHeight: 3,
            color: AppColors.white,
            backgroundColor: AppColors.faint,
          ),
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final paused = snapshot.status == TimerStatus.paused;
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatDuration(Duration(seconds: snapshot.secondsLeft)),
            style: TextStyle(
              fontSize: 120,
              fontWeight: FontWeight.w200,
              height: 1,
              fontFeatures: tabularFigures,
              color: paused ? AppColors.muted : AppColors.white,
            ),
          ),
        ),
        SizedBox(
          height: 24,
          child: paused
              ? const Text(
                  'EN PAUSE',
                  style: TextStyle(letterSpacing: 4, color: AppColors.muted),
                )
              : null,
        ),
      ],
    );
  }
}

class _NextLabel extends StatelessWidget {
  const _NextLabel({required this.snapshot});

  final TimerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final text = switch (snapshot) {
      TimerSnapshot(status: TimerStatus.finished) => 'Terminé',
      TimerSnapshot(nextDuration: final next?) =>
        'Suivant : ${formatDuration(next)}',
      _ => 'Dernier intervalle',
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 26, fontFeatures: tabularFigures),
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
            child: Text(paused ? 'Reprendre' : 'Pause'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: onStop,
            child: const Text('Arrêter'),
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
            child: const Text('Relancer'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: onNew,
            child: const Text('Nouvelle série'),
          ),
        ),
      ],
    );
  }
}
