import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme.dart';
import 'mascot_painter.dart';

/// Face + one-line encouragement shown below the running countdown. The
/// expression and phrase both follow [progress] (reuses
/// `TimerSnapshot.progress`, already computed by the run screen — this
/// widget adds no timing logic of its own), and animate between states
/// instead of hard-swapping.
class Mascot extends StatefulWidget {
  const Mascot({super.key, required this.progress});

  /// Fraction of the current interval already elapsed, in `[0, 1]`.
  final double progress;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late MascotExpression _expression = mascotExpressionForProgress(
    widget.progress,
  );
  late MascotFrame _from = frameFor(_expression);
  late MascotFrame _to = _from;

  /// Bumped every time the expression changes, so a new (but stable until
  /// then) phrase is picked from that state's pool.
  int _phraseSeed = 0;

  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: AppMotion.base,
    value: 1,
  );

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    final next = mascotExpressionForProgress(widget.progress);
    if (next == _expression) return;
    final t = AppMotion.brand.transform(_morph.value);
    _from = lerpMascotFrame(_from, _to, t);
    _to = frameFor(next);
    _expression = next;
    _phraseSeed++;
    _morph.forward(from: 0);
  }

  @override
  void dispose() {
    _morph.dispose();
    super.dispose();
  }

  String _phrase(BuildContext context) {
    final l10n = context.l10n;
    final options = switch (_expression) {
      MascotExpression.fresh => [
        l10n.mascotFresh1,
        l10n.mascotFresh2,
        l10n.mascotFresh3,
      ],
      MascotExpression.mid => [l10n.mascotMid1, l10n.mascotMid2, l10n.mascotMid3],
      MascotExpression.nearEnd => [
        l10n.mascotNearEnd1,
        l10n.mascotNearEnd2,
        l10n.mascotNearEnd3,
      ],
    };
    return options[_phraseSeed % options.length];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: AnimatedBuilder(
            animation: _morph,
            builder: (context, _) {
              final t = AppMotion.brand.transform(_morph.value).clamp(0.0, 1.0);
              return CustomPaint(
                painter: MascotPainter(
                  frame: lerpMascotFrame(_from, _to, t),
                  color: AppColors.accent2,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: AppMotion.base,
          switchInCurve: AppMotion.brand,
          switchOutCurve: AppMotion.brand.flipped,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            _phrase(context),
            key: ValueKey('${_expression.name}-$_phraseSeed'),
            textAlign: TextAlign.center,
            style: AppText.label(color: AppColors.brand400),
          ),
        ),
      ],
    );
  }
}
