import 'package:flutter/widgets.dart';

/// State of each stroke of the mark, all in 0..1. [crownDy] is in mark units
/// (the mark is drawn on a 100×100 grid, like `shortim-mark-*.svg`).
typedef MarkFrame = ({
  double ring,
  double crown,
  double crownDy,
  double hand,
  double ticks,
});

const MarkFrame completeMark = (
  ring: 1,
  crown: 1,
  crownDy: 0,
  hand: 1,
  ticks: 0,
);

/// Native rendition of `assets/logos/shortim-mark-*.svg` (paths `ring`,
/// `crown`, `hand` and the click ticks), with each stroke drawable partially.
class ShortimMarkPainter extends CustomPainter {
  const ShortimMarkPainter({
    this.frame = completeMark,
    this.color = brandLight,
  });

  /// Fixed brand-asset colour (not a UI token).
  static const brandLight = Color(0xFFF2F2F0);

  final MarkFrame frame;
  final Color color;

  static final _ringMetric =
      (Path()
            ..moveTo(50, 26)
            ..arcToPoint(
              const Offset(50, 94),
              radius: const Radius.circular(34),
              largeArc: true,
            )
            ..arcToPoint(
              const Offset(51.78, 26.03),
              radius: const Radius.circular(34),
              largeArc: true,
            ))
          .computeMetrics()
          .single;

  static const _handFrom = Offset(50, 60);
  static const _handTo = Offset(64, 44);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt
      ..color = color;

    if (frame.ring > 0) {
      canvas.drawPath(
        _ringMetric.extractPath(0, _ringMetric.length * frame.ring),
        stroke,
      );
    }
    if (frame.crown > 0) {
      final y = 10 + frame.crownDy;
      canvas.drawLine(
        Offset(38, y),
        Offset(62, y),
        Paint.from(stroke)..color = color.withValues(alpha: frame.crown),
      );
    }
    if (frame.hand > 0) {
      canvas.drawLine(
        _handFrom,
        Offset.lerp(_handFrom, _handTo, frame.hand.clamp(0, 1))!,
        stroke,
      );
    }
    if (frame.ticks > 0.01) {
      final ticks = Paint.from(stroke)
        ..strokeWidth = 5
        ..color = color.withValues(alpha: frame.ticks);
      canvas
        ..drawLine(const Offset(28, 6), const Offset(22, 1), ticks)
        ..drawLine(const Offset(72, 6), const Offset(78, 1), ticks);
    }
  }

  @override
  bool shouldRepaint(ShortimMarkPainter oldDelegate) =>
      frame != oldDelegate.frame || color != oldDelegate.color;
}
