import 'package:flutter/material.dart';

import '../models/series.dart';
import '../models/timer_interval.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../services/timer_engine.dart';
import '../theme.dart';
import '../widgets/duration_picker.dart';
import '../widgets/round_icon_button.dart';
import 'run_screen.dart';

/// Screen 1: build the series (intervals + repetition) and start it.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.sounds, required this.storage});

  final SoundService sounds;
  final StorageService storage;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const _defaultInterval = (minutes: 0, seconds: 30);
  static const _defaultRepeatCount = 2;

  int _idSeq = 0;
  late List<TimerInterval> _intervals = [_newInterval()];
  late String _selectedId = _intervals.first.id;
  LoopMode _loopMode = LoopMode.once;
  int _loopCount = _defaultRepeatCount;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${_idSeq++}';

  TimerInterval _newInterval({int? minutes, int? seconds}) => TimerInterval(
    id: _nextId(),
    minutes: minutes ?? _defaultInterval.minutes,
    seconds: seconds ?? _defaultInterval.seconds,
  );

  Series get _series => Series(
    intervals: _intervals,
    loopMode: _loopMode,
    loopCount: _loopMode == LoopMode.repeatN ? _loopCount : 1,
  );

  int get _selectedIndex => _intervals.indexWhere((i) => i.id == _selectedId);

  /// Reloads the last series, then offers to resume an interrupted run.
  Future<void> _restore() async {
    final draft = await widget.storage.loadDraft();
    if (!mounted) return;
    if (draft != null && draft.intervals.isNotEmpty) {
      setState(() {
        // Fresh ids: persisted ones may collide with newly generated ones.
        _intervals = [
          for (final i in draft.intervals) i.copyWith(id: _nextId()),
        ];
        _selectedId = _intervals.first.id;
        _loopMode = draft.loopMode;
        if (draft.loopMode == LoopMode.repeatN) _loopCount = draft.loopCount;
      });
    }

    final saved = await widget.storage.loadRun();
    if (saved == null || !mounted) return;
    if (!_isStillRunning(saved)) {
      await widget.storage.clearRun();
      return;
    }
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Série interrompue'),
        content: const Text('Une série était en cours. La reprendre ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reprendre'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume ?? false) {
      _openRun(saved.series, restoreFrom: saved.state);
    } else {
      await widget.storage.clearRun();
    }
  }

  bool _isStillRunning(SavedRun saved) {
    if (!saved.series.isValid) return false;
    try {
      final engine = TimerEngine.restore(saved.series, saved.state)..tick();
      return engine.status != TimerStatus.finished;
    } on ArgumentError {
      return false;
    }
  }

  void _addInterval() {
    if (_intervals.length >= Series.maxIntervals) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('${Series.maxIntervals} intervalles maximum'),
          ),
        );
      return;
    }
    // The new interval copies the current one: handy for repeated blocks.
    final current = _intervals[_selectedIndex];
    final added = _newInterval(
      minutes: current.minutes,
      seconds: current.seconds,
    );
    setState(() {
      _intervals.insert(_selectedIndex + 1, added);
      _selectedId = added.id;
    });
  }

  void _updateSelected(int minutes, int seconds) {
    setState(() {
      _intervals[_selectedIndex] = _intervals[_selectedIndex].copyWith(
        minutes: minutes,
        seconds: seconds,
      );
    });
  }

  void _remove(TimerInterval interval) {
    if (_intervals.length <= 1) return;
    setState(() {
      final index = _intervals.indexOf(interval);
      _intervals.removeAt(index);
      if (interval.id == _selectedId) {
        _selectedId = _intervals[index.clamp(0, _intervals.length - 1)].id;
      }
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      _intervals.insert(newIndex, _intervals.removeAt(oldIndex));
    });
  }

  Future<void> _start() async {
    final series = _series;
    if (!series.isValid) return;
    await widget.storage.saveDraft(series);
    if (!mounted) return;
    _openRun(series);
  }

  void _openRun(Series series, {TimerRunState? restoreFrom}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RunScreen(
          series: series,
          sounds: widget.sounds,
          storage: widget.storage,
          restoreFrom: restoreFrom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;
    final selected = _intervals[selectedIndex];
    final series = _series;
    final hasEmpty = _intervals.any((i) => !i.isValid);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'SHORTIM',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 6,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Intervalle ${selectedIndex + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppColors.muted),
              ),
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: DurationPicker(
                      key: ValueKey(selected.id),
                      minutes: selected.minutes,
                      seconds: selected.seconds,
                      onChanged: _updateSelected,
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.add,
                    tooltip: 'Ajouter un intervalle',
                    enabled: _intervals.length < Series.maxIntervals,
                    onPressed: _addInterval,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TotalDuration(series: series),
              const SizedBox(height: 8),
              Expanded(
                child: _IntervalList(
                  intervals: _intervals,
                  selectedId: _selectedId,
                  onSelect: (i) => setState(() => _selectedId = i.id),
                  onRemove: _remove,
                  onReorder: _reorder,
                ),
              ),
              const SizedBox(height: 12),
              _LoopSelector(
                mode: _loopMode,
                count: _loopCount,
                onModeChanged: (m) => setState(() => _loopMode = m),
                onCountChanged: (c) => setState(() => _loopCount = c),
              ),
              const SizedBox(height: 16),
              if (hasEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Chaque intervalle doit durer au moins 1 seconde',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              FilledButton(
                onPressed: series.isValid ? _start : null,
                child: const Text('Démarrer'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalDuration extends StatelessWidget {
  const _TotalDuration({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final detail = series.rounds > 1
        ? '  (${series.rounds} × ${formatDuration(series.roundDuration)})'
        : '';
    return Text(
      'Durée totale : ${formatDuration(series.totalDuration)}$detail',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontFeatures: tabularFigures),
    );
  }
}

class _IntervalList extends StatelessWidget {
  const _IntervalList({
    required this.intervals,
    required this.selectedId,
    required this.onSelect,
    required this.onRemove,
    required this.onReorder,
  });

  final List<TimerInterval> intervals;
  final String selectedId;
  final ValueChanged<TimerInterval> onSelect;
  final ValueChanged<TimerInterval> onRemove;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final canRemove = intervals.length > 1;
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: intervals.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, _, _) => Material(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
      itemBuilder: (context, index) {
        final interval = intervals[index];
        final isSelected = interval.id == selectedId;
        return Padding(
          key: ValueKey(interval.id),
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected ? AppColors.white : AppColors.faint,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelect(interval),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${index + 1}.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                    Text(
                      formatDuration(interval.duration),
                      style: TextStyle(
                        fontSize: 20,
                        fontFeatures: tabularFigures,
                        color: interval.isValid
                            ? AppColors.white
                            : AppColors.faint,
                      ),
                    ),
                    const Spacer(),
                    if (canRemove)
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.muted,
                        onPressed: () => onRemove(interval),
                      ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.drag_handle,
                          color: AppColors.muted,
                          semanticLabel: 'Déplacer',
                        ),
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

class _LoopSelector extends StatelessWidget {
  const _LoopSelector({
    required this.mode,
    required this.count,
    required this.onModeChanged,
    required this.onCountChanged,
  });

  final LoopMode mode;
  final int count;
  final ValueChanged<LoopMode> onModeChanged;
  final ValueChanged<int> onCountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<LoopMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: LoopMode.once, label: Text('1 fois')),
              ButtonSegment(
                value: LoopMode.repeatN,
                label: Text('Répéter x fois'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => onModeChanged(s.single),
          ),
        ),
        if (mode == LoopMode.repeatN)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundIconButton(
                  icon: Icons.remove,
                  tooltip: 'Moins de répétitions',
                  size: 40,
                  enabled: count > 1,
                  onPressed: count > 1 ? () => onCountChanged(count - 1) : null,
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    '$count fois',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                RoundIconButton(
                  icon: Icons.add,
                  tooltip: 'Plus de répétitions',
                  size: 40,
                  enabled: count < Series.maxLoopCount,
                  onPressed: count < Series.maxLoopCount
                      ? () => onCountChanged(count + 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
