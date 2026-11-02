import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/saved_series.dart';
import '../services/series_library.dart';
import '../theme.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/series_name_dialog.dart';
import '../widgets/shortim_mark.dart';

/// What the user picked in "Mes séries": load it into the editor, and
/// optionally start it right away.
typedef LibraryChoice = ({SavedSeries saved, bool launch});

/// "Mes séries": saved series with launch / rename / delete. Pops with a
/// [LibraryChoice], or null when the user just goes back.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.library});

  final SeriesLibrary library;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  static const _stagger = 50; // ms between cards on first display
  static const _maxStaggered = 8;

  final _listKey = GlobalKey<AnimatedListState>();
  late List<SavedSeries> _items = widget.library.items;

  /// Cards fade and slide in one after the other when the screen opens.
  late final _intro = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds:
          AppMotion.slow.inMilliseconds +
          _stagger * math.min(_items.length, _maxStaggered),
    ),
  )..forward();

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  void _choose(SavedSeries saved, {required bool launch}) =>
      Navigator.pop<LibraryChoice>(context, (saved: saved, launch: launch));

  Future<void> _rename(SavedSeries saved) async {
    final name = await showSeriesNameDialog(
      context,
      library: widget.library,
      title: 'Renommer',
      confirmLabel: 'Renommer',
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('« ${saved.name} » supprimée'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => _undoDelete(saved, index),
          ),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    color: AppColors.brand300,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Mes séries',
                      style: AppText.wordmark(fontSize: 32),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 4, bottom: 16),
                child: AnimatedOpacity(
                  opacity: count > 0 ? 1 : 0,
                  duration: AppMotion.base,
                  child: Text(
                    '$count ${count > 1 ? 'SÉRIES' : 'SÉRIE'}',
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
                      padding: const EdgeInsets.only(bottom: 24),
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
                          saved.summary,
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
                    tooltip: 'Lancer',
                    size: 44,
                    onPressed: () => _choose(saved, launch: true),
                  ),
                  PopupMenuButton<_Action>(
                    tooltip: 'Options',
                    icon: const Icon(
                      Icons.more_vert,
                      color: AppColors.brand400,
                    ),
                    onSelected: (action) => switch (action) {
                      _Action.rename => _rename(saved),
                      _Action.delete => _delete(saved),
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _Action.rename,
                        child: Text('Renommer'),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Text('Supprimer'),
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
          const Text(
            'Aucune série enregistrée',
            style: TextStyle(fontSize: 17, color: AppColors.brand300),
          ),
          const SizedBox(height: 8),
          const Text(
            'Composez une série puis touchez « Enregistrer ».',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.brand500),
          ),
        ],
      ),
    );
  }
}
