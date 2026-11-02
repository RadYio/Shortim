import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/shortim_mark.dart';
import '../widgets/transitions.dart';

/// Launch screen: draws the Shortim mark once (timeline of
/// `shortim-mark-animated-*.svg`), then fades into [next]. Tap to skip.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  final WidgetBuilder next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _total = 2900; // ms, including the final hold

  static Interval _at(int fromMs, int toMs, [Curve curve = Curves.linear]) =>
      Interval(fromMs / _total, toMs / _total, curve: curve);

  // Timeline (ms): ring draws 0–1100, crown drops in 1100–1500, "click" at
  // ~1900 (crown dips, ticks flash, hand draws), wordmark, hold.
  static final _ring = _at(0, 1100, AppMotion.brand);
  static final _crownIn = _at(1100, 1500, AppMotion.brand);
  static final _click = _at(1800, 2250);
  static final _ticks = _at(1850, 2300);
  static final _hand = _at(1900, 2250, AppMotion.brand);
  static final _wordmark = _at(2000, 2550, AppMotion.brand);

  /// Crown dips 4 units on the click, then springs back with a slight bounce.
  static final _crownDip = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 4.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 4.0,
        end: 0.0,
      ).chain(CurveTween(curve: AppMotion.emphasis)),
      weight: 70,
    ),
  ]);

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _total),
  );
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(_leave);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show the finished mark, still hand over after a beat.
    if (MediaQuery.disableAnimationsOf(context)) _controller.value = 0.9;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    Navigator.of(context).pushReplacement(fadeSlideRoute<void>(widget.next));
  }

  MarkFrame _frame(double t) {
    final crownIn = _crownIn.transform(t);
    return (
      ring: _ring.transform(t),
      crown: crownIn,
      crownDy: -8 * (1 - crownIn) + _crownDip.transform(_click.transform(t)),
      hand: _hand.transform(t),
      ticks: math.sin(math.pi * _ticks.transform(t)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Semantics(
          label: 'Shortim',
          excludeSemantics: true,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                final word = _wordmark.transform(t);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: const Size.square(120),
                      painter: ShortimMarkPainter(frame: _frame(t)),
                    ),
                    const SizedBox(height: 28),
                    Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - word)),
                        child: Text(
                          'Shortim',
                          style: AppText.wordmark(
                            fontSize: 44,
                            color: ShortimMarkPainter.brandLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
