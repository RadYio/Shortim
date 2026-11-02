import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// Intervals playing their exit animation: already out of the series, but
  /// still in [_intervals] until the card has collapsed.
  final Set<String> _removing = {};

  /// Interval whose card should play its entrance animation.
  String? _appearingId;

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

  List<TimerInterval> get _active => [
    for (final i in _intervals)
      if (!_removing.contains(i.id)) i,
  ];

  Series get _series => Series(
    intervals: _active,
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
        _removing.clear();
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
    if (_active.length >= Series.maxIntervals) {
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
      _appearingId = added.id;
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

  /// Takes the interval out of the series now; its card animates out and
  /// [_finishRemoval] drops it from the list afterwards.
  void _remove(TimerInterval interval) {
    final active = _active;
    if (active.length <= 1 || _removing.contains(interval.id)) return;
    setState(() {
      final index = active.indexOf(interval);
      _removing.add(interval.id);
      if (interval.id == _selectedId) {
        active.removeAt(index);
        _selectedId = active[index.clamp(0, active.length - 1)].id;
      }
    });
  }

  void _finishRemoval(String id) {
    if (!mounted || !_removing.contains(id)) return;
    setState(() {
      _intervals.removeWhere((i) => i.id == id);
      _removing.remove(id);
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
    final active = _active;
    final hasEmpty = active.any((i) => !i.isValid);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const _Wordmark(),
              const SizedBox(height: 24),
              _Switch(
                child: Text(
                  'INTERVALLE ${active.indexOf(selected) + 1}',
                  key: ValueKey(selected.id),
                  textAlign: TextAlign.center,
                  style: AppText.label(),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: _Switch(
                      child: DurationPicker(
                        key: ValueKey(selected.id),
                        minutes: selected.minutes,
                        seconds: selected.seconds,
                        onChanged: _updateSelected,
                      ),
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.add,
                    tooltip: 'Ajouter un intervalle',
                    enabled: active.length < Series.maxIntervals,
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
                  removing: _removing,
                  appearingId: _appearingId,
                  selectedId: _selectedId,
                  onSelect: (i) => setState(() => _selectedId = i.id),
                  onRemove: _remove,
                  onRemoved: _finishRemoval,
                  onAppeared: (id) {
                    if (_appearingId == id) _appearingId = null;
                  },
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
                    style: TextStyle(color: AppColors.brand400, fontSize: 13),
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Shortim',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/logos/shortim-mark-white.svg', height: 30),
          const SizedBox(width: 10),
          Text('Shortim', style: AppText.wordmark(fontSize: 30)),
        ],
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
      style: AppText.mono(fontSize: 14, color: AppColors.brand300),
    );
  }
}

/// Cross-fades (with a slight scale) when the selected interval changes.
class _Switch extends StatelessWidget {
  const _Switch({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.brand,
      switchOutCurve: AppMotion.brand.flipped,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _IntervalList extends StatelessWidget {
  const _IntervalList({
    required this.intervals,
    required this.removing,
    required this.appearingId,
    required this.selectedId,
    required this.onSelect,
    required this.onRemove,
    required this.onRemoved,
    required this.onAppeared,
    required this.onReorder,
  });

  final List<TimerInterval> intervals;
  final Set<String> removing;
  final String? appearingId;
  final String selectedId;
  final ValueChanged<TimerInterval> onSelect;
  final ValueChanged<TimerInterval> onRemove;
  final ValueChanged<String> onRemoved;
  final ValueChanged<String> onAppeared;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    // Numbering skips cards that are animating out.
    var n = 0;
    final numbers = {
      for (final i in intervals)
        if (!removing.contains(i.id)) i.id: ++n,
    };
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: intervals.length,
      onReorderItem: onReorder,
      proxyDecorator: (child, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Transform.scale(
          scale: 1 + 0.03 * AppMotion.brand.transform(animation.value),
          child: child,
        ),
        child: Material(type: MaterialType.transparency, child: child),
      ),
      itemBuilder: (context, index) {
        final interval = intervals[index];
        return _IntervalCard(
          key: ValueKey(interval.id),
          interval: interval,
          index: index,
          number: numbers[interval.id],
          selected: interval.id == selectedId,
          removing: removing.contains(interval.id),
          appearing: interval.id == appearingId,
          canRemove: n > 1,
          onTap: () => onSelect(interval),
          onRemove: () => onRemove(interval),
          onRemoved: () => onRemoved(interval.id),
          onAppeared: () => onAppeared(interval.id),
        );
      },
    );
  }
}

/// One interval row. Enters with scale + fade + slide (emphasis), leaves
/// with the symmetric motion while its height collapses.
class _IntervalCard extends StatefulWidget {
  const _IntervalCard({
    super.key,
    required this.interval,
    required this.index,
    required this.number,
    required this.selected,
    required this.removing,
    required this.appearing,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
    required this.onRemoved,
    required this.onAppeared,
  });

  final TimerInterval interval;
  final int index;

  /// Position shown to the user; null while animating out.
  final int? number;
  final bool selected;
  final bool removing;
  final bool appearing;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onRemoved;
  final VoidCallback onAppeared;

  @override
  State<_IntervalCard> createState() => _IntervalCardState();
}

class _IntervalCardState extends State<_IntervalCard>
    with SingleTickerProviderStateMixin {
  static const _radius = 20.0;
  static final _scale = Tween(begin: 0.9, end: 1.0);
  static final _slide = Tween(begin: const Offset(0, 0.25), end: Offset.zero);

  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    reverseDuration: AppMotion.base,
    value: widget.appearing ? 0 : 1,
  );
  late final _soft = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.brand,
    reverseCurve: AppMotion.brand.flipped,
  );
  late final _pop = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.emphasis,
    reverseCurve: AppMotion.brand.flipped,
  );
  late int _number = widget.number ?? widget.index + 1;

  @override
  void initState() {
    super.initState();
    if (widget.removing) {
      // Rebuilt (e.g. scrolled back) mid-removal: finish it at once.
      _controller.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRemoved());
    } else if (widget.appearing) {
      _controller.forward().then((_) => widget.onAppeared());
    }
  }

  @override
  void didUpdateWidget(_IntervalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != null) _number = widget.number!;
    if (widget.removing && !oldWidget.removing) {
      _controller.reverse().then((_) {
        if (mounted) widget.onRemoved();
      });
    }
  }

  @override
  void dispose() {
    _soft.dispose();
    _pop.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _soft,
      child: FadeTransition(
        opacity: _soft,
        child: ScaleTransition(
          scale: _scale.animate(_pop),
          child: SlideTransition(
            position: _slide.animate(_pop),
            child: IgnorePointer(
              ignoring: widget.removing,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _card(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final interval = widget.interval;
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.brand,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: widget.selected
              ? Theme.of(context).colorScheme.primary
              : AppColors.brand700,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '$_number.',
                    style: AppText.mono(
                      fontSize: 13,
                      color: AppColors.brand500,
                    ),
                  ),
                ),
                Text(
                  formatDuration(interval.duration),
                  style: AppText.mono(
                    fontSize: 20,
                    color: interval.isValid
                        ? AppColors.text
                        : AppColors.brand600,
                  ),
                ),
                const Spacer(),
                if (widget.canRemove || widget.removing)
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.brand500,
                    onPressed: widget.onRemove,
                  ),
                ReorderableDragStartListener(
                  index: widget.index,
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(4, 12, 16, 12),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.brand500,
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
                    style: AppText.mono(fontSize: 20),
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
