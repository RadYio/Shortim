import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/saved_series.dart';
import '../services/series_library.dart';
import '../theme.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/series_name_dialog.dart';
import '../widgets/shortim_mark.dart';

/// "Mes séries": saved series with launch / rename / delete. Lives inside
/// the shell's persistent bottom menu: [onChoice] reports a pick (load,
/// optionally launch) back to it. No back button — the bottom menu is the
/// only nav.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.library,
    required this.libraryReady,
    required this.isActive,
    required this.onChoice,
  });

  final SeriesLibrary library;
  final Future<void> libraryReady;

  /// Whether this is the shell's current section. Series can be saved from
  /// the Chrono tab while this one sits inactive in the background: use the
  /// inactive→active edge to pick up any such change.
  final bool isActive;
  final ValueChanged<LibraryChoice> onChoice;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  static const _stagger = 50; // ms between cards on first display
  static const _maxStaggered = 8;

  var _listKey = GlobalKey<AnimatedListState>();
  late List<SavedSeries> _items = widget.library.items;

  /// Cards fade and slide in one after the other when the screen opens.
  /// Created eagerly (not `late`) so disposing before a first build never
  /// triggers a ticker lookup on a deactivated widget.
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            AppMotion.slow.inMilliseconds +
            _stagger * math.min(_items.length, _maxStaggered),
      ),
    )..forward();
    // The shared library may still be loading when this tab first builds
    // (IndexedStack mounts every section up front): refresh once it's in.
    widget.libraryReady.then((_) {
      if (mounted) setState(() => _items = widget.library.items);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Just switched into this tab: a series may have been saved elsewhere
    // (e.g. from Chrono) while it sat inactive in the background. A fresh
    // key rebuilds the AnimatedList from scratch, no incremental diffing.
    if (widget.isActive && !oldWidget.isActive) {
      setState(() {
        _items = widget.library.items;
        _listKey = GlobalKey<AnimatedListState>();
      });
    }
  }

  void _choose(SavedSeries saved, {required bool launch}) =>
      widget.onChoice((saved: saved, launch: launch));

  Future<void> _rename(SavedSeries saved) async {
    final name = await showSeriesNameDialog(
      context,
      library: widget.library,
      title: context.l10n.rename,
      confirmLabel: context.l10n.rename,
      initial: saved.name,
      renamingId: saved.id,
    );
    if (name == null || name == saved.name) return;
    if (await widget.library.rename(saved.id, name) && mounted) {
      setState(() => _items = widget.library.items);
    }
  }

  Future<void> _delete(SavedSeries saved) async {
    final index = await widget.library.delete(saved.id);
    if (index < 0 || !mounted) return;
    setState(() => _items = widget.library.items);
    _listKey.currentState!.removeItem(
      index,
      (context, animation) =>
          _transition(animation, _card(saved, enabled: false)),
      duration: AppMotion.base,
    );
    showAppSnackBar(
      context,
      context.l10n.deletedSnack(saved.name),
      action: SnackBarAction(
        label: context.l10n.undo,
        onPressed: () => _undoDelete(saved, index),
      ),
    );
  }

  Future<void> _undoDelete(SavedSeries saved, int index) async {
    await widget.library.restore(saved, index);
    if (!mounted) return;
    setState(() => _items = widget.library.items);
    _listKey.currentState!.insertItem(
      _items.indexWhere((s) => s.id == saved.id),
      duration: AppMotion.slow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _items.length;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                context.l10n.mySeries,
                style: AppText.wordmark(fontSize: 32),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                child: AnimatedOpacity(
                  opacity: count > 0 ? 1 : 0,
                  duration: AppMotion.base,
                  child: Text(
                    context.l10n.seriesCount(count),
                    style: AppText.label(),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    AnimatedList(
                      key: _listKey,
                      initialItemCount: count,
                      padding: const EdgeInsets.only(
                        bottom: kBottomBarReserve,
                      ),
                      itemBuilder: (context, index, animation) {
                        final saved = _items[index];
                        return _transition(
                          animation,
                          _staggered(index, _card(saved)),
                        );
                      },
                    ),
                    IgnorePointer(
                      ignoring: count > 0,
                      child: AnimatedOpacity(
                        opacity: count > 0 ? 0 : 1,
                        duration: AppMotion.slow,
                        curve: AppMotion.brand,
                        child: const _EmptyState(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Insert / remove motion driven by [AnimatedList]: height and fade in `brand`,
  /// scale in `emphasis`, symmetric on the way out. Tweens rather than
  /// [CurvedAnimation]s: these are rebuilt often and need no disposal.
  Widget _transition(Animation<double> animation, Widget child) {
    final soft = animation.drive(CurveTween(curve: AppMotion.brand));
    final pop = animation.drive(CurveTween(curve: AppMotion.emphasis));
    return SizeTransition(
      sizeFactor: soft,
      child: FadeTransition(
        opacity: soft,
        child: ScaleTransition(
          scale: Tween(begin: 0.9, end: 1.0).animate(pop),
          child: child,
        ),
      ),
    );
  }

  /// First-display cascade; cards past [_maxStaggered] share the last slot.
  Widget _staggered(int index, Widget child) {
    final total = _intro.duration!.inMilliseconds;
    final start = _stagger * math.min(index, _maxStaggered);
    final slot = Interval(
      start / total,
      (start + AppMotion.slow.inMilliseconds) / total,
    );
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final t = slot.transform(_intro.value);
        return Opacity(
          opacity: AppMotion.brand.transform(t),
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - AppMotion.emphasis.transform(t))),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _card(SavedSeries saved, {bool enabled = true}) {
    return Padding(
      key: ValueKey(saved.id),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: IgnorePointer(
        ignoring: !enabled,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.brand700),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _choose(saved, launch: false),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 4, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saved.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          seriesSummary(context.l10n, saved.series),
                          style: AppText.mono(
                            fontSize: 13,
                            color: AppColors.brand400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.play_arrow_rounded,
                    tooltip: context.l10n.launch,
                    size: 44,
                    onPressed: () => _choose(saved, launch: true),
                  ),
                  PopupMenuButton<_Action>(
                    tooltip: context.l10n.options,
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.brand400,
                    ),
                    onSelected: (action) => switch (action) {
                      _Action.rename => _rename(saved),
                      _Action.delete => _delete(saved),
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _Action.rename,
                        child: Text(context.l10n.rename),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Text(context.l10n.delete),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Action { rename, delete }

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: const Size.square(56),
            painter: ShortimMarkPainter(
              color: ShortimMarkPainter.brandLight.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.emptyLibraryTitle,
            style: const TextStyle(fontSize: 17, color: AppColors.brand300),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.emptyLibraryHint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.brand500),
          ),
        ],
      ),
    );
  }
}
